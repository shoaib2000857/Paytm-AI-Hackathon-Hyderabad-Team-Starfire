import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paytm_intent_mesh/main.dart';

Future<void> loadAppFonts() async {
  final loader = FontLoader('AppRoboto')
    ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf'));
  await loader.load();
}

const intent = <String, dynamic>{
  'category': 'bakery',
  'request_type': 'custom_cake',
  'item_or_service': 'chocolate cake',
  'attributes': {'weight': '1 kg', 'flavour': 'chocolate', 'eggless': true},
  'budget_max': 800,
  'needed_by': 'Tomorrow · before 7 PM',
  'radius_km': 5,
  'hard_constraints': ['eggless', 'budget ≤ ₹800'],
  'soft_preferences': ['nearby', 'earlier better']
};

const merchants = <Map<String, dynamic>>[
  {
    'id': 'M001',
    'name': 'Sweet Crumbs',
    'distance_km': 1.2,
    'rating': 4.8,
    'match_score': .94,
    'delivery': false
  },
  {
    'id': 'M002',
    'name': 'HomeBakes by Anu',
    'distance_km': 2.8,
    'rating': 4.7,
    'match_score': .89,
    'delivery': false
  },
  {
    'id': 'M003',
    'name': 'Cake House',
    'distance_km': 3.1,
    'rating': 4.6,
    'match_score': .86,
    'delivery': true
  }
];

final offers = <Map<String, dynamic>>[
  {
    'id': 'O001',
    'price': 750,
    'ready_at': '18:30',
    'delivery': false,
    'merchant': merchants[0]
  },
  {
    'id': 'O002',
    'price': 700,
    'ready_at': '19:00',
    'delivery': false,
    'merchant': merchants[1]
  },
  {
    'id': 'O003',
    'price': 800,
    'ready_at': '18:00',
    'delivery': true,
    'merchant': merchants[2]
  }
];

Future<void> shot(WidgetTester tester, Widget page, String name) async {
  await tester.binding.setSurfaceSize(const Size(430, 840));
  await tester.pumpWidget(IntentMeshApp(home: page));
  await tester.pump(const Duration(milliseconds: 500));
  await expectLater(
      find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('presentation screenshot pack', (tester) async {
    await loadAppFonts();
    await shot(tester, const AskScreen(audioEnabled: false), '01_ask_paytm');
    await shot(tester, const ConfirmScreen(rawText: 'cake', intent: intent),
        '02_intent_packet');
    await shot(
        tester,
        const MatchesScreen(
            intent: intent, result: {'id': 'I001', 'matches': merchants}),
        '03_merchant_mesh');
    await shot(
        tester,
        const MerchantSoundboxScreen(
            intent: intent,
            intentId: 'I001',
            matches: merchants,
            audioEnabled: false),
        '04_merchant_soundbox');
    await shot(
        tester, OffersScreen(offers: offers, intent: intent), '05_live_offers');
    await shot(
        tester, PaymentScreen(offer: offers[0], intent: intent), '06_checkout');
    await shot(
        tester,
        const SuccessScreen(payment: {
          'id': 'P001',
          'amount': 750,
          'remaining': 0,
          'payment_plan': 'full',
          'merchant': {'id': 'M001', 'name': 'Sweet Crumbs'}
        }, intent: intent),
        '07_payment_success');
    await shot(
        tester,
        const OpportunityPulseScreen(merchantId: 'M001', initialData: {
          'period': 'This week',
          'potential_demand': 18400,
          'requests': 43,
          'trends': [
            {
              'label': 'Eggless cakes under ₹600',
              'count': 18,
              'change': 41,
              'unfulfilled': 12,
              'value': 8200
            },
            {
              'label': 'Same-day custom cakes',
              'count': 12,
              'change': 18,
              'unfulfilled': 7,
              'value': 6100
            },
            {
              'label': '500g cakes after 8 PM',
              'count': 9,
              'change': 12,
              'unfulfilled': 6,
              'value': 4100
            }
          ]
        }),
        '08_opportunity_pulse');
  });
}
