import 'package:flutter/material.dart';

import '../../../models/listing.dart';

import '../../checkout/web_checkout_page.dart';

class ProductInfo extends StatelessWidget {
  final Listing listing;

  const ProductInfo({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          listing.title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        Text(
          "${listing.price.toStringAsFixed(2)} ${listing.currency}",
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),

        const SizedBox(height: 24),

        Row(
          children: [
            const Icon(Icons.location_on_outlined),
            const SizedBox(width: 6),
            Text(listing.city),
          ],
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            const Icon(Icons.inventory_2_outlined),
            const SizedBox(width: 6),
            Text(listing.condition),
          ],
        ),

        const SizedBox(height: 30),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WebCheckoutPage(listingId: listing.id),
                ),
              );
            },
            icon: const Icon(Icons.shopping_cart_checkout),
            label: const Text("Buy now"),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text("Chat with seller"),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.favorite_border),
            label: const Text("Add to favorites"),
          ),
        ),
      ],
    );
  }
}
