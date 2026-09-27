import 'package:flutter/material.dart';

import 'api_service.dart';
import 'app_navigator.dart';

class PromotionPaymentReturnPage extends StatefulWidget {
  final String paymentId;
  final String status;

  const PromotionPaymentReturnPage({
    super.key,
    required this.paymentId,
    required this.status,
  });

  @override
  State<PromotionPaymentReturnPage> createState() =>
      _PromotionPaymentReturnPageState();
}

class _PromotionPaymentReturnPageState
    extends State<PromotionPaymentReturnPage> {
  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _payment;

  @override
  void initState() {
    super.initState();
    _checkPayment();
  }

  Future<void> _checkPayment() async {
    if (widget.paymentId.trim().isEmpty) {
      setState(() {
        _loading = false;
        _error = 'ID-ul plății este invalid.';
      });
      return;
    }

    try {
      final payment = await ApiService.getPromotionPayment(widget.paymentId);

      if (!mounted) return;

      setState(() {
        _payment = payment;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _goBack() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF0B0D0F)
        : const Color(0xFFF5F7F8);

    final cardColor = isDark ? const Color(0xFF15191C) : Colors.white;

    final primaryText = isDark ? Colors.white : const Color(0xFF111315);

    final secondaryText = isDark
        ? const Color(0xFFB7BEC4)
        : const Color(0xFF6E7479);

    final borderColor = isDark
        ? const Color(0xFF292F34)
        : const Color(0xFFE7EAEC);

    final green = const Color(0xFF50C878);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: primaryText,
        title: const Text(
          'Plată promovare',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: _loading
                  ? _buildLoading(primaryText, secondaryText)
                  : _error != null
                  ? _buildError(
                      primaryText,
                      secondaryText,
                      cardColor,
                      borderColor,
                    )
                  : _buildSuccess(
                      primaryText,
                      secondaryText,
                      cardColor,
                      borderColor,
                      green,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(Color primaryText, Color secondaryText) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),

        const SizedBox(
          width: 34,
          height: 34,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Color(0xFF50C878),
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Verificăm plata...',
          style: TextStyle(
            color: primaryText,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Așteptăm confirmarea plății de la NETOPIA.',
          textAlign: TextAlign.center,
          style: TextStyle(color: secondaryText, fontSize: 15),
        ),

        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildError(
    Color primaryText,
    Color secondaryText,
    Color cardColor,
    Color borderColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withValues(alpha: 0.10),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 46,
              color: Colors.red,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Nu am putut verifica plata',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primaryText,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            _error ?? 'A apărut o eroare.',
            textAlign: TextAlign.center,
            style: TextStyle(color: secondaryText, fontSize: 15, height: 1.5),
          ),

          const SizedBox(height: 28),

          _buildPrimaryButton(),
        ],
      ),
    );
  }

  Widget _buildSuccess(
    Color primaryText,
    Color secondaryText,
    Color cardColor,
    Color borderColor,
    Color green,
  ) {
    final paymentStatus =
        _payment?['status']?.toString().toLowerCase() ?? 'pending';

    final promotion = _payment?['promotion'];

    String promotionStatus = 'pending';

    if (promotion is Map) {
      promotionStatus =
          promotion['status']?.toString().toLowerCase() ?? 'pending';
    }

    // ============================================================
    // PLATĂ REUȘITĂ + PROMOVARE ACTIVĂ
    // ============================================================

    if (paymentStatus == 'paid' && promotionStatus == 'active') {
      return _buildActivated(
        primaryText,
        secondaryText,
        cardColor,
        borderColor,
        green,
      );
    }

    // ============================================================
    // PLATĂ EȘUATĂ
    // ============================================================

    if (paymentStatus == 'failed') {
      return _buildFailed(primaryText, secondaryText, cardColor, borderColor);
    }

    // ============================================================
    // PLATĂ ANULATĂ
    // ============================================================

    if (paymentStatus == 'cancelled') {
      return _buildCancelled(
        primaryText,
        secondaryText,
        cardColor,
        borderColor,
      );
    }

    // ============================================================
    // PLATĂ ÎN AȘTEPTARE
    // ============================================================

    return _buildPending(primaryText, secondaryText, cardColor, borderColor);
  }

  Widget _buildFailed(
    Color primaryText,
    Color secondaryText,
    Color cardColor,
    Color borderColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withValues(alpha: 0.10),
            ),
            child: const Icon(Icons.close_rounded, color: Colors.red, size: 48),
          ),

          const SizedBox(height: 24),

          Text(
            'Plata a eșuat',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primaryText,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Plata promovării nu a fost confirmată. Anunțul nu a fost promovat.',
            textAlign: TextAlign.center,
            style: TextStyle(color: secondaryText, fontSize: 15, height: 1.5),
          ),

          const SizedBox(height: 28),

          _buildPrimaryButton(),
        ],
      ),
    );
  }

  Widget _buildCancelled(
    Color primaryText,
    Color secondaryText,
    Color cardColor,
    Color borderColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.withValues(alpha: 0.10),
            ),
            child: const Icon(
              Icons.remove_circle_outline_rounded,
              color: Colors.orange,
              size: 46,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Plata a fost anulată',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primaryText,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Plata promovării a fost anulată, iar anunțul nu a fost promovat.',
            textAlign: TextAlign.center,
            style: TextStyle(color: secondaryText, fontSize: 15, height: 1.5),
          ),

          const SizedBox(height: 28),

          _buildPrimaryButton(),
        ],
      ),
    );
  }

  Widget _buildActivated(
    Color primaryText,
    Color secondaryText,
    Color cardColor,
    Color borderColor,
    Color green,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 34, 28, 28),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 35,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          // ======================================================
          // SUCCESS ICON
          // ======================================================

          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: green.withValues(alpha: 0.10),
            ),
            child: Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(shape: BoxShape.circle, color: green),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          Text(
            'Promovarea a fost activată',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primaryText,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Plata a fost confirmată, iar anunțul tău este acum promovat.',
            textAlign: TextAlign.center,
            style: TextStyle(color: secondaryText, fontSize: 16, height: 1.5),
          ),

          const SizedBox(height: 30),

          // ======================================================
          // PAYMENT STATUS
          // ======================================================
          _buildStatusRow(
            label: 'Plată',
            value: 'Platit',
            valueColor: green,
            cardColor: cardColor,
            borderColor: borderColor,
            primaryText: primaryText,
            secondaryText: secondaryText,
          ),

          const SizedBox(height: 10),

          // ======================================================
          // PROMOTION STATUS
          // ======================================================
          _buildStatusRow(
            label: 'Promovare',
            value: 'Activ',
            valueColor: green,
            cardColor: cardColor,
            borderColor: borderColor,
            primaryText: primaryText,
            secondaryText: secondaryText,
          ),

          const SizedBox(height: 18),

          // ======================================================
          // PAYMENT ID
          // ======================================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: primaryText.withValues(alpha: 0.035),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ID plată',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                SelectableText(
                  widget.paymentId,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildPrimaryButton(),
        ],
      ),
    );
  }

  Widget _buildPending(
    Color primaryText,
    Color secondaryText,
    Color cardColor,
    Color borderColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.withValues(alpha: 0.10),
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: Colors.orange,
              size: 46,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Plata este în verificare',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primaryText,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Plata a fost trimisă, dar confirmarea NETOPIA nu a fost încă primită.',
            textAlign: TextAlign.center,
            style: TextStyle(color: secondaryText, fontSize: 15, height: 1.5),
          ),

          const SizedBox(height: 28),

          _buildPrimaryButton(),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required String label,
    required String value,
    required Color valueColor,
    required Color cardColor,
    required Color borderColor,
    required Color primaryText,
    required Color secondaryText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: primaryText.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: secondaryText,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _goBack,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: const Text(
          'Înapoi în Nexora',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
