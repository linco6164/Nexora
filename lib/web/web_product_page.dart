import 'package:flutter/material.dart';

import '../catalog/category_catalog.dart';
import '../l10n/app_locale.dart';
import '../api_service.dart';
import '../models/listing.dart';
import '../public_profile_page.dart';
import 'widgets/product/product_gallery.dart';
import 'widgets/product/product_info.dart';
import 'widgets/product/product_description.dart';
import 'widgets/product/product_specifications.dart';
import 'widgets/product/seller_card.dart';
import 'widgets/product/shipping_card.dart';
import 'widgets/header/web_language_selector.dart';
import 'widgets/product/related_products.dart';
import 'widgets/product/product_breadcrumb.dart';
import 'widgets/web_explore.dart';

class WebProductPage extends StatefulWidget {
  final String productId;

  const WebProductPage({super.key, required this.productId});

  @override
  State<WebProductPage> createState() => _WebProductPageState();
}

class _WebProductPageState extends State<WebProductPage> {
  Listing? listing;

  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadListing();
  }

  Future<void> _loadListing() async {
    try {
      final result = await ApiService.getListingById(widget.productId);

      if (!mounted) return;

      setState(() {
        listing = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  void _openSellerProfile() {
    final seller = listing?.seller;
    if (seller == null || seller.id.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PublicProfilePage(userId: seller.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Produs')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 52),
                const SizedBox(height: 12),
                Text(error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      loading = true;
                      error = null;
                    });
                    _loadListing();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.tr('Reîncearcă')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final product = listing!;
    final compact = MediaQuery.sizeOf(context).width < 720;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 58,
        titleSpacing: 4,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 10),
              const Text(
                'Nexora',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ],
          ],
        ),
        actions: [
          WebLanguageSelector(compact: compact),
          SizedBox(width: compact ? 2 : 8),
          IconButton(
            onPressed: () =>
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/', (route) => false),
            tooltip: appLocaleController.value == 'en'
                ? 'Home page'
                : 'Pagina principală',
            icon: const Icon(Icons.home_outlined),
          ),
          SizedBox(width: compact ? 6 : 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          compact ? 16 : 24,
          22,
          compact ? 16 : 24,
          48,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductBreadcrumb(
                  category:
                      findCategoryBySlug(product.category)
                          ?.label(appLocaleController.value) ??
                      product.category,
                  title: product.title,
                  onHome: () {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  onCategory: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            WebExplore(initialCategory: product.category),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 14),

                Container(
                  padding: EdgeInsets.all(compact ? 12 : 22),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: .045),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final gallery = ProductGallery(images: product.images);
                      final info = ProductInfo(listing: product);

                      if (constraints.maxWidth < 780) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [gallery, const SizedBox(height: 24), info],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: gallery),
                          const SizedBox(width: 30),
                          Expanded(flex: 5, child: info),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final primaryDetails = Column(
                      children: [
                        ProductDescription(description: product.description),
                        const SizedBox(height: 18),
                        ProductSpecifications(listing: product),
                      ],
                    );
                    final secondaryDetails = Column(
                      children: [
                        const ShippingCard(),
                        const SizedBox(height: 18),
                        SellerCard(
                          sellerName:
                              product.seller?.username ?? "Utilizator Nexora",
                          avatar: product.seller?.avatar,
                          verified: product.seller?.verified ?? false,
                          listingsCount: null,
                          memberSince: null,
                          onProfile: product.seller == null
                              ? null
                              : _openSellerProfile,
                        ),
                      ],
                    );

                    if (constraints.maxWidth < 820) {
                      return Column(
                        children: [
                          primaryDetails,
                          const SizedBox(height: 18),
                          secondaryDetails,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: primaryDetails),
                        const SizedBox(width: 18),
                        Expanded(flex: 5, child: secondaryDetails),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 42),

                RelatedProducts(currentListingId: product.id),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
