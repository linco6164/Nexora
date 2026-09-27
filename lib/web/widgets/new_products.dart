import 'package:flutter/material.dart';

import '../../models/listing.dart';
import '../../api_service.dart';
import '../../shared/widgets/product_grid.dart';
import '../../shared/widgets/responsive_container.dart';
import '../../shared/widgets/section_title.dart';

class NewProducts extends StatefulWidget {
  const NewProducts({super.key});

  @override
  State<NewProducts> createState() => _NewProductsState();
}

class _NewProductsState extends State<NewProducts> {
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    return ResponsiveContainer(
      child: Column(
        children: [
          const SectionTitle(
            title: "New Arrivals",
            subtitle: "Recently added products",
          ),
          ProductGrid(products: _products),
        ],
      ),
    );
  }
}