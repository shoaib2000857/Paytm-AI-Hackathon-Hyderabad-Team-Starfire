import 'package:flutter_test/flutter_test.dart';
import 'package:paytm_intent_mesh/main.dart';

void main() {
  testWidgets('renders the Ask Paytm experience', (tester) async {
    await tester.pumpWidget(const IntentMeshApp());
    expect(find.text('What do you need?'), findsOneWidget);
    expect(find.text('Ask Paytm'), findsOneWidget);
    expect(find.text('Use current location'), findsOneWidget);
  });
}
