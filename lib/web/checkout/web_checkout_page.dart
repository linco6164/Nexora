import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api_service.dart';

import '../legal/terms_page.dart';
import '../legal/privacy_page.dart';

class WebCheckoutPage extends StatefulWidget {
  final String listingId;

  const WebCheckoutPage({super.key, required this.listingId});

  @override
  State<WebCheckoutPage> createState() => _WebCheckoutPageState();
}

class _WebCheckoutPageState extends State<WebCheckoutPage> {
  List<Map<String, dynamic>> _addresses = [];

  String? _selectedAddressId;

  String? _delivery;
  String _payment = 'card';

  bool _isPaying = false;

  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countyController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _loadCheckout();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _countyController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  double get deliveryPrice {
    switch (_delivery) {
      case 'fan':
        return 22;
      case 'gls':
        return 20;
      default:
        return 19;
    }
  }

  final double productPrice = 149;

  double get total => productPrice + deliveryPrice;

  Future<void> _openAddAddress() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _CheckoutAddressForm();
      },
    );

    if (result == true) {
      await _loadCheckout();
    }
  }

  Future<void> _loadCheckout() async {
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

          _selectedAddressId =
              defaultAddress['_id']?.toString() ??
              defaultAddress['id']?.toString();
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException ? e.message : 'Nu am putut încărca adresele.',
          ),
        ),
      );
    }
  }

  Future<void> _submitOrder() async {
    if (_isPaying) return;

    if (_selectedAddressId == null || _selectedAddressId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selectează o adresă de livrare.')),
      );
      return;
    }

    if (!_acceptedTerms || !_acceptedPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Trebuie să accepți Termenii și condițiile și Politica de confidențialitate.',
          ),
        ),
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
        deliveryMethod: _delivery,
        paymentMethod: _payment,
      );

      final paymentId = payment['paymentId']?.toString();

      if (paymentId == null || paymentId.isEmpty) {
        throw ApiException('Serverul nu a returnat ID-ul plății.');
      }

      final checkoutUrl =
          '${ApiService.baseUrl}'
          '/payments/netopia/checkout/$paymentId';

      final uri = Uri.parse(checkoutUrl);

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) {
          return AlertDialog(
            title: const Text('Plata este pregătită'),
            content: const Text(
              'Vei fi redirecționat către '
              'NETOPIA Payments pentru a finaliza plata cu cardul.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Anulează'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _openPayment(uri);
                },
                child: const Text('Continuă plata'),
              ),
            ],
          );
        },
      );
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

  Future<void> _openPayment(Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nu am putut deschide pagina NETOPIA.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 42),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Finalizare comandă',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -1,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Completează datele pentru livrare și plată.',
                    style: TextStyle(
                      fontSize: 15,
                      color: theme.colorScheme.onSurface.withValues(alpha: .58),
                    ),
                  ),

                  const SizedBox(height: 36),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: Column(
                          children: [
                            _buildDeliveryAddress(context),

                            const SizedBox(height: 24),

                            _buildDeliveryMethod(context),

                            const SizedBox(height: 24),

                            _buildPaymentMethod(context),
                          ],
                        ),
                      ),

                      const SizedBox(width: 24),

                      SizedBox(width: 340, child: _buildSummary(context)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, Widget child) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: .18)),
      ),
      child: child,
    );
  }

  Widget _title(BuildContext context, String title, String subtitle) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: .55),
          ),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).colorScheme.onSurface
            .withValues(alpha: .035),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryAddress(BuildContext context) {
    final theme = Theme.of(context);

    return _card(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(
            context,
            'Adresa de livrare',
            'Selectează adresa la care vrei să primești comanda.',
          ),

          const SizedBox(height: 20),

          if (_addresses.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: .06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: .20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Nu ai încă nicio adresă salvată.',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _addresses.map((address) {
                final addressId =
                    address['_id']?.toString() ?? address['id']?.toString();

                final selected = addressId == _selectedAddressId;

                final county = address['county']?.toString() ?? '';

                final city = address['city']?.toString() ?? '';

                final street = address['street']?.toString() ?? '';

                final number = address['number']?.toString() ?? '';

                final postalCode = address['postalCode']?.toString() ?? '';

                final isDefault = address['isDefault'] == true;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: addressId == null
                        ? null
                        : () {
                            setState(() {
                              _selectedAddressId = addressId;
                            });
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.colorScheme.primary.withValues(alpha: .07)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.dividerColor.withValues(alpha: .18),
                          width: selected ? 1.4 : 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: selected
                                  ? theme.colorScheme.primary.withValues(
                                      alpha: .12,
                                    )
                                  : theme.colorScheme.onSurface.withValues(
                                      alpha: .05,
                                    ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.location_on_outlined,
                              color: selected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withValues(
                                      alpha: .55,
                                    ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$street $number',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),

                                    if (isDefault)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: .10),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          'Implicită',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  '$city, $county',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: .62),
                                  ),
                                ),

                                if (postalCode.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    'Cod poștal: $postalCode',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: .48),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          Radio<String>(
                            value: addressId ?? '',
                            groupValue: _selectedAddressId,
                            onChanged: addressId == null
                                ? null
                                : (value) {
                                    if (value == null) {
                                      return;
                                    }

                                    setState(() {
                                      _selectedAddressId = value;
                                    });
                                  },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 4),

          OutlinedButton.icon(
            onPressed: _openAddAddress,
            icon: const Icon(Icons.add_rounded, size: 19),
            label: const Text('Adaugă o adresă nouă'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _deliveryOption(
    BuildContext context, {
    required String value,
    required String title,
    required String subtitle,
    required double price,
  }) {
    final theme = Theme.of(context);
    final selected = _delivery == value;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() {
          _delivery = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: .07)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: .18),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _delivery,
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _delivery = v;
                });
              },
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: .52),
                    ),
                  ),
                ],
              ),
            ),

            Text(
              '${price.toStringAsFixed(2)} lei',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryMethod(BuildContext context) {
    return _card(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(
            context,
            'Metoda de livrare',
            'Alege curierul pentru această comandă.',
          ),

          const SizedBox(height: 18),

          _deliveryOption(
            context,
            value: 'sameday',
            title: 'Sameday',
            subtitle: 'Livrare rapidă prin Sameday',
            price: 19,
          ),

          const SizedBox(height: 10),

          _deliveryOption(
            context,
            value: 'fan',
            title: 'FAN Courier',
            subtitle: 'Livrare prin FAN Courier',
            price: 22,
          ),

          const SizedBox(height: 10),

          _deliveryOption(
            context,
            value: 'gls',
            title: 'GLS',
            subtitle: 'Livrare prin GLS',
            price: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(BuildContext context) {
    final theme = Theme.of(context);

    return _card(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(context, 'Metoda de plată', 'Plătește online în siguranță.'),

          const SizedBox(height: 18),

          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() {
                _payment = 'card';
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: .06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: .55),
                ),
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: 'card',
                    groupValue: _payment,
                    onChanged: (value) {
                      setState(() {
                        _payment = value ?? 'netopia';
                      });
                    },
                  ),

                  const Icon(Icons.credit_card_rounded, size: 24),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Card bancar',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Procesat securizat prin NETOPIA Payments',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  Image.asset(
                    'assets/payments/netopia_payments_logo.png',
                    width: 115,
                    height: 55,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalAcceptance(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withValues(alpha: .18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: _acceptedTerms,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (value) {
              setState(() {
                _acceptedTerms = value ?? false;
              });
            },
            title: Wrap(
              children: [
                const Text(
                  'Am citit și accept ',
                  style: TextStyle(fontSize: 12.5),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TermsPage()),
                    );
                  },
                  child: Text(
                    'Termenii și condițiile',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const Text('.', style: TextStyle(fontSize: 12.5)),
              ],
            ),
          ),

          CheckboxListTile(
            value: _acceptedPrivacy,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (value) {
              setState(() {
                _acceptedPrivacy = value ?? false;
              });
            },
            title: Wrap(
              children: [
                const Text(
                  'Am citit și accept ',
                  style: TextStyle(fontSize: 12.5),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PrivacyPage()),
                    );
                  },
                  child: Text(
                    'Politica de confidențialitate',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const Text('.', style: TextStyle(fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    final theme = Theme.of(context);

    return _card(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sumar comandă',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: .05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.image_outlined),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Text(
                  'Produs Nexora',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),

              Text(
                '${productPrice.toStringAsFixed(2)} lei',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Divider(color: theme.dividerColor.withValues(alpha: .18)),

          const SizedBox(height: 16),

          _summaryRow(
            context,
            'Subtotal',
            '${productPrice.toStringAsFixed(2)} lei',
          ),

          const SizedBox(height: 10),

          _summaryRow(
            context,
            'Livrare',
            '${deliveryPrice.toStringAsFixed(2)} lei',
          ),

          const SizedBox(height: 16),

          Divider(color: theme.dividerColor.withValues(alpha: .18)),

          const SizedBox(height: 16),

          _summaryRow(
            context,
            'Total',
            '${total.toStringAsFixed(2)} lei',
            bold: true,
          ),

          const SizedBox(height: 22),

          _buildLegalAcceptance(context),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submitOrder,
              icon: const Icon(Icons.lock_rounded, size: 18),
              label: const Text('Plătește și finalizează'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Center(
            child: Text(
              'Plata este procesată securizat.',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: .45),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 16 : 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            color: theme.colorScheme.onSurface.withValues(
              alpha: bold ? 1 : .58,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 18 : 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CheckoutAddressForm extends StatefulWidget {
  const _CheckoutAddressForm();

  @override
  State<_CheckoutAddressForm> createState() => _CheckoutAddressFormState();
}

class _CheckoutAddressFormState extends State<_CheckoutAddressForm> {
  final _formKey = GlobalKey<FormState>();

  final _countyController = TextEditingController();
  final _cityController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _postalCodeController = TextEditingController();

  bool _isDefault = false;
  bool _saving = false;

  @override
  void dispose() {
    _countyController.dispose();
    _cityController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _postalCodeController.dispose();

    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Câmp obligatoriu';
    }

    return null;
  }

  InputDecoration _inputDecoration(
    BuildContext context,
    String label,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: theme.colorScheme.onSurface.withValues(alpha: .035),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.3),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await ApiService.createAddress(
        county: _countyController.text.trim(),
        city: _cityController.text.trim(),
        street: _streetController.text.trim(),
        number: _numberController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        isDefault: _isDefault,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException ? e.message : 'Nu am putut salva adresa.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final keyboard = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: const BoxConstraints(maxWidth: 650),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 18, 24, keyboard + 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: .20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  'Adaugă o adresă nouă',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),

                const SizedBox(height: 6),

                Text(
                  'Completează datele pentru livrare.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: .55),
                  ),
                ),

                const SizedBox(height: 24),

                TextFormField(
                  controller: _countyController,
                  validator: _required,
                  decoration: _inputDecoration(
                    context,
                    'Județ',
                    Icons.map_outlined,
                  ),
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _cityController,
                  validator: _required,
                  decoration: _inputDecoration(
                    context,
                    'Localitate',
                    Icons.location_city_outlined,
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _streetController,
                        validator: _required,
                        decoration: _inputDecoration(
                          context,
                          'Stradă',
                          Icons.signpost_outlined,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _numberController,
                        validator: _required,
                        decoration: _inputDecoration(
                          context,
                          'Nr.',
                          Icons.tag_rounded,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _postalCodeController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    context,
                    'Cod poștal',
                    Icons.mail_outlined,
                  ),
                ),

                const SizedBox(height: 10),

                CheckboxListTile(
                  value: _isDefault,
                  onChanged: (value) {
                    setState(() {
                      _isDefault = value ?? false;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'Folosește ca adresă implicită',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Se salvează...' : 'Salvează adresa'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
