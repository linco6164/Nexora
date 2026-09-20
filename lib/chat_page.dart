import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final TextEditingController _messageController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];

  bool _isLoading = true;
  bool _otherIsTyping = false;

  @override
  void initState() {
    super.initState();

    _loadMessages();

    SocketService.joinConversation(widget.conversationId);

    SocketService.onNewMessage((message) {
      if (message.conversationId != widget.conversationId) {
        return;
      }

      if (!mounted) return;

      setState(() {
        _messages.add(message);
      });

      _scrollToBottom();

      if (message.sender.id != widget.myUserId) {
        _markConversationAsSeen();
      }
    });

    SocketService.onTyping((userId) {
      if (!mounted) return;

      if (userId != widget.myUserId) {
        setState(() {
          _otherIsTyping = true;
        });
      }
    });

    SocketService.onStopTyping((userId) {
      if (!mounted) return;

      if (userId != widget.myUserId) {
        setState(() {
          _otherIsTyping = false;
        });
      }
    });
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await ApiService.getMessages(widget.conversationId);

      if (!mounted) return;

      setState(() {
        _messages
          ..clear()
          ..addAll(messages);

        _isLoading = false;
      });

      await _markConversationAsSeen();

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    SocketService.sendMessage(
      conversationId: widget.conversationId,
      text: text,
    );

    SocketService.stopTyping(widget.conversationId);

    _messageController.clear();
  }

  Future<void> _showOfferDialog() async {
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return const _OfferBottomSheet();
      },
    );

    if (amount == null) {
      return;
    }

    try {
      final message = await ApiService.sendOffer(
        conversationId: widget.conversationId,
        amount: amount,
      );

      if (!mounted) return;

      setState(() {
        _messages.add(message);
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Nu am putut trimite oferta: $e')));
    }
  }

  Future<void> _acceptOffer(Offer offer) async {
    try {
      await ApiService.acceptOffer(offer.id);

      await _loadMessages();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Oferta a fost acceptată.')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Nu am putut accepta oferta: $e')));
    }
  }

  Future<void> _rejectOffer(Offer offer) async {
    try {
      await ApiService.rejectOffer(offer.id);

      await _loadMessages();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Oferta a fost refuzată.')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Nu am putut refuza oferta: $e')));
    }
  }

  Future<void> _deleteMessageForMe(ChatMessage message) async {
    try {
      await ApiService.deleteMessage(messageId: message.id, mode: 'me');

      await _loadMessages();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Nu am putut șterge mesajul: $e')));
    }
  }

  Future<void> _deleteMessageForEveryone(ChatMessage message) async {
    try {
      await ApiService.deleteMessage(messageId: message.id, mode: 'everyone');

      await _loadMessages();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Nu am putut șterge mesajul: $e')));
    }
  }

  Future<void> _markConversationAsSeen() async {
    try {
      await ApiService.markConversationAsSeen(widget.conversationId);
    } catch (e) {
      debugPrint('MARK AS SEEN ERROR: $e');
    }
  }

  Future<void> _showMessageActions(ChatMessage message) async {
    if (message.isDeleted) {
      return;
    }

    HapticFeedback.mediumImpact();

    final isMine = message.sender.id == widget.myUserId;

    final isOffer = message.type == 'offer';

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Șterge pentru mine'),
                onTap: () {
                  Navigator.pop(context, 'me');
                },
              ),

              if (isMine && !isOffer)
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined),
                  title: const Text('Șterge pentru toți'),
                  onTap: () {
                    Navigator.pop(context, 'everyone');
                  },
                ),

              ListTile(
                leading: const Icon(Icons.close_rounded),
                title: const Text('Anulează'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (action == 'me') {
      await _deleteMessageForMe(message);
    } else if (action == 'everyone') {
      await _deleteMessageForEveryone(message);
    }
  }

  Widget _buildAvatar(String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 14,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: Colors.grey[300],
      );
    }

    return CircleAvatar(
      radius: 14,
      backgroundColor: Colors.grey[300],
      child: const Icon(Icons.person, size: 16, color: Colors.white),
    );
  }

  Widget _buildTextMessage(
    BuildContext context,
    ChatMessage message,
    bool isMine,
    bool showAvatar,
    bool nextIsSameSender,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine)
            SizedBox(
              width: 30,
              child: showAvatar
                  ? _buildAvatar(message.sender.avatar)
                  : const SizedBox(width: 30),
            ),

          if (!isMine) const SizedBox(width: 6),

          Flexible(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: () {
                debugPrint('LONG PRESS MESSAGE: ${message.id}');

                _showMessageActions(message);
              },
              child: Container(
                margin: EdgeInsets.only(top: nextIsSameSender ? 0 : 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: isMine ? colors.primary : Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(
                      isMine ? 18 : (showAvatar ? 4 : 18),
                    ),
                    bottomRight: Radius.circular(
                      isMine ? (showAvatar ? 4 : 18) : 18,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      message.isDeleted ? 'Mesaj șters' : message.text,
                      style: TextStyle(
                        color: message.isDeleted
                            ? Colors.grey
                            : (isMine ? Colors.white : Colors.black87),
                        fontStyle: message.isDeleted
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),

                    if (isMine) ...[
                      const SizedBox(height: 3),
                      _buildMessageStatus(message),
                    ],
                  ],
                ),
              ),
            ),
          ),

          if (isMine) const SizedBox(width: 6),

          if (isMine)
            SizedBox(
              width: 30,
              child: showAvatar
                  ? _buildAvatar(message.sender.avatar)
                  : const SizedBox(width: 30),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageStatus(ChatMessage message) {
    if (message.sender.id != widget.myUserId) {
      return const SizedBox.shrink();
    }

    final delivered = message.deliveredTo.any((id) => id != widget.myUserId);

    final seen = message.seenBy.any((id) => id != widget.myUserId);

    if (seen) {
      return const Icon(
        Icons.done_all_rounded,
        size: 15,
        color: Colors.lightBlue,
      );
    }

    if (delivered) {
      return const Icon(
        Icons.done_all_rounded,
        size: 15,
        color: Colors.white70,
      );
    }

    return const Icon(Icons.done_rounded, size: 15, color: Colors.white70);
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
                  child: Text(
                    'scrie...',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
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
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];

                      final isMine = message.sender.id == widget.myUserId;

                      if (message.type == 'offer' && message.offer != null) {
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onLongPress: () {
                            debugPrint('LONG PRESS OFFER: ${message.id}');

                            _showMessageActions(message);
                          },
                          child: _OfferMessageCard(
                            message: message,
                            offer: message.offer!,
                            isMine: isMine,
                            myUserId: widget.myUserId,
                            onAccept: () => _acceptOffer(message.offer!),
                            onReject: () => _rejectOffer(message.offer!),
                          ),
                        );
                      }

                      final nextMessage = index + 1 < _messages.length
                          ? _messages[index + 1]
                          : null;

                      final nextIsSameSender =
                          nextMessage != null &&
                          nextMessage.sender.id == message.sender.id;

                      final showAvatar = !nextIsSameSender;

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onLongPress: () {
                          debugPrint('LONG PRESS ROW: ${message.id}');

                          _showMessageActions(message);
                        },
                        child: _buildTextMessage(
                          context,
                          message,
                          isMine,
                          showAvatar,
                          nextIsSameSender,
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
                  IconButton(
                    onPressed: _showOfferDialog,
                    tooltip: 'Fă o ofertă',
                    icon: const Icon(Icons.local_offer_outlined),
                  ),

                  const SizedBox(width: 4),

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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
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

class _OfferMessageCard extends StatelessWidget {
  final ChatMessage message;
  final Offer offer;
  final bool isMine;
  final String myUserId;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _OfferMessageCard({
    required this.message,
    required this.offer,
    required this.isMine,
    required this.myUserId,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final canManage = offer.sellerId == myUserId && offer.status == 'pending';

    Color backgroundColor;

    switch (offer.status) {
      case 'accepted':
        backgroundColor = Colors.green.withValues(alpha: 0.12);
        break;

      case 'rejected':
        backgroundColor = Colors.red.withValues(alpha: 0.10);
        break;

      case 'cancelled':
        backgroundColor = Colors.grey.withValues(alpha: 0.12);
        break;

      default:
        backgroundColor = isMine
            ? colors.primary.withValues(alpha: 0.10)
            : colors.surfaceContainerHighest;
    }

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.78,
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_offer_outlined, color: colors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Ofertă',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                _OfferStatus(status: offer.status),
              ],
            ),

            const SizedBox(height: 12),

            if (offer.listing != null) ...[
              Text(
                offer.listing!.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
            ],

            Text(
              '${offer.amount.toStringAsFixed(0)} ${offer.currency}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: colors.primary,
              ),
            ),

            if (offer.listing != null) ...[
              const SizedBox(height: 4),
              Text(
                'Preț anunț: '
                '${offer.listing!.price.toStringAsFixed(0)} '
                '${offer.listing!.currency}',
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
            ],

            if (canManage) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onAccept,
                      child: const Text('Acceptă'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      child: const Text('Refuză'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OfferStatus extends StatelessWidget {
  final String status;

  const _OfferStatus({required this.status});

  @override
  Widget build(BuildContext context) {
    String text;

    switch (status) {
      case 'accepted':
        text = 'Acceptată';
        break;

      case 'rejected':
        text = 'Refuzată';
        break;

      case 'cancelled':
        text = 'Anulată';
        break;

      case 'countered':
        text = 'Contrapropunere';
        break;

      default:
        text = 'În așteptare';
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _OfferBottomSheet extends StatefulWidget {
  const _OfferBottomSheet();

  @override
  State<_OfferBottomSheet> createState() => _OfferBottomSheetState();
}

class _OfferBottomSheetState extends State<_OfferBottomSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = double.tryParse(_controller.text.replaceAll(',', '.').trim());

    if (value == null || value <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Introdu o sumă validă.')));

      return;
    }

    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fă o ofertă',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 8),

          Text(
            'Introdu prețul pe care vrei să îl oferi.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Oferta ta',
              suffixText: 'RON',
              prefixIcon: const Icon(Icons.payments_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('Trimite oferta'),
            ),
          ),
        ],
      ),
    );
  }
}
