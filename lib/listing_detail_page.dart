import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import 'api_service.dart';
import 'models/listing.dart';
import 'chat_page.dart';
import 'public_profile_page.dart';

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
  bool _isPaying = false;

  @override
  void initState() {
    super.initState();

    _listingFuture = ApiService.getListingById(widget.listingId);

    _listingFuture
        .then((listing) {
          if (!mounted) return;

          setState(() {
            _currentListing = listing;
          });
        })
        .catchError((_) {});

    _loadFavoriteStatus();
  }

  // ============================================================
  // FAVORITE
  // ============================================================

  Future<void> _loadFavoriteStatus() async {
    // Pagini de produs sunt publice.
    // Nu apelăm endpoint-ul de favorite dacă utilizatorul
    // nu este autentificat.

    final token = await ApiService.getToken();

    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() => _isFavorite = false);
      }
      return;
    }

    try {
      final isFav = await ApiService.checkFavorite(widget.listingId);

      if (mounted) {
        setState(() => _isFavorite = isFav);
      }
    } catch (_) {
      // Dacă verificarea favoritului eșuează,
      // produsul rămâne accesibil.
      if (mounted) {
        setState(() => _isFavorite = false);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final previousValue = _isFavorite;

    setState(() {
      _isFavorite = !_isFavorite;
    });

    try {
      final result = await ApiService.toggleFavorite(widget.listingId);

      if (!mounted) return;

      setState(() {
        _isFavorite = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isFavorite = previousValue;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Eroare: ${e.toString()}')));
    }
  }

  // ============================================================
  // CONTACT SELLER
  // ============================================================

  Future<void> _handleContactSeller() async {
    final listing = _currentListing;

    if (listing == null) return;

    try {
      final conversation = await ApiService.startConversation(listing.id);

      if (!mounted) return;

      final me = await ApiService.getCurrentUser();

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
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Eroare: ${e.toString()}')));
    }
  }

  // ============================================================
  // PAYMENT
  // ============================================================

  Future<void> _handleCardPayment() async {
    final listing = _currentListing;

    if (listing == null || _isPaying) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Plată cu cardul'),
          content: Text(
            'Vrei să continui plata pentru '
            '${listing.price.toStringAsFixed(2)} '
            '${listing.currency}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Anulează'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Continuă'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isPaying = true;
    });

    try {
      final payment = await ApiService.createNetopiaPayment(listing.id);

      final paymentId = payment['paymentId']?.toString();

      if (paymentId == null || paymentId.isEmpty) {
        throw ApiException('Serverul nu a returnat ID-ul plății.');
      }

      final checkoutUrl =
          'https://api.nx-store.com/payments/'
          'netopia/checkout/$paymentId';

      final uri = Uri.parse(checkoutUrl);

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw ApiException('Nu am putut deschide pagina de plată.');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('ApiException: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPaying = false;
        });
      }
    }
  }

  // ============================================================
  // SELLER PROFILE
  // ============================================================

  void _openSellerProfile() {
    final seller = _currentListing?.seller;

    if (seller == null || seller.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profilul vânzătorului nu este disponibil.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PublicProfilePage(userId: seller.id)),
    );
  }

  // ============================================================
  // SHARE
  // ============================================================

  Future<void> _shareListing() async {
    final listing = _currentListing;

    if (listing == null) {
      return;
    }

    final url = Uri.parse('https://nx-store.com/product/${listing.id}');

    final text =
        '''
${listing.title}

${listing.price.toStringAsFixed(2)} ${listing.currency}

Vezi produsul pe Nexora Store:
$url
''';

    await SharePlus.instance.share(
      ShareParams(uri:url, subject: listing.title),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,

      body: FutureBuilder<Listing>(
        future: _listingFuture,

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Eroare la încărcarea produsului',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}', textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          final listing = snapshot.data;

          if (listing == null) {
            return const Center(child: Text('Produsul nu a fost găsit.'));
          }

          return Stack(
            children: [
              // ======================================================
              // CONTENT
              // ======================================================

              CustomScrollView(
                physics: const BouncingScrollPhysics(),

                slivers: [
                  // ==================================================
                  // PRODUCT IMAGE
                  // ==================================================

                  SliverAppBar(
                    expandedHeight: 360,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: colorScheme.surface,

                    leading: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _CircleButton(
                        icon: Icons.arrow_back,
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),

                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _CircleButton(
                          icon: _isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          iconColor: _isFavorite ? Colors.red : null,
                          onTap: _toggleFavorite,
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _CircleButton(
                          icon: Icons.share_outlined,
                          onTap: _shareListing,
                        ),
                      ),
                    ],

                    flexibleSpace: FlexibleSpaceBar(
                      background: _ProductImageGallery(
                        listing: listing,
                        controller: _imageController,
                        currentImage: _currentImage,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImage = index;
                          });
                        },
                      ),
                    ),
                  ),

                  // ==================================================
                  // PRODUCT INFORMATION
                  // ==================================================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 140),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // PRICE
                          Text(
                            '${listing.price.toStringAsFixed(0)} '
                            '${listing.currency}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          if (listing.negotiable) ...[
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(
                                  Icons.swap_horiz_rounded,
                                  size: 17,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Preț negociabil',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 12),

                          // TITLE
                          Text(
                            listing.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // INFO CHIPS
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

                              if (listing.brand != null &&
                                  listing.brand!.trim().isNotEmpty)
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

                          const SizedBox(height: 24),

                          const Divider(),

                          const SizedBox(height: 24),

                          // ==================================================
                          // SELLER
                          // ==================================================
                          if (listing.seller != null) ...[
                            Text(
                              'VÂNZĂTOR',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.grey,
                                letterSpacing: 0.8,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 27,
                                    backgroundColor:
                                        colorScheme.primaryContainer,
                                    backgroundImage:
                                        listing.seller!.avatar != null
                                        ? NetworkImage(listing.seller!.avatar!)
                                        : null,
                                    child: listing.seller!.avatar == null
                                        ? Text(
                                            listing.seller!.username[0]
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          )
                                        : null,
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                listing.seller!.username,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),

                                            if (listing.seller!.verified) ...[
                                              const SizedBox(width: 5),
                                              const Icon(
                                                Icons.verified,
                                                size: 17,
                                                color: Colors.blue,
                                              ),
                                            ],
                                          ],
                                        ),

                                        if (listing.seller!.rating > 0) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.star_rounded,
                                                size: 16,
                                                color: Colors.amber,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                listing.seller!.rating
                                                    .toStringAsFixed(1),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  OutlinedButton(
                                    onPressed: _openSellerProfile,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 9,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text('Vezi profil'),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 28),
                          ],

                          // ==================================================
                          // DESCRIPTION
                          // ==================================================
                          const Text(
                            'DESCRIERE',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.grey,
                              fontSize: 12,
                              letterSpacing: 0.8,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            listing.description,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.55,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ==================================================
                          // STATS
                          // ==================================================
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _ListingStat(
                                    icon: Icons.visibility_outlined,
                                    value: '${listing.views}',
                                    label: 'vizualizări',
                                  ),
                                ),

                                Container(
                                  width: 1,
                                  height: 32,
                                  color: Colors.grey.withValues(alpha: 0.25),
                                ),

                                Expanded(
                                  child: _ListingStat(
                                    icon: Icons.favorite_border,
                                    value: '${listing.favorites}',
                                    label: 'favorite',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ==========================================================
              // BOTTOM ACTION BAR
              // ==========================================================
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // CONTACT
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _currentListing == null || _isPaying
                                ? null
                                : _handleContactSeller,
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Contactează'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // BUY
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: _isPaying ? null : _handleCardPayment,
                            icon: _isPaying
                                ? const SizedBox(
                                    width: 19,
                                    height: 19,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.shopping_bag_outlined),
                            label: Text(
                              _isPaying ? 'Se deschide...' : 'Cumpără acum',
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ========================================================================
// PRODUCT IMAGE GALLERY
// ========================================================================

class _ProductImageGallery extends StatelessWidget {
  final Listing listing;
  final PageController controller;
  final int currentImage;
  final ValueChanged<int> onPageChanged;

  const _ProductImageGallery({
    required this.listing,
    required this.controller,
    required this.currentImage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (listing.images.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image_outlined, size: 64, color: Colors.grey),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: controller,
          itemCount: listing.images.length,
          onPageChanged: onPageChanged,
          itemBuilder: (context, index) {
            return Image.network(
              listing.images[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.image_not_supported_outlined, size: 48),
                  ),
                );
              },
            );
          },
        ),

        // Gradient jos
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 100,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Dots
        if (listing.images.length > 1)
          Positioned(
            bottom: 18,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(listing.images.length, (index) {
                final active = index == currentImage;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: active ? 1 : 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

// ========================================================================
// CIRCLE BUTTON
// ========================================================================

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.black.withValues(alpha: 0.38),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: iconColor ?? Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ========================================================================
// INFO CHIP
// ========================================================================

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================================================
// LISTING STAT
// ========================================================================

class _ListingStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _ListingStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 19, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }
}
