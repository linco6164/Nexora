import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'app_feedback.dart';
import 'socket_service.dart';
import 'models/chat_models.dart';
import 'chat_page.dart';
import 'web/widgets/web_page_frame.dart';

class MessagesTab extends StatefulWidget {
  const MessagesTab({super.key});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  Future<List<Conversation>>? _conversationsFuture;

  String? _myUserId;

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  bool _onlyUnread = false;
  VoidCallback? _removeConversationUpdatedListener;
  final Set<String> _hiddenConversationIds = <String>{};
  final Set<String> _deletingConversationIds = <String>{};
  final Map<String, DateTime> _conversationDeletedAt = <String, DateTime>{};

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final me = await ApiService.getCurrentUser();

      if (!mounted) return;

      final userId = me['_id']?.toString();

      if (userId == null || userId.isEmpty) {
        return;
      }

      setState(() {
        _myUserId = userId;
        _conversationsFuture = ApiService.getConversations();
      });

      try {
        await SocketService.connect();

        if (!mounted) return;

        _removeConversationUpdatedListener?.call();
        _removeConversationUpdatedListener =
            SocketService.onConversationUpdated(_handleConversationUpdated);
      } catch (error) {
        debugPrint('MESSAGES SOCKET ERROR: $error');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _conversationsFuture = Future.error(e);
      });
    }
  }

  void _handleConversationUpdated(Conversation updated) {
    if (!mounted) return;

    final deletedAt = _conversationDeletedAt[updated.id];
    final hasNewActivity =
        deletedAt != null &&
        updated.lastMessageAt != null &&
        updated.lastMessageAt!.isAfter(deletedAt);

    if (_hiddenConversationIds.contains(updated.id) && !hasNewActivity) {
      return;
    }

    if (hasNewActivity) {
      _hiddenConversationIds.remove(updated.id);
      _conversationDeletedAt.remove(updated.id);
    }

    final future = _conversationsFuture;

    if (future == null) return;

    future.then((conversations) {
      if (!mounted) return;

      final index = conversations.indexWhere(
        (conversation) => conversation.id == updated.id,
      );

      if (index == -1) {
        setState(() {
          _conversationsFuture = ApiService.getConversations();
        });

        return;
      }

      final updatedList = List<Conversation>.from(conversations);

      updatedList[index] = updated;

      updatedList.sort((a, b) {
        final aDate = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        final bDate = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      setState(() {
        _conversationsFuture = Future.value(updatedList);
      });
    }, onError: (_) {});
  }

  Future<void> _refresh() async {
    final future = ApiService.getConversations();

    setState(() {
      _conversationsFuture = future;
    });

    await future;
  }

  Future<void> _deleteConversation(Conversation conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ștergi conversația?'),
          content: const Text(
            'Conversația va fi eliminată din lista ta de mesaje.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Anulează'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Șterge'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _deletingConversationIds.add(conversation.id);
    });

    try {
      await ApiService.deleteConversation(conversation.id);

      if (!mounted) return;

      final current =
          await (_conversationsFuture ??
              Future<List<Conversation>>.value(const <Conversation>[]));

      if (!mounted) return;

      setState(() {
        _hiddenConversationIds.add(conversation.id);
        _conversationDeletedAt[conversation.id] = DateTime.now().toUtc();
        _deletingConversationIds.remove(conversation.id);
        _conversationsFuture = Future<List<Conversation>>.value(
          current
              .where((item) => item.id != conversation.id)
              .toList(growable: false),
        );
      });

      AppFeedback.success(context, 'Conversația a fost ștearsă.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _deletingConversationIds.remove(conversation.id);
      });

      AppFeedback.error(
        context,
        e,
        fallback: 'Conversația nu a putut fi ștearsă.',
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _removeConversationUpdatedListener?.call();

    super.dispose();
  }

  List<Conversation> _filterConversations(List<Conversation> conversations) {
    final myUserId = _myUserId;
    if (myUserId == null) return const <Conversation>[];

    final query = _searchQuery.trim().toLowerCase();

    return conversations.where((conversation) {
      if (_hiddenConversationIds.contains(conversation.id)) return false;

      if (_onlyUnread && conversation.unreadCountFor(myUserId) == 0) {
        return false;
      }

      if (query.isEmpty) return true;

      final other = conversation.otherParticipant(myUserId);

      final username = other?.username.toLowerCase() ?? '';

      final lastMessage = conversation.lastMessage.toLowerCase();

      final listingTitle = conversation.listing?.title.toLowerCase() ?? '';

      return username.contains(query) ||
          lastMessage.contains(query) ||
          listingTitle.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    if (_myUserId == null || _conversationsFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<List<Conversation>>(
      future: _conversationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildError(context, snapshot.error.toString());
        }

        final allConversations = snapshot.data ?? const <Conversation>[];
        final conversations = _filterConversations(allConversations);
        final unreadConversations = allConversations
            .where((item) => item.unreadCountFor(_myUserId!) > 0)
            .length;

        final content = RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (!kIsWeb)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mesaje',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Conversațiile tale',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                  ),
                ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    kIsWeb ? 16 : 20,
                    kIsWeb ? 16 : 4,
                    kIsWeb ? 16 : 20,
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: kIsWeb ? 44 : null,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Caută după persoană, produs sau mesaj',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    tooltip: 'Șterge căutarea',
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  )
                                : null,
                            filled: true,
                            fillColor: colors.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                kIsWeb ? 10 : 18,
                              ),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text('Toate (${allConversations.length})'),
                            selected: !_onlyUnread,
                            onSelected: (_) {
                              setState(() => _onlyUnread = false);
                            },
                          ),
                          ChoiceChip(
                            label: Text('Necitite ($unreadConversations)'),
                            selected: _onlyUnread,
                            onSelected: (_) {
                              setState(() => _onlyUnread = true);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (conversations.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    kIsWeb ? 8 : 12,
                    0,
                    kIsWeb ? 8 : 12,
                    kIsWeb ? 24 : 110,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final conversation = conversations[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: _ConversationTile(
                          conversation: conversation,
                          myUserId: _myUserId!,
                          isDeleting: _deletingConversationIds.contains(
                            conversation.id,
                          ),
                          onDelete: () => _deleteConversation(conversation),
                          onTap: () {
                            final other = conversation.otherParticipant(
                              _myUserId!,
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatPage(
                                  conversationId: conversation.id,
                                  otherUsername:
                                      other?.username ?? 'Utilizator',
                                  myUserId: _myUserId!,
                                  listing: conversation.listing,
                                ),
                              ),
                            ).then((_) => _refresh());
                          },
                        ),
                      );
                    }, childCount: conversations.length),
                  ),
                ),
            ],
          ),
        );

        if (!kIsWeb) return content;

        return WebPageFrame(
          title: 'Mesaje',
          subtitle: unreadConversations == 0
              ? '${allConversations.length} conversații'
              : '$unreadConversations conversații necitite',
          maxWidth: 920,
          actions: [
            IconButton(
              onPressed: _refresh,
              tooltip: 'Reîncarcă',
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          child: content,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final hasSearch = _searchQuery.trim().isNotEmpty;
    final isFiltered = hasSearch || _onlyUnread;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                isFiltered ? Icons.filter_alt_off_rounded : Icons.chat_outlined,
                size: 34,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isFiltered ? 'Nu am găsit conversații' : 'Nicio conversație încă',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered ? 'Schimbă filtrul sau încearcă un alt termen.' : 'Când contactezi un cumpărător sau un vânzător, conversația va apărea aici.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 52, color: colors.error),
            const SizedBox(height: 16),
            Text(
              'Nu am putut încărca mesajele.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            FilledButton(onPressed: _refresh, child: const Text('Reîncearcă')),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final String myUserId;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isDeleting;

  const _ConversationTile({
    required this.conversation,
    required this.myUserId,
    required this.onTap,
    required this.onDelete,
    this.isDeleting = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final other = conversation.otherParticipant(myUserId);

    final unread = conversation.unreadCountFor(myUserId);

    final avatar = other?.avatar;

    final username = other?.username ?? 'Utilizator';
    final listingImages = conversation.listing?.images ?? const <String>[];
    final listingImage = listingImages.isEmpty ? null : listingImages.first;

    return Material(
      color: unread > 0
          ? colors.primaryContainer.withValues(alpha: 0.20)
          : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kIsWeb ? 12 : 18),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: InkWell(
        onTap: isDeleting ? null : onTap,
        onLongPress: isDeleting ? null : onDelete,
        borderRadius: BorderRadius.circular(kIsWeb ? 12 : 18),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: kIsWeb ? 14 : 10,
            vertical: kIsWeb ? 10 : 11,
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: kIsWeb ? 24 : 26,
                    backgroundImage: avatar != null && avatar.isNotEmpty
                        ? NetworkImage(avatar)
                        : null,
                    backgroundColor: colors.surfaceContainerHighest,
                    child: avatar == null || avatar.isEmpty
                        ? Text(
                            username.isNotEmpty
                                ? username[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  if (unread > 0)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: unread > 0
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (conversation.lastMessageAt != null)
                          Text(
                            _formatDate(conversation.lastMessageAt!),
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.onSurfaceVariant,
                              fontWeight: unread > 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (conversation.listing != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          conversation.listing!.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        if (conversation.lastMessageStatus != null) ...[
                          _MessageStatus(
                            status: conversation.lastMessageStatus!,
                          ),
                          const SizedBox(width: 5),
                        ],

                        Expanded(
                          child: Text(
                            conversation.lastMessage.trim().isEmpty
                                ? 'Începe conversația'
                                : conversation.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: unread > 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (listingImage != null && listingImage.isNotEmpty) ...[
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    listingImage,
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 42,
                      height: 42,
                      color: colors.surfaceContainerHighest,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
              if (isDeleting)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                PopupMenuButton<String>(
                  tooltip: 'Opțiuni conversație',
                  onSelected: (value) {
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded),
                          SizedBox(width: 10),
                          Text('Șterge conversația'),
                        ],
                      ),
                    ),
                  ],
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();

    final local = date.toLocal();

    final difference = now.difference(local);

    if (difference.inMinutes < 1) {
      return 'acum';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }

    if (difference.inDays == 1) {
      return 'ieri';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}z';
    }

    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}';
  }
}

class _MessageStatus extends StatelessWidget {
  final String status;

  const _MessageStatus({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    switch (status) {
      case 'seen':
        return Icon(Icons.done_all_rounded, size: 16, color: colors.primary);

      case 'delivered':
        return Icon(
          Icons.done_all_rounded,
          size: 16,
          color: colors.onSurfaceVariant,
        );

      case 'sent':
        return Icon(
          Icons.check_rounded,
          size: 16,
          color: colors.onSurfaceVariant,
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
