import 'package:flutter/material.dart';

import 'api_service.dart';
import 'my_listings_page.dart';
import 'promotion_netopia_checkout.dart';

class PromotionPage extends StatefulWidget {
  const PromotionPage({super.key});

  @override
  State<PromotionPage> createState() => _PromotionPageState();
}

class _PromotionPageState extends State<PromotionPage> {
  List<Map<String, dynamic>> _promotions = [];

  bool _loading = true;
  String? _error;
  String? _retryingPromotionId;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _backgroundColor => Theme.of(context).scaffoldBackgroundColor;

  Color get _cardColor => Theme.of(context).cardColor;

  Color get _textColor => Theme.of(context).colorScheme.onSurface;

  Color get _secondaryTextColor =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.58);

  Color get _borderColor =>
      Theme.of(context).dividerColor.withValues(alpha: 0.25);

  Color get _surfaceColor => Theme.of(context).colorScheme.surface;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final promotions = await ApiService.getMyPromotions();

      if (!mounted) return;

      setState(() {
        _promotions = promotions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Activă';

      case 'pending':
        return 'În așteptarea plății';

      case 'expired':
        return 'Expirată';

      case 'cancelled':
        return 'Anulată';

      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF16A34A);

      case 'pending':
        return const Color(0xFFF59E0B);

      case 'expired':
        return _secondaryTextColor;

      case 'cancelled':
        return const Color(0xFFDC2626);

      default:
        return _secondaryTextColor;
    }
  }

  String _durationLabel(dynamic value) {
    final duration = value is num
        ? value.toInt()
        : int.tryParse(value.toString()) ?? 0;

    if (duration == 24) {
      return '24 ore';
    }

    if (duration == 72) {
      return '3 zile';
    }

    if (duration == 168) {
      return '7 zile';
    }

    return '$duration ore';
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return '-';

    final local = date.toLocal();

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(local.day)}.'
        '${two(local.month)}.'
        '${local.year} '
        '${two(local.hour)}:'
        '${two(local.minute)}';
  }

  Future<void> _retryPayment(Map<String, dynamic> promotion) async {
    final promotionId = promotion['_id']?.toString();

    if (promotionId == null || promotionId.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID-ul promovării este invalid.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    if (_retryingPromotionId != null) {
      return;
    }

    setState(() {
      _retryingPromotionId = promotionId;
    });

    try {
      final result = await ApiService.createPromotionPayment(
        promotionId: promotionId,
      );

      if (!mounted) return;

      final checkout = result['checkout'];

      if (checkout is! Map) {
        throw Exception('Datele pentru checkout NETOPIA sunt invalide.');
      }

      final checkoutMap = Map<String, dynamic>.from(checkout);

      final gatewayUrl = checkoutMap['gatewayUrl']?.toString();

      final envKey = checkoutMap['env_key']?.toString();

      final data = checkoutMap['data']?.toString();

      final cipher = checkoutMap['cipher']?.toString();

      final iv = checkoutMap['iv']?.toString();

      if (gatewayUrl == null ||
          gatewayUrl.isEmpty ||
          envKey == null ||
          envKey.isEmpty ||
          data == null ||
          data.isEmpty ||
          cipher == null ||
          cipher.isEmpty ||
          iv == null ||
          iv.isEmpty) {
        throw Exception('Datele pentru plata NETOPIA lipsesc.');
      }

      await PromotionNetopiaCheckout.open(
        gatewayUrl: gatewayUrl,
        envKey: envKey,
        data: data,
        cipher: cipher,
        iv: iv,
      );

      if (!mounted) return;

      await _loadPromotions();
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _retryingPromotionId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _backgroundColor,
        foregroundColor: _textColor,
        title: const Text(
          'Instrumente promoționale',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPromotions,
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: _cardColor,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _buildHeroCard(),

            const SizedBox(height: 20),

            _buildMyPromotionsHeader(),

            const SizedBox(height: 12),

            _buildPromotionsContent(),

            const SizedBox(height: 24),

            _buildHowItWorks(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDark
              ? const [Color(0xFF181818), Color(0xFF292929)]
              : const [Color(0xFF111111), Color(0xFF292929)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Fă-ți anunțurile mai vizibile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Promovează un anunț pentru a-l afișa mai vizibil în Nexora Store.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70),
              fontSize: 14,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyListingsPage()),
                );

                _loadPromotions();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Alege un anunț',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPromotionsHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Promovările mele',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _textColor,
            ),
          ),
        ),
        IconButton(
          onPressed: _loadPromotions,
          icon: Icon(Icons.refresh_rounded, color: _textColor),
        ),
      ],
    );
  }

  Widget _buildPromotionsContent() {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 50),
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: Color(0xFFDC2626),
            ),

            const SizedBox(height: 10),

            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: _secondaryTextColor),
            ),

            const SizedBox(height: 14),

            OutlinedButton(
              onPressed: _loadPromotions,
              child: const Text('Încearcă din nou'),
            ),
          ],
        ),
      );
    }

    if (_promotions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          children: [
            Icon(Icons.campaign_outlined, size: 52, color: _secondaryTextColor),

            const SizedBox(height: 14),

            Text(
              'Nu ai nicio promovare',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textColor,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Promovările tale vor apărea aici.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _secondaryTextColor),
            ),
          ],
        ),
      );
    }

    return Column(children: _promotions.map(_buildPromotionCard).toList());
  }

  Widget _buildPromotionCard(Map<String, dynamic> promotion) {
    final status = promotion['status']?.toString() ?? 'pending';

    final duration = promotion['duration'];

    final amount = promotion['amount'];

    final currency = promotion['currency']?.toString() ?? 'RON';

    final listingRaw = promotion['listing'];

    Map<String, dynamic>? listing;

    if (listingRaw is Map) {
      listing = Map<String, dynamic>.from(listingRaw);
    }

    final title = listing?['title']?.toString() ?? 'Anunț';

    final images = listing?['images'];

    String? imageUrl;

    if (images is List && images.isNotEmpty) {
      imageUrl = images.first?.toString();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
        boxShadow: _isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildListingImage(imageUrl),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _textColor,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(status)
                            .withValues(alpha: _isDark ? 0.16 : 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: TextStyle(
                          color: _statusColor(status),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Divider(height: 1, color: _borderColor),

          const SizedBox(height: 14),

          Row(
            children: [
              _InfoItem(
                icon: Icons.schedule_rounded,
                label: 'Durată',
                value: _durationLabel(duration),
              ),

              const SizedBox(width: 20),

              _InfoItem(
                icon: Icons.payments_outlined,
                label: 'Preț',
                value: '${amount ?? '-'} $currency',
              ),
            ],
          ),

          if (promotion['startsAt'] != null) ...[
            const SizedBox(height: 12),
            _DateRow(
              label: 'Început',
              value: _formatDate(promotion['startsAt']),
            ),
          ],

          if (promotion['expiresAt'] != null) ...[
            const SizedBox(height: 8),
            _DateRow(
              label: 'Expiră',
              value: _formatDate(promotion['expiresAt']),
            ),
          ],
          if (status == 'pending' ||
              status == 'failed' ||
              status == 'cancelled') ...[
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _retryingPromotionId == promotion['_id']?.toString()
                    ? null
                    : () => _retryPayment(promotion),

                icon: _retryingPromotionId == promotion['_id']?.toString()
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        status == 'pending'
                            ? Icons.payment_rounded
                            : Icons.refresh_rounded,
                      ),

                label: Text(
                  _retryingPromotionId == promotion['_id']?.toString()
                      ? 'Se deschide plata...'
                      : status == 'pending'
                      ? 'Continuă plata'
                      : 'Reîncearcă plata',

                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,

                  foregroundColor: Colors.white,

                  disabledBackgroundColor: Theme.of(context).colorScheme.primary
                      .withOpacity(0.55),

                  disabledForegroundColor: Colors.white,

                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListingImage(String? imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 82,
        height: 82,
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholder(),
              )
            : _imagePlaceholder(),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: _isDark ? const Color(0xFF252525) : const Color(0xFFF1F1F2),
      child: Icon(Icons.image_outlined, color: _secondaryTextColor),
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cum funcționează?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _textColor,
            ),
          ),

          const SizedBox(height: 16),

          _Step(
            number: '1',
            title: 'Alege anunțul',
            description: 'Selectează unul dintre anunțurile tale.',
            textColor: _textColor,
            secondaryTextColor: _secondaryTextColor,
          ),

          _Step(
            number: '2',
            title: 'Alege durata',
            description: 'Selectează perioada pentru care vrei promovarea.',
            textColor: _textColor,
            secondaryTextColor: _secondaryTextColor,
          ),

          _Step(
            number: '3',
            title: 'Plătește',
            description: 'Finalizează plata prin NETOPIA, iar promovarea se activează după confirmare.',
            textColor: _textColor,
            secondaryTextColor: _secondaryTextColor,
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
          ),

          const SizedBox(width: 8),

          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final String value;

  const _DateRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),

        const Spacer(),

        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final Color textColor;
  final Color secondaryTextColor;

  const _Step({
    required this.number,
    required this.title,
    required this.description,
    required this.textColor,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF292929) : const Color(0xFFF0F0F1),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: TextStyle(fontWeight: FontWeight.w800, color: textColor),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: secondaryTextColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
