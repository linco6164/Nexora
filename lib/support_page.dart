import 'package:flutter/material.dart';

import 'api_service.dart';
import 'socket_service.dart';

class SupportPage extends StatefulWidget {
  final String? ticketId;
  final String? banReason;
  final bool createBanTicket;

  const SupportPage({
    super.key,
    this.ticketId,
    this.banReason,
    this.createBanTicket = false,
  });

  @override
  State<SupportPage> createState() =>
      _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final TextEditingController _messageController =
      TextEditingController();

  final TextEditingController _subjectController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  Map<String, dynamic>? _ticket;

  List<dynamic> _tickets = [];

  bool _loading = true;
  bool _sending = false;
  bool _creatingTicket = false;

  bool _showCreateForm = false;

  String _selectedCategory = 'other';

  static const Map<String, String> _categoryLabels = {
    'account_banned': 'Cont blocat',
    'account': 'Cont',
    'payments': 'Plăți',
    'orders': 'Comenzi',
    'listings': 'Anunțuri',
    'technical': 'Probleme tehnice',
    'logistics': 'Livrare',
    'moderation': 'Moderare',
    'other': 'Altele',
  };

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    final ticketId =
        _ticket?['_id']?.toString();

    if (ticketId != null &&
        ticketId.isNotEmpty) {
      SocketService.leaveSupportTicket(
        ticketId,
      );
    }

    SocketService.clearSupportListeners();

    _messageController.dispose();
    _subjectController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      await SocketService.connect();

      SocketService.onSupportMessage(
        _handleIncomingSupportMessage,
      );

      SocketService.onSupportError(
        _handleSupportError,
      );

      if (widget.ticketId != null &&
          widget.ticketId!.isNotEmpty) {
        await _openTicketById(
          widget.ticketId!,
        );
        return;
      }

      if (widget.createBanTicket) {
        await _createBanTicket();
        return;
      }

      await _loadTickets();

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    } catch (e) {
      debugPrint(
        'SUPPORT INITIALIZE ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showError(
        'Nu s-a putut încărca suportul: $e',
      );
    }
  }

  Future<void> _loadTickets() async {
    final tickets =
        await ApiService.getSupportTickets();

    if (!mounted) return;

    setState(() {
      _tickets = tickets;
    });
  }

  Future<void> _openTicketById(
    String ticketId,
  ) async {
    final response =
        await ApiService.getSupportTicket(
      ticketId,
    );

    final ticket =
        response['ticket'] ??
        response['data'];

    if (ticket == null) {
      throw ApiException(
        'Ticketul nu a fost găsit.',
      );
    }

    if (!mounted) return;

    setState(() {
      _ticket =
          Map<String, dynamic>.from(ticket);

      _loading = false;
      _showCreateForm = false;
    });

    _connectToSupportSocket();
    _scrollToBottom();
  }

  Future<void> _createBanTicket() async {
    if (_creatingTicket) return;

    setState(() {
      _creatingTicket = true;
      _loading = true;
    });

    try {
      final banReason =
          widget.banReason?.trim() ?? '';

      final response =
          await ApiService.createSupportTicket(
        subject: 'Cont blocat',
        category: 'account_banned',
        message:
            'Doresc să contest blocarea contului meu.',
        banReason: banReason,
      );

      final ticket =
          response['ticket'] ??
          response['data'];

      if (ticket == null) {
        throw ApiException(
          'Serverul nu a returnat ticketul creat.',
        );
      }

      if (!mounted) return;

      setState(() {
        _ticket =
            Map<String, dynamic>.from(ticket);

        _loading = false;
        _creatingTicket = false;
        _showCreateForm = false;
      });

      _connectToSupportSocket();
      _scrollToBottom();
    } catch (e) {
      debugPrint(
        'CREATE BAN SUPPORT TICKET ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
        _creatingTicket = false;
      });

      _showError(
        'Nu s-a putut crea tichetul: $e',
      );
    }
  }

  Future<void> _createTicket() async {
    final subject =
        _subjectController.text.trim();

    final message =
        _messageController.text.trim();

    if (subject.isEmpty) {
      _showError(
        'Introdu un subiect.',
      );
      return;
    }

    if (message.isEmpty) {
      _showError(
        'Descrie problema.',
      );
      return;
    }

    if (_creatingTicket) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _creatingTicket = true;
    });

    try {
      final response =
          await ApiService.createSupportTicket(
        subject: subject,
        category: _selectedCategory,
        message: message,
      );

      final ticket =
          response['ticket'] ??
          response['data'];

      if (ticket == null) {
        throw ApiException(
          'Serverul nu a returnat ticketul creat.',
        );
      }

      if (!mounted) return;

      setState(() {
        _ticket =
            Map<String, dynamic>.from(ticket);

        _creatingTicket = false;
        _showCreateForm = false;

        _subjectController.clear();
        _messageController.clear();
        _selectedCategory = 'other';
      });

      _connectToSupportSocket();
      _scrollToBottom();

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Ticketul a fost trimis către Support.',
            ),
          ),
        );

      _loadTickets();
    } catch (e) {
      debugPrint(
        'CREATE SUPPORT TICKET ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _creatingTicket = false;
      });

      _showError(
        'Nu s-a putut crea tichetul: $e',
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  void _connectToSupportSocket() {
    final ticketId =
        _ticket?['_id']?.toString();

    if (ticketId == null ||
        ticketId.isEmpty) {
      debugPrint(
        'SUPPORT SOCKET: ticket ID missing',
      );
      return;
    }

    debugPrint(
      'SUPPORT SOCKET: joining ticket $ticketId',
    );

    SocketService.joinSupportTicket(
      ticketId,
    );
  }

  void _handleIncomingSupportMessage(
    Map<String, dynamic> data,
  ) {
    if (!mounted) return;

    final ticketId =
        data['ticketId']?.toString();

    final currentTicketId =
        _ticket?['_id']?.toString();

    if (ticketId == null ||
        ticketId != currentTicketId) {
      return;
    }

    final newMessage =
        data['message'];

    if (newMessage == null ||
        newMessage is! Map) {
      return;
    }

    final messages =
        List<dynamic>.from(
      _ticket?['messages'] ?? [],
    );

    final messageId =
        newMessage['_id']?.toString();

    if (messageId != null &&
        messages.any(
          (item) =>
              item is Map &&
              item['_id']?.toString() ==
                  messageId,
        )) {
      return;
    }

    setState(() {
      messages.add(
        Map<String, dynamic>.from(
          newMessage,
        ),
      );

      _ticket = {
        ...?_ticket,
        'messages': messages,
      };

      _sending = false;
    });

    _scrollToBottom();
  }

  void _handleSupportError(
    String message,
  ) {
    if (!mounted) return;

    setState(() {
      _sending = false;
    });

    _showError(message);
  }

  Future<void> _sendMessage() async {
    final message =
        _messageController.text.trim();

    if (message.isEmpty ||
        _sending ||
        _ticket == null) {
      return;
    }

    final ticketId =
        _ticket!['_id']?.toString();

    if (ticketId == null ||
        ticketId.isEmpty) {
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      SocketService.sendSupportMessage(
        ticketId: ticketId,
        message: message,
      );

      _messageController.clear();
    } catch (e) {
      debugPrint(
        'SEND SUPPORT SOCKET ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _sending = false;
      });

      _showError(
        'Mesajul nu a putut fi trimis: $e',
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!_scrollController.hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration:
              const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      },
    );
  }

  void _showTicketList() {
    final currentId =
        _ticket?['_id']?.toString();

    if (currentId != null &&
        currentId.isNotEmpty) {
      SocketService.leaveSupportTicket(
        currentId,
      );
    }

    setState(() {
      _ticket = null;
      _showCreateForm = false;
    });

    _loadTickets();
  }

  void _openCreateForm() {
    setState(() {
      _ticket = null;
      _showCreateForm = true;
      _selectedCategory = 'other';
    });
  }

  String _messageText(dynamic message) {
    if (message is Map) {
      return message['message']
              ?.toString() ??
          '';
    }

    return '';
  }

  bool _isAdminMessage(
    dynamic message,
  ) {
    if (message is Map) {
      return message['senderType'] ==
          'admin';
    }

    return false;
  }

  String _ticketSubject(
    dynamic ticket,
  ) {
    if (ticket is Map) {
      return ticket['subject']
              ?.toString() ??
          'Ticket';
    }

    return 'Ticket';
  }

  String _ticketStatus(
    dynamic ticket,
  ) {
    if (ticket is Map) {
      return ticket['status']
              ?.toString() ??
          'open';
    }

    return 'open';
  }

  String _ticketStatusLabel(
    String status,
  ) {
    switch (status) {
      case 'pending':
        return 'În așteptare';

      case 'closed':
        return 'Rezolvat';

      case 'open':
      default:
        return 'Deschis';
    }
  }

  Widget _buildCategoryDropdown(
    ColorScheme colorScheme,
  ) {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Categorie',
        prefixIcon:
            const Icon(
          Icons.category_outlined,
        ),
        filled: true,
        fillColor:
            colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      items: _categoryLabels.entries
          .map(
            (entry) =>
                DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _selectedCategory = value;
        });
      },
    );
  }

  Widget _buildCreateForm(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final colorScheme =
        theme.colorScheme;

    return SafeArea(
      child: ListView(
        padding:
            const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _showCreateForm =
                        false;
                  });
                },
                icon: const Icon(
                  Icons.arrow_back_rounded,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Trimite un ticket',
                  style: theme
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            'Cum te putem ajuta?',
            style: theme
                .textTheme
                .headlineSmall
                ?.copyWith(
                  fontWeight:
                      FontWeight.w700,
                ),
          ),

          const SizedBox(height: 8),

          Text(
            'Descrie problema, iar echipa Nexora o va analiza.',
            style: theme
                .textTheme
                .bodyMedium
                ?.copyWith(
                  color: colorScheme
                      .onSurfaceVariant,
                ),
          ),

          const SizedBox(height: 24),

          _buildCategoryDropdown(
            colorScheme,
          ),

          const SizedBox(height: 14),

          TextField(
            controller:
                _subjectController,
            maxLength: 200,
            textInputAction:
                TextInputAction.next,
            decoration:
                InputDecoration(
              labelText: 'Subiect',
              hintText:
                  'Ex. Nu pot finaliza plata',
              prefixIcon:
                  const Icon(
                Icons.subject_rounded,
              ),
              filled: true,
              fillColor: colorScheme
                  .surfaceContainerHighest,
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                borderSide:
                    BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 2),

          TextField(
            controller:
                _messageController,
            minLines: 6,
            maxLines: 10,
            maxLength: 5000,
            textInputAction:
                TextInputAction.newline,
            decoration:
                InputDecoration(
              labelText: 'Mesaj',
              hintText:
                  'Descrie problema în detaliu...',
              alignLabelWithHint: true,
              prefixIcon:
                  const Padding(
                padding:
                    EdgeInsets.only(
                  bottom: 96,
                ),
                child: Icon(
                  Icons
                      .chat_bubble_outline_rounded,
                ),
              ),
              filled: true,
              fillColor: colorScheme
                  .surfaceContainerHighest,
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                borderSide:
                    BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed:
                  _creatingTicket
                      ? null
                      : _createTicket,
              icon: _creatingTicket
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme
                            .onPrimary,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                    ),
              label: Text(
                _creatingTicket
                    ? 'Se trimite...'
                    : 'Trimite ticket',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketList(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final colorScheme =
        theme.colorScheme;

    return RefreshIndicator(
      onRefresh: _loadTickets,
      child: _tickets.isEmpty
          ? ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height:
                      MediaQuery.of(context)
                              .size
                              .height *
                          .28,
                ),
                Icon(
                  Icons
                      .support_agent_rounded,
                  size: 64,
                  color:
                      colorScheme.primary,
                ),
                const SizedBox(
                  height: 18,
                ),
                Center(
                  child: Text(
                    'Nu ai niciun ticket',
                    style: theme
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Center(
                  child: Padding(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 32,
                    ),
                    child: Text(
                      'Trimite un ticket dacă ai nevoie de ajutor.',
                      textAlign:
                          TextAlign.center,
                      style: theme
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.all(16),
              itemCount:
                  _tickets.length,
              separatorBuilder:
                  (_, _) =>
                      const SizedBox(
                height: 10,
              ),
              itemBuilder:
                  (context, index) {
                final ticket =
                    _tickets[index];

                final status =
                    _ticketStatus(
                  ticket,
                );

                final messages =
                    ticket is Map
                        ? List<dynamic>.from(
                            ticket['messages'] ??
                                [],
                          )
                        : <dynamic>[];

                final preview =
                    messages.isNotEmpty
                        ? _messageText(
                            messages
                                .last,
                          )
                        : 'Fără mesaje';

                return Card(
                  elevation: 0,
                  clipBehavior:
                      Clip.antiAlias,
                  child: InkWell(
                    onTap: () async {
                      final id =
                          ticket is Map
                              ? ticket['_id']
                                  ?.toString()
                              : null;

                      if (id == null ||
                          id.isEmpty) {
                        return;
                      }

                      setState(() {
                        _loading = true;
                      });

                      try {
                        await _openTicketById(
                          id,
                        );
                      } catch (e) {
                        if (!mounted) {
                          return;
                        }

                        setState(() {
                          _loading =
                              false;
                        });

                        _showError(
                          'Nu s-a putut încărca ticketul: $e',
                        );
                      }
                    },
                    child: Padding(
                      padding:
                          const EdgeInsets
                              .all(16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _ticketSubject(
                                    ticket,
                                  ),
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style: theme
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                      ),
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal:
                                      10,
                                  vertical: 5,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color: colorScheme
                                      .primaryContainer,
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    20,
                                  ),
                                ),
                                child: Text(
                                  _ticketStatusLabel(
                                    status,
                                  ),
                                  style: theme
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: colorScheme
                                            .onPrimaryContainer,
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          Text(
                            preview,
                            maxLines: 2,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style: theme
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final colorScheme =
        theme.colorScheme;

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons
                  .support_agent_rounded,
              size: 64,
              color:
                  colorScheme.primary,
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              'Suport Nexora',
              style: theme
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                  ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              'Contactează echipa Nexora pentru ajutor.',
              textAlign:
                  TextAlign.center,
              style: theme
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    color: colorScheme
                        .onSurfaceVariant,
                  ),
            ),
            const SizedBox(
              height: 24,
            ),
            FilledButton.icon(
              onPressed:
                  _openCreateForm,
              icon: const Icon(
                Icons
                    .add_comment_outlined,
              ),
              label: const Text(
                'Trimite un ticket',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChat(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final messages =
        List<dynamic>.from(
      _ticket!['messages'] ?? [],
    );

    final status =
        _ticket!['status']
                ?.toString() ??
            'open';

    final isClosed =
        status == 'closed';

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller:
                _scrollController,
            padding:
                const EdgeInsets.all(16),
            itemCount:
                messages.length,
            itemBuilder:
                (context, index) {
              final message =
                  messages[index];

              final isAdmin =
                  _isAdminMessage(
                message,
              );

              final text =
                  _messageText(
                message,
              );

              return _buildMessageBubble(
                context,
                text,
                isAdmin,
              );
            },
          ),
        ),
        if (!isClosed)
          _buildMessageComposer(
            context,
            colorScheme,
          )
        else
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(16),
            decoration:
                BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorScheme
                      .outlineVariant,
                ),
              ),
            ),
            child: Text(
              'Acest tichet a fost închis.',
              textAlign:
                  TextAlign.center,
              style: theme
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    color: colorScheme
                        .onSurfaceVariant,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    String message,
    bool isAdmin,
  ) {
    final theme =
        Theme.of(context);

    final colorScheme =
        theme.colorScheme;

    final alignment = isAdmin
        ? Alignment.centerLeft
        : Alignment.centerRight;

    final backgroundColor =
        isAdmin
            ? colorScheme
                .surfaceContainerHighest
            : colorScheme.primary;

    final textColor = isAdmin
        ? colorScheme.onSurface
        : colorScheme.onPrimary;

    return Align(
      alignment: alignment,
      child: Container(
        constraints:
            const BoxConstraints(
          maxWidth: 330,
        ),
        margin:
            const EdgeInsets.only(
          bottom: 10,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        decoration:
            BoxDecoration(
          color: backgroundColor,
          borderRadius:
              BorderRadius.circular(
            16,
          ),
        ),
        child: Text(
          message,
          style: theme
              .textTheme
              .bodyMedium
              ?.copyWith(
                color: textColor,
                height: 1.4,
              ),
        ),
      ),
    );
  }

  Widget _buildMessageComposer(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return SafeArea(
      top: false,
      child: Container(
        padding:
            const EdgeInsets.fromLTRB(
          12,
          10,
          12,
          12,
        ),
        decoration:
            BoxDecoration(
          color:
              colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme
                  .outlineVariant,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller:
                    _messageController,
                minLines: 1,
                maxLines: 5,
                textInputAction:
                    TextInputAction
                        .newline,
                onSubmitted: (_) {
                  if (!_sending) {
                    _sendMessage();
                  }
                },
                decoration:
                    InputDecoration(
                  hintText:
                      'Scrie un mesaj...',
                  filled: true,
                  fillColor: colorScheme
                      .surfaceContainerHighest,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 8,
            ),
            IconButton(
              onPressed: _sending
                  ? null
                  : _sendMessage,
              style:
                  IconButton.styleFrom(
                backgroundColor:
                    colorScheme.primary,
                foregroundColor:
                    colorScheme.onPrimary,
              ),
              icon: _sending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme
                            .onPrimary,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final colorScheme =
        theme.colorScheme;

    return Scaffold(
      backgroundColor:
          colorScheme.surface,
      appBar: AppBar(
        title: Text(
          _ticket != null
              ? 'Suport Nexora'
              : 'Ajutor și suport',
        ),
        centerTitle: false,
        backgroundColor:
            colorScheme.surface,
        foregroundColor:
            colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (_ticket == null &&
              !_showCreateForm)
            IconButton(
              tooltip:
                  'Trimite un ticket',
              onPressed:
                  _openCreateForm,
              icon: const Icon(
                Icons
                    .add_comment_outlined,
              ),
            ),
          if (_ticket != null)
            IconButton(
              tooltip:
                  'Înapoi la ticketurile mele',
              onPressed:
                  _showTicketList,
              icon: const Icon(
                Icons
                    .close_rounded,
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : _showCreateForm
              ? _buildCreateForm(
                  context,
                )
              : _ticket == null
                  ? _tickets.isNotEmpty
                      ? _buildTicketList(
                          context,
                        )
                      : _buildEmptyState(
                          context,
                        )
                  : _buildChat(
                      context,
                      theme,
                      colorScheme,
                    ),
      floatingActionButton:
          !_loading &&
                  _ticket == null &&
                  !_showCreateForm &&
                  _tickets.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed:
                      _openCreateForm,
                  icon: const Icon(
                    Icons
                        .add_comment_outlined,
                  ),
                  label: const Text(
                    'Ticket nou',
                  ),
                )
              : null,
    );
  }
}