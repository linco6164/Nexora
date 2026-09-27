import 'package:flutter/material.dart';
import '../../../models/listing.dart';

class ProductSpecifications extends StatelessWidget {
  final Listing listing;

  const ProductSpecifications({
    super.key,
    required this.listing,
  });

 Widget _row(
  BuildContext context,
  String title,
  String value,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 180,
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(width: 24),

        Expanded(
          child: Text(value),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
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
            const Text(
              "Specifications",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            _row(context, "Category", listing.category),

            Divider(),

            _row(context, "Condition", listing.condition),

            Divider(),

            _row(context, "City", listing.city),

            Divider(),

            _row(context, "Currency", listing.currency),
          ],
        ),
      ),
    );
  }
}