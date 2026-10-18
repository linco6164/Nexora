import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';
import 'checkout_page.dart';
import 'shared/widgets/offer_purchase_action.dart';
import 'app_navigator.dart';
import 'app_feedback.dart';
import 'models/chat_models.dart';
import 'socket_service.dart';
import 'web/widgets/web_page_frame.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String otherUsername;
  final String myUserId;
  final ConversationListing? listing;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.otherUsername,
    required this.myUserId,
    this.listing,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with WidgetsBindingObserver, RouteAware {
  static const int _maximumAttachments = 5;

  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<ChatMessage> _messages = <ChatMessage>[];
  final List<XFile> _pendingImages = <XFile>[];
  final List<String> _recentEmojis = <String>[];

  bool _isLoading = true;
  int _messageLoadVersion = 0;
  final Set<String> _updatingOfferIds = {};
  bool _isSending = false;
  bool _otherIsTyping = false;
  bool _typingWasSent = false;
  bool _showEmojiPicker = false;
  int _emojiCategoryIndex = 1;
  String? _loadError;
  Timer? _typingTimer;
  VoidCallback? _removeNewMessageListener;
  VoidCallback? _removeTypingListener;
  VoidCallback? _removeStopTypingListener;
  VoidCallback? _removeOfferUpdatedListener;
  VoidCallback? _removeMessageDeletedListener;
  VoidCallback? _removeMessagesSeenListener;

  bool get _canSend =>
      !_isSending &&
      (_messageController.text.trim().isNotEmpty || _pendingImages.isNotEmpty);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) appRouteObserver.subscribe(this, route);
  }

  @override
  void didPopNext() => _loadMessages(showLoading: false);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        ModalRoute.of(context)?.isCurrent == true) {
      _loadMessages(showLoading: false);
    }
  }

  Future<void> _initialize() async {
    await _loadMessages();

    try {
      await SocketService.connect();
      if (!mounted) return;

      _removeNewMessageListener = SocketService.onNewMessage(_handleNewMessage);
      _removeTypingListener = SocketService.onTyping((userId) {
        if (mounted && userId != widget.myUserId) {
          setState(() => _otherIsTyping = true);
        }
      });
      _removeStopTypingListener = SocketService.onStopTyping((userId) {
        if (mounted && userId != widget.myUserId) {
          setState(() => _otherIsTyping = false);
        }
      });
      _removeOfferUpdatedListener = SocketService.onOfferUpdated((
        conversationId,
      ) {
        if (mounted && conversationId == widget.conversationId) {
          _loadMessages(showLoading: false);
        }
      });
      _removeMessageDeletedListener = SocketService.onMessageDeleted(
        _handleConversationEvent,
      );
      _removeMessagesSeenListener = SocketService.onMessagesSeen(
        _handleConversationEvent,
      );
      SocketService.joinConversation(widget.conversationId);
      await _loadMessages(showLoading: false);
    } catch (error) {
      if (mounted) {
        _showError(error, 'Conexiunea în timp real nu este disponibilă.');
      }
    }
  }

  void _handleNewMessage(ChatMessage message) {
    if (!mounted || message.conversationId != widget.conversationId) return;

    _addMessageIfMissing(message);
    _scrollToBottom();

    if (message.sender.id != widget.myUserId) {
      _markConversationAsSeen();
    }
  }

  void _handleConversationEvent(String conversationId) {
    if (mounted && conversationId == widget.conversationId) {
      _loadMessages(showLoading: false);
    }
  }

  void _addMessageIfMissing(ChatMessage message) {
    if (_messages.any((item) => item.id == message.id)) return;

    setState(() {
      _messages.add(message);
      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    });
  }

  Future<void> _loadMessages({bool showLoading = true}) async {
    final version = ++_messageLoadVersion;
    if (mounted && showLoading) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final messages = await ApiService.getMessages(widget.conversationId);
      if (!mounted || version != _messageLoadVersion) return;

      setState(() {
        _messages
          ..clear()
          ..addAll(messages)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        _isLoading = false;
        _loadError = null;
      });

      await _markConversationAsSeen();
      _scrollToBottom(jump: true);
    } catch (error) {
      if (!mounted || version != _messageLoadVersion) return;
      if (!showLoading && _messages.isNotEmpty) {
        debugPrint('Chat refresh: $error');
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError = _errorMessage(error, 'Mesajele nu au putut fi încărcate.');
      });
    }
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final target = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleTextChanged(String value) {
    setState(() {});
    _typingTimer?.cancel();

    if (value.trim().isEmpty) {
      _stopTyping();
      return;
    }

    if (!_typingWasSent) {
      SocketService.typing(widget.conversationId);
      _typingWasSent = true;
    }

    _typingTimer = Timer(const Duration(milliseconds: 1200), _stopTyping);
  }

  void _toggleEmojiPicker() {
    if (_isSending) return;

    final shouldShow = !_showEmojiPicker;
    if (shouldShow) {
      _messageFocusNode.unfocus();
    }

    setState(() => _showEmojiPicker = shouldShow);

    if (!shouldShow) {
      _messageFocusNode.requestFocus();
    }
  }

  void _closeEmojiPicker({bool focusMessage = false}) {
    if (!_showEmojiPicker) return;
    setState(() => _showEmojiPicker = false);
    if (focusMessage) {
      _messageFocusNode.requestFocus();
    }
  }

  void _insertEmoji(String emoji) {
    final value = _messageController.value;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    final updatedText = value.text.replaceRange(start, end, emoji);

    _messageController.value = TextEditingValue(
      text: updatedText,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );

    setState(() {
      _recentEmojis.remove(emoji);
      _recentEmojis.insert(0, emoji);
      if (_recentEmojis.length > 24) {
        _recentEmojis.removeRange(24, _recentEmojis.length);
      }
    });
    _handleTextChanged(updatedText);
  }

  void _stopTyping() {
    _typingTimer?.cancel();
    if (!_typingWasSent) return;
    SocketService.stopTyping(widget.conversationId);
    _typingWasSent = false;
  }

  Future<void> _pickImages() async {
    _closeEmojiPicker();
    try {
      final selected = await _imagePicker.pickMultiImage(
        imageQuality: 84,
        maxWidth: 1800,
      );
      if (!mounted || selected.isEmpty) return;

      final available = _maximumAttachments - _pendingImages.length;
      if (available <= 0) {
        _showInfo('Poți atașa maximum $_maximumAttachments imagini.');
        return;
      }

      setState(() => _pendingImages.addAll(selected.take(available)));

      if (selected.length > available) {
        _showInfo('Au fost păstrate primele $_maximumAttachments imagini.');
      }
    } catch (error) {
      if (mounted) _showError(error, 'Imaginile nu au putut fi selectate.');
    }
  }

  Future<void> _sendMessage() async {
    if (!_canSend) return;

    final text = _messageController.text.trim();
    final images = List<XFile>.from(_pendingImages);
    setState(() {
      _isSending = true;
      _showEmojiPicker = false;
    });

    try {
      final uploadedImages = images.isEmpty
          ? const <String>[]
          : await ApiService.uploadXFiles(images, folder: 'chat');

      final message = await SocketService.sendMessage(
        conversationId: widget.conversationId,
        senderId: widget.myUserId,
        text: text,
        images: uploadedImages,
      );

      if (!mounted) return;
      _addMessageIfMissing(message);
      _messageController.clear();
      _stopTyping();
      setState(() {
        _pendingImages.clear();
        _isSending = false;
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSending = false);
      _showError(error, 'Mesajul nu a putut fi trimis.');
    }
  }

  Future<void> _showOfferDialog() async {
    _closeEmojiPicker();
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _OfferBottomSheet(),
    );

    if (amount == null) return;

    try {
      final message = await ApiService.sendOffer(
        conversationId: widget.conversationId,
        amount: amount,
      );
      if (!mounted) return;
      _addMessageIfMissing(message);
      _scrollToBottom();
    } catch (error) {
      if (mounted) _showError(error, 'Oferta nu a putut fi trimisă.');
    }
  }

  Future<void> _acceptOffer(Offer offer) async {
    if (!_updatingOfferIds.add(offer.id)) return;
    setState(() {});
    try {
      final accepted = await ApiService.acceptOffer(offer.id);
      _updateOffer(accepted);
      await _loadMessages(showLoading: false);
      if (mounted) {
        _showInfo(
          'Oferta a fost acceptată. Cumpărătorul poate finaliza comanda.',
        );
      }
    } catch (error) {
      if (mounted) _showError(error, 'Oferta nu a putut fi acceptată.');
    } finally {
      if (mounted) setState(() => _updatingOfferIds.remove(offer.id));
    }
  }

  Future<void> _rejectOffer(Offer offer) async {
    if (!_updatingOfferIds.add(offer.id)) return;
    setState(() {});
    try {
      final rejected = await ApiService.rejectOffer(offer.id);
      _updateOffer(rejected);
      await _loadMessages(showLoading: false);
      if (mounted) _showInfo('Oferta a fost refuzată.');
    } catch (error) {
      if (mounted) _showError(error, 'Oferta nu a putut fi refuzată.');
    } finally {
      if (mounted) setState(() => _updatingOfferIds.remove(offer.id));
    }
  }

  void _updateOffer(Offer updated) {
    if (!mounted) return;
    // Apply the confirmed response immediately, even if the list refresh fails.
    setState(() {
      for (var index = 0; index < _messages.length; index++) {
        if (_messages[index].offer?.id == updated.id) {
          _messages[index] = _messages[index].withOffer(updated);
        }
      }
    });
  }

  Future<void> _purchaseOffer(Offer offer) async {
    if (!offer.canBePurchasedBy(widget.myUserId)) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            CheckoutPage(listingId: offer.listingId, offerId: offer.id),
      ),
    );
    if (mounted) await _loadMessages(showLoading: false);
  }

  Future<void> _deleteMessage(ChatMessage message, String mode) async {
    try {
      await ApiService.deleteMessage(messageId: message.id, mode: mode);
      await _loadMessages();
    } catch (error) {
      if (mounted) _showError(error, 'Mesajul nu a putut fi șters.');
    }
  }

  Future<void> _markConversationAsSeen() async {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;
    final unseenIncoming = _messages
        .where(
          (message) =>
              message.sender.id != widget.myUserId &&
              !message.seenBy.contains(widget.myUserId),
        )
        .toList(growable: false);

    if (unseenIncoming.isEmpty) return;

    try {
      await ApiService.markConversationAsSeen(widget.conversationId);
      SocketService.markSeen(
        conversationId: widget.conversationId,
        messageId: unseenIncoming.last.id,
      );
    } catch (error) {
      debugPrint('MARK AS SEEN ERROR: $error');
    }
  }

  Future<void> _showMessageActions(ChatMessage message) async {
    if (message.isDeleted) return;
    HapticFeedback.mediumImpact();

    final canDeleteForEveryone =
        message.sender.id == widget.myUserId && message.type != 'offer';

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Șterge pentru mine'),
              onTap: () => Navigator.pop(context, 'me'),
            ),
            if (canDeleteForEveryone)
              ListTile(
                leading: const Icon(Icons.delete_forever_outlined),
                title: const Text('Șterge pentru toți'),
                onTap: () => Navigator.pop(context, 'everyone'),
              ),
            ListTile(
              leading: const Icon(Icons.close_rounded),
              title: const Text('Anulează'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;
    await _deleteMessage(message, action);
  }

  Widget _buildListingContext() {
    final listing = widget.listing;
    if (listing == null) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final image = listing.images.isEmpty ? null : listing.images.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: image == null
                ? Container(
                    width: 44,
                    height: 44,
                    color: colors.surfaceContainerHighest,
                    child: const Icon(Icons.inventory_2_outlined, size: 20),
                  )
                : Image.network(
                    image,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 44,
                      height: 44,
                      color: colors.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_outlined, size: 20),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatAmount(listing.price)} ${listing.currency}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _showOfferDialog,
            icon: const Icon(Icons.local_offer_outlined, size: 17),
            label: const Text('Ofertă'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return _ChatState(
        icon: Icons.error_outline_rounded,
        title: 'Mesajele nu au putut fi încărcate',
        message: _loadError!,
        actionLabel: 'Reîncearcă',
        onAction: _loadMessages,
      );
    }

    if (_messages.isEmpty) {
      return const _ChatState(
        icon: Icons.waving_hand_outlined,
        title: 'Începe conversația',
        message: 'Trimite primul mesaj și discută detaliile produsului în siguranță.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBubbleWidth = constraints.maxWidth > 720
            ? 500.0
            : constraints.maxWidth * 0.78;

        return ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            kIsWeb ? 24 : 12,
            16,
            kIsWeb ? 24 : 12,
            22,
          ),
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            final message = _messages[index];
            final previous = index > 0 ? _messages[index - 1] : null;
            final next = index + 1 < _messages.length
                ? _messages[index + 1]
                : null;
            final startsNewDay =
                previous == null ||
                !_sameDay(previous.createdAt, message.createdAt);
            final nextIsSameSender =
                next != null &&
                next.sender.id == message.sender.id &&
                _sameDay(next.createdAt, message.createdAt);
            final isMine = message.sender.id == widget.myUserId;

            final bubble = message.type == 'offer' && message.offer != null
                ? _OfferMessageCard(
                    message: message,
                    offer: message.offer!,
                    isMine: isMine,
                    myUserId: widget.myUserId,
                    maxWidth: maxBubbleWidth,
                    onAccept: () => _acceptOffer(message.offer!),
                    onReject: () => _rejectOffer(message.offer!),
                    onPurchase: () => _purchaseOffer(message.offer!),
                    isUpdating: _updatingOfferIds.contains(message.offer!.id),
                    onOptions: () => _showMessageActions(message),
                  )
                : _MessageBubble(
                    message: message,
                    isMine: isMine,
                    showAvatar: !isMine && !nextIsSameSender,
                    maxWidth: maxBubbleWidth,
                    onOptions: () => _showMessageActions(message),
                    onOpenImage: _showImage,
                  );

            return Column(
              children: [
                if (startsNewDay) _DateDivider(date: message.createdAt),
                bubble,
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildComposer() {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(kIsWeb ? 16 : 8, 8, kIsWeb ? 16 : 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_showEmojiPicker) ...[
                _EmojiPicker(
                  selectedCategoryIndex: _emojiCategoryIndex,
                  recentEmojis: _recentEmojis,
                  onCategorySelected: (index) {
                    setState(() => _emojiCategoryIndex = index);
                  },
                  onEmojiSelected: _insertEmoji,
                ),
                const SizedBox(height: 8),
              ],
              if (_pendingImages.isNotEmpty)
                SizedBox(
                  height: 76,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pendingImages.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) => _PendingImagePreview(
                      file: _pendingImages[index],
                      onRemove: _isSending
                          ? null
                          : () =>
                                setState(() => _pendingImages.removeAt(index)),
                    ),
                  ),
                ),
              if (_pendingImages.isNotEmpty) const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: _isSending ? null : _pickImages,
                    tooltip: 'Atașează imagini',
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                  ),
                  if (widget.listing == null)
                    IconButton(
                      onPressed: _isSending ? null : _showOfferDialog,
                      tooltip: 'Fă o ofertă',
                      icon: const Icon(Icons.local_offer_outlined),
                    ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _messageFocusNode,
                      enabled: !_isSending,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: _handleTextChanged,
                      onTap: () => _closeEmojiPicker(),
                      decoration: InputDecoration(
                        hintText: 'Scrie un mesaj...',
                        filled: true,
                        fillColor: colors.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 11,
                        ),
                        suffixIcon: IconButton(
                          onPressed: _isSending ? null : _toggleEmojiPicker,
                          tooltip: _showEmojiPicker
                              ? 'Închide emoticoanele'
                              : 'Adaugă un emoticon',
                          icon: Icon(
                            _showEmojiPicker
                                ? Icons.keyboard_alt_outlined
                                : Icons.sentiment_satisfied_alt_outlined,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _canSend ? _sendMessage : null,
                    tooltip: 'Trimite',
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImage(String url) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton.filledTonal(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _errorMessage(Object error, String fallback) {
    if (error is ApiException) return error.message;
    return fallback;
  }

  void _showError(Object error, String fallback) {
    AppFeedback.error(context, _errorMessage(error, fallback));
  }

  void _showInfo(String message) {
    AppFeedback.info(context, message);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    _stopTyping();
    SocketService.leaveConversation(widget.conversationId);
    _removeNewMessageListener?.call();
    _removeTypingListener?.call();
    _removeStopTypingListener?.call();
    _removeOfferUpdatedListener?.call();
    _removeMessageDeletedListener?.call();
    _removeMessagesSeenListener?.call();
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        _buildListingContext(),
        Expanded(child: _buildMessages()),
        _buildComposer(),
      ],
    );

    return PopScope(
      canPop: !_showEmojiPicker,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _showEmojiPicker) {
          _closeEmojiPicker();
        }
      },
      child: Scaffold(
        appBar: kIsWeb
            ? null
            : AppBar(
                titleSpacing: 4,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.otherUsername),
                    if (_otherIsTyping)
                      Text(
                        'scrie...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                  ],
                ),
                actions: [
                  IconButton(
                    onPressed: _loadMessages,
                    tooltip: 'Reîncarcă mesajele',
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
        body: kIsWeb
            ? WebPageFrame(
                title: widget.otherUsername,
                subtitle: _otherIsTyping ? 'scrie...' : 'Conversație',
                maxWidth: 860,
                actions: [
                  IconButton(
                    onPressed: _loadMessages,
                    tooltip: 'Reîncarcă mesajele',
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    tooltip: 'Înapoi la mesaje',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
                child: body,
              )
            : body,
      ),
    );
  }
}

class _EmojiPicker extends StatelessWidget {
  final int selectedCategoryIndex;
  final List<String> recentEmojis;
  final ValueChanged<int> onCategorySelected;
  final ValueChanged<String> onEmojiSelected;

  const _EmojiPicker({
    required this.selectedCategoryIndex,
    required this.recentEmojis,
    required this.onCategorySelected,
    required this.onEmojiSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final pickerHeight = kIsWeb || viewportHeight >= 560 ? 220.0 : 170.0;
    final categories = <_EmojiCategory>[
      _EmojiCategory(
        label: 'Recente',
        icon: Icons.history_rounded,
        emojis: recentEmojis,
      ),
      ..._emojiCategories,
    ];
    final safeIndex = selectedCategoryIndex.clamp(0, categories.length - 1);
    final selected = categories[safeIndex];

    return Container(
      height: pickerHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 3),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = index == safeIndex;
                return IconButton(
                  onPressed: () => onCategorySelected(index),
                  tooltip: category.label,
                  style: IconButton.styleFrom(
                    backgroundColor: isSelected
                        ? colors.primaryContainer
                        : Colors.transparent,
                    foregroundColor: isSelected
                        ? colors.onPrimaryContainer
                        : colors.onSurfaceVariant,
                  ),
                  icon: Icon(category.icon, size: 20),
                );
              },
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          Expanded(
            child: selected.emojis.isEmpty
                ? Center(
                    child: Text(
                      'Emoticoanele folosite apar aici.',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 700
                          ? 14
                          : constraints.maxWidth >= 480
                          ? 10
                          : 8;
                      return GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisExtent: 42,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemCount: selected.emojis.length,
                        itemBuilder: (context, index) {
                          final emoji = selected.emojis[index];
                          return InkWell(
                            onTap: () => onEmojiSelected(emoji),
                            borderRadius: BorderRadius.circular(10),
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmojiCategory {
  final String label;
  final IconData icon;
  final List<String> emojis;

  const _EmojiCategory({
    required this.label,
    required this.icon,
    required this.emojis,
  });
}

const List<_EmojiCategory> _emojiCategories = <_EmojiCategory>[
  _EmojiCategory(
    label: 'Expresii',
    icon: Icons.sentiment_satisfied_alt_outlined,
    emojis: <String>[
      '😀',
      '😃',
      '😄',
      '😁',
      '😆',
      '😅',
      '😂',
      '🤣',
      '😊',
      '😇',
      '🙂',
      '🙃',
      '😉',
      '😌',
      '😍',
      '🥰',
      '😘',
      '😗',
      '😙',
      '😚',
      '😋',
      '😛',
      '😝',
      '😜',
      '🤪',
      '🤨',
      '🧐',
      '🤓',
      '😎',
      '🥳',
      '🤩',
      '😏',
      '😒',
      '😞',
      '😔',
      '😟',
      '😕',
      '🙁',
      '☹️',
      '😣',
      '😖',
      '😫',
      '😩',
      '🥺',
      '😢',
      '😭',
      '😤',
      '😠',
      '😡',
      '🤬',
      '🤯',
      '😳',
      '🥵',
      '🥶',
      '😱',
      '😨',
      '😰',
      '😥',
      '🤗',
      '🤔',
      '🫢',
      '🤭',
      '🫣',
      '🤫',
      '🤥',
      '😶',
      '😐',
      '😑',
      '😬',
      '🙄',
      '😯',
      '😴',
      '🤤',
      '😷',
      '🤒',
      '🤕',
    ],
  ),
  _EmojiCategory(
    label: 'Gesturi',
    icon: Icons.pan_tool_alt_outlined,
    emojis: <String>[
      '👋',
      '🤚',
      '🖐️',
      '✋',
      '🖖',
      '🫶',
      '👌',
      '🤌',
      '🤏',
      '✌️',
      '🤞',
      '🫰',
      '🤟',
      '🤘',
      '🤙',
      '👈',
      '👉',
      '👆',
      '👇',
      '☝️',
      '👍',
      '👎',
      '✊',
      '👊',
      '🤛',
      '🤜',
      '👏',
      '🙌',
      '👐',
      '🤲',
      '🤝',
      '🙏',
      '💪',
      '🦾',
      '🫵',
      '💅',
    ],
  ),
  _EmojiCategory(
    label: 'Inimi și simboluri',
    icon: Icons.favorite_border_rounded,
    emojis: <String>[
      '❤️',
      '🧡',
      '💛',
      '💚',
      '💙',
      '💜',
      '🖤',
      '🤍',
      '🤎',
      '💔',
      '❤️‍🔥',
      '❤️‍🩹',
      '💕',
      '💞',
      '💓',
      '💗',
      '💖',
      '💘',
      '💝',
      '💟',
      '❣️',
      '💋',
      '🌹',
      '✨',
      '⭐',
      '🌟',
      '💫',
      '🔥',
      '🎉',
      '🎊',
      '✅',
      '❌',
      '⚠️',
      '💯',
      '❓',
      '❗',
    ],
  ),
  _EmojiCategory(
    label: 'Animale și natură',
    icon: Icons.pets_outlined,
    emojis: <String>[
      '🐶',
      '🐱',
      '🐭',
      '🐹',
      '🐰',
      '🦊',
      '🐻',
      '🐼',
      '🐨',
      '🐯',
      '🦁',
      '🐮',
      '🐷',
      '🐸',
      '🐵',
      '🐔',
      '🐧',
      '🐦',
      '🦄',
      '🐝',
      '🦋',
      '🐌',
      '🐞',
      '🐟',
      '🐬',
      '🌱',
      '🌿',
      '🍀',
      '🌸',
      '🌺',
      '🌻',
      '🌞',
      '🌙',
      '☀️',
      '🌈',
      '❄️',
    ],
  ),
  _EmojiCategory(
    label: 'Mâncare',
    icon: Icons.restaurant_outlined,
    emojis: <String>[
      '🍏',
      '🍎',
      '🍐',
      '🍊',
      '🍋',
      '🍌',
      '🍉',
      '🍇',
      '🍓',
      '🫐',
      '🍒',
      '🍑',
      '🥭',
      '🍍',
      '🥥',
      '🥑',
      '🍅',
      '🥕',
      '🌽',
      '🥐',
      '🍞',
      '🧀',
      '🍔',
      '🍟',
      '🍕',
      '🌭',
      '🥪',
      '🌮',
      '🍝',
      '🍜',
      '🍦',
      '🍩',
      '🍪',
      '🎂',
      '☕',
      '🥤',
    ],
  ),
  _EmojiCategory(
    label: 'Obiecte',
    icon: Icons.lightbulb_outline_rounded,
    emojis: <String>[
      '🎁',
      '🛍️',
      '📦',
      '🚚',
      '💳',
      '💰',
      '📱',
      '💻',
      '⌚',
      '📷',
      '🎧',
      '🎮',
      '📚',
      '✏️',
      '🔑',
      '🔒',
      '🔔',
      '💡',
      '🧸',
      '👕',
      '👗',
      '👟',
      '👜',
      '💍',
      '🏠',
      '🚗',
      '🚲',
      '✈️',
      '🏆',
      '⚽',
      '🎵',
      '🛠️',
      '🧹',
      '🪴',
      '🛒',
      '📍',
    ],
  ),
];

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final bool showAvatar;
  final double maxWidth;
  final VoidCallback onOptions;
  final ValueChanged<String> onOpenImage;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.showAvatar,
    required this.maxWidth,
    required this.onOptions,
    required this.onOpenImage,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = isMine ? colors.onPrimary : colors.onSurface;
    final background = isMine ? colors.primary : colors.surfaceContainerHighest;
    final hasText = message.text.trim().isNotEmpty || message.isDeleted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            SizedBox(
              width: 30,
              child: showAvatar ? _Avatar(url: message.sender.avatar) : null,
            ),
            const SizedBox(width: 6),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Material(
              color: background,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onLongPress: onOptions,
                onSecondaryTap: onOptions,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    message.images.isEmpty ? 13 : 6,
                    message.images.isEmpty ? 9 : 6,
                    message.images.isEmpty ? 8 : 6,
                    6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!message.isDeleted && message.images.isNotEmpty)
                        _MessageImages(
                          images: message.images,
                          onOpen: onOpenImage,
                        ),
                      if (!message.isDeleted &&
                          message.images.isNotEmpty &&
                          hasText)
                        const SizedBox(height: 7),
                      if (hasText)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: message.images.isEmpty ? 0 : 6,
                          ),
                          child: Text(
                            message.isDeleted ? 'Mesaj șters' : message.text,
                            style: TextStyle(
                              color: message.isDeleted
                                  ? foreground.withValues(alpha: 0.68)
                                  : foreground,
                              fontStyle: message.isDeleted
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(message.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: foreground.withValues(alpha: 0.70),
                            ),
                          ),
                          if (isMine) ...[
                            const SizedBox(width: 4),
                            _MessageDeliveryStatus(
                              message: message,
                              color: foreground.withValues(alpha: 0.78),
                            ),
                          ],
                          SizedBox(
                            width: 25,
                            height: 22,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              tooltip: 'Opțiuni mesaj',
                              onPressed: onOptions,
                              icon: Icon(
                                Icons.more_horiz_rounded,
                                size: 16,
                                color: foreground.withValues(alpha: 0.72),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageImages extends StatelessWidget {
  final List<String> images;
  final ValueChanged<String> onOpen;

  const _MessageImages({required this.images, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final availableWidth = (MediaQuery.sizeOf(context).width - 80)
        .clamp(160.0, 330.0)
        .toDouble();

    if (images.length == 1) {
      return _NetworkMessageImage(
        url: images.first,
        width: availableWidth,
        height: availableWidth * 2 / 3,
        onTap: () => onOpen(images.first),
      );
    }

    final thumbnailWidth = ((availableWidth - 4) / 2)
        .clamp(76.0, 142.0)
        .toDouble();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: images
          .map(
            (url) => _NetworkMessageImage(
              url: url,
              width: thumbnailWidth,
              height: thumbnailWidth * .79,
              onTap: () => onOpen(url),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _NetworkMessageImage extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final VoidCallback onTap;

  const _NetworkMessageImage({
    required this.url,
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.network(
          url,
          width: width,
          height: height,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : Container(
                  width: width,
                  height: height,
                  color: colors.surfaceContainerHigh,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
          errorBuilder: (_, _, _) => Container(
            width: width,
            height: height,
            color: colors.surfaceContainerHigh,
            child: const Icon(Icons.broken_image_outlined),
          ),
        ),
      ),
    );
  }
}

class _MessageDeliveryStatus extends StatelessWidget {
  final ChatMessage message;
  final Color color;

  const _MessageDeliveryStatus({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    final seen = message.seenBy.any((id) => id != message.sender.id);
    final delivered = message.deliveredTo.any((id) => id != message.sender.id);

    if (seen) {
      return const Icon(
        Icons.done_all_rounded,
        size: 14,
        color: Colors.lightBlueAccent,
      );
    }
    return Icon(
      delivered ? Icons.done_all_rounded : Icons.done_rounded,
      size: 14,
      color: color,
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;

  const _Avatar({this.url});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 14,
      backgroundImage: url != null && url!.isNotEmpty
          ? NetworkImage(url!)
          : null,
      backgroundColor: colors.surfaceContainerHighest,
      child: url == null || url!.isEmpty
          ? Icon(Icons.person_rounded, size: 16, color: colors.onSurfaceVariant)
          : null,
    );
  }
}

class _DateDivider extends StatelessWidget {
  final DateTime date;

  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              _formatDay(date),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _ChatState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ChatState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PendingImagePreview extends StatefulWidget {
  final XFile file;
  final VoidCallback? onRemove;

  const _PendingImagePreview({required this.file, required this.onRemove});

  @override
  State<_PendingImagePreview> createState() => _PendingImagePreviewState();
}

class _PendingImagePreviewState extends State<_PendingImagePreview> {
  late Future<Uint8List> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = widget.file.readAsBytes();
  }

  @override
  void didUpdateWidget(covariant _PendingImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _bytes = widget.file.readAsBytes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: FutureBuilder<Uint8List>(
                future: _bytes,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const ColoredBox(
                      color: Colors.black12,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  return Image.memory(snapshot.data!, fit: BoxFit.cover);
                },
              ),
            ),
          ),
          Positioned(
            right: -5,
            top: -5,
            child: IconButton.filled(
              visualDensity: VisualDensity.compact,
              iconSize: 15,
              tooltip: 'Elimină imaginea',
              onPressed: widget.onRemove,
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferMessageCard extends StatelessWidget {
  final VoidCallback onPurchase;
  final bool isUpdating;
  final ChatMessage message;
  final Offer offer;
  final bool isMine;
  final String myUserId;
  final double maxWidth;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onOptions;

  const _OfferMessageCard({
    required this.onPurchase,
    required this.isUpdating,
    required this.message,
    required this.offer,
    required this.isMine,
    required this.myUserId,
    required this.maxWidth,
    required this.onAccept,
    required this.onReject,
    required this.onOptions,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final canManage = offer.sellerId == myUserId && offer.status == 'pending';

    final Color backgroundColor = switch (offer.status) {
      'accepted' => Colors.green.withValues(alpha: 0.12),
      'rejected' => Colors.red.withValues(alpha: 0.10),
      'cancelled' => Colors.grey.withValues(alpha: 0.12),
      _ =>
        isMine
            ? colors.primary.withValues(alpha: 0.10)
            : colors.surfaceContainerHighest,
    };

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: 20,
                  color: colors.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Ofertă',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                _OfferStatus(status: offer.status),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'Opțiuni mesaj',
                    onPressed: onOptions,
                    icon: const Icon(Icons.more_horiz_rounded, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (offer.listing != null) ...[
              Text(
                offer.listing!.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
            ],
            Text(
              '${_formatAmount(offer.amount)} ${offer.currency}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: colors.primary,
              ),
            ),
            if (offer.listing != null) ...[
              const SizedBox(height: 3),
              Text(
                'Preț anunț: ${_formatAmount(offer.listing!.price)} ${offer.listing!.currency}',
                style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
              ),
            ],
            if (canManage) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: isUpdating ? null : onAccept,
                      child: Text(
                        isUpdating ? 'Se actualizează...' : 'Acceptă',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isUpdating ? null : onReject,
                      child: const Text('Refuză'),
                    ),
                  ),
                ],
              ),
            ],
            if (offer.isAccepted) ...[
              const SizedBox(height: 12),
              OfferPurchaseAction(
                offer: offer,
                userId: myUserId,
                onPurchase: onPurchase,
              ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _formatTime(message.createdAt),
                style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
              ),
            ),
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
    final text = switch (status) {
      'accepted' => 'Acceptată',
      'rejected' => 'Refuzată',
      'cancelled' => 'Anulată',
      'countered' => 'Contrapropunere',
      _ => 'În așteptare',
    };

    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
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
  final TextEditingController _controller = TextEditingController();

  void _submit() {
    final value = double.tryParse(_controller.text.replaceAll(',', '.').trim());
    if (value == null || value <= 0) {
      AppFeedback.warning(context, 'Introdu o sumă validă.');
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fă o ofertă',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Introdu prețul pe care vrei să îl oferi.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Oferta ta',
                suffixText: 'RON',
                prefixIcon: const Icon(Icons.payments_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Trimite oferta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _sameDay(DateTime first, DateTime second) {
  final a = first.toLocal();
  final b = second.toLocal();
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _formatDay(DateTime value) {
  final date = value.toLocal();
  final now = DateTime.now();
  if (_sameDay(date, now)) return 'Astăzi';
  if (_sameDay(date, now.subtract(const Duration(days: 1)))) return 'Ieri';
  const months = <String>[
    'ianuarie',
    'februarie',
    'martie',
    'aprilie',
    'mai',
    'iunie',
    'iulie',
    'august',
    'septembrie',
    'octombrie',
    'noiembrie',
    'decembrie',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _formatTime(DateTime value) {
  final date = value.toLocal();
  return '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}

String _formatAmount(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}
