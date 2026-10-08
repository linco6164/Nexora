import 'package:flutter/material.dart';

import '../../../models/listing.dart';
import '../../../api_service.dart';
import '../../../chat_page.dart';

import '../../checkout/web_checkout_page.dart';

class ProductInfo extends StatefulWidget {
  final Listing listing;

  const ProductInfo({super.key, required this.listing});

  @override
  State<ProductInfo> createState() => _ProductInfoState();
}

class _ProductInfoState extends State<ProductInfo> {
  bool _favorite = false;
  bool _updatingFavorite = false;
  bool _openingChat = false;

  Listing get listing => widget.listing;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    try {
      final favorite = await ApiService.checkFavorite(listing.id);
      if (mounted) setState(() => _favorite = favorite);
    } catch (_) {
      // Produsul rămâne accesibil vizitatorilor neautentificați.
    }
  }

  Future<void> _toggleFavorite() async {
    if (_updatingFavorite) return;
    setState(() => _updatingFavorite = true);

    try {
      final favorite = await ApiService.toggleFavorite(listing.id);
      if (mounted) setState(() => _favorite = favorite);
    } catch (error) {
      if (!mounted) return;
      _showError(error, 'Favoritele nu au putut fi actualizate.');
    } finally {
      if (mounted) setState(() => _updatingFavorite = false);
    }
  }

  Future<void> _startChat() async {
    if (_openingChat) return;
    setState(() => _openingChat = true);

    try {
      final me = await ApiService.getCurrentUser();
      final myUserId = me['_id']?.toString() ?? '';
      final conversation = await ApiService.startConversation(listing.id);
      final other = conversation.otherParticipant(myUserId);

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatPage(
            conversationId: conversation.id,
            otherUsername:
                other?.username ?? listing.seller?.username ?? 'Vânzător',
            myUserId: myUserId,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error, 'Conversația nu a putut fi deschisă.');
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  void _showError(Object error, String fallback) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error is ApiException ? error.message : fallback)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          listing.title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        Text(
          "${listing.price.toStringAsFixed(2)} ${listing.currency}",
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Prețul produsului. Costul livrării este afișat separat înainte de plată.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: .62),
            height: 1.4,
          ),
        ),

        const SizedBox(height: 24),

        Row(
          children: [
            const Icon(Icons.location_on_outlined),
            const SizedBox(width: 6),
            Text(listing.city),
          ],
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            const Icon(Icons.inventory_2_outlined),
            const SizedBox(width: 6),
            Text(listing.condition),
          ],
        ),

        const SizedBox(height: 30),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WebCheckoutPage(listingId: listing.id),
                ),
              );
            },
            icon: const Icon(Icons.shopping_cart_checkout),
            label: const Text('Cumpără acum'),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openingChat ? null : _startChat,
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(
              _openingChat ? 'Se deschide...' : 'Discută cu vânzătorul',
            ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _updatingFavorite ? null : _toggleFavorite,
            icon: Icon(_favorite ? Icons.favorite : Icons.favorite_border),
            label: Text(
              _favorite ? 'Elimină din favorite' : 'Adaugă la favorite',
            ),
          ),
        ),
      ],
    );
  }
}
