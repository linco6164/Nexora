import 'package:flutter/material.dart';

import 'api_service.dart';
import 'models/listing.dart';
import 'listing_detail_page.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  final List<Map<String, String>> categories = [
    {
      'id': 'fashion',
      'name': 'Fashion',
      'icon': '👗',
    },
    {
      'id': 'shoes',
      'name': 'Încălțăminte',
      'icon': '👟',
    },
    {
      'id': 'electronics',
      'name': 'Electronice',
      'icon': '📱',
    },
    {
      'id': 'gaming',
      'name': 'Gaming',
      'icon': '🎮',
    },
    {
      'id': 'home',
      'name': 'Casă',
      'icon': '🏠',
    },
    {
      'id': 'beauty',
      'name': 'Beauty',
      'icon': '💄',
    },
    {
      'id': 'kids',
      'name': 'Copii',
      'icon': '🧸',
    },
    {
      'id': 'sports',
      'name': 'Sport',
      'icon': '⚽',
    },
  ];

  void _openCategory(
    String categoryId,
    String categoryName,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryListingsPage(
          category: categoryId,
          categoryName: categoryName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'Explorează',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Text(
              'Descoperă produse din categoriile preferate.',
              style: TextStyle(
                fontSize: 15,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final category = categories[index];

                return _CategoryCard(
                  name: category['name']!,
                  icon: category['icon']!,
                  onTap: () {
                    _openCategory(
                      category['id']!,
                      category['name']!,
                    );
                  },
                );
              },
              childCount: categories.length,
            ),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 110),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final String icon;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.name,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: const TextStyle(
                      fontSize: 27,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
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
  final String category;
  final String categoryName;

  const CategoryListingsPage({
    super.key,
    required this.category,
    required this.categoryName,
  });

  @override
  State<CategoryListingsPage> createState() =>
      _CategoryListingsPageState();
}

class _CategoryListingsPageState
    extends State<CategoryListingsPage> {
  late Future<List<Listing>> _listingsFuture;

  @override
  void initState() {
    super.initState();

    _listingsFuture =
        ApiService.getListingsByCategory(widget.category);
  }

  Future<void> _refresh() async {
    setState(() {
      _listingsFuture =
          ApiService.getListingsByCategory(widget.category);
    });

    await _listingsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Listing>>(
          future: _listingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Eroare: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _refresh,
                        child: const Text(
                          'Reîncearcă',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final listings = snapshot.data ?? [];

            if (listings.isEmpty) {
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
                        'Nu există anunțuri în această categorie.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return GridView.builder(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                12,
                12,
                12,
                24,
              ),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
              itemCount: listings.length,
              itemBuilder: (context, index) {
                return _ListingCard(
                  listing: listings[index],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final Listing listing;

  const _ListingCard({
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ListingDetailPage(
                listingId: listing.id,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              child: listing.images.isNotEmpty
                  ? Image.network(
                      listing.images.first,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) {
                        return Container(
                          color:
                              colors.surfaceContainerHighest,
                          child: const Icon(
                            Icons
                                .image_not_supported_outlined,
                          ),
                        );
                      },
                    )
                  : Container(
                      color:
                          colors.surfaceContainerHighest,
                      child: const Icon(
                        Icons.image_outlined,
                        size: 40,
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
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
                        color:
                            colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          listing.city,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                colors.onSurfaceVariant,
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