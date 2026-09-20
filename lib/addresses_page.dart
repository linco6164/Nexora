import 'package:flutter/material.dart';

import 'api_service.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _addresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final addresses = await ApiService.getAddresses();

      if (!mounted) return;

      setState(() {
        _addresses = addresses;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  Future<void> _deleteAddress(
    Map<String, dynamic> address,
  ) async {
    final id = address['_id']?.toString();

    if (id == null || id.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Șterge adresa'),
          content: const Text(
            'Sigur vrei să ștergi această adresă?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Anulează'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Șterge',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteAddress(id);

      if (!mounted) return;

      await _loadAddresses();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adresa a fost ștearsă.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  Future<void> _setDefaultAddress(
    Map<String, dynamic> address,
  ) async {
    final id = address['_id']?.toString();

    if (id == null || id.isEmpty) return;

    try {
      await ApiService.setDefaultAddress(id);

      if (!mounted) return;

      await _loadAddresses();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Adresa implicită a fost actualizată.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  Future<void> _openAddressForm({
    Map<String, dynamic>? address,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _AddressFormSheet(
          address: address,
        );
      },
    );

    if (result == true && mounted) {
      await _loadAddresses();
    }
  }

  String _buildAddressLine(
    Map<String, dynamic> address,
  ) {
    final street = address['street']?.toString() ?? '';
    final number = address['number']?.toString() ?? '';
    final building = address['building']?.toString() ?? '';
    final staircase = address['staircase']?.toString() ?? '';
    final floor = address['floor']?.toString() ?? '';
    final apartment = address['apartment']?.toString() ?? '';

    final parts = <String>[];

    if (street.isNotEmpty) {
      parts.add('Str. $street');
    }

    if (number.isNotEmpty) {
      parts.add('nr. $number');
    }

    if (building.isNotEmpty) {
      parts.add('bl. $building');
    }

    if (staircase.isNotEmpty) {
      parts.add('sc. $staircase');
    }

    if (floor.isNotEmpty) {
      parts.add('et. $floor');
    }

    if (apartment.isNotEmpty) {
      parts.add('ap. $apartment');
    }

    return parts.join(', ');
  }

  String _buildCityLine(
    Map<String, dynamic> address,
  ) {
    final city = address['city']?.toString() ?? '';
    final county = address['county']?.toString() ?? '';
    final postalCode =
        address['postalCode']?.toString() ?? '';

    final parts = <String>[];

    if (city.isNotEmpty) {
      parts.add(city);
    }

    if (county.isNotEmpty) {
      parts.add(county);
    }

    if (postalCode.isNotEmpty) {
      parts.add(postalCode);
    }

    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adrese salvate'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadAddresses,
              child: _addresses.isEmpty
                  ? ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      children: [
                        const SizedBox(height: 100),
                        Icon(
                          Icons.location_on_outlined,
                          size: 72,
                          color: Theme.of(context)
                              .colorScheme
                              .primary,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Nu ai nicio adresă salvată',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Adaugă o adresă pentru a face cumpărăturile și livrările mai rapide.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 28),
                        FilledButton.icon(
                          onPressed: _openAddressForm,
                          icon: const Icon(Icons.add),
                          label: const Text(
                            'Adaugă adresă',
                          ),
                          style: FilledButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        32,
                      ),
                      children: [
                        ..._addresses.map(
                          (address) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(
                                bottom: 12,
                              ),
                              child: _AddressCard(
                                address: address,
                                addressLine:
                                    _buildAddressLine(
                                  address,
                                ),
                                cityLine:
                                    _buildCityLine(
                                  address,
                                ),
                                onEdit: () {
                                  _openAddressForm(
                                    address: address,
                                  );
                                },
                                onDelete: () {
                                  _deleteAddress(
                                    address,
                                  );
                                },
                                onSetDefault: () {
                                  _setDefaultAddress(
                                    address,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _openAddressForm,
                          icon: const Icon(Icons.add),
                          label: const Text(
                            'Adaugă adresă',
                          ),
                          style:
                              OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }
}

// ============================================================
// ADDRESS CARD
// ============================================================

class _AddressCard extends StatelessWidget {
  final Map<String, dynamic> address;
  final String addressLine;
  final String cityLine;

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _AddressCard({
    required this.address,
    required this.addressLine,
    required this.cityLine,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    final isDefault =
        address['isDefault'] == true;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surface,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: isDefault
              ? Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Adresă de livrare',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isDefault)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Implicită',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .primary,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            if (addressLine.isNotEmpty)
              Text(
                addressLine,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

            if (cityLine.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                cityLine,
                style: TextStyle(
                  color: Colors.grey[700],
                ),
              ),
            ],

            const SizedBox(height: 14),

            Row(
              children: [
                if (!isDefault)
                  TextButton.icon(
                    onPressed: onSetDefault,
                    icon: const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                    ),
                    label: const Text(
                      'Implicită',
                    ),
                  ),

                const Spacer(),

                IconButton(
                  onPressed: onEdit,
                  tooltip: 'Editează',
                  icon: const Icon(
                    Icons.edit_outlined,
                  ),
                ),

                IconButton(
                  onPressed: onDelete,
                  tooltip: 'Șterge',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ADDRESS FORM
// ============================================================

class _AddressFormSheet extends StatefulWidget {
  final Map<String, dynamic>? address;

  const _AddressFormSheet({
    this.address,
  });

  @override
  State<_AddressFormSheet> createState() =>
      _AddressFormSheetState();
}

class _AddressFormSheetState
    extends State<_AddressFormSheet> {
  final _formKey =
      GlobalKey<FormState>();

  late final TextEditingController
      _countyController;

  late final TextEditingController
      _cityController;

  late final TextEditingController
      _streetController;

  late final TextEditingController
      _numberController;

  late final TextEditingController
      _buildingController;

  late final TextEditingController
      _staircaseController;

  late final TextEditingController
      _floorController;

  late final TextEditingController
      _apartmentController;

  late final TextEditingController
      _postalCodeController;

  bool _isDefault = false;
  bool _isSaving = false;

  bool get _isEditing =>
      widget.address != null;

  @override
  void initState() {
    super.initState();

    final address = widget.address;

    _countyController =
        TextEditingController(
      text:
          address?['county']?.toString() ?? '',
    );

    _cityController =
        TextEditingController(
      text:
          address?['city']?.toString() ?? '',
    );

    _streetController =
        TextEditingController(
      text:
          address?['street']?.toString() ?? '',
    );

    _numberController =
        TextEditingController(
      text:
          address?['number']?.toString() ?? '',
    );

    _buildingController =
        TextEditingController(
      text:
          address?['building']?.toString() ?? '',
    );

    _staircaseController =
        TextEditingController(
      text:
          address?['staircase']?.toString() ?? '',
    );

    _floorController =
        TextEditingController(
      text:
          address?['floor']?.toString() ?? '',
    );

    _apartmentController =
        TextEditingController(
      text:
          address?['apartment']?.toString() ?? '',
    );

    _postalCodeController =
        TextEditingController(
      text:
          address?['postalCode']?.toString() ?? '',
    );

    _isDefault =
        address?['isDefault'] == true;
  }

  @override
  void dispose() {
    _countyController.dispose();
    _cityController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _buildingController.dispose();
    _staircaseController.dispose();
    _floorController.dispose();
    _apartmentController.dispose();
    _postalCodeController.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_isEditing) {
        final id =
            widget.address!['_id']?.toString();

        if (id == null || id.isEmpty) {
          throw ApiException(
            'ID-ul adresei lipsește.',
          );
        }

        await ApiService.updateAddress(
          addressId: id,
          county:
              _countyController.text.trim(),
          city:
              _cityController.text.trim(),
          street:
              _streetController.text.trim(),
          number:
              _numberController.text.trim(),
          building:
              _buildingController.text.trim(),
          staircase:
              _staircaseController.text.trim(),
          floor:
              _floorController.text.trim(),
          apartment:
              _apartmentController.text.trim(),
          postalCode:
              _postalCodeController.text.trim(),
          isDefault: _isDefault,
        );
      } else {
        await ApiService.createAddress(
          county:
              _countyController.text.trim(),
          city:
              _cityController.text.trim(),
          street:
              _streetController.text.trim(),
          number:
              _numberController.text.trim(),
          building:
              _buildingController.text.trim(),
          staircase:
              _staircaseController.text.trim(),
          floor:
              _floorController.text.trim(),
          apartment:
              _apartmentController.text.trim(),
          postalCode:
              _postalCodeController.text.trim(),
          isDefault: _isDefault,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  InputDecoration _decoration(
    String label, {
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon:
          icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context)
              .colorScheme
              .primary,
          width: 2,
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Câmp obligatoriu';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bottom =
        MediaQuery.of(context)
            .viewInsets
            .bottom;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .scaffoldBackgroundColor,
        borderRadius:
            const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration:
                        BoxDecoration(
                      color: Colors.grey
                          .withValues(alpha: 0.3),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  _isEditing
                      ? 'Editează adresa'
                      : 'Adaugă adresă',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller:
                            _countyController,
                        decoration:
                            _decoration(
                          'Județ',
                          icon: Icons
                              .map_outlined,
                        ),
                        validator:
                            _required,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller:
                            _cityController,
                        decoration:
                            _decoration(
                          'Oraș',
                          icon: Icons
                              .location_city_outlined,
                        ),
                        validator:
                            _required,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller:
                            _streetController,
                        decoration:
                            _decoration(
                          'Stradă',
                          icon: Icons
                              .signpost_outlined,
                        ),
                        validator:
                            _required,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller:
                            _numberController,
                        decoration:
                            _decoration('Nr.'),
                        validator:
                            _required,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller:
                            _buildingController,
                        decoration:
                            _decoration('Bloc'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller:
                            _staircaseController,
                        decoration:
                            _decoration('Scară'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller:
                            _floorController,
                        keyboardType:
                            TextInputType.number,
                        decoration:
                            _decoration('Etaj'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller:
                            _apartmentController,
                        keyboardType:
                            TextInputType.number,
                        decoration:
                            _decoration(
                          'Apartament',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller:
                      _postalCodeController,
                  keyboardType:
                      TextInputType.number,
                  decoration:
                      _decoration(
                    'Cod poștal',
                    icon: Icons
                        .markunread_mailbox_outlined,
                  ),
                ),

                const SizedBox(height: 8),

                SwitchListTile(
                  contentPadding:
                      EdgeInsets.zero,
                  title: const Text(
                    'Adresă implicită',
                  ),
                  subtitle: const Text(
                    'Va fi folosită implicit pentru livrări.',
                  ),
                  value: _isDefault,
                  onChanged: (value) {
                    setState(() {
                      _isDefault = value;
                    });
                  },
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed:
                        _isSaving ? null : _save,
                    style:
                        FilledButton.styleFrom(
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEditing
                                ? 'Salvează modificările'
                                : 'Adaugă adresa',
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