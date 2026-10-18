import 'package:flutter/material.dart';

import '../../models/listing.dart';
import '../../api_service.dart';
import '../../l10n/app_locale.dart';
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
  String? _error;

  List<Listing> _products = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final products = await ApiService.getListings();

      if (!mounted) return;

      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString();
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
          SectionTitle(
            title: appLocaleController.value == 'en'
                ? 'Recommended'
                : 'Recomandate',
            subtitle: appLocaleController.value == 'en'
                ? 'Products selected for you'
                : 'Produse selectate pentru tine',
          ),
          ProductGrid(products: _products.skip(2).take(10).toList()),
        ],
      ),
    );
  }
}
