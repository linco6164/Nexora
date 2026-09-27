import 'package:flutter/material.dart';

import '../../models/listing.dart';
import '../../web/web_product_page.dart';
import 'product_card.dart';

class ProductGrid extends StatelessWidget {
  final List<Listing> products;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ProductGrid({
    super.key,
    required this.products,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text("Nu există produse."),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 2;

        if (constraints.maxWidth >= 1400) {
          columns = 5;
        } else if (constraints.maxWidth >= 1100) {
          columns = 4;
        } else if (constraints.maxWidth >= 800) {
          columns = 3;
        }

        return GridView.builder(
          shrinkWrap: shrinkWrap,
          physics: physics,
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: .68,
          ),
          itemBuilder: (_, index) {
            final product = products[index];

            return ProductCard(
              id: product.id,
              title: product.title,
              image: product.images.isNotEmpty ? product.images.first : "",
              price: product.price,
              location: product.city,
              isFavorite: false,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WebProductPage(productId: product.id),
                  ),
                );
              },
              onFavorite: () {
                // TODO
              },
            );
          },
        );
      },
    );
  }
}
