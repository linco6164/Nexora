import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';
import 'HomePage.dart';

class SellPage extends StatefulWidget {
  const SellPage({super.key});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _cityController = TextEditingController();
  final _brandController = TextEditingController();

  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  String _category = 'Îmbrăcăminte';
  String _condition = 'good';

  bool _negotiable = false;
  bool _shipping = true;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Îmbrăcăminte',
    'Încălțăminte',
    'Accesorii',
    'Electronice',
    'Casă și grădină',
    'Altele',
  ];

  final Map<String, String> _conditions = {
    'new': 'Nou',
    'like_new': 'Ca nou',
    'good': 'Bună',
    'fair': 'Acceptabilă',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _cityController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(
      imageQuality: 80,
    );

    if (picked.isEmpty) return;

    setState(() {
      _selectedImages.addAll(
        picked.map((x) => File(x.path)),
      );

      if (_selectedImages.length > 10) {
        _selectedImages.removeRange(
          10,
          _selectedImages.length,
        );
      }
    });
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adaugă cel puțin o imagine'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final imageUrls = await ApiService.uploadImages(
        _selectedImages,
        folder: 'listings',
      );

      await ApiService.createListing(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        condition: _condition,
        price: double.parse(
          _priceController.text.trim(),
        ),
        city: _cityController.text.trim(),
        images: imageUrls,
        negotiable: _negotiable,
        shipping: _shipping,
        brand: _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anunț publicat cu succes!'),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eroare: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text(
          'Postează un anunț',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            32,
          ),
          children: [
            _buildPhotosSection(),

            const SizedBox(height: 24),

            _buildSectionTitle(
              'Informații despre produs',
              Icons.sell_outlined,
            ),

            const SizedBox(height: 12),

            _buildTextField(
              controller: _titleController,
              label: 'Titlu anunț',
              hint: 'Ex. Geacă Nike neagră',
              icon: Icons.title_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Introdu un titlu';
                }

                if (value.trim().length < 3) {
                  return 'Titlul trebuie să aibă cel puțin 3 caractere';
                }

                return null;
              },
            ),

            const SizedBox(height: 14),

            _buildTextField(
              controller: _descriptionController,
              label: 'Descriere',
              hint: 'Descrie produsul, starea lui și eventualele detalii...',
              icon: Icons.notes_outlined,
              maxLines: 5,
              maxLength: 1000,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Adaugă o descriere';
                }

                return null;
              },
            ),

            const SizedBox(height: 14),

            _buildDropdown(
              label: 'Categorie',
              icon: Icons.category_outlined,
              value: _category,
              items: _categories,
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _category = value;
                });
              },
            ),

            const SizedBox(height: 14),

            _buildConditionSelector(),

            const SizedBox(height: 24),

            _buildSectionTitle(
              'Preț și livrare',
              Icons.payments_outlined,
            ),

            const SizedBox(height: 12),

            _buildTextField(
              controller: _priceController,
              label: 'Preț',
              hint: '0,00',
              icon: Icons.payments_outlined,
              suffixText: 'RON',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Introdu prețul';
                }

                final price = double.tryParse(
                  value.trim().replaceAll(',', '.'),
                );

                if (price == null) {
                  return 'Preț invalid';
                }

                if (price <= 0) {
                  return 'Prețul trebuie să fie mai mare decât 0';
                }

                return null;
              },
            ),

            const SizedBox(height: 14),

            _buildTextField(
              controller: _brandController,
              label: 'Brand',
              hint: 'Ex. Nike, Adidas, Apple...',
              icon: Icons.local_offer_outlined,
              optional: true,
            ),

            const SizedBox(height: 14),

            _buildTextField(
              controller: _cityController,
              label: 'Oraș',
              hint: 'Ex. Călărași',
              icon: Icons.location_on_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Introdu orașul';
                }

                return null;
              },
            ),

            const SizedBox(height: 12),

            _buildOptionTile(
              icon: Icons.handshake_outlined,
              title: 'Preț negociabil',
              subtitle: 'Permite cumpărătorilor să îți trimită oferte',
              value: _negotiable,
              onChanged: (value) {
                setState(() {
                  _negotiable = value;
                });
              },
            ),

            const SizedBox(height: 10),

            _buildOptionTile(
              icon: Icons.local_shipping_outlined,
              title: 'Livrare disponibilă',
              subtitle: 'Permite livrarea produsului către cumpărător',
              value: _shipping,
              onChanged: (value) {
                setState(() {
                  _shipping = value;
                });
              },
            ),

            const SizedBox(height: 28),

            _buildPublishButton(),

            const SizedBox(height: 12),

            Center(
              child: Text(
                'Prin publicare, anunțul tău va deveni vizibil pe Nexora.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Fotografii',
          Icons.photo_library_outlined,
        ),

        const SizedBox(height: 4),

        Text(
          'Adaugă până la 10 fotografii',
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          height: 128,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._selectedImages.asMap().entries.map(
                (entry) {
                  final index = entry.key;
                  final file = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(
                      right: 10,
                    ),
                    child: _buildImagePreview(
                      file,
                      index,
                    ),
                  );
                },
              ),

              if (_selectedImages.length < 10)
                _buildAddPhotoButton(),
            ],
          ),
        ),

        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '${_selectedImages.length}/10 fotografii',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImagePreview(
    File file,
    int index,
  ) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            file,
            width: 128,
            height: 128,
            fit: BoxFit.cover,
          ),
        ),

        Positioned(
          top: 7,
          right: 7,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),

        if (index == 0)
          Positioned(
            left: 7,
            bottom: 7,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Principală',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 128,
        height: 128,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withOpacity(0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 30,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'Adaugă poze',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 19,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? suffixText,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    bool optional = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        labelText: optional ? '$label (opțional)' : label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixText: suffixText,
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant,
          ),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildConditionSelector() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 21,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 10),
              const Text(
                'Starea produsului',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _conditions.entries.map(
              (entry) {
                final selected = _condition == entry.key;

                return ChoiceChip(
                  label: Text(entry.value),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _condition = entry.key;
                    });
                  },
                  showCheckmark: false,
                  avatar: selected
                      ? const Icon(
                          Icons.check,
                          size: 17,
                        )
                      : null,
                );
              },
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 4,
        ),
        secondary: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: value
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: value
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildPublishButton() {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: _isSubmitting ? null : _handleSubmit,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.publish_outlined,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Publică anunțul',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}