import 'package:flutter/material.dart';

import '../../api_service.dart';
import '../../models/listing.dart';
import '../../shared/widgets/product_grid.dart';
import '../../shared/widgets/responsive_container.dart';

class WebExplore extends StatefulWidget {
  final String initialQuery;
  final String initialCategory;

  const WebExplore({
    super.key,
    this.initialQuery = '',
    this.initialCategory = 'all',
  });

  @override
  State<WebExplore> createState() => _WebExploreState();
}

class _WebExploreState extends State<WebExplore> {
  static const _categoryLabels = <String, String>{
    'all': 'Toate categoriile',
    'fashion': 'Fashion',
    'shoes': 'Încălțăminte',
    'electronics': 'Electronice',
    'gaming': 'Gaming',
    'home': 'Casă',
    'beauty': 'Beauty',
    'kids': 'Copii',
    'sports': 'Sport',
    'auto': 'Auto',
    'pets': 'Animale',
    'books': 'Cărți',
  };

  static const _conditionLabels = <String, String>{
    'new': 'Nou',
    'like_new': 'Ca nou',
    'good': 'Bună',
    'fair': 'Acceptabilă',
  };

  late final TextEditingController _searchController;
  bool _loading = true;
  String? _error;
  List<Listing> _products = [];
  String _category = 'all';
  final Set<String> _conditions = {};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _category = _categoryLabels.containsKey(widget.initialCategory)
        ? widget.initialCategory
        : 'all';
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

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
        _error = error is ApiException
            ? error.message
            : 'Produsele nu au putut fi încărcate.';
      });
    }
  }

  List<Listing> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();

    return _products.where((product) {
      final matchesQuery =
          query.isEmpty ||
          product.title.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query) ||
          product.brand?.toLowerCase().contains(query) == true ||
          product.city.toLowerCase().contains(query);
      final matchesCategory =
          _category == 'all' || product.category == _category;
      final matchesCondition =
          _conditions.isEmpty || _conditions.contains(product.condition);
      return matchesQuery && matchesCategory && matchesCondition;
    }).toList();
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _category = 'all';
      _conditions.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveContainer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 280, child: _buildFilters(context)),
                  const SizedBox(width: 30),
                  Expanded(child: _buildProducts(context)),
                ],
              );
            }

            return Column(
              children: [
                _buildFilters(context, compact: true),
                const SizedBox(height: 14),
                Expanded(child: _buildProducts(context)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProducts(BuildContext context) {
    final products = _filteredProducts;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explorează',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${products.length} produse găsite',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Reîncarcă',
              onPressed: _loading ? null : _loadProducts,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _ErrorState(message: _error!, onRetry: _loadProducts)
              : RefreshIndicator(
                  onRefresh: _loadProducts,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 40),
                    child: ProductGrid(products: products),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context, {bool compact = false}) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filtre',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                ),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Resetează'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Caută produse...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(
                labelText: 'Categorie',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _categoryLabels.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 14),
            Text(
              'Starea produsului',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: _conditionLabels.entries.map((entry) {
                return FilterChip(
                  label: Text(entry.value),
                  selected: _conditions.contains(entry.key),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _conditions.add(entry.key);
                      } else {
                        _conditions.remove(entry.key);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            if (compact) const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 46),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reîncearcă'),
          ),
        ],
      ),
    );
  }
}
