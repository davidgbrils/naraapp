import 'package:flutter_test/flutter_test.dart';
import 'package:nara/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const NaraApp());
    await tester.pump(const Duration(seconds: 1));
  });
}