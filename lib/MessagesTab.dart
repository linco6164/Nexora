import 'package:flutter/material.dart';
import 'api_service.dart';
import 'models/chat_models.dart';
import 'ChatPage.dart';

class MessagesTab extends StatefulWidget {
  const MessagesTab({super.key});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  late Future<List<Conversation>> _conversationsFuture;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndConversations();
  }

  Future<void> _loadCurrentUserAndConversations() async {
    final me = await ApiService.getCurrentUser();
    setState(() {
      _myUserId = me['_id'];
      _conversationsFuture = ApiService.getConversations();
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _conversationsFuture = ApiService.getConversations();
    });
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'acum';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}z';
  }

  @override
  Widget build(BuildContext context) {
    if (_myUserId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Conversation>>(
        future: _conversationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Eroare: ${snapshot.error}'));
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 100),
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Center(child: Text('Nicio conversație încă')),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final other = conversation.otherParticipant(_myUserId!);
              final unreadCount = conversation.unreadCountFor(_myUserId!);

              return ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundImage: other?.avatar != null
                          ? NetworkImage(other!.avatar!)
                          : null,
                      child: other?.avatar == null
                          ? Text(other?.username[0].toUpperCase() ?? '?')
                          : null,
                    ),
                  ],
                ),
                title: Text(
                  other?.username ?? 'Utilizator',
                  style: TextStyle(
                    fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  conversation.listing != null
                      ? '${conversation.listing!.title} • ${conversation.lastMessage}'
                      : conversation.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                    color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(conversation.lastMessageAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(height: 4),
                      CircleAvatar(
                        radius: 9,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        conversationId: conversation.id,
                        otherUsername: other?.username ?? 'Utilizator',
                        myUserId: _myUserId!,
                      ),
                    ),
                  ).then((_) => _refresh());
                },
              );
            },
          );
        },
      ),
    );
  }
}