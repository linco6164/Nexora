import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';
import 'app_feedback.dart';
import 'catalog/category_catalog.dart';
import 'home_page.dart';
import 'l10n/app_locale.dart';
import 'models/listing.dart';

class SellPage extends StatefulWidget {
  final bool embedded;
  final VoidCallback? onPublished;
  final Listing? listing;

  const SellPage({
    super.key,
    this.embedded = false,
    this.onPublished,
    this.listing,
  });

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  final _detailsFormKey = GlobalKey<FormState>();
  final _priceFormKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _cityController = TextEditingController();
  final _brandController = TextEditingController();
  final _sizeController = TextEditingController();
  final _colorController = TextEditingController();
  final _materialController = TextEditingController();
  final _picker = ImagePicker();
  final List<_SelectedImage> _selectedImages = [];
  final List<String> _existingImages = [];

  int _currentStep = 0;
  String _category = listingCategoryCatalog.first.slug;
  late String _subcategory = listingCategoryCatalog.first.children.first.slug;
  late String _categoryDetail =
      listingCategoryCatalog.first.children.first.children.first.slug;
  String _condition = 'good';
  bool _negotiable = false;
  bool _shipping = true;
  bool _isSubmitting = false;

  bool get _isEditing => widget.listing != null;
  int get _imageCount => _existingImages.length + _selectedImages.length;

  static const _conditions = {
    'new': 'Nou',
    'like_new': 'Ca nou',
    'good': 'Bună',
    'fair': 'Acceptabilă',
  };

  String get _language => appLocaleController.value;
  CategoryNode get _categoryNode => categoryBySlug(_category);
  CategoryNode get _subcategoryNode => _categoryNode.children.firstWhere(
    (node) => node.slug == _subcategory,
    orElse: () => _categoryNode.children.first,
  );
  CategoryNode get _detailNode => _subcategoryNode.children.firstWhere(
    (node) => node.slug == _categoryDetail,
    orElse: () => _subcategoryNode.children.first,
  );

  @override
  void initState() {
    super.initState();
    final listing = widget.listing;
    if (listing == null) return;

    _titleController.text = listing.title;
    _descriptionController.text = listing.description;
    _priceController.text = listing.price.toStringAsFixed(2);
    _cityController.text = listing.city;
    _brandController.text = listing.brand ?? '';
    _sizeController.text = listing.size ?? '';
    _colorController.text = listing.color ?? '';
    _materialController.text = listing.material ?? '';
    _existingImages.addAll(listing.images);
    _negotiable = listing.negotiable;
    _shipping = listing.shipping;
    if (_conditions.containsKey(listing.condition)) {
      _condition = listing.condition;
    }

    final category = findCategoryBySlug(listing.category);
    if (category == null) return;
    _category = category.slug;

    final subcategory = category.children.firstWhere(
      (node) => node.slug == listing.subcategory,
      orElse: () => category.children.first,
    );
    _subcategory = subcategory.slug;

    final detail = subcategory.children.firstWhere(
      (node) => node.slug == listing.categoryDetail,
      orElse: () => subcategory.children.first,
    );
    _categoryDetail = detail.slug;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _cityController.dispose();
    _brandController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    _materialController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 80);
    if (files.isEmpty) return;
    final images = await Future.wait(
      files.map(
        (file) async =>
            _SelectedImage(file: file, bytes: await file.readAsBytes()),
      ),
    );
    if (!mounted) return;
    setState(() {
      _selectedImages.addAll(images);
      final allowedNewImages = 10 - _existingImages.length;
      if (_selectedImages.length > allowedNewImages) {
        _selectedImages.removeRange(allowedNewImages, _selectedImages.length);
      }
    });
  }

  void _message(String text, {AppFeedbackType type = AppFeedbackType.warning}) {
    switch (type) {
      case AppFeedbackType.success:
        AppFeedback.success(context, text);
        break;
      case AppFeedbackType.error:
        AppFeedback.error(context, text);
        break;
      case AppFeedbackType.info:
      case AppFeedbackType.notification:
        AppFeedback.info(context, text);
        break;
      case AppFeedbackType.warning:
        AppFeedback.warning(context, text);
        break;
    }
  }

  bool _validateStep() {
    if (_currentStep == 0 && _imageCount == 0) {
      _message(context.tr('Adaugă cel puțin o imagine'));
      return false;
    }
    if (_currentStep == 1) {
      return _detailsFormKey.currentState?.validate() ?? false;
    }
    if (_currentStep == 2) {
      return _priceFormKey.currentState?.validate() ?? false;
    }
    return true;
  }

  void _continue() {
    if (!_validateStep()) {
      if (_currentStep > 0) {
        _message(
          context.tr('Completează câmpurile obligatorii pentru a continua.'),
        );
      }
      return;
    }
    if (_currentStep < 3) setState(() => _currentStep++);
  }

  String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _publish() async {
    if (_imageCount == 0 ||
        _titleController.text.trim().length < 3 ||
        _descriptionController.text.trim().length < 20 ||
        _cityController.text.trim().isEmpty) {
      _message(
        context.tr('Completează câmpurile obligatorii pentru a continua.'),
      );
      return;
    }
    final price = double.tryParse(
      _priceController.text.trim().replaceAll(',', '.'),
    );
    if (price == null || price <= 0) {
      _message(context.tr('Preț invalid'));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final uploadedImages = _selectedImages.isEmpty
          ? <String>[]
          : await ApiService.uploadXFiles(
              _selectedImages.map((image) => image.file).toList(),
              folder: 'listings',
            );
      final imageUrls = [..._existingImages, ...uploadedImages];

      if (_isEditing) {
        await ApiService.updateListing(
          listingId: widget.listing!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _category,
          subcategory: _subcategory,
          categoryDetail: _categoryDetail,
          condition: _condition,
          price: price,
          city: _cityController.text.trim(),
          images: imageUrls,
          negotiable: _negotiable,
          shipping: _shipping,
          brand: _optional(_brandController),
          size: _optional(_sizeController),
          color: _optional(_colorController),
          material: _optional(_materialController),
        );
      } else {
        await ApiService.createListing(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _category,
          subcategory: _subcategory,
          categoryDetail: _categoryDetail,
          condition: _condition,
          price: price,
          city: _cityController.text.trim(),
          images: imageUrls,
          negotiable: _negotiable,
          shipping: _shipping,
          brand: _optional(_brandController),
          size: _optional(_sizeController),
          color: _optional(_colorController),
          material: _optional(_materialController),
        );
      }
      if (!mounted) return;
      _message(
        context.tr(
          _isEditing
              ? 'Anunț actualizat cu succes!'
              : 'Anunț publicat cu succes!',
        ),
        type: AppFeedbackType.success,
      );
      if (_isEditing) {
        Navigator.of(context).pop(true);
        return;
      }
      if (widget.onPublished != null) {
        widget.onPublished!();
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (_) => false,
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        _message(error.message, type: AppFeedbackType.error);
      }
    } catch (error) {
      if (mounted) {
        AppFeedback.error(
          context,
          error,
          fallback: 'Anunțul nu a putut fi salvat.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final pageTitle = _isEditing ? 'Editează anunțul' : 'Publică un anunț';
    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(context.tr(pageTitle)),
              backgroundColor: colors.surface,
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.embedded ? 1100 : 900),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(pageTitle),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr(
                    _isEditing ? 'Actualizează informațiile anunțului tău.' : 'Completează pașii de mai jos pentru a publica produsul.',
                  ),
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => Theme(
                      data: theme.copyWith(
                        canvasColor: colors.surfaceContainerLowest,
                      ),
                      child: Stepper(
                        type: constraints.maxWidth < 720
                            ? StepperType.vertical
                            : StepperType.horizontal,
                        currentStep: _currentStep,
                        elevation: 0,
                        margin: const EdgeInsets.only(top: 12),
                        onStepTapped: (step) {
                          if (step < _currentStep && !_isSubmitting) {
                            setState(() => _currentStep = step);
                          }
                        },
                        onStepContinue: _continue,
                        onStepCancel: _currentStep == 0 || _isSubmitting
                            ? null
                            : () => setState(() => _currentStep--),
                        controlsBuilder: _buildControls,
                        steps: _buildSteps(),
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

  List<Step> _buildSteps() => [
    Step(
      title: Text(context.tr('Fotografii')),
      isActive: _currentStep >= 0,
      state: _stepState(0),
      content: _surface(_photosStep()),
    ),
    Step(
      title: Text(context.tr('Detalii articol')),
      isActive: _currentStep >= 1,
      state: _stepState(1),
      content: _surface(_detailsStep()),
    ),
    Step(
      title: Text(context.tr('Preț și livrare')),
      isActive: _currentStep >= 2,
      state: _stepState(2),
      content: _surface(_priceStep()),
    ),
    Step(
      title: Text(context.tr('Verificare')),
      isActive: _currentStep >= 3,
      state: _stepState(3),
      content: _surface(_reviewStep()),
    ),
  ];

  StepState _stepState(int step) {
    if (step < _currentStep) return StepState.complete;
    if (step == _currentStep) return StepState.editing;
    return StepState.indexed;
  }

  Widget _surface(Widget child) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: child,
    );
  }

  Widget _buildControls(BuildContext context, ControlsDetails details) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        children: [
          if (_currentStep > 0)
            OutlinedButton.icon(
              onPressed: _isSubmitting ? null : details.onStepCancel,
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(context.tr('Înapoi')),
            ),
          const Spacer(),
          if (_currentStep < 3)
            FilledButton.icon(
              onPressed: details.onStepContinue,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(context.tr('Continuă')),
            )
          else
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _publish,
              icon: _isSubmitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _isEditing ? Icons.save_outlined : Icons.publish_outlined,
                    ),
              label: Text(
                context.tr(
                  _isEditing
                      ? (_isSubmitting
                            ? 'Se salvează...'
                            : 'Salvează modificările')
                      : (_isSubmitting ? 'Se publică...' : 'Publică anunțul'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _photosStep() {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeading(
          context.tr('Fotografii'),
          context.tr('Adaugă până la 10 fotografii clare ale produsului.'),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ..._existingImages.asMap().entries.map(
              (entry) => _existingImagePreview(entry.value, entry.key),
            ),
            ..._selectedImages.asMap().entries.map(
              (entry) => _imagePreview(
                entry.value,
                entry.key,
                isPrimary: _existingImages.isEmpty && entry.key == 0,
              ),
            ),
            if (_imageCount < 10) _addPhotoButton(),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '$_imageCount/10',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _detailsStep() {
    return Form(
      key: _detailsFormKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeading(
            context.tr('Detalii articol'),
            _language == 'en'
                ? 'Choose the exact category and describe your item.'
                : 'Alege categoria exactă și descrie produsul.',
          ),
          const SizedBox(height: 18),
          _categoryPath(),
          const SizedBox(height: 14),
          _responsiveRow([
            _categoryDropdown(
              context.tr('Categorie'),
              _category,
              listingCategoryCatalog,
              _changeCategory,
            ),
            _categoryDropdown(
              context.tr('Subcategorie'),
              _subcategory,
              _categoryNode.children,
              _changeSubcategory,
            ),
            _categoryDropdown(
              context.tr('Tip produs'),
              _categoryDetail,
              _subcategoryNode.children,
              (value) {
                if (value != null) setState(() => _categoryDetail = value);
              },
            ),
          ]),
          const SizedBox(height: 16),
          _responsiveRow([
            _textField(
              _brandController,
              context.tr('Brand'),
              'Nike, Adidas, Apple...',
              Icons.local_offer_outlined,
              optional: true,
            ),
            _textField(
              _sizeController,
              context.tr('Mărime'),
              _language == 'en' ? 'E.g. M, 42, 15 inch' : 'Ex. M, 42, 15 inch',
              Icons.straighten_outlined,
              optional: true,
            ),
          ]),
          const SizedBox(height: 14),
          _conditionSelector(),
          const SizedBox(height: 14),
          _responsiveRow([
            _textField(
              _colorController,
              context.tr('Culori'),
              _language == 'en' ? 'E.g. Black, blue' : 'Ex. Negru, albastru',
              Icons.palette_outlined,
              optional: true,
            ),
            _textField(
              _materialController,
              context.tr('Material (recomandat)'),
              _language == 'en' ? 'E.g. Cotton, leather' : 'Ex. Bumbac, piele',
              Icons.texture_outlined,
              optional: true,
            ),
          ]),
          const SizedBox(height: 18),
          _textField(
            _titleController,
            context.tr('Titlu anunț'),
            context.tr('Ex. Geacă Nike neagră'),
            Icons.title_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return context.tr('Introdu un titlu');
              }
              if (value.trim().length < 3) {
                return context.tr(
                  'Titlul trebuie să aibă cel puțin 3 caractere',
                );
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _textField(
            _descriptionController,
            context.tr('Descriere'),
            context.tr(
              'Descrie produsul, starea, defectele, dimensiunile și ce include...',
            ),
            Icons.notes_outlined,
            maxLines: 5,
            maxLength: 1000,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return context.tr('Adaugă o descriere');
              }
              if (value.trim().length < 20) {
                return context.tr(
                  'Descrierea trebuie să aibă cel puțin 20 de caractere',
                );
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _priceStep() {
    return Form(
      key: _priceFormKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeading(
            context.tr('Preț și livrare'),
            _language == 'en'
                ? 'Set the price, location and delivery options.'
                : 'Stabilește prețul, localitatea și opțiunile de livrare.',
          ),
          const SizedBox(height: 18),
          _responsiveRow([
            _textField(
              _priceController,
              context.tr('Preț'),
              '0,00',
              Icons.payments_outlined,
              suffixText: 'RON',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.tr('Introdu prețul');
                }
                final price = double.tryParse(value.replaceAll(',', '.'));
                if (price == null) return context.tr('Preț invalid');
                return price <= 0
                    ? context.tr('Prețul trebuie să fie mai mare decât 0')
                    : null;
              },
            ),
            _textField(
              _cityController,
              context.tr('Oraș'),
              _language == 'en' ? 'E.g. Bucharest' : 'Ex. București',
              Icons.location_on_outlined,
              validator: (value) => value == null || value.trim().isEmpty
                  ? context.tr('Introdu orașul')
                  : null,
            ),
          ]),
          const SizedBox(height: 14),
          _optionTile(
            Icons.handshake_outlined,
            context.tr('Preț negociabil'),
            context.tr('Permite cumpărătorilor să îți trimită oferte'),
            _negotiable,
            (value) => setState(() => _negotiable = value),
          ),
          const SizedBox(height: 12),
          _optionTile(
            Icons.local_shipping_outlined,
            context.tr('Livrare disponibilă'),
            context.tr('Permite livrarea produsului către cumpărător'),
            _shipping,
            (value) => setState(() => _shipping = value),
          ),
        ],
      ),
    );
  }

  Widget _reviewStep() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeading(
          context.tr('Previzualizare anunț'),
          context.tr('Verifică informațiile înainte de publicare.'),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final preview = ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 240,
                height: 190,
                child: _existingImages.isNotEmpty
                    ? Image.network(
                        _existingImages.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => ColoredBox(
                          color: colors.surfaceContainerHighest,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            size: 42,
                          ),
                        ),
                      )
                    : _selectedImages.isNotEmpty
                    ? Image.memory(
                        _selectedImages.first.bytes,
                        fit: BoxFit.cover,
                      )
                    : ColoredBox(
                        color: colors.surfaceContainerHighest,
                        child: const Icon(Icons.image_outlined, size: 42),
                      ),
              ),
            );
            final info = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleController.text,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_priceController.text} RON',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _reviewLine(
                  Icons.category_outlined,
                  '${_categoryNode.label(_language)} · '
                  '${_subcategoryNode.label(_language)} · '
                  '${_detailNode.label(_language)}',
                ),
                _reviewLine(
                  Icons.auto_awesome_outlined,
                  context.tr(_conditions[_condition]!),
                ),
                _reviewLine(Icons.location_on_outlined, _cityController.text),
              ],
            );
            if (constraints.maxWidth < 650) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [preview, const SizedBox(height: 18), info],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                preview,
                const SizedBox(width: 22),
                Expanded(child: info),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _descriptionController.text,
            style: TextStyle(color: colors.onSurfaceVariant, height: 1.5),
          ),
        ),
      ],
    );
  }

  void _changeCategory(String? value) {
    if (value == null) return;
    final category = categoryBySlug(value);
    setState(() {
      _category = category.slug;
      _subcategory = category.children.first.slug;
      _categoryDetail = category.children.first.children.first.slug;
    });
  }

  void _changeSubcategory(String? value) {
    if (value == null) return;
    final subcategory = _categoryNode.children.firstWhere(
      (node) => node.slug == value,
    );
    setState(() {
      _subcategory = subcategory.slug;
      _categoryDetail = subcategory.children.first.slug;
    });
  }

  Widget _categoryPath() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _categoryNode.color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(_categoryNode.icon, color: _categoryNode.color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${_categoryNode.label(_language)}  /  '
              '${_subcategoryNode.label(_language)}  /  '
              '${_detailNode.label(_language)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryDropdown(
    String label,
    String value,
    List<CategoryNode> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: _decoration(label, Icons.category_outlined),
      items: items
          .map(
            (node) => DropdownMenuItem(
              value: node.slug,
              child: Text(
                node.label(_language),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _responsiveRow(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 680) {
          return Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index < children.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
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
      decoration: _decoration(
        optional ? '$label (${context.tr('Opțional').toLowerCase()})' : label,
        icon,
      ).copyWith(hintText: hint, suffixText: suffixText),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: colors.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
    );
  }

  Widget _conditionSelector() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Starea produsului'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _conditions.entries.map((entry) {
              final selected = _condition == entry.key;
              return ChoiceChip(
                label: Text(context.tr(entry.value)),
                selected: selected,
                showCheckmark: false,
                onSelected: (_) => setState(() => _condition = entry.key),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _optionTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Icon(
          icon,
          color: value ? colors.primary : colors.onSurfaceVariant,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget _existingImagePreview(String imageUrl, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: 138,
            height: 138,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.square(
              dimension: 138,
              child: ColoredBox(
                color: Colors.black12,
                child: Icon(Icons.image_not_supported_outlined),
              ),
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: IconButton.filled(
            onPressed: () => setState(() => _existingImages.removeAt(index)),
            icon: const Icon(Icons.close_rounded, size: 17),
          ),
        ),
        if (index == 0) _primaryImageBadge(),
      ],
    );
  }

  Widget _imagePreview(
    _SelectedImage image,
    int index, {
    required bool isPrimary,
  }) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            image.bytes,
            width: 138,
            height: 138,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: IconButton.filled(
            onPressed: () => setState(() => _selectedImages.removeAt(index)),
            icon: const Icon(Icons.close_rounded, size: 17),
          ),
        ),
        if (isPrimary) _primaryImageBadge(),
      ],
    );
  }

  Widget _primaryImageBadge() {
    return Positioned(
      left: 7,
      bottom: 7,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .68),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            context.tr('Principală'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _addPhotoButton() {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: _pickImages,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 138,
        height: 138,
        decoration: BoxDecoration(
          color: colors.primaryContainer.withValues(alpha: .3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.primary.withValues(alpha: .35)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: colors.primary, size: 29),
            const SizedBox(height: 7),
            Text(
              context.tr('Adaugă poze'),
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepHeading(String title, String subtitle) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _reviewLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _SelectedImage {
  final XFile file;
  final Uint8List bytes;

  const _SelectedImage({required this.file, required this.bytes});
}
