import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nara/providers/app_provider.dart';
import 'package:nara/screens/home/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home screen renders without layout exceptions', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final provider = AppProvider();
    provider.setNavIndex(0);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('Voice tools are visible when Voice Beta is enabled', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final provider = AppProvider();
    provider.setNavIndex(0);
    await provider.setVoiceBetaEnabled(true);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('BETA'), findsWidgets);
    expect(find.text('Example voice commands'), findsOneWidget);
    expect(find.text('Run Typed Command'), findsOneWidget);
  });

  testWidgets('Voice tools are hidden when Voice Beta is disabled', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final provider = AppProvider();
    provider.setNavIndex(0);
    await provider.setVoiceBetaEnabled(false);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('OFF'), findsWidgets);
    expect(find.text('Voice Beta is off'), findsOneWidget);
    expect(find.text('Example voice commands'), findsNothing);
    expect(find.text('Run Typed Command'), findsNothing);
  });

  testWidgets('Voice Beta switch in Home updates UI instantly', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final provider = AppProvider();
    provider.setNavIndex(0);
    await provider.setVoiceBetaEnabled(false);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('OFF'), findsWidgets);
    expect(find.text('Example voice commands'), findsNothing);

    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsWidgets);
    await tester.tap(switchFinder.first);
    await tester.pumpAndSettle();

    expect(find.text('BETA'), findsWidgets);
    expect(find.text('Example voice commands'), findsOneWidget);
    expect(find.text('Run Typed Command'), findsOneWidget);
  });
}
