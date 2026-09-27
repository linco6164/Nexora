class PromotionNetopiaCheckout {
  static Future<void> open({
    required String gatewayUrl,
    required String envKey,
    required String data,
    required String cipher,
    required String iv,
  }) {
    throw UnsupportedError(
      'NETOPIA checkout nu este disponibil pe această platformă.',
    );
  }
}