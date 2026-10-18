import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'activity_events.dart';
import 'activity_controller.dart';
import 'chat_page.dart';
import 'listing_detail_page.dart';
import 'web/web_product_page.dart';
import 'app_feedback.dart';
import 'invite_friend_page.dart';
import 'models/notification_model.dart';
import 'order_page.dart';
import 'web/widgets/web_page_frame.dart';

class NotificationsPage extends StatefulWidget {
  final String? type;
  const NotificationsPage({super.key, this.type});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<AppNotification>> _notificationsFuture;
  StreamSubscription<ActivityEvent>? _activitySubscription;
  Timer? _reloadTimer;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = ApiService.getNotifications(type: widget.type);
    _activitySubscription = activityEvents.stream.listen(
      (_) => _scheduleReload(),
    );
    activityController.addListener(_scheduleReload);
  }

  void _scheduleReload() {
    _reloadTimer?.cancel();
    _reloadTimer = Timer(const Duration(milliseconds: 400), _reloadQuietly);
  }

  Future<void> _reloadQuietly() async {
    try {
      final items = await ApiService.getNotifications(type: widget.type);
      if (mounted) setState(() => _notificationsFuture = Future.value(items));
    } catch (_) {
      // Keep the current list when the network is temporarily unavailable.
    }
  }

  @override
  void dispose() {
    _reloadTimer?.cancel();
    _activitySubscription?.cancel();
    activityController.removeListener(_scheduleReload);
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _notificationsFuture = ApiService.getNotifications(type: widget.type);
    });

    await _notificationsFuture;
  }

  Future<void> _markAllAsRead() async {
    try {
      if (widget.type == null) {
        await ApiService.markAllNotificationsAsRead();
      } else {
        // Never clear unrelated notifications on an older server.
        final items = await _notificationsFuture;
        await Future.wait(
          items
              .where((item) => !item.read)
              .map((item) => ApiService.markNotificationAsRead(item.id)),
        );
      }

      if (!mounted) return;

      setState(() {
        _notificationsFuture = ApiService.getNotifications(type: widget.type);
      });

      AppFeedback.success(
        context,
        widget.type == null
            ? 'Toate notificările au fost marcate ca citite.'
            : 'Notificările afișate au fost marcate ca citite.',
      );
    } catch (e) {
      if (!mounted) return;

      AppFeedback.error(
        context,
        e,
        fallback: 'Notificările nu au putut fi actualizate.',
      );
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.read) return;

    try {
      await ApiService.markNotificationAsRead(notification.id);

      if (!mounted) return;

      setState(() {
        _notificationsFuture = ApiService.getNotifications(type: widget.type);
      });
    } catch (e) {
      if (!mounted) return;

      AppFeedback.error(
        context,
        e,
        fallback: 'Notificarea nu a putut fi marcată drept citită.',
      );
    }
  }

  Future<void> _handleNotificationTap(AppNotification notification) async {
    // Marcăm notificarea ca citită înainte de navigare.
    await _markAsRead(notification);

    if (!mounted) {
      return;
    }

    // ========================================================
    // ORDER DETAILS
    // ========================================================

    if (notification.route == 'order_details') {
      final orderId = notification.orderId;

      if (orderId == null || orderId.isEmpty) {
        AppFeedback.warning(context, 'Notificarea nu conține ID-ul comenzii.');

        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderDetailsPage(orderId: orderId)),
      );

      if (mounted) {
        await _refresh();
      }

      return;
    }

    if (notification.route == 'referrals') {
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const InviteFriendPage()));

      if (mounted) {
        await _refresh();
      }

      return;
    }

    final conversationId = notification.conversationId;
    if (conversationId != null && conversationId.isNotEmpty) {
      try {
        final user = await ApiService.getCurrentUser();
        final userId = (user['_id'] ?? user['id'])?.toString() ?? '';
        final conversations = await ApiService.getConversations();
        final conversation = conversations.firstWhere(
          (c) => c.id == conversationId,
        );
        final other = conversation.otherParticipant(userId);
        if (!mounted || other == null) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatPage(
              conversationId: conversationId,
              otherUsername: other.username,
              myUserId: userId,
              listing: conversation.listing,
            ),
          ),
        );
      } catch (error) {
        if (mounted) {
          AppFeedback.error(
            context,
            error,
            fallback: 'Conversația nu a putut fi deschisă.',
          );
        }
      }
    } else if (notification.listingId?.isNotEmpty == true) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => kIsWeb
              ? WebProductPage(productId: notification.listingId!)
              : ListingDetailPage(listingId: notification.listingId!),
        ),
      );
    }
    if (mounted) await _refresh();
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    try {
      await ApiService.deleteNotification(notification.id);

      if (!mounted) return;

      setState(() {
        _notificationsFuture = ApiService.getNotifications(type: widget.type);
      });
    } catch (e) {
      if (!mounted) return;

      AppFeedback.error(
        context,
        e,
        fallback: 'Notificarea nu a putut fi ștearsă.',
      );
    }
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'Acum';

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min';
    }

    if (diff.inHours < 24) {
      return '${diff.inHours} h';
    }

    if (diff.inDays < 7) {
      return '${diff.inDays} zile';
    }

    if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} săpt.';
    }

    if (diff.inDays < 365) {
      return '${(diff.inDays / 30).floor()} luni';
    }

    return '${(diff.inDays / 365).floor()} ani';
  }

  int _unreadCount(List<AppNotification> notifications) {
    return notifications.where((n) => !n.read).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final body = FutureBuilder<List<AppNotification>>(
      future: _notificationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final notifications = snapshot.data ?? [];
        final pageUnreadCount = _unreadCount(notifications);
        final totalUnreadCount = widget.type == null
            ? activityController.counts.notifications
            : activityController.counts.favorites;
        final unreadCount = totalUnreadCount > pageUnreadCount
            ? totalUnreadCount
            : pageUnreadCount;

        if (notifications.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Activitatea ta',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              unreadCount == 0
                                  ? 'Ești la curent cu toate notificările'
                                  : '$unreadCount notificări necitite',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (unreadCount > 0)
                        TextButton.icon(
                          onPressed: _markAllAsRead,
                          icon: const Icon(Icons.done_all, size: 18),
                          label: Text(
                            widget.type == null
                                ? 'Citește toate'
                                : 'Citește afișate',
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _NotificationCard(
                        notification: notification,
                        time: _formatTime(notification.createdAt),
                        onTap: () {
                          _handleNotificationTap(notification);
                        },
                        onDelete: () => _deleteNotification(notification),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: kIsWeb
          ? null
          : AppBar(
              elevation: 0,
              backgroundColor: colorScheme.surface,
              title: const Text(
                'Notificări',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
      body: kIsWeb
          ? WebPageFrame(
              title: 'Notificări',
              subtitle: 'Activitatea recentă a contului tău',
              maxWidth: 900,
              actions: [
                IconButton(
                  onPressed: _refresh,
                  tooltip: 'Reîncarcă',
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
              child: body,
            )
          : body,
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 130),

          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 46,
                color: colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Center(
            child: Text(
              'Nicio notificare',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
            ),
          ),

          const SizedBox(height: 8),

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Când vei avea activitate nouă, o vei vedea aici.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 54, color: colorScheme.error),
            const SizedBox(height: 16),
            const Text(
              'Nu am putut încărca notificările',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _notificationsFuture = ApiService.getNotifications();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Încearcă din nou'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final String time;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.time,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isUnread = !notification.read;
    final accent = _accentColor(colorScheme);

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Ștergi notificarea?'),
                  content: const Text('Această acțiune nu poate fi anulată.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Anulează'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Șterge'),
                    ),
                  ],
                );
              },
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline, color: colorScheme.onError, size: 26),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              color: isUnread
                  ? accent.withValues(alpha: 0.09)
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isUnread
                    ? accent.withValues(alpha: 0.32)
                    : colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIcon(context),

                  const SizedBox(width: 13),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isUnread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 5),

                        Text(
                          notification.message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),

                        if (isUnread) ...[
                          const SizedBox(height: 9),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Necitită',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUnread = !notification.read;
    final accent = _accentColor(colorScheme);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isUnread
            ? accent.withValues(alpha: 0.14)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        notification.icon,
        size: 23,
        color: isUnread ? accent : colorScheme.onSurfaceVariant,
      ),
    );
  }

  Color _accentColor(ColorScheme colors) {
    return switch (notification.type) {
      'message' => colors.primary,
      'favorite' => const Color(0xFFE44B78),
      'offer' => const Color(0xFFE59324),
      'sale' => const Color(0xFF24A866),
      'listing' => const Color(0xFF3979E8),
      _ => const Color(0xFF7C5CFC),
    };
  }
}
