import 'package:flutter/material.dart';

import '../../models/listing.dart';
import '../../api_service.dart';
import '../../shared/widgets/product_grid.dart';
import '../../shared/widgets/responsive_container.dart';
import '../../shared/widgets/section_title.dart';

class FeaturedProducts extends StatefulWidget {
  const FeaturedProducts({super.key});

  @override
  State<FeaturedProducts> createState() => _FeaturedProductsState();
}

class _FeaturedProductsState extends State<FeaturedProducts> {
  bool _loading = true;
  String? _error;

  List<Listing> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      // TODO:
      // Înlocuiește cu endpointul real:
      //
      // ApiService.getFeaturedProducts()

      final products = await ApiService.getListings();

      if (!mounted) return;

      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Text(_error!),
        ),
      );
    }

    return ResponsiveContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: "Featured products",
            subtitle: "Popular products chosen for you",
          ),

          ProductGrid(
            products: _products,
          ),
        ],
      ),
    );
  }
}