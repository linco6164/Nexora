import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'notifications_page.dart';
import 'shared/widgets/activity_badge.dart';
import 'models/listing.dart';
import 'listing_detail_page.dart';
import 'web/web_product_page.dart';
import 'shared/widgets/product_grid.dart';
import 'shared/widgets/responsive_container.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<Listing>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _favoritesFuture = ApiService.getFavorites();
  }

  Future<void> _refresh() async {
    setState(() {
      _favoritesFuture = ApiService.getFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb ? null : AppBar(title: const Text('Favorite')),
      body: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextButton.icon(
                icon: const ActivityBadge(
                  kind: ActivityKind.favorites,
                  child: Icon(Icons.favorite_border_rounded),
                ),
                label: const Text('Activitate favorite'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsPage(type: 'favorite'),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<Listing>>(
                future: _favoritesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Eroare: ${snapshot.error}'));
                  }

                  final favorites = snapshot.data ?? [];

                  if (favorites.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        Icon(
                          Icons.favorite_border,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Center(child: Text('Niciun anunț favorit încă')),
                      ],
                    );
                  }

                  if (kIsWeb) {
                    final theme = Theme.of(context);
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: ResponsiveContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Favorite',
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${favorites.length} produse salvate',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: _refresh,
                                  tooltip: 'Reîncarcă',
                                  icon: const Icon(Icons.refresh_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ProductGrid(
                              products: favorites,
                              productsAreFavorites: true,
                              onFavoriteRemoved: (_) => _refresh(),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.68,
                        ),
                    itemCount: favorites.length,
                    itemBuilder: (context, index) {
                      final listing = favorites[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => kIsWeb
                                    ? WebProductPage(productId: listing.id)
                                    : ListingDetailPage(listingId: listing.id),
                              ),
                            ).then((_) => _refresh());
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
                                      )
                                    : Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image_outlined),
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
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
