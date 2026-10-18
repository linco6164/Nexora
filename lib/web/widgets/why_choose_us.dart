import 'package:flutter/material.dart';

import '../../l10n/app_locale.dart';
import '../../shared/widgets/responsive_container.dart';
import '../../shared/widgets/section_title.dart';

class WhyChooseUs extends StatelessWidget {
  const WhyChooseUs({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: Column(
        children: [
          SectionTitle(
            title: appLocaleController.value == 'en'
                ? 'Why Nexora?'
                : 'De ce Nexora?',
            subtitle: appLocaleController.value == 'en'
                ? 'A simple and secure experience, from listing to delivery'
                : 'O experiență simplă și sigură, de la listare la livrare',
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth >= 760
                  ? (constraints.maxWidth - 42) / 4
                  : (constraints.maxWidth - 14) / 2;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _Benefit(
                    width: itemWidth,
                    icon: Icons.verified_user_outlined,
                    title: appLocaleController.value == 'en'
                        ? 'Verified sellers'
                        : 'Vânzători verificați',
                  ),
                  _Benefit(
                    width: itemWidth,
                    icon: Icons.lock_outline_rounded,
                    title: appLocaleController.value == 'en'
                        ? 'Protected payments'
                        : 'Plăți protejate',
                  ),
                  _Benefit(
                    width: itemWidth,
                    icon: Icons.local_shipping_outlined,
                    title: context.tr('Livrare rapidă'),
                  ),
                  _Benefit(
                    width: itemWidth,
                    icon: Icons.support_agent_outlined,
                    title: appLocaleController.value == 'en'
                        ? 'Dedicated support'
                        : 'Suport dedicat',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final double width;
  final IconData icon;
  final String title;

  const _Benefit({
    required this.width,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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
