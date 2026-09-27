import 'package:flutter/material.dart';

import '../api_service.dart';
import '../models/listing.dart';
import 'widgets/product/product_gallery.dart';
import 'widgets/product/product_info.dart';
import 'widgets/product/product_description.dart';
import 'widgets/product/product_specifications.dart';
import 'widgets/product/seller_card.dart';
import 'widgets/product/shipping_card.dart';
import 'widgets/product/related_products.dart';
import 'widgets/product/product_breadcrumb.dart';



class WebProductPage extends StatefulWidget {
  final String productId;

  const WebProductPage({super.key, required this.productId});

  @override
  State<WebProductPage> createState() => _WebProductPageState();
}

class _WebProductPageState extends State<WebProductPage> {
  Listing? listing;

  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadListing();
  }

  Future<void> _loadListing() async {
    try {
      final result = await ApiService.getListingById(widget.productId);

      if (!mounted) return;

      setState(() {
        listing = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(body: Center(child: Text(error!)));
    }

    final product = listing!;

    return Scaffold(
      appBar: AppBar(title: Text(product.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductBreadcrumb(
                  category: product.category,
                  title: product.title,
                ),

                const SizedBox(height: 24),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: ProductGallery(images: product.images),
                    ),

                    const SizedBox(width: 40),

                    Expanded(flex: 5, child: ProductInfo(listing: product)),
                  ],
                ),

                const SizedBox(height: 40),

                ProductDescription(description: product.description),

                const SizedBox(height: 30),

                ProductSpecifications(listing: product),

                const SizedBox(height: 30),

                const ShippingCard(),

                const SizedBox(height: 30),

                SellerCard(
                  sellerName: product.seller?.username ?? "Nexora User",
                  avatar: product.seller?.avatar,
                  verified: product.seller?.verified ?? false,
                  listingsCount: null,
                  memberSince: null,
                ),

                const SizedBox(height: 40),

                RelatedProducts(currentListingId: product.id),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
