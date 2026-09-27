import 'package:flutter/material.dart';

import 'api_service.dart';

class SavedCardsPage extends StatefulWidget {
  const SavedCardsPage({
    super.key,
  });

  @override
  State<SavedCardsPage> createState() =>
      _SavedCardsPageState();
}

class _SavedCardsPageState
    extends State<SavedCardsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _cards = [];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      final cards =
          await ApiService.getSavedCards();

      if (!mounted) return;

      setState(() {
        _cards = cards;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        e.toString().replaceFirst(
              'ApiException: ',
              '',
            ),
      );
    }
  }

  Future<void> _setDefault(
    String cardId,
  ) async {
    try {
      await ApiService.setDefaultSavedCard(
        cardId,
      );

      await _loadCards();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
              'ApiException: ',
              '',
            ),
      );
    }
  }

  Future<void> _deleteCard(
    Map<String, dynamic> card,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme =
            Theme.of(context);

        return AlertDialog(
          backgroundColor:
              theme.colorScheme.surface,
          title: const Text(
            'Ștergi cardul?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            '${card['brand'] ?? 'Card'} •••• ${card['last4'] ?? ''}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Anulează',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Șterge',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteSavedCard(
        card['_id'].toString(),
      );

      await _loadCards();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
              'ApiException: ',
              '',
            ),
      );
    }
  }

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final isDark =
        theme.brightness ==
            Brightness.dark;

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            theme.scaffoldBackgroundColor,
        foregroundColor:
            theme.colorScheme.onSurface,

        title: const Text(
          'Cardurile mele',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),

        actions: [
          IconButton(
            onPressed: _loading
                ? null
                : _loadCards,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),

      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadCards,

              child: _cards.isEmpty
                  ? _buildEmptyState(
                      context,
                    )
                  : ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),

                      padding:
                          const EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        32,
                      ),

                      children: [
                        _buildHeader(
                          context,
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        ..._cards.map(
                          (card) =>
                              _buildCard(
                            context,
                            card,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        _buildAddCardButton(
                          context,
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        Container(
                          padding:
                              const EdgeInsets.all(
                            14,
                          ),
                          decoration:
                              BoxDecoration(
                            color: isDark
                                ? Colors.white
                                    .withOpacity(
                                    0.05,
                                  )
                                : Colors.black
                                    .withOpacity(
                                    0.035,
                                  ),
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Icon(
                                Icons
                                    .lock_outline_rounded,
                                size: 19,
                                color: theme
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(
                                  0.65,
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Text(
                                  'Datele complete ale cardului nu sunt stocate de Nexora Store. Sunt păstrate doar informațiile necesare identificării cardului salvat.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: theme
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(
                                      0.65,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'Metode de plată',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface
                .withOpacity(0.65),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_cards.length} ${_cards.length == 1 ? 'card salvat' : 'carduri salvate'}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ),

      children: [
        const SizedBox(
          height: 110,
        ),

        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary
                .withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.credit_card_outlined,
            size: 42,
            color:
                theme.colorScheme.primary,
          ),
        ),

        const SizedBox(height: 22),

        const Center(
          child: Text(
            'Nu ai carduri salvate',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Cardurile salvate vor putea fi folosite rapid la următoarele cumpărături.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: theme.colorScheme.onSurface
                .withOpacity(0.60),
          ),
        ),

        const SizedBox(height: 26),

        _buildAddCardButton(
          context,
        ),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context,
    Map<String, dynamic> card,
  ) {
    final theme =
        Theme.of(context);

    final brand =
        card['brand']?.toString() ??
            'Card';

    final last4 =
        card['last4']?.toString() ?? '';

    final isDefault =
        card['isDefault'] == true;

    final expMonth =
        card['expMonth']?.toString();

    final expYear =
        card['expYear']?.toString();

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      padding:
          const EdgeInsets.all(18),

      decoration:
          BoxDecoration(
        color: theme.colorScheme.surface,

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color: isDefault
              ? theme.colorScheme.primary
              : theme.dividerColor
                  .withOpacity(0.35),

          width:
              isDefault ? 1.5 : 1,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(
              theme.brightness ==
                      Brightness.dark
                  ? 0.10
                  : 0.04,
            ),
            blurRadius: 18,
            offset:
                const Offset(0, 7),
          ),
        ],
      ),

      child: Column(
        children: [
          Row(
            children: [
              _buildCardIcon(
                context,
                brand,
              ),

              const SizedBox(
                width: 14,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      '$brand •••• $last4',
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    if (expMonth != null &&
                        expYear != null)
                      Padding(
                        padding:
                            const EdgeInsets
                                .only(
                          top: 5,
                        ),
                        child: Text(
                          'Expiră $expMonth/$expYear',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme
                                .colorScheme
                                .onSurface
                                .withOpacity(
                              0.55,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              if (isDefault)
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration:
                      BoxDecoration(
                    color: theme
                        .colorScheme
                        .primary
                        .withOpacity(
                      0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Icon(
                    Icons
                        .check_rounded,
                    size: 18,
                    color: theme
                        .colorScheme
                        .primary,
                  ),
                ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          Divider(
            height: 1,
            color: theme.dividerColor
                .withOpacity(0.35),
          ),

          const SizedBox(
            height: 8,
          ),

          Row(
            children: [
              if (!isDefault)
                TextButton.icon(
                  onPressed: () =>
                      _setDefault(
                    card['_id']
                        .toString(),
                  ),
                  icon: const Icon(
                    Icons
                        .check_circle_outline_rounded,
                    size: 18,
                  ),
                  label: const Text(
                    'Implicit',
                  ),
                ),

              const Spacer(),

              IconButton(
                tooltip:
                    'Șterge cardul',
                onPressed: () =>
                    _deleteCard(
                  card,
                ),
                icon: Icon(
                  Icons
                      .delete_outline_rounded,
                  color: theme
                      .colorScheme
                      .error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardIcon(
    BuildContext context,
    String brand,
  ) {
    final theme =
        Theme.of(context);

    return Container(
      width: 56,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary
                .withOpacity(0.70),
          ],
        ),
        borderRadius:
            BorderRadius.circular(11),
      ),
      child: const Icon(
        Icons.credit_card_rounded,
        color: Colors.white,
        size: 23,
      ),
    );
  }

  Widget _buildAddCardButton(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    return OutlinedButton.icon(
      onPressed: () {
        _showAddCardInfo(
          context,
        );
      },

      icon: const Icon(
        Icons.add_rounded,
      ),

      label: const Text(
        'Adaugă card',
        style: TextStyle(
          fontWeight: FontWeight.w800,
        ),
      ),

      style:
          OutlinedButton.styleFrom(
        minimumSize:
            const Size.fromHeight(
          54,
        ),

        side: BorderSide(
          color: theme.colorScheme.primary
              .withOpacity(0.45),
        ),

        foregroundColor:
            theme.colorScheme.primary,

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
        ),
      ),
    );
  }

  void _showAddCardInfo(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          theme.colorScheme.surface,
      showDragHandle: true,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              24,
              8,
              24,
              24,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration:
                      BoxDecoration(
                    color: theme
                        .colorScheme
                        .primary
                        .withOpacity(
                      0.10,
                    ),
                    shape:
                        BoxShape.circle,
                  ),
                  child: Icon(
                    Icons
                        .credit_card_rounded,
                    color: theme
                        .colorScheme
                        .primary,
                    size: 28,
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                const Text(
                  'Adaugă un card',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  'Cardul va fi adăugat prin procesatorul de plăți. Nexora Store nu va salva numărul complet al cardului sau codul CVV.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    height: 1.45,
                    color: theme
                        .colorScheme
                        .onSurface
                        .withOpacity(
                      0.62,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },
                    child: const Text(
                      'Închide',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}