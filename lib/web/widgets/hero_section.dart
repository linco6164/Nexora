import 'package:flutter/material.dart';

import '../../l10n/app_locale.dart';
import '../../shared/widgets/responsive_container.dart';

class HeroSection extends StatelessWidget {
  final VoidCallback? onExplore;

  const HeroSection({super.key, this.onExplore});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: ResponsiveContainer(
        child: Container(
          constraints: const BoxConstraints(minHeight: 350),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF153B2A), Color(0xFF28744B)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF153B2A).withValues(alpha: .20),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 780;
              final phone = constraints.maxWidth < 520;
              return Stack(
                children: [
                  Positioned(
                    right: -80,
                    top: -110,
                    child: Container(
                      width: 330,
                      height: 330,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: .06),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(phone ? 20 : (compact ? 28 : 48)),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: _buildCopy(context, compact, phone),
                        ),
                        if (!compact) ...[
                          const SizedBox(width: 44),
                          Expanded(flex: 4, child: _buildVisual(theme)),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCopy(BuildContext context, bool compact, bool phone) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: Colors.white.withValues(alpha: .16)),
          ),
          child: Text(
            appLocaleController.value == 'en'
                ? 'TRUSTED MARKETPLACE'
                : 'MARKETPLACE ROMÂNESC',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          appLocaleController.value == 'en'
              ? 'Great things deserve a new story.'
              : 'Lucrurile bune merită o nouă poveste.',
          style: TextStyle(
            color: Colors.white,
            fontSize: phone ? 28 : (compact ? 32 : 44),
            height: 1.05,
            letterSpacing: -1.4,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 590),
          child: Text(
            appLocaleController.value == 'en'
                ? 'Discover carefully presented products, shop safely and sell easily in a community built on trust.'
                : 'Descoperă produse atent prezentate, cumpără în siguranță și vinde simplu, într-o comunitate construită pe încredere.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 26),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onExplore,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF153B2A),
                minimumSize: const Size(0, 44),
              ),
              icon: const Icon(Icons.search_rounded, size: 19),
              label: Text(context.tr('Explorează produsele')),
            ),
            OutlinedButton.icon(
              onPressed: onExplore,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: .45)),
                minimumSize: const Size(0, 44),
              ),
              icon: const Icon(Icons.sell_outlined, size: 18),
              label: Text(context.tr('Vezi marketplace-ul')),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 20,
          runSpacing: 8,
          children: [
            _TrustItem(
              Icons.verified_user_outlined,
              appLocaleController.value == 'en'
                  ? 'Verified sellers'
                  : 'Vânzători verificați',
            ),
            _TrustItem(
              Icons.lock_outline_rounded,
              appLocaleController.value == 'en'
                  ? 'Protected payments'
                  : 'Plăți protejate',
            ),
            _TrustItem(
              Icons.local_shipping_outlined,
              context.tr('Livrare rapidă'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVisual(ThemeData theme) {
    return Center(
      child: SizedBox(
        height: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: -.08,
              child: Container(
                width: 230,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .18),
                  ),
                ),
              ),
            ),
            Container(
              width: 214,
              height: 236,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 28,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        size: 72,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 15),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Icon(
                          Icons.favorite_rounded,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ],
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
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustItem(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
