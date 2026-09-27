import 'package:url_launcher/url_launcher.dart';

class PromotionNetopiaCheckout {
  static Future<void> open({
    required String gatewayUrl,
    required String envKey,
    required String data,
    required String cipher,
    required String iv,
  }) async {
    final uri = Uri.https(
      'api.nx-store.com',
      '/promotions/payment/checkout',
      {
        'gatewayUrl': gatewayUrl,
        'env_key': envKey,
        'data': data,
        'cipher': cipher,
        'iv': iv,
      },
    );

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      throw Exception(
        'Nu s-a putut deschide checkout-ul NETOPIA.',
      );
    }
  }
}