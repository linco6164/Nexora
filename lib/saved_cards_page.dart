import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';

class SavedCardsPage extends StatefulWidget {
  final bool embedded;

  const SavedCardsPage({super.key, this.embedded = false});

  @override
  State<SavedCardsPage> createState() => _SavedCardsPageState();
}

class _SavedCardsPageState extends State<SavedCardsPage>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _awaitingEnrollment = false;
  bool _promptIsBusy = false;
  String? _loadError;
  String? _activeSetupId;
  List<Map<String, dynamic>> _cards = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCards();

    if (kIsWeb) {
      final setupId = Uri.base.queryParameters['cardSetupId'];

      if (setupId != null && setupId.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_pollEnrollment(setupId));
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _activeSetupId = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingEnrollment) {
      _awaitingEnrollment = false;
      _loadCards(showLoader: false);
    }
  }

  Future<void> _loadCards({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }

    try {
      final cards = await ApiService.getSavedCards();

      if (!mounted) return;

      setState(() {
        _cards = cards;
        _loading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;

      final message = _cleanError(error);

      setState(() {
        _loading = false;
        _loadError = message;
      });

      if (_cards.isNotEmpty) {
        _showMessage(message);
      }
    }
  }

  Future<void> _setDefault(String cardId) async {
    try {
      await ApiService.setDefaultSavedCard(cardId);
      await _loadCards(showLoader: false);
    } catch (error) {
      if (mounted) _showMessage(_cleanError(error));
    }
  }

  Future<void> _deleteCard(Map<String, dynamic> card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Ștergi cardul?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            '${card['brand'] ?? 'Card'} •••• ${card['last4'] ?? ''}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Anulează'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              child: const Text('Șterge'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteSavedCard(card['_id'].toString());
      await _loadCards(showLoader: false);
    } catch (error) {
      if (mounted) _showMessage(_cleanError(error));
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('ApiException: ', '');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _pollEnrollment(String setupId) async {
    if (_activeSetupId == setupId) return;

    _activeSetupId = setupId;

    if (mounted) {
      setState(() => _awaitingEnrollment = true);
    }

    String? lastError;

    for (var attempt = 0; attempt < 30; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }

      if (!mounted || _activeSetupId != setupId) return;

      try {
        final result = await ApiService.getSavedCardEnrollmentStatus(setupId);
        final status = result['status']?.toString();

        if (status == 'completed') {
          _activeSetupId = null;
          setState(() => _awaitingEnrollment = false);
          await _loadCards(showLoader: false);

          if (mounted) {
            _showMessage('Cardul a fost adăugat cu succes.');
          }
          return;
        }

        if (status == 'failed') {
          _activeSetupId = null;
          setState(() => _awaitingEnrollment = false);
          _showMessage(
            result['errorMessage']?.toString() ??
                'Cardul nu a putut fi adăugat.',
          );
          return;
        }
      } catch (error) {
        lastError = _cleanError(error);
      }
    }

    if (!mounted || _activeSetupId != setupId) return;

    _activeSetupId = null;
    setState(() => _awaitingEnrollment = false);
    _showMessage(
      lastError ?? 'Confirmarea NETOPIA durează mai mult. Folosește butonul Actualizează.',
    );
  }

  Future<void> _openAddCard() async {
    Future<void> startEnrollment(
      BuildContext promptContext,
      StateSetter setPromptState,
    ) async {
      setPromptState(() => _promptIsBusy = true);

      try {
        final session = await ApiService.createSavedCardEnrollment();
        final opened = await launchUrl(
          session.checkoutUri,
          mode: kIsWeb
              ? LaunchMode.platformDefault
              : LaunchMode.externalApplication,
          webOnlyWindowName: kIsWeb ? '_blank' : null,
        );

        if (!opened) {
          throw ApiException('Nu am putut deschide pagina securizată.');
        }

        if (!mounted || !promptContext.mounted) return;

        setState(() => _awaitingEnrollment = true);
        Navigator.of(promptContext).pop();

        unawaited(_pollEnrollment(session.setupId));

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text(
                'Finalizează adăugarea la NETOPIA, apoi revino aici.',
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 12),
              action: SnackBarAction(
                label: 'Actualizează',
                onPressed: () {
                  _awaitingEnrollment = false;
                  _loadCards(showLoader: false);
                },
              ),
            ),
          );
      } catch (error) {
        if (!mounted || !promptContext.mounted) return;

        setPromptState(() => _promptIsBusy = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(_cleanError(error)),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    }

    _promptIsBusy = false;

    Widget builder(BuildContext promptContext) {
      return StatefulBuilder(
        builder: (context, setPromptState) {
          return _CardEnrollmentPrompt(
            busy: _promptIsBusy,
            onContinue: () => startEnrollment(promptContext, setPromptState),
            onCancel: _promptIsBusy
                ? null
                : () => Navigator.of(promptContext).pop(),
          );
        },
      );
    }

    if (kIsWeb) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 470),
            child: builder(dialogContext),
          ),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: widget.embedded
          ? null
          : AppBar(
              elevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              foregroundColor: theme.colorScheme.onSurface,
              title: const Text(
                'Cardurile mele',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              actions: [
                IconButton(
                  tooltip: 'Actualizează',
                  onPressed: _loading ? null : _loadCards,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
      body: SafeArea(
        top: !widget.embedded,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && _cards.isEmpty) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadCards(showLoader: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          widget.embedded ? 28 : 16,
          widget.embedded ? 36 : 8,
          widget.embedded ? 28 : 16,
          36,
        ),
        children: [
          _buildHeader(),
          const SizedBox(height: 22),
          if (_awaitingEnrollment) ...[
            _buildEnrollmentBanner(),
            const SizedBox(height: 16),
          ],
          if (_cards.isEmpty)
            _buildEmptyContent()
          else ...[
            ..._cards.map(_buildCard),
            const SizedBox(height: 8),
            _buildAddCardButton(),
          ],
          const SizedBox(height: 16),
          _buildSecurityNotice(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.embedded ? 'Cardurile mele' : 'Metode de plată',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_cards.length} ${_cards.length == 1 ? 'card salvat' : 'carduri salvate'}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
        ),
        if (widget.embedded)
          IconButton.filledTonal(
            tooltip: 'Actualizează',
            onPressed: () => _loadCards(showLoader: false),
            icon: const Icon(Icons.refresh_rounded),
          ),
      ],
    );
  }

  Widget _buildEmptyContent() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.credit_card_outlined,
              size: 42,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Nu ai carduri salvate',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Adaugă un card pentru plăți mai rapide la următoarele cumpărături.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 26),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: _buildAddCardButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.cloud_off_outlined,
          size: 54,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 18),
        const Text(
          'Nu am putut încărca cardurile',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          _loadError!,
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 22),
        Center(
          child: FilledButton.icon(
            onPressed: _loadCards,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Încearcă din nou'),
          ),
        ),
      ],
    );
  }

  Widget _buildEnrollmentBanner() {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(Icons.open_in_new_rounded, color: colors.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Ai finalizat adăugarea în pagina NETOPIA?',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              setState(() => _awaitingEnrollment = false);
              _loadCards(showLoader: false);
            },
            child: const Text('Verifică'),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> card) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final brand = card['brand']?.toString().trim();
    final displayBrand = brand == null || brand.isEmpty ? 'Card' : brand;
    final last4 = card['last4']?.toString() ?? '';
    final isDefault = card['isDefault'] == true;
    final expiry = _formatExpiry(card['expMonth'], card['expYear']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDefault
              ? colors.primary
              : colors.outlineVariant.withValues(alpha: 0.55),
          width: isDefault ? 1.5 : 1,
        ),
        boxShadow: theme.brightness == Brightness.dark
            ? null
            : [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.045),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildCardIcon(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$displayBrand •••• $last4',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (expiry != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        'Expiră $expiry',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        size: 17,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Implicit',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: colors.outlineVariant),
          const SizedBox(height: 7),
          Row(
            children: [
              if (!isDefault)
                TextButton.icon(
                  onPressed: () => _setDefault(card['_id'].toString()),
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                  ),
                  label: const Text('Setează implicit'),
                ),
              const Spacer(),
              IconButton(
                tooltip: 'Șterge cardul',
                onPressed: () => _deleteCard(card),
                icon: Icon(Icons.delete_outline_rounded, color: colors.error),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardIcon() {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: 58,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withValues(alpha: 0.68)],
        ),
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Icon(
        Icons.credit_card_rounded,
        color: Colors.white,
        size: 23,
      ),
    );
  }

  String? _formatExpiry(dynamic month, dynamic year) {
    final parsedMonth = int.tryParse(month?.toString() ?? '');
    final parsedYear = int.tryParse(year?.toString() ?? '');

    if (parsedMonth == null || parsedYear == null) return null;

    final shortYear = (parsedYear % 100).toString().padLeft(2, '0');
    return '${parsedMonth.toString().padLeft(2, '0')}/$shortYear';
  }

  Widget _buildAddCardButton() {
    final colors = Theme.of(context).colorScheme;

    return OutlinedButton.icon(
      onPressed: _openAddCard,
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'Adaugă card',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        side: BorderSide(color: colors.primary.withValues(alpha: 0.45)),
        foregroundColor: colors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSecurityNotice() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.055 : 0.035,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 19,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Numărul complet al cardului și codul CVV sunt introduse doar în pagina securizată NETOPIA și nu sunt stocate de Nexora.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardEnrollmentPrompt extends StatelessWidget {
  final bool busy;
  final VoidCallback onContinue;
  final VoidCallback? onCancel;

  const _CardEnrollmentPrompt({
    required this.busy,
    required this.onContinue,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.all(Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Închide',
                  onPressed: onCancel,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_card_rounded,
                  color: colors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Adaugă un card',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 9),
              Text(
                'Vei continua în pagina securizată NETOPIA pentru verificarea cardului. Nexora va primi doar marca, ultimele 4 cifre și tokenul de plată.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.5, color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Datele complete ale cardului nu ajung pe serverele Nexora.',
                        style: TextStyle(fontSize: 12.5, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: busy ? null : onContinue,
                  icon: busy
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_outline_rounded),
                  label: Text(
                    busy ? 'Se pregătește...' : 'Continuă securizat',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
