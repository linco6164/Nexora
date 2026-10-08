import 'package:flutter/material.dart';

import '../api_service.dart';
import '../chat_page.dart';
import '../models/listing.dart';
import '../public_profile_page.dart';
import 'widgets/product/product_gallery.dart';
import 'widgets/product/product_info.dart';
import 'widgets/product/product_description.dart';
import 'widgets/product/product_specifications.dart';
import 'widgets/product/seller_card.dart';
import 'widgets/product/shipping_card.dart';
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
  bool _openingChat = false;

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

  Future<void> _openChat() async {
    final product = listing;
    if (product == null || _openingChat) return;

    setState(() => _openingChat = true);
    try {
      final me = await ApiService.getCurrentUser();
      final myUserId = me['_id']?.toString() ?? '';
      final conversation = await ApiService.startConversation(product.id);
      final other = conversation.otherParticipant(myUserId);

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatPage(
            conversationId: conversation.id,
            otherUsername:
                other?.username ?? product.seller?.username ?? 'Vânzător',
            myUserId: myUserId,
          ),
        ),
      );
    } catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            exception is ApiException
                ? exception.message
                : 'Conversația nu a putut fi deschisă.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _openingChat = false);
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
                  label: const Text('Reîncearcă'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final product = listing!;

    return Scaffold(
      appBar: AppBar(title: Text(product.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductBreadcrumb(
                  category: product.category,
                  title: product.title,
                  onHome: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
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

                const SizedBox(height: 24),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final gallery = ProductGallery(images: product.images);
                    final info = ProductInfo(listing: product);

                    if (constraints.maxWidth < 900) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [gallery, const SizedBox(height: 24), info],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: gallery),
                        const SizedBox(width: 40),
                        Expanded(flex: 5, child: info),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 40),

                ProductDescription(description: product.description),

                const SizedBox(height: 30),

                ProductSpecifications(listing: product),

                const SizedBox(height: 30),

                const ShippingCard(),

                const SizedBox(height: 30),

                SellerCard(
                  sellerName: product.seller?.username ?? "Nexora User",
                  avatar: product.seller?.avatar,
                  verified: product.seller?.verified ?? false,
                  listingsCount: null,
                  memberSince: null,
                  onMessage: _openingChat ? null : _openChat,
                  onProfile: product.seller == null ? null : _openSellerProfile,
                ),

                const SizedBox(height: 40),

                RelatedProducts(currentListingId: product.id),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
