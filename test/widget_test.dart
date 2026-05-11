import 'package:flutter_test/flutter_test.dart';
import 'package:nara/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const NaraApp());
    // Pump enough time to allow splash screen to navigate
    await tester.pump(const Duration(seconds: 3));
  });
}