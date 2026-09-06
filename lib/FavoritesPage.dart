import 'package:flutter/material.dart';
import 'api_service.dart';
import 'models/listing.dart';
import 'ListingDetailPage.dart';

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
      appBar: AppBar(title: const Text('Favorite')),
      body: RefreshIndicator(
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
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Center(child: Text('Niciun anunț favorit încă')),
                ],
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ListingDetailPage(listingId: listing.id),
                        ),
                      ).then((_) => _refresh());
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: listing.images.isNotEmpty
                              ? Image.network(listing.images.first, width: double.infinity, fit: BoxFit.cover)
                              : Container(color: Colors.grey[200], child: const Icon(Icons.image_outlined)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('${listing.price.toStringAsFixed(0)} ${listing.currency}',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
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
    );
  }
}