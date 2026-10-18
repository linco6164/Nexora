import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';

class PrepareShipmentPage extends StatefulWidget {
  final String orderId;

  const PrepareShipmentPage({super.key, required this.orderId});

  @override
  State<PrepareShipmentPage> createState() => _PrepareShipmentPageState();
}

class _PrepareShipmentPageState extends State<PrepareShipmentPage> {
  final _formKey = GlobalKey<FormState>();

  final _weightController = TextEditingController();

  final _widthController = TextEditingController();

  final _lengthController = TextEditingController();

  final _heightController = TextEditingController();

  int _packageType = 0;

  bool _loading = false;

  bool _checkingExistingShipment = true;

  Map<String, dynamic>? _shipment;

  String? _failedShipmentMessage;

  // ==========================================================

  // INIT

  // ==========================================================

  @override
  void initState() {
    super.initState();

    _loadExistingShipment();
  }

  // ==========================================================

  // DISPOSE

  // ==========================================================

  @override
  void dispose() {
    _weightController.dispose();

    _widthController.dispose();

    _lengthController.dispose();

    _heightController.dispose();

    super.dispose();
  }

  // ==========================================================

  // LOAD EXISTING SHIPMENT

  // ==========================================================

  Future<void> _loadExistingShipment() async {
    try {
      final shipment = await ApiService.getSamedayShipmentByOrder(
        orderId: widget.orderId,
      );

      if (!mounted) {
        return;
      }

      if (shipment == null) {
        setState(() {
          _checkingExistingShipment = false;
        });

        return;
      }

      final status = shipment['status']?.toString().trim() ?? '';

      // Un AWB anterior a eșuat.

      // Lăsăm formularul disponibil pentru retry.

      if (status == 'failed') {
        setState(() {
          _shipment = null;

          _failedShipmentMessage =
              shipment['errorMessage']?.toString().trim() ??
              'Generarea AWB-ului anterior a eșuat. Poți încerca din nou.';

          _checkingExistingShipment = false;
        });

        return;
      }

      setState(() {
        _shipment = shipment;

        _failedShipmentMessage = null;

        _checkingExistingShipment = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _checkingExistingShipment = false;
      });

      final message = error is ApiException
          ? error.message
          : 'Nu am putut verifica transportul existent.';

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // ==========================================================

  // PARSE NUMBER

  // ==========================================================

  double? _parseNumber(String value) {
    final clean = value.trim().replaceAll(',', '.');

    if (clean.isEmpty) {
      return null;
    }

    return double.tryParse(clean);
  }

  // ==========================================================

  // GENERATE AWB

  // ==========================================================

  Future<void> _generateAwb() async {
    if (_loading) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final weight = _parseNumber(_weightController.text);

    if (weight == null || weight <= 0) {
      return;
    }

    final width = _parseNumber(_widthController.text);

    final length = _parseNumber(_lengthController.text);

    final height = _parseNumber(_heightController.text);

    setState(() {
      _loading = true;

      _failedShipmentMessage = null;
    });

    try {
      final shipment = await ApiService.createSamedayLockerShipment(
        orderId: widget.orderId,

        packageWeight: weight,

        packageType: _packageType,

        width: width,

        length: length,

        height: height,
      );

      if (!mounted) {
        return;
      }

      final status = shipment['status']?.toString() ?? '';

      if (status == 'failed') {
        setState(() {
          _failedShipmentMessage =
              shipment['errorMessage']?.toString() ??
              'Nu am putut genera AWB-ul.';
        });

        return;
      }

      setState(() {
        _shipment = shipment;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AWB-ul a fost generat.')));
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = error is ApiException
          ? error.message
          : 'Nu am putut genera AWB-ul.';

      setState(() {
        _failedShipmentMessage = message;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ==========================================================

  // OPEN PDF

  // ==========================================================

  Future<void> _openPdf() async {
    final pdfLink = _shipment?['pdfLink']?.toString().trim();

    if (pdfLink == null || pdfLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF-ul AWB nu este disponibil.')),
      );

      return;
    }

    final uri = Uri.tryParse(pdfLink);

    if (uri == null) {
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nu am putut deschide PDF-ul.')),
      );
    }
  }

  // ==========================================================

  // STATUS LABEL

  // ==========================================================

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Se generează';

      case 'ready_for_dropoff':
        return 'Pregătit pentru predare';

      case 'dropped_off':
        return 'Predat în Easybox';

      case 'in_transit':
        return 'În tranzit';

      case 'delivered':
        return 'Livrat';

      case 'failed':
        return 'Eroare';

      default:
        return status.isEmpty ? 'Transport creat' : status;
    }
  }

  // ==========================================================

  // BUILD

  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,

      appBar: AppBar(
        title: const Text('Pregătește coletul'),

        elevation: 0,

        backgroundColor: colors.surface,

        surfaceTintColor: Colors.transparent,
      ),

      body: SafeArea(
        child: _checkingExistingShipment
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),

                child: _shipment != null ? _buildShipment() : _buildForm(),
              ),
      ),
    );
  }

  // ==========================================================

  // FORM

  // ==========================================================

  Widget _buildForm() {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Form(
      key: _formKey,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ==================================================

          // PREVIOUS FAILURE

          // ==================================================
          if (_failedShipmentMessage != null) ...[
            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(14),

              decoration: BoxDecoration(
                color: colors.errorContainer,

                borderRadius: BorderRadius.circular(14),
              ),

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Icon(
                    Icons.error_outline_rounded,

                    color: colors.onErrorContainer,
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      _failedShipmentMessage!,

                      style: TextStyle(color: colors.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],

          // ==================================================

          // INTRO

          // ==================================================
          Container(
            width: double.infinity,

            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,

              borderRadius: BorderRadius.circular(18),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: colors.primary),

                    const SizedBox(width: 10),

                    Text(
                      'Detalii colet',

                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  'Introdu greutatea coletului și, dacă le cunoști, dimensiunile ambalajului.',

                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,

                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ==================================================

          // PACKAGE TYPE

          // ==================================================
          Text(
            'Tip colet',

            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<int>(
            initialValue: _packageType,

            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),

            items: const [
              DropdownMenuItem(value: 0, child: Text('Colet standard')),

              DropdownMenuItem(value: 1, child: Text('Colet mic')),

              DropdownMenuItem(value: 2, child: Text('Colet oversized')),
            ],

            onChanged: _loading
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _packageType = value;
                    });
                  },
          ),

          const SizedBox(height: 18),

          // ==================================================

          // WEIGHT

          // ==================================================
          TextFormField(
            controller: _weightController,

            enabled: !_loading,

            keyboardType: const TextInputType.numberWithOptions(decimal: true),

            decoration: InputDecoration(
              labelText: 'Greutate',

              hintText: 'Ex: 1.2',

              suffixText: 'kg',

              prefixIcon: const Icon(Icons.scale_outlined),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),

            validator: (value) {
              final weight = _parseNumber(value ?? '');

              if (weight == null || weight <= 0) {
                return 'Introdu o greutate validă.';
              }

              return null;
            },
          ),

          const SizedBox(height: 22),

          // ==================================================

          // DIMENSIONS

          // ==================================================
          Text(
            'Dimensiuni',

            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Opțional — dimensiunile sunt în centimetri.',

            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _dimensionField(
                  controller: _widthController,

                  label: 'Lățime',
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _dimensionField(
                  controller: _lengthController,

                  label: 'Lungime',
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          _dimensionField(controller: _heightController, label: 'Înălțime'),

          const SizedBox(height: 26),

          // ==================================================

          // GENERATE

          // ==================================================
          SizedBox(
            width: double.infinity,

            height: 54,

            child: FilledButton.icon(
              onPressed: _loading ? null : _generateAwb,

              icon: _loading
                  ? const SizedBox(
                      width: 20,

                      height: 20,

                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.description_outlined),

              label: Text(
                _loading
                    ? 'Se generează...'
                    : _failedShipmentMessage != null
                    ? 'Încearcă din nou'
                    : 'Generează AWB',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================

  // DIMENSION FIELD

  // ==========================================================

  Widget _dimensionField({
    required TextEditingController controller,

    required String label,
  }) {
    return TextFormField(
      controller: controller,

      enabled: !_loading,

      keyboardType: const TextInputType.numberWithOptions(decimal: true),

      decoration: InputDecoration(
        labelText: label,

        suffixText: 'cm',

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),

      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return null;
        }

        final number = _parseNumber(value);

        if (number == null || number <= 0) {
          return 'Valoare invalidă';
        }

        return null;
      },
    );
  }

  // ==========================================================

  // EXISTING / GENERATED SHIPMENT

  // ==========================================================

  Widget _buildShipment() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final awb = _shipment?['awbNumber']?.toString().trim() ?? '';

    final trackingUrl = awb.isNotEmpty
        ? 'https://sameday.ro/#awb=${Uri.encodeComponent(awb)}'
        : null;

    final status = _shipment?['status']?.toString().trim() ?? '';

    final lockerName = _shipment?['destinationLockerName']?.toString().trim();

    final lockerAddress = _shipment?['destinationLockerAddress']
        ?.toString()
        .trim();

    final lockerCity = _shipment?['destinationLockerCity']?.toString().trim();

    final lockerCounty = _shipment?['destinationLockerCounty']
        ?.toString()
        .trim();

    final pdf = _shipment?['pdfLink']?.toString().trim();

    final trackingEventsRaw = _shipment?['trackingEvents'];

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

    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded, size: 42, color: colors.primary),
        ),

        const SizedBox(height: 18),

        Text(
          'Transport Sameday',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          _statusLabel(status),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 24),

        if (awb.isNotEmpty)
          _infoCard(
            title: 'Număr AWB',
            value: awb,
            icon: Icons.confirmation_number_outlined,
          ),

        if (awb.isNotEmpty && lockerName != null && lockerName.isNotEmpty)
          const SizedBox(height: 10),

        if (lockerName != null && lockerName.isNotEmpty)
          _infoCard(
            title: 'Easybox destinație',
            value: [
              lockerName,
              if (lockerAddress != null && lockerAddress.isNotEmpty)
                lockerAddress,
              if (lockerCity != null && lockerCity.isNotEmpty) lockerCity,
              if (lockerCounty != null && lockerCounty.isNotEmpty) lockerCounty,
            ].join('\n'),
            icon: Icons.inventory_2_outlined,
          ),

        const SizedBox(height: 24),

        if (pdf != null && pdf.isNotEmpty)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: _openPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Deschide AWB PDF'),
            ),
          ),

        if (pdf == null || pdf.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'PDF-ul AWB nu este disponibil momentan.',
              textAlign: TextAlign.center,
            ),
          ),

        if (trackingUrl != null) ...[
          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(trackingUrl);

                final opened = await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );

                if (!opened && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Nu am putut deschide tracking-ul Sameday.',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.local_shipping_outlined),
              label: const Text('Urmărește coletul'),
            ),
          ),
        ],

        if (trackingEvents.isNotEmpty) ...[
          const SizedBox(height: 28),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Istoric transport',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(height: 12),

          ...trackingEvents.map((event) {
            final eventStatus =
                event['status']?.toString().trim() ?? 'Actualizare Sameday';

            final rawDate = event['statusDate']?.toString();

            final eventDate = rawDate != null
                ? DateTime.tryParse(rawDate)?.toLocal()
                : null;

            final dateText = eventDate == null
                ? ''
                : '${eventDate.day.toString().padLeft(2, '0')}.'
                      '${eventDate.month.toString().padLeft(2, '0')}.'
                      '${eventDate.year} '
                      '${eventDate.hour.toString().padLeft(2, '0')}:'
                      '${eventDate.minute.toString().padLeft(2, '0')}';

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_shipping_outlined,
                      size: 18,
                      color: colors.primary,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eventStatus,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),

                        if (dateText.isNotEmpty) ...[
                          const SizedBox(height: 4),

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

        const SizedBox(height: 18),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context, _shipment);
            },
            child: const Text('Gata'),
          ),
        ),
      ],
    );
  }

  // ==========================================================

  // INFO CARD

  // ==========================================================

  Widget _infoCard({
    required String title,

    required String value,

    required IconData icon,
  }) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: colors.outlineVariant),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(icon, color: colors.primary),

          const SizedBox(width: 12),

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

                const SizedBox(height: 4),

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
      ),
    );
  }
}
