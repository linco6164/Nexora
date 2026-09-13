import 'package:flutter/material.dart';
import 'api_service.dart';
import 'socket_service.dart';
import 'models/chat_models.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String otherUsername;
  final String myUserId;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.otherUsername,
    required this.myUserId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _otherIsTyping = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    SocketService.joinConversation(widget.conversationId);

    SocketService.onNewMessage((message) {
      if (message.conversationId == widget.conversationId && mounted) {
        setState(() => _messages.add(message));
        _scrollToBottom();
      }
    });

    SocketService.onTyping((userId) {
      if (userId != widget.myUserId && mounted) {
        setState(() => _otherIsTyping = true);
      }
    });

    SocketService.onStopTyping((userId) {
      if (userId != widget.myUserId && mounted) {
        setState(() => _otherIsTyping = false);
      }
    });
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await ApiService.getMessages(widget.conversationId);
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    SocketService.sendMessage(conversationId: widget.conversationId, text: text);
    SocketService.stopTyping(widget.conversationId);
    _messageController.clear();
  }

  @override
  void dispose() {
    SocketService.leaveConversation(widget.conversationId);
    SocketService.offNewMessage();
    SocketService.offTyping();
    SocketService.offStopTyping();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUsername),
        bottom: _otherIsTyping
            ? PreferredSize(
                preferredSize: const Size.fromHeight(20),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('scrie...', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMine = message.sender.id == widget.myUserId;

                      return Align(
                        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isMine
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            message.text,
                            style: TextStyle(color: isMine ? Colors.white : Colors.black87),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: (text) {
                        if (text.isNotEmpty) {
                          SocketService.typing(widget.conversationId);
                        } else {
                          SocketService.stopTyping(widget.conversationId);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Scrie un mesaj...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}