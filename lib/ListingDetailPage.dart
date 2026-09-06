import 'package:flutter/material.dart';

import 'api_service.dart';
import 'models/listing.dart';
import 'ChatPage.dart';

class ListingDetailPage extends StatefulWidget {
  final String listingId;

  const ListingDetailPage({super.key, required this.listingId});

  @override
  State<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage> {
  late Future<Listing> _listingFuture;
  final PageController _imageController = PageController();
  int _currentImage = 0;
  Listing? _currentListing;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _listingFuture = ApiService.getListingById(widget.listingId);
    _listingFuture.then((listing) {
      if (mounted) {
        setState(() => _currentListing = listing);
      }
    }).catchError((_) {});

    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final isFav = await ApiService.checkFavorite(widget.listingId);
      if (mounted) setState(() => _isFavorite = isFav);
    } catch (_) {
      // silențios — dacă eșuează, rămâne pe false
    }
  }

  Future<void> _toggleFavorite() async {
    // optimistic update
    setState(() => _isFavorite = !_isFavorite);

    try {
      final result = await ApiService.toggleFavorite(widget.listingId);
      if (mounted) setState(() => _isFavorite = result);
    } catch (e) {
      // revenim la starea anterioară dacă eșuează
      if (mounted) setState(() => _isFavorite = !_isFavorite);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _handleContactSeller() async {
    final listing = _currentListing;
    if (listing == null) {
      print('🔴 _currentListing e null, ies din funcție');
      return;
    }

    print('🟢 Încep contactarea vânzătorului pentru listing: ${listing.id}');

    try {
      final conversation = await ApiService.startConversation(listing.id);
      print('🔵 Conversație creată: ${conversation.id}');

      if (!mounted) {
        print('🟠 Widget nu mai e mounted, ies');
        return;
      }

      final me = await ApiService.getCurrentUser();
      print('🟡 User curent obținut: ${me['_id']}');

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            conversationId: conversation.id,
            otherUsername: listing.seller?.username ?? 'Vânzător',
            myUserId: me['_id'],
          ),
        ),
      );
      print('✅ Navigare efectuată');
    } catch (e, stackTrace) {
      print('🔴🔴 EROARE: $e');
      print('Stack trace: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Eroare: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Listing>(
        future: _listingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Eroare: ${snapshot.error}'));
          }

          final listing = snapshot.data!;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: listing.images.isNotEmpty
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            PageView.builder(
                              controller: _imageController,
                              onPageChanged: (i) =>
                                  setState(() => _currentImage = i),
                              itemCount: listing.images.length,
                              itemBuilder: (context, index) => Image.network(
                                listing.images[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 48,
                                      ),
                                    ),
                              ),
                            ),
                            if (listing.images.length > 1)
                              Positioned(
                                bottom: 12,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    listing.images.length,
                                    (index) {
                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                        ),
                                        width: index == _currentImage ? 18 : 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(
                                            index == _currentImage ? 1 : 0.5,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_outlined, size: 64),
                        ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.favorite_border,
                      color: Colors.white,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white),
                    onPressed: () {
                      // TODO: share listing
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${listing.price.toStringAsFixed(0)} ${listing.currency}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (listing.negotiable) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Preț negociabil',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        listing.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            icon: Icons.location_on_outlined,
                            label: listing.city,
                          ),
                          _InfoChip(
                            icon: Icons.sell_outlined,
                            label: listing.conditionLabel,
                          ),
                          if (listing.brand != null)
                            _InfoChip(
                              icon: Icons.local_offer_outlined,
                              label: listing.brand!,
                            ),
                          if (listing.shipping)
                            const _InfoChip(
                              icon: Icons.local_shipping_outlined,
                              label: 'Livrare disponibilă',
                            ),
                        ],
                      ),
                      const Divider(height: 32),

                      // Info vânzător
                      if (listing.seller != null) ...[
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: listing.seller!.avatar != null
                                  ? NetworkImage(listing.seller!.avatar!)
                                  : null,
                              child: listing.seller!.avatar == null
                                  ? Text(
                                      listing.seller!.username[0].toUpperCase(),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        listing.seller!.username,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (listing.seller!.verified) ...[
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.verified,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (listing.seller!.rating > 0)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 14,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          listing.seller!.rating
                                              .toStringAsFixed(1),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                // TODO: navigare spre profil public vânzător
                              },
                              child: const Text('Vezi profil'),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                      ],

                      const Text(
                        'Descriere',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        listing.description,
                        style: TextStyle(color: Colors.grey[800], height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${listing.views} vizualizări',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${listing.favorites} favorite',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 100,
                      ), // spațiu pentru butonul fix de jos
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _currentListing == null ? null : _handleContactSeller,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Contactează vânzătorul'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
