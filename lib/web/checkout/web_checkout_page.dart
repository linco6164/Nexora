import 'package:flutter/material.dart';

import '../../checkout_page.dart';

/// Păstrează punctul de intrare web, dar folosește același checkout complet și
/// responsive ca aplicația Android. Astfel, produsul, totalurile, adresele,
/// livrarea și cardurile salvate sunt întotdeauna citite din backend.
class WebCheckoutPage extends StatelessWidget {
  final String listingId;

  const WebCheckoutPage({super.key, required this.listingId});

  @override
  Widget build(BuildContext context) => CheckoutPage(listingId: listingId);
}
