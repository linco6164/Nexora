import 'package:flutter/material.dart';

import 'api_service.dart';

import 'package:url_launcher/url_launcher.dart';

import 'addresses_page.dart';

import 'saved_cards_page.dart';

class CheckoutPage extends StatefulWidget {
  final String listingId;

  const CheckoutPage({super.key, required this.listingId});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _loading = true;

  bool _isPaying = false;

  String? _error;

  List<Map<String, dynamic>> _addresses = [];

  String? _selectedAddressId;

  String _deliveryMethod = 'courier';

  String _selectedPaymentMethod = 'card';

  List<Map<String, dynamic>> _savedCards = [];
  String? _selectedCardId;
  Map<String, dynamic>? _checkout;

  @override
  void initState() {
    super.initState();

    _loadAddresses();

    _loadSavedCards();
  }

  Future<void> _loadSavedCards() async {
    try {
      final cards = await ApiService.getSavedCards();
      if (!mounted) return;
      setState(() {
        _savedCards = cards;
        if (cards.isEmpty) {
          _selectedCardId = null;
          return;
        }
        final defaultCard = cards.firstWhere(
          (card) => card['isDefault'] == true,
          orElse: () => cards.first,
        );
        _selectedCardId = defaultCard['_id']?.toString();
      });
    } catch (_) {}
  }

  Future<void> _loadAddresses() async {
    try {
      final addresses = await ApiService.getAddresses();

      if (!mounted) return;

      setState(() {
        _addresses = addresses;

        if (addresses.isNotEmpty) {
          final defaultAddress = addresses.firstWhere(
            (address) => address['isDefault'] == true,

            orElse: () => addresses.first,
          );

          _selectedAddressId = defaultAddress['_id']?.toString();
        }
      });

      if (_selectedAddressId != null) {
        await _loadCheckout();
      } else {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _cleanError(e);

        _loading = false;
      });
    }
  }

  Future<void> _loadCheckout() async {
    final addressId = _selectedAddressId;

    if (addressId == null) return;

    setState(() {
      _loading = true;

      _error = null;
    });

    try {
      final result = await ApiService.getCheckout(
        listingId: widget.listingId,

        addressId: addressId,

        deliveryMethod: _deliveryMethod,
      );

      if (!mounted) return;

      setState(() {
        _checkout = result;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _cleanError(e);

        _loading = false;
      });
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('ApiException: ', '');
  }

  String _formatPrice(dynamic value, String currency) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;

    return '${number.toStringAsFixed(2)} $currency';
  }

  String _addressText(Map<String, dynamic> address) {
    final parts = <String>[];

    final street = address['street']?.toString();

    final number = address['number']?.toString();

    if (street != null && street.isNotEmpty) {
      parts.add(
        '$street${number != null && number.isNotEmpty ? ' $number' : ''}',
      );
    }

    final building = address['building']?.toString();

    if (building != null && building.isNotEmpty) {
      parts.add('Bloc $building');
    }

    final staircase = address['staircase']?.toString();

    if (staircase != null && staircase.isNotEmpty) {
      parts.add('Scara $staircase');
    }

    final floor = address['floor']?.toString();

    if (floor != null && floor.isNotEmpty) {
      parts.add('Etaj $floor');
    }

    final apartment = address['apartment']?.toString();

    if (apartment != null && apartment.isNotEmpty) {
      parts.add('Ap. $apartment');
    }

    final city = address['city']?.toString();

    final county = address['county']?.toString();

    final locality = <String>[];

    if (city != null && city.isNotEmpty) {
      locality.add(city);
    }

    if (county != null && county.isNotEmpty) {
      locality.add(county);
    }

    if (locality.isNotEmpty) {
      parts.add(locality.join(', '));
    }

    final postalCode = address['postalCode']?.toString();

    if (postalCode != null && postalCode.isNotEmpty) {
      parts.add(postalCode);
    }

    return parts.join(', ');
  }

  Map<String, dynamic>? get _price {
    final value = _checkout?['price'];

    if (value is! Map) return null;

    return Map<String, dynamic>.from(value);
  }

  Map<String, dynamic>? get _listing {
    final value = _checkout?['listing'];

    if (value is! Map) return null;

    return Map<String, dynamic>.from(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,

      appBar: AppBar(
        elevation: 0,

        backgroundColor: colors.surface,

        surfaceTintColor: Colors.transparent,

        foregroundColor: colors.onSurface,

        centerTitle: false,

        title: Text(
          'Finalizare comandă',

          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,

            letterSpacing: -0.4,
          ),
        ),
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    if (_loading && _checkout == null) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    if (_error != null && _checkout == null) {
      return _buildError();
    }

    if (_addresses.isEmpty) {
      return _buildNoAddress();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        if (isWide) {
          return _buildWideLayout();
        }

        return _buildMobileLayout();
      },
    );
  }

  Widget _buildMobileLayout() {
    return RefreshIndicator(
      onRefresh: _loadCheckout,

      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),

        children: [
          _buildProductSection(),

          const SizedBox(height: 12),

          _buildAddressSection(),

          const SizedBox(height: 12),

          _buildDeliverySection(),

          const SizedBox(height: 12),

          _buildPaymentSection(),

          const SizedBox(height: 12),

          _buildPriceSection(),

          const SizedBox(height: 20),

          _buildPayButton(),
        ],
      ),
    );
  }

  Widget _buildWideLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),

        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Expanded(
                flex: 3,

                child: Column(
                  children: [
                    _buildProductSection(),

                    const SizedBox(height: 12),

                    _buildAddressSection(),

                    const SizedBox(height: 12),

                    _buildDeliverySection(),

                    const SizedBox(height: 12),

                    _buildPaymentSection(),
                  ],
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                flex: 2,

                child: Column(
                  children: [
                    _buildPriceSection(),

                    const SizedBox(height: 12),

                    _buildPayButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 58,

              height: 58,

              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,

                shape: BoxShape.circle,
              ),

              child: Icon(
                Icons.error_outline_rounded,

                size: 30,

                color: colors.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Nu am putut încărca checkout-ul',

              textAlign: TextAlign.center,

              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _error ?? 'A apărut o eroare.',

              textAlign: TextAlign.center,

              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,

                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            FilledButton(
              onPressed: _loadCheckout,

              child: const Text('Încearcă din nou'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAddress() {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 72,

              height: 72,

              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,

                shape: BoxShape.circle,
              ),

              child: Icon(
                Icons.location_on_outlined,

                size: 34,

                color: colors.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'Adaugă o adresă de livrare',

              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Ai nevoie de o adresă pentru a continua comanda.',

              textAlign: TextAlign.center,

              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,

                height: 1.4,
              ),
            ),

            const SizedBox(height: 22),

            FilledButton.icon(
              onPressed: _openAddresses,

              icon: const Icon(Icons.add_rounded),

              label: const Text('Adaugă adresă'),

              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 50),

                padding: const EdgeInsets.symmetric(horizontal: 22),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSection() {
    final listing = _listing;

    if (listing == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final images = listing['images'] is List
        ? List<String>.from(
            (listing['images'] as List).map((e) => e.toString()),
          )
        : <String>[];

    final currency = listing['currency']?.toString() ?? 'RON';

    return _CheckoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const _SectionTitle(
            icon: Icons.shopping_bag_outlined,

            title: 'Produs',
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              _ProductImage(imageUrl: images.isNotEmpty ? images.first : null),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      listing['title']?.toString() ?? '',

                      maxLines: 2,

                      overflow: TextOverflow.ellipsis,

                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,

                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _formatPrice(listing['price'], currency),

                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,

                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    if (_addresses.isEmpty) {
      return const SizedBox.shrink();
    }

    final selected = _addresses.firstWhere(
      (address) => address['_id']?.toString() == _selectedAddressId,

      orElse: () => _addresses.first,
    );

    return _CheckoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionTitle(
                  icon: Icons.location_on_outlined,

                  title: 'Adresă de livrare',
                ),
              ),

              TextButton(
                onPressed: _showAddressPicker,

                child: const Text(
                  'Schimbă',

                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          _InnerSurface(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const _SmallIconContainer(icon: Icons.location_on_outlined),

                const SizedBox(width: 11),

                Expanded(
                  child: Text(
                    _addressText(selected),

                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(height: 1.45, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySection() {
    return _CheckoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const _SectionTitle(
            icon: Icons.local_shipping_outlined,

            title: 'Detalii livrare',
          ),

          const SizedBox(height: 16),

          _DeliveryOption(
            icon: Icons.local_shipping_outlined,

            title: 'Livrare prin curier',

            subtitle: 'Livrare la adresa selectată',

            price: '14,99 RON',

            selected: _deliveryMethod == 'courier',

            onTap: () {
              if (_deliveryMethod == 'courier') {
                return;
              }

              setState(() {
                _deliveryMethod = 'courier';
              });

              _loadCheckout();
            },
          ),

          const SizedBox(height: 10),

          _DeliveryOption(
            icon: Icons.storefront_outlined,

            title: 'Punct de ridicare',

            subtitle: 'Alege un punct de ridicare',

            price: '11,99 RON',

            selected: _deliveryMethod == 'pickup_point',

            onTap: () {
              if (_deliveryMethod == 'pickup_point') {
                return;
              }

              setState(() {
                _deliveryMethod = 'pickup_point';
              });

              _loadCheckout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _CheckoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionTitle(
                  icon: Icons.payment_outlined,
                  title: 'Plată',
                ),
              ),
              TextButton(
                onPressed: _showPaymentPicker,
                child: const Text(
                  'Schimbă',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InnerSurface(
            child: Row(
              children: [
                _SmallIconContainer(icon: _paymentIcon()),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _paymentTitle(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _paymentSubtitle(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _paymentIcon() {
    switch (_selectedPaymentMethod) {
      case 'google_pay':
        return Icons.account_balance_wallet_outlined;
      case 'apple_pay':
        return Icons.apple;
      default:
        return Icons.credit_card_outlined;
    }
  }

  Map<String, dynamic>? get _selectedSavedCard {
    for (final card in _savedCards) {
      if (card['_id']?.toString() == _selectedCardId) return card;
    }
    return null;
  }

  String _paymentTitle() {
    if (_selectedPaymentMethod == 'google_pay') return 'Google Pay';
    if (_selectedPaymentMethod == 'apple_pay') return 'Apple Pay';
    final card = _selectedSavedCard;
    if (card == null) return 'Card';
    final brand = card['brand']?.toString() ?? 'Card';
    final last4 = card['last4']?.toString() ?? '';
    return last4.isEmpty ? brand : '$brand •••• $last4';
  }

  String _paymentSubtitle() {
    if (_selectedPaymentMethod == 'google_pay')
      return 'Plată rapidă cu Google Pay';
    if (_selectedPaymentMethod == 'apple_pay')
      return 'Plată rapidă cu Apple Pay';
    final card = _selectedSavedCard;
    if (card == null) return 'Alege un card salvat sau adaugă unul nou';
    return card['isDefault'] == true ? 'Card implicit' : 'Card salvat';
  }

  void _showPaymentPicker() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Alege metoda de plată',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_savedCards.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Carduri salvate',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._savedCards.map(
                      (card) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildSavedCardOption(sheetContext, card),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _addCard();
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Adaugă card nou'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.onSurface,
                        side: BorderSide(color: colors.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentMethodOption(
                    sheetContext,
                    Icons.account_balance_wallet_outlined,
                    'Google Pay',
                    'Plată rapidă cu Google Pay',
                    'google_pay',
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentMethodOption(
                    sheetContext,
                    Icons.apple,
                    'Apple Pay',
                    'Plată rapidă cu Apple Pay',
                    'apple_pay',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedCardOption(
    BuildContext sheetContext,
    Map<String, dynamic> card,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final id = card['_id']?.toString();
    final selected = _selectedPaymentMethod == 'card' && id == _selectedCardId;
    final brand = card['brand']?.toString() ?? 'Card';
    final last4 = card['last4']?.toString() ?? '';
    final month = card['expMonth']?.toString();
    final year = card['expYear']?.toString();
    var label = last4.isEmpty ? brand : '$brand •••• $last4';
    if (month != null && year != null && month.isNotEmpty && year.isNotEmpty)
      label += '  •  Exp. $month/$year';

    return Material(
      color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          if (id == null) return;
          setState(() {
            _selectedPaymentMethod = 'card';
            _selectedCardId = id;
          });
          Navigator.pop(sheetContext);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.credit_card_outlined,
                  size: 21,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (card['isDefault'] == true) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Card implicit',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 21,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(
    BuildContext sheetContext,
    IconData icon,
    String title,
    String subtitle,
    String value,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final selected = _selectedPaymentMethod == value;

    return Material(
      color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          setState(() {
            _selectedPaymentMethod = value;
            _selectedCardId = null;
          });
          Navigator.pop(sheetContext);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 21, color: colors.onSurface),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 21,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addCard() async {
     await Navigator.push(
      context,

      MaterialPageRoute(builder: (_) => const SavedCardsPage()),
    );

    if (!mounted) return;

    await _loadSavedCards();
  }

  Widget _buildPriceSection() {
    final price = _price;

    if (price == null) {
      return const SizedBox.shrink();
    }

    final currency = price['currency']?.toString() ?? 'RON';

    return _CheckoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const _SectionTitle(
            icon: Icons.receipt_long_outlined,

            title: 'Detalii preț',
          ),

          const SizedBox(height: 18),

          _PriceRow(
            label: 'Preț produs',

            value: _formatPrice(price['itemPrice'], currency),
          ),

          const SizedBox(height: 12),

          _PriceRow(
            label: 'Protecția cumpărătorului',

            value: _formatPrice(price['buyerProtectionFee'], currency),
          ),

          const SizedBox(height: 12),

          _PriceRow(
            label: 'Expediere',

            value: _formatPrice(price['shippingCost'], currency),
          ),

          const SizedBox(height: 16),

          Divider(
            height: 1,

            color: Theme.of(context).colorScheme.outlineVariant,
          ),

          const SizedBox(height: 16),

          _PriceRow(
            label: 'Total de plată',

            value: _formatPrice(price['total'], currency),

            emphasized: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    final price = _price;

    final currency = price?['currency']?.toString() ?? 'RON';

    final total = price?['total'];

    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return SizedBox(
      width: double.infinity,

      height: 56,

      child: FilledButton(
        onPressed: _isPaying || price == null ? null : _pay,

        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,

          foregroundColor: colors.onPrimary,

          disabledBackgroundColor: colors.surfaceContainerHighest,

          disabledForegroundColor: colors.onSurfaceVariant,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),

        child: _isPaying
            ? SizedBox(
                width: 22,

                height: 22,

                child: CircularProgressIndicator(
                  strokeWidth: 2.2,

                  color: colors.onPrimary,
                ),
              )
            : Text(
                total == null
                    ? 'Plătește'
                    : 'Plătește ${_formatPrice(total, currency)}',

                style: const TextStyle(
                  fontSize: 16,

                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }

  Future<void> _pay() async {
    if (_isPaying) return;

    if (_selectedAddressId == null || _selectedAddressId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selectează o adresă de livrare.')),
      );
      return;
    }

    if (_selectedPaymentMethod == 'card' &&
        (_selectedCardId == null || _selectedCardId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selectează un card salvat.')),
      );
      return;
    }

    setState(() {
      _isPaying = true;
    });

    try {
      final payment = await ApiService.createNetopiaPayment(
        listingId: widget.listingId,
        addressId: _selectedAddressId!,
        deliveryMethod: _deliveryMethod,
        paymentMethod: _selectedPaymentMethod,
        savedCardId: _selectedPaymentMethod == 'card' ? _selectedCardId : null,
      );

      final paymentId = payment['paymentId']?.toString();

      if (paymentId == null || paymentId.isEmpty) {
        throw ApiException('Serverul nu a returnat ID-ul plății.');
      }

      final checkoutUrl =
          'https://api.nx-store.com/payments/netopia/checkout/$paymentId';

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _NetopiaPaymentPage(checkoutUrl: checkoutUrl),
        ),
      );

      if (!mounted) return;

      await _loadCheckout();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException ? error.message : 'Nu am putut iniția plata.',
          ),
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

  Future<void> _openAddresses() async {
    await Navigator.push(
      context,

      MaterialPageRoute(builder: (_) => const AddressesPage()),
    );

    if (!mounted) return;

    await _loadAddresses();
  }

  void _showAddressPicker() {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    showModalBottomSheet<void>(
      context: context,

      backgroundColor: colors.surface,

      showDragHandle: true,

      isScrollControlled: true,

      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),

                  child: Text(
                    'Alege adresa',

                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                ..._addresses.map((address) {
                  final id = address['_id']?.toString();

                  final selected = id == _selectedAddressId;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),

                    child: Material(
                      color: colors.surfaceContainerLow,

                      borderRadius: BorderRadius.circular(15),

                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),

                        onTap: () {
                          Navigator.pop(sheetContext);

                          setState(() {
                            _selectedAddressId = id;
                          });

                          _loadCheckout();
                        },

                        child: Padding(
                          padding: const EdgeInsets.all(14),

                          child: Row(
                            children: [
                              Icon(
                                selected
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_off_rounded,

                                size: 23,

                                color: selected
                                    ? colors.primary
                                    : colors.onSurfaceVariant,
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Text(
                                  _addressText(address),

                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    height: 1.4,

                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 6),

                SizedBox(
                  width: double.infinity,

                  height: 50,

                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);

                      _openAddresses();
                    },

                    icon: const Icon(Icons.add_rounded),

                    label: const Text('Adaugă adresă nouă'),

                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.onSurface,

                      side: BorderSide(color: colors.outline),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CheckoutCard extends StatelessWidget {
  final Widget child;

  const _CheckoutCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.45),
        ),

        boxShadow: theme.brightness == Brightness.dark
            ? null
            : [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.035),

                  blurRadius: 18,

                  offset: const Offset(0, 5),
                ),
              ],
      ),

      child: child,
    );
  }
}

class _InnerSurface extends StatelessWidget {
  final Widget child;

  const _InnerSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,

        borderRadius: BorderRadius.circular(14),
      ),

      child: child,
    );
  }
}

class _SmallIconContainer extends StatelessWidget {
  final IconData icon;

  const _SmallIconContainer({required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 38,

      height: 38,

      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,

        borderRadius: BorderRadius.circular(11),
      ),

      child: Icon(icon, size: 20, color: colors.onSurface),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;

  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 36,

          height: 36,

          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,

            borderRadius: BorderRadius.circular(11),
          ),

          child: Icon(icon, size: 19, color: colors.onSurface),
        ),

        const SizedBox(width: 10),

        Text(
          title,

          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,

            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? imageUrl;

  const _ProductImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 82,

      height: 82,

      clipBehavior: Clip.antiAlias,

      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,

        borderRadius: BorderRadius.circular(14),
      ),

      child: imageUrl == null || imageUrl!.isEmpty
          ? Icon(Icons.image_outlined, size: 28, color: colors.onSurfaceVariant)
          : Image.network(
              imageUrl!,

              fit: BoxFit.cover,

              errorBuilder: (_, __, ___) => Icon(
                Icons.image_outlined,

                size: 28,

                color: colors.onSurfaceVariant,
              ),
            ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;

  final String value;

  final bool emphasized;

  const _PriceRow({
    required this.label,

    required this.value,

    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final style = theme.textTheme.bodyMedium?.copyWith(
      fontSize: emphasized ? 16 : 14,

      fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,

      color: colors.onSurface,
    );

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),

        Text(value, style: style),
      ],
    );
  }
}

class _DeliveryOption extends StatelessWidget {
  final IconData icon;

  final String title;

  final String subtitle;

  final String price;

  final bool selected;

  final VoidCallback onTap;

  const _DeliveryOption({
    required this.icon,

    required this.title,

    required this.subtitle,

    required this.price,

    required this.selected,

    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Material(
      color: selected ? colors.primaryContainer : colors.surfaceContainerLow,

      borderRadius: BorderRadius.circular(15),

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(15),

        child: Container(
          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),

            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,

              width: selected ? 1.4 : 1,
            ),
          ),

          child: Row(
            children: [
              Container(
                width: 40,

                height: 40,

                decoration: BoxDecoration(
                  color: colors.surface,

                  borderRadius: BorderRadius.circular(12),
                ),

                child: Icon(icon, size: 21, color: colors.onSurface),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,

                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,

                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Text(
                price,

                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,

                size: 21,

                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NetopiaPaymentPage extends StatefulWidget {
  final String checkoutUrl;

  const _NetopiaPaymentPage({
    required this.checkoutUrl,
  });

  @override
  State<_NetopiaPaymentPage> createState() =>
      _NetopiaPaymentPageState();
}

class _NetopiaPaymentPageState
    extends State<_NetopiaPaymentPage> {
  bool _opening = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _openPayment();
  }

  Future<void> _openPayment() async {
    try {
      final uri = Uri.parse(
        widget.checkoutUrl,
      );

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception(
          'Nu am putut deschide pagina NETOPIA.',
        );
      }

      if (mounted) {
        setState(() {
          _opening = false;
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _opening = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Plată NETOPIA',
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              if (_opening) ...[
                const CircularProgressIndicator(),

                const SizedBox(height: 24),

                const Text(
                  'Se deschide pagina de plată...',
                  textAlign: TextAlign.center,
                ),
              ] else if (_error != null) ...[
                const Icon(
                  Icons.error_outline,
                  size: 56,
                  color: Colors.red,
                ),

                const SizedBox(height: 16),

                Text(
                  _error!,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                FilledButton(
                  onPressed: _openPayment,
                  child: const Text(
                    'Încearcă din nou',
                  ),
                ),
              ] else ...[
                const Icon(
                  Icons.credit_card,
                  size: 56,
                ),

                const SizedBox(height: 16),

                const Text(
                  'Pagina NETOPIA a fost deschisă.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                const Text(
                  'Finalizează plata în pagina deschisă, apoi revino în aplicație.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 28),

                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Am terminat plata',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
