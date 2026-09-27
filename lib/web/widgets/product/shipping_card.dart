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
              "Shipping & Protection",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            item(
              Icons.local_shipping_outlined,
              "Fast delivery",
              "Delivery through integrated courier partners.",
            ),

            const SizedBox(height: 24),

            item(
              Icons.security_outlined,
              "Buyer protection",
              "Orders are protected through the Nexora platform.",
            ),

            const SizedBox(height: 24),

            item(
              Icons.assignment_return_outlined,
              "Returns",
              "Return policy depends on the seller and product type.",
            ),
          ],
        ),
      ),
    );
  }
}