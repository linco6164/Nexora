import 'package:flutter/material.dart';

class ShippingCard extends StatelessWidget {
  const ShippingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget item(
      IconData icon,
      String title,
      String subtitle,
    ) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Livrare, protecție și retur',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            item(
              Icons.local_shipping_outlined,
              'Livrare prin curier',
              'Sameday, FAN Courier sau GLS. Termen estimat: 2-5 zile lucrătoare.',
            ),

            const SizedBox(height: 24),

            item(
              Icons.security_outlined,
              'Plată protejată',
              'Plata online este procesată securizat prin NETOPIA Payments.',
            ),

            const SizedBox(height: 24),

            item(
              Icons.assignment_return_outlined,
              'Retur în 14 zile',
              'Consumatorii pot solicita retragerea online, cu excepțiile prevăzute de lege.',
            ),
          ],
        ),
      ),
    );
  }
}
