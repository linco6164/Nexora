import 'package:flutter/material.dart';

import '../../api_service.dart';
import '../../catalog/category_catalog.dart';
import '../../l10n/app_locale.dart';
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
  String _subcategory = 'all';
  String _categoryDetail = 'all';
  final Set<String> _conditions = {};
  bool _compactFiltersExpanded = false;

  int get _activeFilterCount {
    var count = _conditions.length;
    if (_searchController.text.trim().isNotEmpty) count++;
    if (_category != 'all') count++;
    if (_subcategory != 'all') count++;
    if (_categoryDetail != 'all') count++;
    return count;
  }

  CategoryNode? get _selectedCategory {
    if (_category == 'all') return null;
    for (final category in listingCategoryCatalog) {
      if (category.slug == _category) return category;
    }
    return null;
  }

  CategoryNode? get _selectedSubcategory {
    if (_subcategory == 'all') return null;
    for (final subcategory
        in _selectedCategory?.children ?? const <CategoryNode>[]) {
      if (subcategory.slug == _subcategory) return subcategory;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _category =
        listingCategoryCatalog.any(
          (category) => category.slug == widget.initialCategory,
        )
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
            : appLocaleController.value == 'en'
            ? 'Products could not be loaded.'
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
      final matchesSubcategory =
          _subcategory == 'all' || product.subcategory == _subcategory;
      final matchesCategoryDetail =
          _categoryDetail == 'all' || product.categoryDetail == _categoryDetail;
      final matchesCondition =
          _conditions.isEmpty || _conditions.contains(product.condition);
      return matchesQuery &&
          matchesCategory &&
          matchesSubcategory &&
          matchesCategoryDetail &&
          matchesCondition;
    }).toList();
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _category = 'all';
      _subcategory = 'all';
      _categoryDetail = 'all';
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
                  SizedBox(width: 218, child: _buildFilters(context)),
                  const SizedBox(width: 18),
                  Expanded(child: _buildProducts(context)),
                ],
              );
            }

            return Column(
              children: [
                _buildFilters(context, compact: true),
                const SizedBox(height: 12),
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
                    appLocaleController.value == 'en'
                        ? 'Explore'
                        : 'Explorează',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appLocaleController.value == 'en'
                        ? '${products.length} products found'
                        : '${products.length} produse găsite',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: context.tr('Reîncarcă'),
              onPressed: _loading ? null : _loadProducts,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
    final colors = theme.colorScheme;
    final activeFilters = _activeFilterCount;

    InputDecoration fieldDecoration({
      String? labelText,
      String? hintText,
      required IconData icon,
      Widget? suffixIcon,
    }) {
      final border = OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.outlineVariant),
      );

      return InputDecoration(
        labelText: labelText,
        hintText: hintText,
        isDense: true,
        filled: true,
        fillColor: colors.surface,
        prefixIcon: Icon(icon, size: 18),
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: border,
        enabledBorder: border,
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 17,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      context.tr('Filtre'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (activeFilters > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$activeFilters',
                        style: TextStyle(
                          color: colors.onPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  if (compact)
                    IconButton(
                      tooltip: _compactFiltersExpanded
                          ? context.tr('Închide')
                          : context.tr('Filtre'),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(
                        () =>
                            _compactFiltersExpanded = !_compactFiltersExpanded,
                      ),
                      icon: AnimatedRotation(
                        turns: _compactFiltersExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                    )
                  else
                    TextButton(
                      onPressed: activeFilters == 0 ? null : _resetFilters,
                      child: Text(context.tr('Resetează')),
                    ),
                ],
              ),
              if (!compact || _compactFiltersExpanded) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: fieldDecoration(
                    hintText: context.tr('Caută produse...'),
                    icon: Icons.search_rounded,
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey('category-$_category'),
                  initialValue: _category,
                  isExpanded: true,
                  decoration: fieldDecoration(
                    labelText: context.tr('Categorie'),
                    icon: Icons.grid_view_rounded,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text(context.tr('Toate categoriile')),
                    ),
                    ...listingCategoryCatalog.map(
                      (category) => DropdownMenuItem(
                        value: category.slug,
                        child: Text(category.label(appLocaleController.value)),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _category = value;
                        _subcategory = 'all';
                        _categoryDetail = 'all';
                      });
                    }
                  },
                ),
                if (_selectedCategory != null) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    key: ValueKey('subcategory-$_category-$_subcategory'),
                    initialValue: _subcategory,
                    isExpanded: true,
                    decoration: fieldDecoration(
                      labelText: context.tr('Subcategorie'),
                      icon: Icons.account_tree_outlined,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text(context.tr('Toate')),
                      ),
                      ..._selectedCategory!.children.map(
                        (subcategory) => DropdownMenuItem(
                          value: subcategory.slug,
                          child: Text(
                            subcategory.label(appLocaleController.value),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _subcategory = value;
                          _categoryDetail = 'all';
                        });
                      }
                    },
                  ),
                ],
                if (_selectedSubcategory?.children.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    key: ValueKey(
                      'category-detail-$_subcategory-$_categoryDetail',
                    ),
                    initialValue: _categoryDetail,
                    isExpanded: true,
                    decoration: fieldDecoration(
                      labelText: context.tr('Tip produs'),
                      icon: Icons.category_outlined,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text(context.tr('Toate')),
                      ),
                      ..._selectedSubcategory!.children.map(
                        (detail) => DropdownMenuItem(
                          value: detail.slug,
                          child: Text(
                            detail.label(appLocaleController.value),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _categoryDetail = value);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  context.tr('Starea produsului'),
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
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      label: Text(context.tr(entry.value)),
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
                if (compact && activeFilters > 0) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.restart_alt_rounded, size: 17),
                      label: Text(context.tr('Resetează')),
                    ),
                  ),
                ],
              ],
            ],
          ),
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
            label: Text(context.tr('Reîncearcă')),
          ),
        ],
      ),
    );
  }
}
