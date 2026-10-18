import 'package:flutter/material.dart';

import '../../../l10n/app_locale.dart';

class ShippingCard extends StatelessWidget {
  const ShippingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget item(IconData icon, String title, String subtitle) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 4),

                Text(subtitle),
              ],
            ),
          ),
        ],
      );
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appLocaleController.value == 'en'
                  ? 'Shipping, protection and returns'
                  : 'Livrare, protecție și retur',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 18),

            item(
              Icons.local_shipping_outlined,
              appLocaleController.value == 'en'
                  ? 'Courier delivery'
                  : 'Livrare prin curier',
              appLocaleController.value == 'en'
                  ? 'Sameday, FAN Courier or GLS. Estimated time: 2-5 business days.'
                  : 'Sameday, FAN Courier sau GLS. Termen estimat: 2-5 zile lucrătoare.',
            ),

            const SizedBox(height: 18),

            item(
              Icons.security_outlined,
              appLocaleController.value == 'en'
                  ? 'Protected payment'
                  : 'Plată protejată',
              appLocaleController.value == 'en'
                  ? 'Online payments are securely processed through NETOPIA Payments.'
                  : 'Plata online este procesată securizat prin NETOPIA Payments.',
            ),

            const SizedBox(height: 18),

            item(
              Icons.assignment_return_outlined,
              appLocaleController.value == 'en'
                  ? '14-day return'
                  : 'Retur în 14 zile',
              appLocaleController.value == 'en'
                  ? 'Consumers may request withdrawal online, subject to legal exceptions.'
                  : 'Consumatorii pot solicita retragerea online, cu excepțiile prevăzute de lege.',
            ),
          ],
        ),
      ),
    );
  }
}
