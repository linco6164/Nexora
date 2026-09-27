import 'package:flutter/material.dart';

import 'promotion_netopia_checkout.dart';

import 'api_service.dart';
import 'models/listing.dart';

class PromotionDurationPage extends StatefulWidget {
  final Listing listing;

  const PromotionDurationPage({super.key, required this.listing});

  @override
  State<PromotionDurationPage> createState() => _PromotionDurationPageState();
}

class _PromotionDurationPageState extends State<PromotionDurationPage> {
  List<_PromotionOption> _options = [];

  bool _loadingPackages = true;
  bool _creatingPromotion = false;

  String? _error;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    try {
      final packages = await ApiService.getPromotionPackages();

      if (!mounted) return;

      final options = packages.map((item) {
        final data = Map<String, dynamic>.from(item);

        final duration = (data['duration'] as num).toInt();

        return _PromotionOption(
          duration: duration,
          title: _durationLabel(duration),
          description: _descriptionForDuration(duration),
          price: (data['amount'] as num).toDouble(),
          currency: data['currency']?.toString() ?? 'RON',
        );
      }).toList();

      setState(() {
        _options = options;
        _loadingPackages = false;

        if (_selectedIndex >= _options.length) {
          _selectedIndex = 0;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loadingPackages = false;
      });
    }
  }

  String _durationLabel(int duration) {
    switch (duration) {
      case 24:
        return '24 ore';

      case 72:
        return '3 zile';

      case 168:
        return '7 zile';

      default:
        return '$duration ore';
    }
  }

  String _descriptionForDuration(int duration) {
    switch (duration) {
      case 24:
        return 'Crește vizibilitatea timp de 24 de ore.';

      case 72:
        return 'Promovează anunțul timp de 3 zile.';

      case 168:
        return 'Vizibilitate crescută timp de 7 zile.';

      default:
        return 'Promovează anunțul pentru perioada selectată.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Promovează anunțul',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _buildBody(context, colorScheme),
    );
  }

  Widget _buildBody(BuildContext context, ColorScheme colorScheme) {
    if (_loadingPackages) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 52,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Nu am putut încărca pachetele de promovare.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _loadingPackages = true;
                  });

                  _loadPackages();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Încearcă din nou'),
              ),
            ],
          ),
        ),
      );
    }

    if (_options.isEmpty) {
      return const Center(
        child: Text('Nu există pachete de promovare disponibile.'),
      );
    }

    final selected = _options[_selectedIndex];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _buildListingCard(context),

        const SizedBox(height: 28),

        Text(
          'Alege perioada',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: 12),

        ...List.generate(_options.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildOption(context, index, _options[index]),
          );
        }),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(Icons.rocket_launch_rounded, color: colorScheme.primary),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Promovare selectată',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '${selected.title} • '
                      '${selected.price.toStringAsFixed(2)} '
                      '${selected.currency}',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: _creatingPromotion ? null : _continue,
            icon: _creatingPromotion
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward_rounded),
            label: Text(
              _creatingPromotion ? 'Se procesează...' : 'Continuă',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListingCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final images = widget.listing.images;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 82,
              height: 82,
              child: images.isNotEmpty
                  ? Image.network(
                      images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const Center(
                          child: Icon(Icons.image_not_supported_outlined),
                        );
                      },
                    )
                  : const Center(child: Icon(Icons.image_outlined)),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.listing.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '${widget.listing.price.toStringAsFixed(2)} '
                  '${widget.listing.currency}',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    int index,
    _PromotionOption option,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final selected = _selectedIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _creatingPromotion
            ? null
            : () {
                setState(() {
                  _selectedIndex = index;
                });
              },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primaryContainer
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? colorScheme.primary : colorScheme.outline,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      option.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Text(
                '${option.price.toStringAsFixed(2)} '
                '${option.currency}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _continue() async {
    if (_options.isEmpty) return;

    final selected = _options[_selectedIndex];

    setState(() {
      _creatingPromotion = true;
      _error = null;
    });

    try {
      // 1. Creăm promovarea.
      final promotion = await ApiService.createPromotion(
        listingId: widget.listing.id,
        duration: selected.duration,
      );

      final promotionId =
          promotion['_id']?.toString() ?? promotion['id']?.toString();

      if (promotionId == null || promotionId.isEmpty) {
        throw Exception('Backend-ul nu a returnat ID-ul promovării.');
      }

      // 2. Creăm plata NETOPIA.
      final payment = await ApiService.createPromotionPayment(
        promotionId: promotionId,
      );

      final checkout = Map<String, dynamic>.from(payment['checkout'] ?? {});

      final gatewayUrl = checkout['gatewayUrl']?.toString();

      final envKey = checkout['env_key']?.toString();

      final data = checkout['data']?.toString();

      final cipher = checkout['cipher']?.toString();

      final iv = checkout['iv']?.toString();

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
        throw Exception('Datele pentru checkout NETOPIA sunt incomplete.');
      }

      if (!mounted) return;

      PromotionNetopiaCheckout.open(
        gatewayUrl: gatewayUrl,
        envKey: envKey,
        data: data,
        cipher: cipher,
        iv: iv,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _creatingPromotion = false;
        });
      }
    }
  }
}

class _PromotionOption {
  final int duration;
  final String title;
  final String description;
  final double price;
  final String currency;

  const _PromotionOption({
    required this.duration,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
  });
}
