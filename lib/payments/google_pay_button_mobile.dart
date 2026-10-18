import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pay/pay.dart';

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
    if (defaultTargetPlatform != TargetPlatform.android || !enabled) {
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

    final paymentConfiguration = PaymentConfiguration.fromJsonString(
      jsonEncode(configuration),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GooglePayButton(
      paymentConfiguration: paymentConfiguration,
      paymentItems: [
        PaymentItem(
          label: 'Total Nexora',
          amount: total,
          status: PaymentItemStatus.final_price,
        ),
      ],
      type: GooglePayButtonType.buy,
      theme: isDark ? GooglePayButtonTheme.light : GooglePayButtonTheme.dark,
      width: double.infinity,
      height: 56,
      cornerRadius: 14,
      loadingIndicator: const Center(child: CircularProgressIndicator()),
      childOnError: SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.account_balance_wallet_outlined),
          label: const Text('Google Pay nu este disponibil'),
        ),
      ),
      onError: (error) =>
          onError(error ?? Exception('Google Pay nu a putut procesa plata.')),
      onPaymentResult: (result) async {
        await onPaymentResult(Map<String, dynamic>.from(result));
      },
    );
  }
}
