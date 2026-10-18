import 'package:flutter/material.dart';

import '../../models/chat_models.dart';

class OfferPurchaseAction extends StatelessWidget {
  final Offer offer;
  final String userId;
  final VoidCallback onPurchase;

  const OfferPurchaseAction({
    super.key,
    required this.offer,
    required this.userId,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    if (!offer.isAccepted) return const SizedBox.shrink();
    if (offer.listing != null && offer.listing!.status != 'active') {
      return const Text('Produsul nu mai este disponibil.');
    }
    if (offer.canBePurchasedBy(userId)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: onPurchase,
            icon: const Icon(Icons.shopping_bag_outlined, size: 18),
            label: Text(
              'Cumpără la ${offer.amount.toStringAsFixed(2)} ${offer.currency}',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Livrarea și protecția cumpărătorului se adaugă la finalizarea comenzii.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }
    if (offer.sellerId == userId) {
      return const Text(
        'Ai acceptat oferta. Cumpărătorul poate finaliza acum comanda la acest preț.',
      );
    }
    return const SizedBox.shrink();
  }
}
