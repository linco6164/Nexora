import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:startapp/models/chat_models.dart';
import 'package:startapp/shared/widgets/offer_purchase_action.dart';

Offer offer({String status = 'accepted', String listingStatus = 'active'}) =>
    Offer.fromJson({
      '_id': 'offer-1',
      'conversation': 'conversation-1',
      'listing': {
        '_id': 'listing-1',
        'title': 'Produs',
        'price': 500,
        'currency': 'RON',
        'images': [],
        'status': listingStatus,
      },
      'buyer': {'_id': 'buyer'},
      'seller': {'_id': 'seller'},
      'amount': 400,
      'currency': 'RON',
      'status': status,
    });

Widget screen(Offer value, String userId, VoidCallback onPurchase) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 280,
            child: OfferPurchaseAction(
              offer: value,
              userId: userId,
              onPurchase: onPurchase,
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('buyer can purchase an accepted offer at the negotiated price', (
    tester,
  ) async {
    var purchases = 0;
    await tester.pumpWidget(screen(offer(), 'buyer', () => purchases++));
    expect(find.text('Cumpără la 400.00 RON'), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    expect(purchases, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('seller sees confirmation without a purchase button', (
    tester,
  ) async {
    await tester.pumpWidget(screen(offer(), 'seller', () {}));
    expect(find.byType(FilledButton), findsNothing);
    expect(find.textContaining('Cumpărătorul poate finaliza'), findsOneWidget);
  });

  testWidgets(
    'third party and unavailable products cannot show purchase actions',
    (tester) async {
      await tester.pumpWidget(screen(offer(), 'other-user', () {}));
      expect(find.byType(FilledButton), findsNothing);
      await tester.pumpWidget(
        screen(offer(listingStatus: 'sold'), 'buyer', () {}),
      );
      expect(find.byType(FilledButton), findsNothing);
      expect(find.text('Produsul nu mai este disponibil.'), findsOneWidget);
    },
  );

  for (final status in ['pending', 'rejected', 'cancelled', 'expired']) {
    testWidgets('$status offer cannot be purchased', (tester) async {
      await tester.pumpWidget(screen(offer(status: status), 'buyer', () {}));
      expect(find.byType(FilledButton), findsNothing);
    });
  }

  test(
    'acceptance response updates the message and preserves listing details',
    () {
      final original = ChatMessage.fromJson({
        '_id': 'message',
        'conversation': 'conversation-1',
        'sender': 'buyer',
        'type': 'offer',
        'offer': {
          '_id': 'offer-1',
          'buyer': 'buyer',
          'seller': 'seller',
          'listing': {'_id': 'listing-1', 'title': 'Produs', 'price': 500},
          'amount': 400,
          'status': 'pending',
        },
      });
      final accepted = Offer.fromJson({
        '_id': 'offer-1',
        'buyer': 'buyer',
        'seller': 'seller',
        'listing': 'listing-1',
        'amount': 400,
        'status': 'accepted',
      });
      final updated = original.withOffer(accepted);
      expect(updated.id, original.id);
      expect(updated.offer!.canBePurchasedBy('buyer'), isTrue);
      expect(updated.offer!.listing!.title, 'Produs');
      expect(original.offer!.isPending, isTrue);
    },
  );
}
