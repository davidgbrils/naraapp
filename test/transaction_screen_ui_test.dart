import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nara/providers/app_provider.dart';
import 'package:nara/screens/transaction/transaction_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Transaction tab label stays visible on small screen', (tester) async {
    final provider = AppProvider();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: TransactionScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Utang/Piutang'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Transaction labels switch to English when language is English', (tester) async {
    final provider = AppProvider();
    await provider.setLanguage('English');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: TransactionScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Debt/Receivable'), findsOneWidget);
  });

  testWidgets('Transaction screen accepts DateTime and String createdAt values', (tester) async {
    final provider = AppProvider();
    provider.addExpense({
      'title': 'DateTime Expense',
      'amount': 12000,
      'category': 'Makan',
      'createdAt': DateTime.now(),
    });
    provider.addIncome({
      'title': 'String Income',
      'amount': 20000,
      'category': 'Gaji',
      'createdAt': DateTime.now().toIso8601String(),
    });
    provider.addDebt({
      'title': 'Mixed Debt',
      'amount': 30000,
      'type': 'utang',
      'date': 'Hari ini',
      'createdAt': DateTime.now(),
    });

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: TransactionScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('Pengeluaran'), findsOneWidget);
  });
}
