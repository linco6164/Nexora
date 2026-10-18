import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';

import 'web/widgets/web_page_frame.dart';

import 'review_page.dart';

class OrderPage extends StatefulWidget {
  final int initialTab;

  const OrderPage({super.key, this.initialTab = 0});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<dynamic> _orders = [];

  List<dynamic> _sellingOrders = [];

  bool _loadingOrders = true;

  bool _loadingSellingOrders = true;

  String? _ordersError;

  String? _sellingOrdersError;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,

      vsync: this,

      initialIndex: widget.initialTab,
    );

    _loadOrders();

    _loadSellingOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();

    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loadingOrders = true;

      _ordersError = null;
    });

    try {
      final orders = await ApiService.getOrders();

      if (!mounted) return;

      setState(() {
        _orders = orders;

        _loadingOrders = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _ordersError = e.toString();

        _loadingOrders = false;
      });
    }
  }

  Future<void> _loadSellingOrders() async {
    setState(() {
      _loadingSellingOrders = true;

      _sellingOrdersError = null;
    });

    try {
      final orders = await ApiService.getSellingOrders();

      if (!mounted) return;

      setState(() {
        _sellingOrders = orders;

        _loadingSellingOrders = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _sellingOrdersError = e.toString();

        _loadingSellingOrders = false;
      });
    }
  }

  Future<void> _refresh() async {
    await Future.wait([_loadOrders(), _loadSellingOrders()]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    final tabs = TabBar(
      controller: _tabController,

      tabs: const [
        Tab(text: 'Cumpărături'),

        Tab(text: 'Vânzări'),
      ],
    );

    final content = TabBarView(
      controller: _tabController,

      children: [_buildOrdersTab(), _buildSellingTab()],
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,

      appBar: kIsWeb
          ? null
          : AppBar(
              title: const Text(
                'Comenzile mele',

                style: TextStyle(fontWeight: FontWeight.w700),
              ),

              centerTitle: false,

              elevation: 0,

              backgroundColor: colorScheme.surface,

              foregroundColor: colorScheme.onSurface,

              bottom: tabs,
            ),

      body: kIsWeb
          ? WebPageFrame(
              title: 'Comenzi și vânzări',

              subtitle: 'Urmărește cumpărăturile și produsele vândute',

              maxWidth: 980,

              actions: [
                IconButton(
                  onPressed: _refresh,

                  tooltip: 'Reîncarcă',

                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],

              child: Column(
                children: [
                  tabs,

                  Expanded(child: content),
                ],
              ),
            )
          : content,
    );
  }

  Widget _buildOrdersTab() {
    if (_loadingOrders) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_ordersError != null) {
      return _buildError(_ordersError!, _loadOrders);
    }

    if (_orders.isEmpty) {
      return _buildEmpty(
        icon: Icons.shopping_bag_outlined,

        title: 'Nu ai comenzi',

        subtitle: 'Comenzile tale vor apărea aici după ce cumperi un produs.',
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,

      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),

        itemCount: _orders.length,

        separatorBuilder: (_, _) => const SizedBox(height: 12),

        itemBuilder: (context, index) {
          return _buildOrderCard(_orders[index], isSelling: false);
        },
      ),
    );
  }

  Widget _buildSellingTab() {
    if (_loadingSellingOrders) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sellingOrdersError != null) {
      return _buildError(_sellingOrdersError!, _loadSellingOrders);
    }

    if (_sellingOrders.isEmpty) {
      return _buildEmpty(
        icon: Icons.storefront_outlined,

        title: 'Nu ai vânzări',

        subtitle: 'Comenzile pentru produsele tale vor apărea aici.',
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,

      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),

        itemCount: _sellingOrders.length,

        separatorBuilder: (_, _) => const SizedBox(height: 12),

        itemBuilder: (context, index) {
          return _buildOrderCard(_sellingOrders[index], isSelling: true);
        },
      ),
    );
  }

  Widget _buildOrderCard(dynamic rawOrder, {required bool isSelling}) {
    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    final order = Map<String, dynamic>.from(rawOrder as Map);

    final listing = order['listing'] is Map
        ? Map<String, dynamic>.from(order['listing'])
        : <String, dynamic>{};

    final buyer = order['buyer'] is Map
        ? Map<String, dynamic>.from(order['buyer'])
        : <String, dynamic>{};

    final seller = order['seller'] is Map
        ? Map<String, dynamic>.from(order['seller'])
        : <String, dynamic>{};

    final title = listing['title']?.toString() ?? 'Produs';

    final images = listing['images'] is List
        ? List<String>.from(
            (listing['images'] as List).map((e) => e.toString()),
          )
        : <String>[];

    final status = order['status']?.toString() ?? 'unknown';

    final amount = (order['amount'] as num?)?.toDouble() ?? 0;

    final currency = order['currency']?.toString() ?? 'RON';

    final otherUser = isSelling ? buyer : seller;

    final username = otherUser['username']?.toString() ?? 'Utilizator';

    final avatar = otherUser['avatar']?.toString();

    return Card(
      margin: EdgeInsets.zero,

      elevation: 0,

      clipBehavior: Clip.antiAlias,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),

        side: BorderSide(color: colorScheme.outlineVariant),
      ),

      child: InkWell(
        onTap: () {
          _openOrder(order);
        },

        child: Padding(
          padding: const EdgeInsets.all(14),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  _buildProductImage(images.isNotEmpty ? images.first : null),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          title,

                          maxLines: 2,

                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            fontSize: 16,

                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          isSelling
                              ? 'Cumpărător: $username'
                              : 'Vânzător: $username',

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          '${amount.toStringAsFixed(2)} $currency',

                          style: TextStyle(
                            fontSize: 17,

                            fontWeight: FontWeight.w800,

                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildStatusChip(status),
                ],
              ),

              const SizedBox(height: 14),

              Divider(height: 1, color: colorScheme.outlineVariant),

              const SizedBox(height: 12),

              Row(
                children: [
                  CircleAvatar(
                    radius: 15,

                    backgroundImage: avatar != null && avatar.isNotEmpty
                        ? NetworkImage(avatar)
                        : null,

                    child: avatar == null || avatar.isEmpty
                        ? const Icon(Icons.person_outline, size: 17)
                        : null,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      username,

                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),

                  const Icon(Icons.chevron_right_rounded),
                ],
              ),

              if (!isSelling && status == 'completed') ...[
                const SizedBox(height: 12),

                _buildReviewButton(order),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    return Container(
      width: 82,

      height: 82,

      clipBehavior: Clip.antiAlias,

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),

        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),

      child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,

              fit: BoxFit.cover,

              errorBuilder: (_, _, _) {
                return const Icon(Icons.image_not_supported_outlined);
              },
            )
          : const Icon(Icons.image_outlined),
    );
  }

  Widget _buildStatusChip(String status) {
    final colorScheme = Theme.of(context).colorScheme;

    String label;

    IconData icon;

    switch (status) {
      case 'paid':
        label = 'Plătită';

        icon = Icons.check_circle_outline;

        break;

      case 'processing':
        label = 'În procesare';

        icon = Icons.sync_rounded;

        break;

      case 'shipped':
        label = 'Expediată';

        icon = Icons.local_shipping_outlined;

        break;

      case 'delivered':
        label = 'Livrată';

        icon = Icons.inventory_2_outlined;

        break;

      case 'issue_reported':
        label = 'Problemă raportată';

        icon = Icons.report_problem_outlined;

        break;

      case 'completed':
        label = 'Finalizată';

        icon = Icons.task_alt_rounded;

        break;

      case 'cancelled':
        label = 'Anulată';

        icon = Icons.cancel_outlined;

        break;

      case 'refunded':
        label = 'Rambursată';

        icon = Icons.keyboard_return_rounded;

        break;

      default:
        label = status;

        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),

      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,

        borderRadius: BorderRadius.circular(12),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(icon, size: 15, color: colorScheme.primary),

          const SizedBox(width: 5),

          Text(
            label,

            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewButton(Map<String, dynamic> order) {
    return SizedBox(
      width: double.infinity,

      child: FilledButton.icon(
        onPressed: () {
          _openReview(order);
        },

        icon: const Icon(Icons.star_outline_rounded),

        label: const Text('Evaluează vânzătorul'),
      ),
    );
  }

  void _openOrder(Map<String, dynamic> order) {
    final orderId = order['_id']?.toString();

    if (orderId == null || orderId.isEmpty) {
      return;
    }

    Navigator.push(
      context,

      MaterialPageRoute(builder: (_) => OrderDetailsPage(orderId: orderId)),
    );
  }

  void _openReview(Map<String, dynamic> order) {
    final orderId = order['_id']?.toString();

    if (orderId == null || orderId.isEmpty) {
      return;
    }

    final seller = order['seller'] is Map
        ? Map<String, dynamic>.from(order['seller'])
        : <String, dynamic>{};

    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) => ReviewPage(
          orderId: orderId,

          sellerName: seller['username']?.toString() ?? 'Vânzător',
        ),
      ),
    );
  }

  Widget _buildEmpty({
    required IconData icon,

    required String title,

    required String subtitle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(icon, size: 64, color: colorScheme.onSurfaceVariant),

            const SizedBox(height: 18),

            Text(
              title,

              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 8),

            Text(
              subtitle,

              textAlign: TextAlign.center,

              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error, Future<void> Function() retry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Icon(Icons.error_outline_rounded, size: 52),

            const SizedBox(height: 16),

            Text(error, textAlign: TextAlign.center),

            const SizedBox(height: 16),

            FilledButton(
              onPressed: retry,

              child: const Text('Încearcă din nou'),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  Map<String, dynamic>? _order;

  Map<String, dynamic>? _shipment;

  String? _currentUserId;

  bool _confirmingReceipt = false;

  bool _reportingIssue = false;

  bool _loading = true;

  String? _error;

  @override
  void initState() {
    super.initState();

    _loadCurrentUser();

    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _loading = true;

      _error = null;
    });

    try {
      final order = await ApiService.getOrderById(widget.orderId);

      Map<String, dynamic>? shipment;

      try {
        shipment = await ApiService.getSamedayShipmentByOrder(
          orderId: widget.orderId,
        );
      } catch (_) {
        // Comanda trebuie să rămână accesibilă chiar dacă transportul

        // Sameday nu este încă disponibil.

        shipment = null;
      }

      if (!mounted) return;

      setState(() {
        _order = order;

        _shipment = shipment;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();

        _loading = false;
      });
    }
  }

  String _shipmentStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Se generează';

      case 'awb_created':
        return 'AWB creat';

      case 'ready_for_dropoff':
        return 'Pregătit pentru predare';

      case 'dropped_off':
        return 'Predat în Easybox';

      case 'in_transit':
        return 'În tranzit';

      case 'at_locker':
        return 'Ajuns în Easybox';

      case 'delivered':
        return 'Livrat';

      case 'returned':
        return 'Returnat';

      case 'cancelled':
        return 'Anulat';

      case 'failed':
        return 'Eroare';

      default:
        return status.isEmpty ? 'Transport creat' : status;
    }
  }

  Future<void> _openSamedayTracking(String awb) async {
    final cleanAwb = awb.trim();

    if (cleanAwb.isEmpty) {
      return;
    }

    final uri = Uri.parse(
      'https://sameday.ro/#awb=${Uri.encodeComponent(cleanAwb)}',
    );

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nu am putut deschide tracking-ul Sameday.'),
        ),
      );
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await ApiService.getCurrentUser();

      if (!mounted) return;

      setState(() {
        _currentUserId = user['_id']?.toString() ?? user['id']?.toString();
      });
    } catch (_) {
      // Nu blocăm pagina dacă profilul

      // nu poate fi încărcat.
    }
  }

  Future<void> _confirmReceived() async {
    if (_confirmingReceipt) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text('Totul este în regulă?'),

          content: const Text(
            'Prin confirmare, comanda va fi finalizată '
            'iar banii vor deveni disponibili vânzătorului.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },

              child: const Text('Anulează'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },

              child: const Text('Confirmă'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _confirmingReceipt = true;
    });

    try {
      await ApiService.confirmOrderReceived(widget.orderId);

      if (!mounted) return;

      await _loadOrder();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comanda a fost finalizată.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _confirmingReceipt = false;
        });
      }
    }
  }

  Future<void> _reportIssue() async {
    if (_reportingIssue) {
      return;
    }

    final detailsController = TextEditingController();

    String selectedReason = 'damaged';

    final result = await showDialog<Map<String, String>>(
      context: context,

      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Am o problemă'),

              content: SizedBox(
                width: 450,

                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: [
                    const Text('Selectează motivul problemei.'),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: selectedReason,

                      decoration: const InputDecoration(
                        labelText: 'Motiv',

                        border: OutlineInputBorder(),
                      ),

                      items: const [
                        DropdownMenuItem(
                          value: 'item_not_as_described',

                          child: Text('Produsul nu corespunde descrierii'),
                        ),

                        DropdownMenuItem(
                          value: 'damaged',

                          child: Text('Produs deteriorat'),
                        ),

                        DropdownMenuItem(
                          value: 'wrong_item',

                          child: Text('Am primit alt produs'),
                        ),

                        DropdownMenuItem(
                          value: 'missing_item',

                          child: Text(
                            'Lipsește produsul sau o parte din comandă',
                          ),
                        ),

                        DropdownMenuItem(
                          value: 'counterfeit',

                          child: Text('Produs posibil contrafăcut'),
                        ),

                        DropdownMenuItem(
                          value: 'other',

                          child: Text('Altă problemă'),
                        ),
                      ],

                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedReason = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: detailsController,

                      minLines: 3,

                      maxLines: 6,

                      maxLength: 2000,

                      decoration: const InputDecoration(
                        labelText: 'Descrie problema',

                        hintText: 'Spune-ne ce s-a întâmplat...',

                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Banii vânzătorului vor rămâne blocați până la soluționarea problemei.',

                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },

                  child: const Text('Anulează'),
                ),

                FilledButton(
                  onPressed: () {
                    final details = detailsController.text.trim();

                    if (selectedReason == 'other' && details.length < 5) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Descrie problema.')),
                      );

                      return;
                    }

                    Navigator.pop(dialogContext, {
                      'reason': selectedReason,

                      'details': details,
                    });
                  },

                  child: const Text('Raportează problema'),
                ),
              ],
            );
          },
        );
      },
    );

    detailsController.dispose();

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _reportingIssue = true;
    });

    try {
      await ApiService.reportOrderIssue(
        orderId: widget.orderId,

        reason: result['reason']!,

        details: result['details'],
      );

      if (!mounted) return;

      await _loadOrder();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Problema a fost raportată. Finalizarea comenzii a fost suspendată.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _reportingIssue = false;
        });
      }
    }
  }

  Widget _buildShipmentSection(Map<String, dynamic> shipment) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final awb = shipment['awbNumber']?.toString().trim() ?? '';

    final status = shipment['status']?.toString().trim() ?? '';

    final samedayStatus = shipment['samedayStatus']?.toString().trim() ?? '';

    final lockerName =
        shipment['destinationLockerName']?.toString().trim() ?? '';

    final lockerAddress =
        shipment['destinationLockerAddress']?.toString().trim() ?? '';

    final lockerCity =
        shipment['destinationLockerCity']?.toString().trim() ?? '';

    final lockerCounty =
        shipment['destinationLockerCounty']?.toString().trim() ?? '';

    final trackingEventsRaw = shipment['trackingEvents'];

    final trackingEvents = trackingEventsRaw is List
        ? trackingEventsRaw
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];

    trackingEvents.sort((a, b) {
      final aDate =
          DateTime.tryParse(a['statusDate']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);

      final bDate =
          DateTime.tryParse(b['statusDate']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);

      return bDate.compareTo(aDate);
    });

    final lockerParts = <String>[
      if (lockerName.isNotEmpty) lockerName,

      if (lockerAddress.isNotEmpty) lockerAddress,

      if (lockerCity.isNotEmpty) lockerCity,

      if (lockerCounty.isNotEmpty) lockerCounty,
    ];

    return Card(
      elevation: 0,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),

        side: BorderSide(color: colors.outlineVariant),
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                Container(
                  width: 42,

                  height: 42,

                  decoration: BoxDecoration(
                    color: colors.primaryContainer,

                    shape: BoxShape.circle,
                  ),

                  child: Icon(
                    Icons.local_shipping_outlined,

                    color: colors.primary,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        'Transport Sameday',

                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        _shipmentStatusLabel(status),

                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.primary,

                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (samedayStatus.isNotEmpty) ...[
              const SizedBox(height: 14),

              Text(
                samedayStatus,

                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],

            if (awb.isNotEmpty) ...[
              const SizedBox(height: 18),

              _ShipmentInfoRow(
                icon: Icons.confirmation_number_outlined,

                label: 'AWB',

                value: awb,
              ),
            ],

            if (lockerParts.isNotEmpty) ...[
              const SizedBox(height: 12),

              _ShipmentInfoRow(
                icon: Icons.inventory_2_outlined,

                label: 'Easybox destinație',

                value: lockerParts.join('\n'),
              ),
            ],

            if (awb.isNotEmpty) ...[
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,

                child: OutlinedButton.icon(
                  onPressed: () => _openSamedayTracking(awb),

                  icon: const Icon(Icons.route_outlined),

                  label: const Text('Urmărește coletul'),
                ),
              ),
            ],

            if (trackingEvents.isNotEmpty) ...[
              const SizedBox(height: 22),

              Text(
                'Istoric transport',

                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 12),

              ...trackingEvents.map((event) {
                final eventStatus =
                    event['status']?.toString().trim() ?? 'Actualizare Sameday';

                final rawDate = event['statusDate']?.toString();

                final eventDate = rawDate == null
                    ? null
                    : DateTime.tryParse(rawDate)?.toLocal();

                final dateText = eventDate == null
                    ? ''
                    : '${eventDate.day.toString().padLeft(2, '0')}.'
                          '${eventDate.month.toString().padLeft(2, '0')}.'
                          '${eventDate.year} '
                          '${eventDate.hour.toString().padLeft(2, '0')}:'
                          '${eventDate.minute.toString().padLeft(2, '0')}';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),

                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),

                        child: Icon(
                          Icons.check_circle_rounded,

                          size: 19,

                          color: colors.primary,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              eventStatus,

                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            if (dateText.isNotEmpty) ...[
                              const SizedBox(height: 2),

                              Text(
                                dateText,

                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      const loading = Center(child: CircularProgressIndicator());

      return Scaffold(
        body: kIsWeb
            ? const WebPageFrame(
                title: 'Detalii comandă',

                subtitle: 'Se încarcă informațiile comenzii.',

                maxWidth: 900,

                child: loading,
              )
            : loading,
      );
    }

    if (_error != null) {
      final errorContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              Text(_error!, textAlign: TextAlign.center),

              const SizedBox(height: 16),

              FilledButton.icon(
                onPressed: _loadOrder,

                icon: const Icon(Icons.refresh_rounded),

                label: const Text('Încearcă din nou'),
              ),
            ],
          ),
        ),
      );

      return Scaffold(
        appBar: kIsWeb ? null : AppBar(title: const Text('Comandă')),

        body: kIsWeb
            ? WebPageFrame(
                title: 'Detalii comandă',

                subtitle: 'Nu am putut încărca informațiile.',

                maxWidth: 900,

                child: errorContent,
              )
            : errorContent,
      );
    }

    final order = _order!;

    final listing = order['listing'] is Map
        ? Map<String, dynamic>.from(order['listing'])
        : <String, dynamic>{};

    final seller = order['seller'] is Map
        ? Map<String, dynamic>.from(order['seller'])
        : <String, dynamic>{};

    final buyer = order['buyer'] is Map
        ? Map<String, dynamic>.from(order['buyer'])
        : <String, dynamic>{};

    final buyerId =
        buyer['_id']?.toString() ??
        (order['buyer'] is String ? order['buyer'].toString() : null);

    final isBuyer = _currentUserId != null && _currentUserId == buyerId;

    final status = order['status']?.toString() ?? 'unknown';

    final amount = (order['amount'] as num?)?.toDouble() ?? 0;

    final currency = order['currency']?.toString() ?? 'RON';

    final content = RefreshIndicator(
      onRefresh: _loadOrder,

      child: ListView(
        padding: const EdgeInsets.all(20),

        children: [
          Text(
            listing['title']?.toString() ?? 'Produs',

            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 8),

          Text(
            '${amount.toStringAsFixed(2)} $currency',

            style: TextStyle(
              fontSize: 20,

              fontWeight: FontWeight.w800,

              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          const SizedBox(height: 24),

          _OrderStatusTimeline(status: status),

          if (status == 'delivered' && isBuyer) ...[
            const SizedBox(height: 24),

            Card(
              elevation: 0,

              child: Padding(
                padding: const EdgeInsets.all(20),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: [
                    const Text(
                      'Ai primit coletul?',

                      style: TextStyle(
                        fontSize: 18,

                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Dacă produsul este în regulă, confirmă primirea pentru a finaliza comanda.',
                    ),

                    const SizedBox(height: 18),

                    FilledButton.icon(
                      onPressed: _confirmingReceipt ? null : _confirmReceived,

                      icon: _confirmingReceipt
                          ? const SizedBox(
                              width: 18,

                              height: 18,

                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline_rounded),

                      label: Text(
                        _confirmingReceipt
                            ? 'Se finalizează...'
                            : 'Totul este în regulă',
                      ),
                    ),

                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: _reportingIssue || _confirmingReceipt
                          ? null
                          : _reportIssue,

                      icon: _reportingIssue
                          ? const SizedBox(
                              width: 18,

                              height: 18,

                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.report_problem_outlined),

                      label: Text(
                        _reportingIssue ? 'Se raportează...' : 'Am o problemă',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (status == 'issue_reported' && isBuyer) ...[
            const SizedBox(height: 24),

            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.report_problem_outlined,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Problemă raportată',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Finalizarea comenzii este suspendată, iar plata către vânzător rămâne blocată până la soluționarea problemei.',
                          ),
                          if (order['issueDetails']
                                  ?.toString()
                                  .trim()
                                  .isNotEmpty ==
                              true) ...[
                            const SizedBox(height: 12),
                            Text(
                              order['issueDetails'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (_shipment != null) ...[
            const SizedBox(height: 28),

            _buildShipmentSection(_shipment!),
          ],

          const SizedBox(height: 28),

          Card(
            elevation: 0,

            child: ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    seller['avatar'] != null &&
                        seller['avatar'].toString().isNotEmpty
                    ? NetworkImage(seller['avatar'].toString())
                    : null,

                child: seller['avatar'] == null
                    ? const Icon(Icons.person_outline)
                    : null,
              ),

              title: Text(
                seller['username']?.toString() ?? 'Vânzător',

                style: const TextStyle(fontWeight: FontWeight.w700),
              ),

              subtitle: const Text('Vânzător'),
            ),
          ),

          if (status == 'completed') ...[
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,

              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (_) => ReviewPage(
                        orderId: widget.orderId,

                        sellerName:
                            seller['username']?.toString() ?? 'Vânzător',
                      ),
                    ),
                  );
                },

                icon: const Icon(Icons.star_outline_rounded),

                label: const Text('Evaluează vânzătorul'),
              ),
            ),
          ],
        ],
      ),
    );

    return Scaffold(
      appBar: kIsWeb
          ? null
          : AppBar(
              title: const Text(
                'Detalii comandă',

                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),

      body: kIsWeb
          ? WebPageFrame(
              title: 'Detalii comandă',

              subtitle: 'Urmărește starea și informațiile tranzacției.',

              maxWidth: 900,

              child: content,
            )
          : content,
    );
  }
}

class _ShipmentInfoRow extends StatelessWidget {
  final IconData icon;

  final String label;

  final String value;

  const _ShipmentInfoRow({
    required this.icon,

    required this.label,

    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Icon(icon, size: 21, color: colors.primary),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                label,

                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 3),

              SelectableText(
                value,

                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderStatusTimeline extends StatelessWidget {
  final String status;

  const _OrderStatusTimeline({required this.status});

  @override
  Widget build(BuildContext context) {
    const statuses = [
      'paid',

      'processing',

      'shipped',

      'delivered',

      'completed',
    ];

    final effectiveStatus = status == 'issue_reported' ? 'delivered' : status;

    final currentIndex = statuses.indexOf(effectiveStatus);

    return Column(
      children: [
        for (int i = 0; i < statuses.length; i++)
          _buildStep(context, statuses[i], i, currentIndex),
      ],
    );
  }

  Widget _buildStep(
    BuildContext context,

    String status,

    int index,

    int currentIndex,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final completed = currentIndex >= index;

    String label;

    switch (status) {
      case 'paid':
        label = 'Plătită';

        break;

      case 'processing':
        label = 'În procesare';

        break;

      case 'shipped':
        label = 'Expediată';

        break;

      case 'delivered':
        label = 'Livrată';

        break;

      case 'completed':
        label = 'Finalizată';

        break;

      default:
        label = status;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Column(
          children: [
            Icon(
              completed
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,

              color: completed
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),

            if (index < 4)
              Container(
                width: 2,

                height: 36,

                color: completed
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
              ),
          ],
        ),

        const SizedBox(width: 12),

        Padding(
          padding: const EdgeInsets.only(top: 2),

          child: Text(
            label,

            style: TextStyle(
              fontWeight: completed ? FontWeight.w700 : FontWeight.w500,

              color: completed
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
