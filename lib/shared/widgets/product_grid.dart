import 'package:flutter/material.dart';

import '../../api_service.dart';
import '../../models/listing.dart';
import '../../web/web_product_page.dart';
import 'product_card.dart';

class ProductGrid extends StatefulWidget {
  final List<Listing> products;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final ValueChanged<String>? onFavoriteRemoved;
  final bool productsAreFavorites;

  const ProductGrid({
    super.key,
    required this.products,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
    this.onFavoriteRemoved,
    this.productsAreFavorites = false,
  });

  @override
  State<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<ProductGrid> {
  final Set<String> _favoriteIds = {};
  final Set<String> _updatingFavorites = {};

  @override
  void initState() {
    super.initState();
    if (widget.productsAreFavorites) {
      _favoriteIds.addAll(widget.products.map((product) => product.id));
    } else {
      _loadFavorites();
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await ApiService.getFavorites();
      if (!mounted) return;
      setState(() {
        _favoriteIds
          ..clear()
          ..addAll(favorites.map((listing) => listing.id));
      });
    } catch (_) {
      // Produsele publice rămân disponibile și fără autentificare.
    }
  }

  Future<void> _toggleFavorite(String listingId) async {
    if (_updatingFavorites.contains(listingId)) return;

    final wasFavorite = _favoriteIds.contains(listingId);
    setState(() {
      _updatingFavorites.add(listingId);
      wasFavorite
          ? _favoriteIds.remove(listingId)
          : _favoriteIds.add(listingId);
    });

    try {
      final favorite = await ApiService.toggleFavorite(listingId);
      if (!mounted) return;
      setState(() {
        favorite ? _favoriteIds.add(listingId) : _favoriteIds.remove(listingId);
      });
      if (!favorite) widget.onFavoriteRemoved?.call(listingId);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        wasFavorite
            ? _favoriteIds.add(listingId)
            : _favoriteIds.remove(listingId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : 'Favoritele nu au putut fi actualizate.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingFavorites.remove(listingId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text("Nu există produse."),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;

        return GridView.builder(
          shrinkWrap: widget.shrinkWrap,
          physics: widget.physics,
          itemCount: widget.products.length,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: compact ? 205 : 235,
            crossAxisSpacing: compact ? 12 : 16,
            mainAxisSpacing: compact ? 12 : 16,
            childAspectRatio: compact ? .70 : .78,
          ),
          itemBuilder: (_, index) {
            final product = widget.products[index];

            return ProductCard(
              id: product.id,
              title: product.title,
              image: product.images.isNotEmpty ? product.images.first : "",
              price: product.price,
              location: product.city,
              isFavorite: _favoriteIds.contains(product.id),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WebProductPage(productId: product.id),
                  ),
                );
              },
              onFavorite: _updatingFavorites.contains(product.id)
                  ? null
                  : () => _toggleFavorite(product.id),
            );
          },
        );
      },
    );
  }
}
