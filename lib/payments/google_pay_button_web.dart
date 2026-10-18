import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

typedef GooglePayResultCallback = Future<void> Function(
  Map<String, dynamic> paymentData,
);

@JS('nexoraGooglePay.mount')
external void _mountGooglePayButton(
  String elementId,
  String configuration,
  String total,
  String currencyCode,
  JSFunction onResult,
  JSFunction onError,
);

class NexoraGooglePayButton extends StatefulWidget {
  final Map<String, dynamic> configuration;
  final String total;
  final String currencyCode;
  final bool enabled;
  final GooglePayResultCallback onPaymentResult;
  final ValueChanged<Object> onError;

  const NexoraGooglePayButton({
    super.key,
    required this.configuration,
    required this.total,
    required this.currencyCode,
    required this.enabled,
    required this.onPaymentResult,
    required this.onError,
  });

  @override
  State<NexoraGooglePayButton> createState() => _NexoraGooglePayButtonState();
}

class _NexoraGooglePayButtonState extends State<NexoraGooglePayButton> {
  late final String _elementId;
  late final String _viewType;
  late final web.HTMLDivElement _element;

  @override
  void initState() {
    super.initState();
    final identity = identityHashCode(this);
    _elementId = 'nexora-google-pay-$identity';
    _viewType = 'nexora-google-pay-view-$identity';
    _element = web.HTMLDivElement()
      ..id = _elementId
      ..style.width = '100%'
      ..style.height = '56px';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) => _element);

    WidgetsBinding.instance.addPostFrameCallback((_) => _mount());
  }

  @override
  void didUpdateWidget(covariant NexoraGooglePayButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.configuration != widget.configuration ||
        oldWidget.total != widget.total ||
        oldWidget.currencyCode != widget.currencyCode ||
        oldWidget.enabled != widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _mount());
    }
  }

  void _mount() {
    if (!mounted || !widget.enabled) return;

    void handleResult(JSString rawResult) {
      try {
        final decoded = jsonDecode(rawResult.toDart);
        if (decoded is! Map) {
          throw const FormatException('Răspuns Google Pay invalid.');
        }
        widget.onPaymentResult(Map<String, dynamic>.from(decoded));
      } catch (error) {
        widget.onError(error);
      }
    }

    void handleError(JSString rawError) {
      widget.onError(rawError.toDart);
    }

    _mountGooglePayButton(
      _elementId,
      jsonEncode(widget.configuration),
      widget.total,
      widget.currencyCode,
      handleResult.toJS,
      handleError.toJS,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.account_balance_wallet_outlined),
          label: const Text('Plata nu este disponibilă momentan'),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
