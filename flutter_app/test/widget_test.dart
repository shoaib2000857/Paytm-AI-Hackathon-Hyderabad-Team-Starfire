import 'package:flutter_test/flutter_test.dart';
import 'package:paytm_intent_mesh/main.dart';

void main() {
  testWidgets('renders the Ask Paytm experience', (tester) async {
    await tester.pumpWidget(const IntentMeshApp());
    expect(find.text('What do you need today?'), findsOneWidget);
    expect(find.text('ASK PAYTM'), findsOneWidget);
    expect(find.text('Find it for me'), findsOneWidget);
    expect(find.text('Near KMIT'), findsOneWidget);
  });
}
