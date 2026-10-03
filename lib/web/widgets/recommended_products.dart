import 'package:flutter/material.dart';

import '../../models/listing.dart';
import '../../api_service.dart';
import '../../shared/widgets/product_grid.dart';
import '../../shared/widgets/responsive_container.dart';
import '../../shared/widgets/section_title.dart';

class RecommendedProducts extends StatefulWidget {
  const RecommendedProducts({super.key});

  @override
  State<RecommendedProducts> createState() => _RecommendedProductsState();
}

class _RecommendedProductsState extends State<RecommendedProducts> {
  bool _loading = true;

  List<Listing> _products = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final products = await ApiService.getListings();

      debugPrint(products.runtimeType.toString());

      if (!mounted) return;

      if (products.isNotEmpty) {
        debugPrint(products.first.runtimeType.toString());
      }

      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ResponsiveContainer(
      child: Column(
        children: [
          const SectionTitle(
            title: "Recommended",
            subtitle: "Products selected for you",
          ),
          ProductGrid(products: _products),
        ],
      ),
    );
  }
}
