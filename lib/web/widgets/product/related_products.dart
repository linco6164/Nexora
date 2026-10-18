import 'package:flutter/material.dart';

import '../../../api_service.dart';
import '../../../l10n/app_locale.dart';
import '../../../models/listing.dart';
import '../../../shared/widgets/product_card.dart';
import '../../web_product_page.dart';

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
          context.tr('Produse similare'),
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: 18),

        SizedBox(
          height: 300,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (_, index) {
              final product = products[index];

              return SizedBox(
                width: 220,
                child: ProductCard(
                  id: product.id,
                  title: product.title,
                  image: product.images.isNotEmpty ? product.images.first : "",
                  price: product.price,
                  location: product.city,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WebProductPage(productId: product.id),
                      ),
                    );
                  },
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
