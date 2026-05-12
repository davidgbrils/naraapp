import 'package:flutter_test/flutter_test.dart';
import 'package:nara/main.dart';
import 'package:nara/providers/app_provider.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    final appProvider = AppProvider();
    await tester.pumpWidget(NaraApp(appProvider: appProvider));
    // Pump enough time to allow splash screen to navigate
    await tester.pump(const Duration(seconds: 3));
  });
}