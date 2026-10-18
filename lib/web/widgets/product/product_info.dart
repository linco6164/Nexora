import 'package:flutter/material.dart';

import '../../../models/listing.dart';
import '../../../api_service.dart';
import '../../../app_feedback.dart';
import '../../../chat_page.dart';
import '../../../l10n/app_locale.dart';

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
            listing: conversation.listing,
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
    AppFeedback.error(
      context,
      error is ApiException ? error.message : error,
      fallback: fallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                listing.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              tooltip: _favorite
                  ? (appLocaleController.value == 'en'
                        ? 'Remove from favorites'
                        : 'Elimină din favorite')
                  : (appLocaleController.value == 'en'
                        ? 'Add to favorites'
                        : 'Adaugă la favorite'),
              onPressed: _updatingFavorite ? null : _toggleFavorite,
              icon: Icon(
                _favorite ? Icons.favorite_rounded : Icons.favorite_border,
                color: _favorite ? colors.error : null,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: .42),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "${listing.price.toStringAsFixed(2)} ${listing.currency}",
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w900,
              color: colors.primary,
            ),
          ),
        ),

        const SizedBox(height: 6),

        Text(
          appLocaleController.value == 'en'
              ? 'Item price. Shipping cost is shown separately before payment.'
              : 'Prețul produsului. Costul livrării este afișat separat înainte de plată.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: .62),
            height: 1.4,
          ),
        ),

        const SizedBox(height: 18),

        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            _InfoPill(icon: Icons.location_on_outlined, label: listing.city),
            _InfoPill(
              icon: Icons.inventory_2_outlined,
              label: context.tr(listing.conditionLabel),
            ),
            if (listing.brand != null && listing.brand!.isNotEmpty)
              _InfoPill(
                icon: Icons.local_offer_outlined,
                label: listing.brand!,
              ),
          ],
        ),

        const SizedBox(height: 24),

        Divider(color: colors.outlineVariant),

        const SizedBox(height: 18),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WebCheckoutPage(listingId: listing.id),
                ),
              );
            },
            icon: const Icon(Icons.shopping_cart_checkout_rounded),
            label: Text(context.tr('Cumpără acum')),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: _openingChat ? null : _startChat,
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(
              _openingChat
                  ? (appLocaleController.value == 'en'
                        ? 'Opening...'
                        : 'Se deschide...')
                  : (appLocaleController.value == 'en'
                        ? 'Chat with the seller'
                        : 'Discută cu vânzătorul'),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: colors.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
