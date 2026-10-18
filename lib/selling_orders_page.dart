import 'package:flutter/material.dart';

import 'api_service.dart';
import 'prepare_shipment_page.dart';

class SellingOrdersPage extends StatefulWidget {
  const SellingOrdersPage({super.key});

  @override
  State<SellingOrdersPage> createState() => _SellingOrdersPageState();
}

class _SellingOrdersPageState extends State<SellingOrdersPage> {
  bool _loading = true;

  String? _error;

  List<Map<String, dynamic>> _orders = [];

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _loadOrders();
  }

  // ==========================================================
  // LOAD ORDERS
  // ==========================================================

  Future<void> _loadOrders() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final orders = await ApiService.getSellingOrders();

      if (!mounted) {
        return;
      }

      setState(() {
        _orders = orders;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error is ApiException
            ? error.message
            : 'Nu am putut încărca vânzările.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ==========================================================
  // OPEN PREPARE SHIPMENT
  // ==========================================================

  Future<void> _openPrepareShipment(Map<String, dynamic> order) async {
    final orderId = order['_id']?.toString().trim();

    if (orderId == null || orderId.isEmpty) {
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PrepareShipmentPage(orderId: orderId)),
    );

    if (result != null && mounted) {
      await _loadOrders();
    }
  }

  // ==========================================================
  // STATUS LABEL
  // ==========================================================

  String _statusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Plătită';

      case 'processing':
        return 'În procesare';

      case 'shipped':
        return 'Expediată';

      case 'completed':
        return 'Finalizată';

      case 'cancelled':
        return 'Anulată';

      case 'refunded':
        return 'Rambursată';

      default:
        return status;
    }
  }

  // ==========================================================
  // STATUS ICON
  // ==========================================================

  IconData _statusIcon(String status) {
    switch (status) {
      case 'paid':
        return Icons.payments_outlined;

      case 'processing':
        return Icons.inventory_2_outlined;

      case 'shipped':
        return Icons.local_shipping_outlined;

      case 'completed':
        return Icons.check_circle_outline;

      case 'cancelled':
        return Icons.cancel_outlined;

      case 'refunded':
        return Icons.currency_exchange_outlined;

      default:
        return Icons.receipt_long_outlined;
    }
  }

  // ==========================================================
  // DELIVERY LABEL
  // ==========================================================

  String _deliveryLabel(String method) {
    if (method == 'pickup_point') {
      return 'Sameday Easybox';
    }

    return 'Curier';
  }

  // ==========================================================
  // IMAGE
  // ==========================================================

  String? _getListingImage(Map<String, dynamic>? listing) {
    if (listing == null) {
      return null;
    }

    final images = listing['images'];

    if (images is List && images.isNotEmpty) {
      final image = images.first?.toString().trim();

      if (image != null && image.isNotEmpty) {
        return image;
      }
    }

    return null;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,

      appBar: AppBar(
        title: const Text('Vânzările mele'),

        backgroundColor: colors.surface,

        surfaceTintColor: Colors.transparent,

        actions: [
          IconButton(
            onPressed: _loading ? null : _loadOrders,

            icon: const Icon(Icons.refresh),

            tooltip: 'Reîncarcă',
          ),
        ],
      ),

      body: RefreshIndicator(onRefresh: _loadOrders, child: _buildBody()),
    );
  }

  // ==========================================================
  // BODY
  // ==========================================================

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),

        children: [
          const SizedBox(height: 100),

          const Icon(Icons.error_outline_rounded, size: 58),

          const SizedBox(height: 16),

          Text(_error!, textAlign: TextAlign.center),

          const SizedBox(height: 20),

          Center(
            child: FilledButton(
              onPressed: _loadOrders,

              child: const Text('Încearcă din nou'),
            ),
          ),
        ],
      );
    }

    if (_orders.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),

        children: const [
          SizedBox(height: 100),

          Icon(Icons.sell_outlined, size: 64),

          SizedBox(height: 18),

          Text(
            'Nu ai vânzări încă.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),

          SizedBox(height: 8),

          Text(
            'Comenzile primite pentru produsele tale vor apărea aici.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),

      itemCount: _orders.length,

      separatorBuilder: (_, _) => const SizedBox(height: 12),

      itemBuilder: (context, index) {
        return _buildOrderCard(_orders[index]);
      },
    );
  }

  // ==========================================================
  // ORDER CARD
  // ==========================================================

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final listingRaw = order['listing'];

    final listing = listingRaw is Map
        ? Map<String, dynamic>.from(listingRaw)
        : null;

    final buyerRaw = order['buyer'];

    final buyer = buyerRaw is Map ? Map<String, dynamic>.from(buyerRaw) : null;

    final title = listing?['title']?.toString() ?? 'Produs';

    final image = _getListingImage(listing);

    final status = order['status']?.toString() ?? '';

    final deliveryMethod = order['deliveryMethod']?.toString() ?? 'courier';

    final lockerName = order['pickupPointName']?.toString().trim();

    final lockerAddress = order['pickupPointAddress']?.toString().trim();

    final currency =
        order['currency']?.toString() ??
        listing?['currency']?.toString() ??
        'RON';

    final amount = order['amount'] ?? listing?['price'];

    final buyerName = buyer?['fullName']?.toString().trim() ?? '';

    final buyerUsername = buyer?['username']?.toString().trim() ?? '';

    final displayBuyer = buyerName.isNotEmpty
        ? buyerName
        : buyerUsername.isNotEmpty
        ? buyerUsername
        : 'Cumpărător';

    final canPrepare =
        deliveryMethod == 'pickup_point' &&
        (status == 'paid' || status == 'processing');

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: colors.outlineVariant),
      ),

      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),

                  child: Container(
                    width: 76,
                    height: 76,
                    color: colors.surfaceContainerHighest,

                    child: image == null
                        ? const Icon(Icons.image_outlined)
                        : Image.network(
                            image,

                            fit: BoxFit.cover,

                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.broken_image_outlined);
                            },
                          ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 6),

                      if (amount != null)
                        Text(
                          '$amount $currency',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Icon(
                            _statusIcon(status),
                            size: 16,
                            color: colors.primary,
                          ),

                          const SizedBox(width: 5),

                          Text(
                            _statusLabel(status),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: colors.outlineVariant),

          Padding(
            padding: const EdgeInsets.all(14),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                _detailRow(
                  icon: Icons.person_outline,

                  title: 'Cumpărător',

                  value: displayBuyer,
                ),

                const SizedBox(height: 10),

                _detailRow(
                  icon: deliveryMethod == 'pickup_point'
                      ? Icons.inventory_2_outlined
                      : Icons.local_shipping_outlined,

                  title: 'Livrare',

                  value: _deliveryLabel(deliveryMethod),
                ),

                if (deliveryMethod == 'pickup_point' &&
                    lockerName != null &&
                    lockerName.isNotEmpty) ...[
                  const SizedBox(height: 10),

                  _detailRow(
                    icon: Icons.location_on_outlined,

                    title: 'Easybox',

                    value: [
                      lockerName,
                      if (lockerAddress != null && lockerAddress.isNotEmpty)
                        lockerAddress,
                    ].join('\n'),
                  ),
                ],

                if (canPrepare) ...[
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,

                    height: 50,

                    child: FilledButton.icon(
                      onPressed: () => _openPrepareShipment(order),

                      icon: const Icon(Icons.inventory_2_outlined),

                      label: Text(
                        status == 'processing'
                            ? 'Vezi / pregătește coletul'
                            : 'Pregătește coletul',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DETAIL ROW
  // ==========================================================

  Widget _detailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Icon(icon, size: 19, color: colors.onSurfaceVariant),

        const SizedBox(width: 9),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
