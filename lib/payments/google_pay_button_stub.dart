import 'package:flutter/material.dart';

typedef GooglePayResultCallback = Future<void> Function(
  Map<String, dynamic> paymentData,
);

class NexoraGooglePayButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.account_balance_wallet_outlined),
        label: const Text('Google Pay nu este disponibil'),
      ),
    );
  }
}
