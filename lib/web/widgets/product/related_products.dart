import 'package:flutter/material.dart';

import '../../../api_service.dart';
import '../../../models/listing.dart';
import '../../../shared/widgets/product_card.dart';

class RelatedProducts extends StatefulWidget {
  final String currentListingId;

  const RelatedProducts({super.key, required this.currentListingId});

  @override
  State<RelatedProducts> createState() => _RelatedProductsState();
}

class _RelatedProductsState extends State<RelatedProducts> {
  bool loading = true;

  List<Listing> products = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await ApiService.getListings();

      if (!mounted) return;

      setState(() {
        products = result
            .where((e) => e.id != widget.currentListingId)
            .take(8)
            .toList();

        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (products.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Similar products",
          style: Theme.of(context).textTheme.headlineSmall,
        ),

        const SizedBox(height: 24),

        SizedBox(
          height: 430,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 20),
            itemBuilder: (_, index) {
              final product = products[index];

              return SizedBox(
                width: 270,
                child: ProductCard(
                  id: product.id,
                  title: product.title,
                  image: product.images.isNotEmpty ? product.images.first : "",
                  price: product.price,
                  location: product.city,
                  onTap: () {},
                  onFavorite: () {},
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
