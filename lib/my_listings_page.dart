import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'l10n/app_locale.dart';
import 'listing_detail_page.dart';
import 'models/listing.dart';
import 'promotion_duration_page.dart';
import 'sell_page.dart';
import 'web/web_product_page.dart';
import 'web/widgets/web_page_frame.dart';

enum _ListingAction { view, edit, promote, delete }

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({super.key});

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  List<Listing> _listings = [];
  bool _loading = true;
  String? _error;
  String? _busyListingId;

  bool get _isEnglish => appLocaleController.value == 'en';

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings({bool showLoader = false}) async {
    if (showLoader && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final listings = await ApiService.getMyListings();
      if (!mounted) return;
      setState(() {
        _listings = listings;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException ? error.message : error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openListing(Listing listing) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => kIsWeb
            ? WebProductPage(productId: listing.id)
            : ListingDetailPage(listingId: listing.id),
      ),
    );
  }

  Future<void> _openCreateListing() async {
    final created = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const SellPage()));
    if (created == true) await _loadListings(showLoader: true);
  }

  Future<void> _editListing(Listing listing) async {
    final updated = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => SellPage(listing: listing)));
    if (updated == true) await _loadListings(showLoader: true);
  }

  Future<void> _promoteListing(Listing listing) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PromotionDurationPage(listing: listing),
      ),
    );
  }

  Future<void> _deleteListing(Listing listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Șterge anunțul')),
        content: Text(
          _isEnglish
              ? 'Are you sure you want to delete “${listing.title}”? This action cannot be undone.'
              : 'Sigur vrei să ștergi „${listing.title}”? Această acțiune nu poate fi anulată.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('Anulează')),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(context.tr('Șterge')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyListingId = listing.id);
    try {
      await ApiService.deleteListing(listing.id);
      if (!mounted) return;
      setState(() => _listings.removeWhere((item) => item.id == listing.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Anunțul a fost șters.'))),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Eroare: $error')));
    } finally {
      if (mounted) setState(() => _busyListingId = null);
    }
  }

  Future<void> _handleAction(_ListingAction action, Listing listing) async {
    switch (action) {
      case _ListingAction.view:
        await _openListing(listing);
      case _ListingAction.edit:
        await _editListing(listing);
      case _ListingAction.promote:
        await _promoteListing(listing);
      case _ListingAction.delete:
        await _deleteListing(listing);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    return Scaffold(
      appBar: kIsWeb
          ? null
          : AppBar(
              title: Text(context.tr('Anunțurile mele')),
              actions: [
                IconButton(
                  onPressed: _loading
                      ? null
                      : () => _loadListings(showLoader: true),
                  tooltip: context.tr('Reîncarcă'),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
      floatingActionButton: kIsWeb
          ? null
          : FloatingActionButton.extended(
              onPressed: _openCreateListing,
              icon: const Icon(Icons.add_rounded),
              label: Text(context.tr('Anunț nou')),
            ),
      body: kIsWeb
          ? WebPageFrame(
              title: context.tr('Anunțurile mele'),
              subtitle: _isEnglish
                  ? '${_listings.length} published products'
                  : '${_listings.length} produse publicate',
              maxWidth: 1160,
              actions: [
                OutlinedButton.icon(
                  onPressed: _loading
                      ? null
                      : () => _loadListings(showLoader: true),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(context.tr('Reîncarcă')),
                ),
                FilledButton.icon(
                  onPressed: _openCreateListing,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(context.tr('Anunț nou')),
                ),
              ],
              useSurface: false,
              child: body,
            )
          : body,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _loadListings(showLoader: true),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.tr('Încearcă din nou')),
              ),
            ],
          ),
        ),
      );
    }

    if (_listings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 64),
              const SizedBox(height: 16),
              Text(
                context.tr('Nu ai niciun anunț.'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('Publică primul tău produs pentru a începe.'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _openCreateListing,
                icon: const Icon(Icons.add_rounded),
                label: Text(context.tr('Publică un anunț')),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadListings,
      child: GridView.builder(
        padding: EdgeInsets.fromLTRB(16, 8, 16, kIsWeb ? 24 : 96),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: kIsWeb ? 260 : 230,
          crossAxisSpacing: kIsWeb ? 16 : 12,
          mainAxisSpacing: kIsWeb ? 16 : 12,
          mainAxisExtent: kIsWeb ? 300 : 280,
        ),
        itemCount: _listings.length,
        itemBuilder: (context, index) => _listingCard(_listings[index]),
      ),
    );
  }

  Widget _listingCard(Listing listing) {
    final colors = Theme.of(context).colorScheme;
    final busy = _busyListingId == listing.id;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InkWell(
                  onTap: busy ? null : () => _openListing(listing),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _listingImage(listing),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: _statusBadge(listing.status),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Material(
                          color: colors.surface.withValues(alpha: .92),
                          shape: const CircleBorder(),
                          child: PopupMenuButton<_ListingAction>(
                            enabled: !busy,
                            tooltip: context.tr('Mai multe acțiuni'),
                            onSelected: (action) =>
                                _handleAction(action, listing),
                            itemBuilder: (_) => [
                              _menuItem(
                                _ListingAction.view,
                                Icons.visibility_outlined,
                                context.tr('Vezi anunțul'),
                              ),
                              _menuItem(
                                _ListingAction.edit,
                                Icons.edit_outlined,
                                context.tr('Editează'),
                              ),
                              _menuItem(
                                _ListingAction.promote,
                                Icons.campaign_outlined,
                                context.tr('Promovează'),
                              ),
                              _menuItem(
                                _ListingAction.delete,
                                Icons.delete_outline_rounded,
                                context.tr('Șterge'),
                                color: colors.error,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: busy ? null : () => _openListing(listing),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${_formatPrice(listing.price)} ${listing.currency}',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 14,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${listing.views}',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.favorite_border_rounded,
                            size: 14,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${listing.favorites}',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (busy)
            Positioned.fill(
              child: ColoredBox(
                color: colors.surface.withValues(alpha: .72),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _listingImage(Listing listing) {
    if (listing.images.isEmpty) {
      return const ColoredBox(
        color: Colors.black12,
        child: Center(child: Icon(Icons.image_outlined, size: 40)),
      );
    }
    return Image.network(
      listing.images.first,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: Colors.black12,
        child: Center(
          child: Icon(Icons.image_not_supported_outlined, size: 40),
        ),
      ),
    );
  }

  PopupMenuItem<_ListingAction> _menuItem(
    _ListingAction value,
    IconData icon,
    String label, {
    Color? color,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 10),
          Text(label, style: color == null ? null : TextStyle(color: color)),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final colors = Theme.of(context).colorScheme;
    final normalized = status.toLowerCase();
    final (label, color) = switch (normalized) {
      'active' => (context.tr('Activ'), colors.primary),
      'sold' => (context.tr('Vândut'), colors.tertiary),
      'pending' => (context.tr('În verificare'), Colors.orange),
      _ => (context.tr('Inactiv'), colors.onSurfaceVariant),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    return price == price.roundToDouble()
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
  }
}
