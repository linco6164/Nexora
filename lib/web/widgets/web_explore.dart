import 'package:flutter/material.dart';

import '../../models/listing.dart';
import '../../shared/widgets/responsive_container.dart';
import '../../shared/widgets/product_grid.dart';
import '../../shared/widgets/section_title.dart';
import '../../api_service.dart';

class WebExplore extends StatefulWidget {
  const WebExplore({super.key});

  @override
  State<WebExplore> createState() => _WebExploreState();
}

class _WebExploreState extends State<WebExplore> {
  bool _loading = true;
  String? _error;

  List<Listing> _products = [];

  final TextEditingController _searchController =
      TextEditingController();

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
    return Scaffold(
      body: ResponsiveContainer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 280,
              child: _Filters(
                controller: _searchController,
              ),
            ),

            const SizedBox(width: 30),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(
                    title: "Explore",
                    subtitle: "Browse all products",
                  ),

                  if (_loading)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_error != null)
                    Expanded(
                      child: Center(
                        child: Text(_error!),
                      ),
                    )
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        child: ProductGrid(
                          products: _products,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final TextEditingController controller;

  const _Filters({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Search...",
                prefixIcon: Icon(Icons.search),
              ),
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Category",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              items: const [
                DropdownMenuItem(
                  value: "all",
                  child: Text("All"),
                ),
              ],
              onChanged: (_) {},
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Condition",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            CheckboxListTile(
              value: false,
              onChanged: (_) {},
              title: const Text("New"),
            ),

            CheckboxListTile(
              value: false,
              onChanged: (_) {},
              title: const Text("Used"),
            ),

            const SizedBox(height: 20),

            FilledButton(
              onPressed: () {},
              child: const Text("Apply filters"),
            ),
          ],
        ),
      ),
    );
  }
}