import 'package:flutter/material.dart';

import 'api_service.dart';
import 'catalog/category_catalog.dart';
import 'l10n/app_locale.dart';
import 'listing_detail_page.dart';
import 'models/listing.dart';

class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  void _openCategory(
    BuildContext context,
    CategoryNode category, {
    String initialSubcategory = 'all',
    String initialDetail = 'all',
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryListingsPage(
          categoryNode: category,
          initialSubcategory: initialSubcategory,
          initialDetail: initialDetail,
        ),
      ),
    );
  }

  void _showCategoryMenu(BuildContext context, CategoryNode category) {
    final language = appLocaleController.value;
    final isEnglish = language == 'en';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).colorScheme;

        void openCategory({String subcategory = 'all', String detail = 'all'}) {
          Navigator.pop(sheetContext);
          _openCategory(
            context,
            category,
            initialSubcategory: subcategory,
            initialDetail: detail,
          );
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.48,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return Material(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                      child: Column(
                        children: [
                          Container(
                            width: 38,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colors.outlineVariant,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: category.color.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  category.icon,
                                  color: category.color,
                                  size: 25,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.label(language),
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      isEnglish
                                          ? 'Choose a subcategory or product type'
                                          : 'Alege subcategoria sau tipul produsului',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: isEnglish ? 'Close' : 'Închide',
                                onPressed: () => Navigator.pop(sheetContext),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed: openCategory,
                              icon: const Icon(
                                Icons.grid_view_rounded,
                                size: 18,
                              ),
                              label: Text(
                                isEnglish
                                    ? 'View all products'
                                    : 'Vezi toate produsele',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                    sliver: SliverList.separated(
                      itemCount: category.children.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final subcategory = category.children[index];

                        return Container(
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: colors.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () =>
                                    openCategory(subcategory: subcategory.slug),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    11,
                                    10,
                                    9,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          subcategory.label(language),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${subcategory.children.length} ${isEnglish ? 'types' : 'tipuri'}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colors.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 17,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (subcategory.children.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    10,
                                    0,
                                    10,
                                    10,
                                  ),
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: subcategory.children.map((
                                      detail,
                                    ) {
                                      return ActionChip(
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        side: BorderSide.none,
                                        backgroundColor: colors.surface,
                                        labelStyle: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        label: Text(detail.label(language)),
                                        onPressed: () => openCategory(
                                          subcategory: subcategory.slug,
                                          detail: detail.slug,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final language = appLocaleController.value;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    language == 'en' ? 'Explore' : 'Explorează',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${listingCategoryCatalog.length} ${language == 'en' ? 'categories' : 'categorii'}',
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 2, 18, 14),
            child: Text(
              language == 'en'
                  ? 'Find what you need, from category to product type.'
                  : 'Găsește rapid ce cauți, de la categorie la tipul produsului.',
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.32,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final category = listingCategoryCatalog[index];
              return _CategoryCard(
                category: category,
                language: language,
                onTap: () => _showCategoryMenu(context, category),
              );
            }, childCount: listingCategoryCatalog.length),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 110)),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryNode category;
  final String language;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.language,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final preview = category.children
        .take(2)
        .map((subcategory) => subcategory.label(language))
        .join(' · ');

    return Material(
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(category.icon, color: category.color, size: 21),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.north_east_rounded,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                category.label(language),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${category.children.length} ${language == 'en' ? 'subcategories' : 'subcategorii'}',
                style: TextStyle(
                  color: category.color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryListingsPage extends StatefulWidget {
  final CategoryNode categoryNode;
  final String initialSubcategory;
  final String initialDetail;

  const CategoryListingsPage({
    super.key,
    required this.categoryNode,
    this.initialSubcategory = 'all',
    this.initialDetail = 'all',
  });

  @override
  State<CategoryListingsPage> createState() => _CategoryListingsPageState();
}

class _CategoryListingsPageState extends State<CategoryListingsPage> {
  late Future<List<Listing>> _listingsFuture;
  String _subcategory = 'all';
  String _categoryDetail = 'all';

  @override
  void initState() {
    super.initState();
    CategoryNode? selectedSubcategory;
    for (final node in widget.categoryNode.children) {
      if (node.slug == widget.initialSubcategory) {
        selectedSubcategory = node;
        break;
      }
    }
    _subcategory = selectedSubcategory?.slug ?? 'all';
    _categoryDetail =
        selectedSubcategory?.children.any(
              (node) => node.slug == widget.initialDetail,
            ) ==
            true
        ? widget.initialDetail
        : 'all';
    _listingsFuture = ApiService.getListingsByCategory(
      widget.categoryNode.slug,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _listingsFuture = ApiService.getListingsByCategory(
        widget.categoryNode.slug,
      );
    });
    await _listingsFuture;
  }

  List<Listing> _filterListings(List<Listing> listings) {
    return listings.where((listing) {
      final matchesSubcategory =
          _subcategory == 'all' || listing.subcategory == _subcategory;
      final matchesDetail =
          _categoryDetail == 'all' || listing.categoryDetail == _categoryDetail;
      return matchesSubcategory && matchesDetail;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final language = appLocaleController.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryNode.label(language),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Listing>>(
          future: _listingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _CategoryErrorState(
                message: 'Eroare: ${snapshot.error}',
                onRetry: _refresh,
              );
            }

            final listings = _filterListings(snapshot.data ?? const []);

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _CategoryFilters(
                    category: widget.categoryNode,
                    selectedSubcategory: _subcategory,
                    selectedDetail: _categoryDetail,
                    language: language,
                    productCount: listings.length,
                    onSubcategoryChanged: (value) {
                      setState(() {
                        _subcategory = value;
                        _categoryDetail = 'all';
                      });
                    },
                    onDetailChanged: (value) {
                      setState(() => _categoryDetail = value);
                    },
                  ),
                ),
                if (listings.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyCategoryState(filtered: _subcategory != 'all'),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.68,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _ListingCard(listing: listings[index]),
                        childCount: listings.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  final CategoryNode category;
  final String selectedSubcategory;
  final String selectedDetail;
  final String language;
  final int productCount;
  final ValueChanged<String> onSubcategoryChanged;
  final ValueChanged<String> onDetailChanged;

  const _CategoryFilters({
    required this.category,
    required this.selectedSubcategory,
    required this.selectedDetail,
    required this.language,
    required this.productCount,
    required this.onSubcategoryChanged,
    required this.onDetailChanged,
  });

  CategoryNode? get selectedNode {
    for (final node in category.children) {
      if (node.slug == selectedSubcategory) return node;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = selectedNode?.children ?? const <CategoryNode>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Subcategorii',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '$productCount produse',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Toate'),
                    selected: selectedSubcategory == 'all',
                    onSelected: (_) => onSubcategoryChanged('all'),
                  ),
                ),
                ...category.children.map(
                  (node) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(node.label(language)),
                      selected: selectedSubcategory == node.slug,
                      onSelected: (_) => onSubcategoryChanged(node.slug),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Tip produs',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Toate'),
                      selected: selectedDetail == 'all',
                      onSelected: (_) => onDetailChanged('all'),
                    ),
                  ),
                  ...details.map(
                    (node) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(node.label(language)),
                        selected: selectedDetail == node.slug,
                        onSelected: (_) => onDetailChanged(node.slug),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyCategoryState extends StatelessWidget {
  final bool filtered;

  const _EmptyCategoryState({required this.filtered});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 60,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              filtered
                  ? 'Nu există anunțuri în subcategoria selectată.'
                  : 'Nu există anunțuri în această categorie.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _CategoryErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Center(
          child: FilledButton(
            onPressed: onRetry,
            child: const Text('Reîncearcă'),
          ),
        ),
      ],
    );
  }
}

class _ListingCard extends StatelessWidget {
  final Listing listing;

  const _ListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ListingDetailPage(listingId: listing.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: listing.images.isNotEmpty
                  ? Image.network(
                      listing.images.first,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: colors.surfaceContainerHighest,
                        child: const Center(
                          child: Icon(Icons.image_not_supported_outlined),
                        ),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      color: colors.surfaceContainerHighest,
                      child: const Icon(Icons.image_outlined, size: 40),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${listing.price.toStringAsFixed(0)} ${listing.currency}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          listing.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
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
