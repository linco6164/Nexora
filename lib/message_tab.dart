import 'package:flutter/material.dart';

import 'api_service.dart';
import 'socket_service.dart';
import 'models/chat_models.dart';
import 'chat_page.dart';

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

  @override
  void initState() {
    super.initState();

    _initialize();

    SocketService.onConversationUpdated(_handleConversationUpdated);
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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _conversationsFuture = Future.error(e);
      });
    }
  }

  void _handleConversationUpdated(Conversation updated) {
    if (!mounted) return;

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
    });
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

    try {
      await ApiService.deleteConversation(conversation.id);

      if (!mounted) return;

      await _refresh();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nu am putut șterge conversația: $e')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();

    SocketService.offConversationUpdated();

    super.dispose();
  }

  String _formatTime(DateTime? date) {
    if (date == null) {
      return '';
    }

    final now = DateTime.now();
    final localDate = date.toLocal();

    final difference = now.difference(localDate);

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

    return '${localDate.day.toString().padLeft(2, '0')}.'
        '${localDate.month.toString().padLeft(2, '0')}';
  }

  List<Conversation> _filterConversations(List<Conversation> conversations) {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return conversations;
    }

    return conversations.where((conversation) {
      final other = conversation.otherParticipant(_myUserId!);

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

        final conversations = _filterConversations(snapshot.data ?? []);

        return RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
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
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Caută conversații...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();

                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                              icon: const Icon(Icons.close_rounded),
                            )
                          : null,
                      filled: true,
                      fillColor: colors.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
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
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 110),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final conversation = conversations[index];

                      return GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onLongPress: () {
                          _deleteConversation(conversation);
                        },
                        child: _ConversationTile(
                          conversation: conversation,
                          myUserId: _myUserId!,
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
                                ),
                              ),
                            ).then((_) {
                              _refresh();
                            });
                          },
                        ),
                      );
                    }, childCount: conversations.length),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final hasSearch = _searchQuery.trim().isNotEmpty;

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
                hasSearch ? Icons.search_off_rounded : Icons.chat_outlined,
                size: 34,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasSearch ? 'Nu am găsit conversații' : 'Nicio conversație încă',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch ? 'Încearcă un alt nume sau cuvânt.' : 'Când contactezi un cumpărător sau un vânzător, conversația va apărea aici.',
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

  const _ConversationTile({
    required this.conversation,
    required this.myUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final other = conversation.otherParticipant(myUserId);

    final unread = conversation.unreadCountFor(myUserId);

    final avatar = other?.avatar;

    final username = other?.username ?? 'Utilizator';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 28,
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
                              fontSize: 18,
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
              const SizedBox(width: 14),
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
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
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

  const _MessageStatus({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    switch (status) {
      case 'seen':
        return Icon(
          Icons.done_all_rounded,
          size: 16,
          color: colors.primary,
        );

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
