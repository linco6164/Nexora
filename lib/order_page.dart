import 'package:flutter/material.dart';
import 'api_service.dart';
import 'review_page.dart';

class OrderPage extends StatefulWidget {
  final int initialTab;

  const OrderPage({
    super.key,
    this.initialTab = 0,
  });

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
      final orders =
          await ApiService.getSellingOrders();

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
    await Future.wait([
      _loadOrders(),
      _loadSellingOrders(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Comenzile mele',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Cumpărături'),
            Tab(text: 'Vânzări'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersTab(),
          _buildSellingTab(),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    if (_loadingOrders) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_ordersError != null) {
      return _buildError(
        _ordersError!,
        _loadOrders,
      );
    }

    if (_orders.isEmpty) {
      return _buildEmpty(
        icon: Icons.shopping_bag_outlined,
        title: 'Nu ai comenzi',
        subtitle:
            'Comenzile tale vor apărea aici după ce cumperi un produs.',
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          32,
        ),
        itemCount: _orders.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildOrderCard(
            _orders[index],
            isSelling: false,
          );
        },
      ),
    );
  }

  Widget _buildSellingTab() {
    if (_loadingSellingOrders) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_sellingOrdersError != null) {
      return _buildError(
        _sellingOrdersError!,
        _loadSellingOrders,
      );
    }

    if (_sellingOrders.isEmpty) {
      return _buildEmpty(
        icon: Icons.storefront_outlined,
        title: 'Nu ai vânzări',
        subtitle:
            'Comenzile pentru produsele tale vor apărea aici.',
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          32,
        ),
        itemCount: _sellingOrders.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildOrderCard(
            _sellingOrders[index],
            isSelling: true,
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(
    dynamic rawOrder, {
    required bool isSelling,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final order = Map<String, dynamic>.from(
      rawOrder as Map,
    );

    final listing = order['listing'] is Map
        ? Map<String, dynamic>.from(
            order['listing'],
          )
        : <String, dynamic>{};

    final buyer = order['buyer'] is Map
        ? Map<String, dynamic>.from(
            order['buyer'],
          )
        : <String, dynamic>{};

    final seller = order['seller'] is Map
        ? Map<String, dynamic>.from(
            order['seller'],
          )
        : <String, dynamic>{};

    final title =
        listing['title']?.toString() ??
            'Produs';

    final images = listing['images'] is List
        ? List<String>.from(
            (listing['images'] as List)
                .map((e) => e.toString()),
          )
        : <String>[];

    final status =
        order['status']?.toString() ??
            'unknown';

    final amount =
        (order['amount'] as num?)?.toDouble() ??
            0;

    final currency =
        order['currency']?.toString() ??
            'RON';

    final otherUser =
        isSelling ? buyer : seller;

    final username =
        otherUser['username']?.toString() ??
            'Utilizator';

    final avatar =
        otherUser['avatar']?.toString();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: () {
          _openOrder(order);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildProductImage(
                    images.isNotEmpty
                        ? images.first
                        : null,
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          isSelling
                              ? 'Cumpărător: $username'
                              : 'Vânzător: $username',
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                colorScheme.onSurfaceVariant,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          '${amount.toStringAsFixed(2)} $currency',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.w800,
                            color:
                                colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildStatusChip(status),
                ],
              ),

              const SizedBox(height: 14),

              Divider(
                height: 1,
                color: colorScheme.outlineVariant,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundImage:
                        avatar != null &&
                                avatar.isNotEmpty
                            ? NetworkImage(avatar)
                            : null,
                    child:
                        avatar == null ||
                                avatar.isEmpty
                            ? const Icon(
                                Icons.person_outline,
                                size: 17,
                              )
                            : null,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      username,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right_rounded,
                  ),
                ],
              ),

              if (!isSelling &&
                  status == 'completed') ...[
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
        color:
            Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
      ),
      child: imageUrl != null &&
              imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) {
                return const Icon(
                  Icons.image_not_supported_outlined,
                );
              },
            )
          : const Icon(
              Icons.image_outlined,
            ),
    );
  }

  Widget _buildStatusChip(String status) {
    final colorScheme =
        Theme.of(context).colorScheme;

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
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: colorScheme
            .surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewButton(
    Map<String, dynamic> order,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          _openReview(order);
        },
        icon: const Icon(
          Icons.star_outline_rounded,
        ),
        label: const Text(
          'Evaluează vânzătorul',
        ),
      ),
    );
  }

  void _openOrder(
    Map<String, dynamic> order,
  ) {
    final orderId =
        order['_id']?.toString();

    if (orderId == null ||
        orderId.isEmpty) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailsPage(
          orderId: orderId,
        ),
      ),
    );
  }

  void _openReview(
    Map<String, dynamic> order,
  ) {
    final orderId =
        order['_id']?.toString();

    if (orderId == null ||
        orderId.isEmpty) {
      return;
    }

    final seller = order['seller'] is Map
        ? Map<String, dynamic>.from(
            order['seller'],
          )
        : <String, dynamic>{};

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewPage(
          orderId: orderId,
          sellerName:
              seller['username']
                  ?.toString() ??
              'Vânzător',
        ),
      ),
    );
  }

  Widget _buildEmpty({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color:
                  colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(
    String error,
    Future<void> Function() retry,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: retry,
              child: const Text(
                'Încearcă din nou',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailsPage> createState() =>
      _OrderDetailsPageState();
}

class _OrderDetailsPageState
    extends State<OrderDetailsPage> {
  Map<String, dynamic>? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final order =
          await ApiService.getOrderById(
        widget.orderId,
      );

      if (!mounted) return;

      setState(() {
        _order = order;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Comandă'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final order = _order!;

    final listing = order['listing'] is Map
        ? Map<String, dynamic>.from(
            order['listing'],
          )
        : <String, dynamic>{};

    final seller = order['seller'] is Map
        ? Map<String, dynamic>.from(
            order['seller'],
          )
        : <String, dynamic>{};

    final status =
        order['status']?.toString() ??
            'unknown';

    final amount =
        (order['amount'] as num?)?.toDouble() ??
            0;

    final currency =
        order['currency']?.toString() ??
            'RON';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalii comandă',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrder,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              listing['title']?.toString() ??
                  'Produs',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '${amount.toStringAsFixed(2)} $currency',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color:
                    Theme.of(context)
                        .colorScheme
                        .primary,
              ),
            ),

            const SizedBox(height: 24),

            _OrderStatusTimeline(
              status: status,
            ),

            const SizedBox(height: 28),

            Card(
              elevation: 0,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      seller['avatar'] != null &&
                              seller['avatar']
                                  .toString()
                                  .isNotEmpty
                          ? NetworkImage(
                              seller['avatar']
                                  .toString(),
                            )
                          : null,
                  child:
                      seller['avatar'] == null
                          ? const Icon(
                              Icons.person_outline,
                            )
                          : null,
                ),
                title: Text(
                  seller['username']
                          ?.toString() ??
                      'Vânzător',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'Vânzător',
                ),
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
                        builder: (_) =>
                            ReviewPage(
                          orderId:
                              widget.orderId,
                          sellerName:
                              seller['username']
                                      ?.toString() ??
                                  'Vânzător',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.star_outline_rounded,
                  ),
                  label: const Text(
                    'Evaluează vânzătorul',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderStatusTimeline
    extends StatelessWidget {
  final String status;

  const _OrderStatusTimeline({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    const statuses = [
      'paid',
      'processing',
      'shipped',
      'completed',
    ];

    final currentIndex =
        statuses.indexOf(status);

    return Column(
      children: [
        for (int i = 0;
            i < statuses.length;
            i++)
          _buildStep(
            context,
            statuses[i],
            i,
            currentIndex,
          ),
      ],
    );
  }

  Widget _buildStep(
    BuildContext context,
    String status,
    int index,
    int currentIndex,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final completed =
        currentIndex >= index;

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
      case 'completed':
        label = 'Finalizată';
        break;
      default:
        label = status;
    }

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              completed
                  ? Icons.check_circle_rounded
                  : Icons
                      .radio_button_unchecked,
              color: completed
                  ? colorScheme.primary
                  : colorScheme
                      .onSurfaceVariant,
            ),
            if (index < 3)
              Container(
                width: 2,
                height: 36,
                color: completed
                    ? colorScheme.primary
                    : colorScheme
                        .outlineVariant,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding:
              const EdgeInsets.only(top: 2),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: completed
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: completed
                  ? colorScheme.onSurface
                  : colorScheme
                      .onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}