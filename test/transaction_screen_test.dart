import 'package:flutter_test/flutter_test.dart';
import 'package:nara/providers/app_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppProvider debt payment', () {
    test('addDebt initializes debt with paidAmount and status', () {
      final provider = AppProvider();
      final initialCount = provider.debts.length;
      
      provider.addDebt({
        'title': 'Utang Test',
        'amount': 100000,
        'type': 'utang',
        'date': 'Hari ini',
      });

      expect(provider.debts.length, initialCount + 1);
      final debt = provider.debts.first; // Latest added is first
      expect(debt['title'], 'Utang Test');
      expect(debt['amount'], 100000);
      expect(debt['paidAmount'], 0);
      expect(debt['status'], 'berjalan');
    });

    test('updateDebtPayment increases paidAmount', () {
      final provider = AppProvider();
      
      provider.addDebt({
        'title': 'Utang Test',
        'amount': 100000,
        'type': 'utang',
        'date': 'Hari ini',
      });

      expect(provider.debts.first['paidAmount'], 0);

      provider.updateDebtPayment(0, 50000);

      expect(provider.debts.first['paidAmount'], 50000);
      expect(provider.debts.first['status'], 'berjalan'); // Still ongoing
    });

    test('updateDebtPayment can be called multiple times (cumulative)', () {
      final provider = AppProvider();
      
      provider.addDebt({
        'title': 'Utang Test',
        'amount': 100000,
        'type': 'utang',
        'date': 'Hari ini',
      });

      provider.updateDebtPayment(0, 30000);
      expect(provider.debts.first['paidAmount'], 30000);
      expect(provider.debts.first['status'], 'berjalan');

      provider.updateDebtPayment(0, 20000);
      expect(provider.debts.first['paidAmount'], 50000);
      expect(provider.debts.first['status'], 'berjalan');
    });

    test('updateDebtPayment auto-marks as lunas when fully paid', () {
      final provider = AppProvider();
      
      provider.addDebt({
        'title': 'Utang Test',
        'amount': 100000,
        'type': 'utang',
        'date': 'Hari ini',
      });

      provider.updateDebtPayment(0, 100000);
      expect(provider.debts.first['paidAmount'], 100000);
      expect(provider.debts.first['status'], 'lunas');
    });

    test('updateDebtPayment ignores payments after debt is paid', () {
      final provider = AppProvider();

      provider.addDebt({
        'title': 'Utang Test',
        'amount': 100000,
        'type': 'utang',
        'date': 'Hari ini',
      });

      provider.updateDebtPayment(0, 100000);
      provider.updateDebtPayment(0, 50000);

      expect(provider.debts.first['paidAmount'], 100000);
      expect(provider.debts.first['status'], 'lunas');
      expect((provider.debts.first['paymentHistory'] as List).length, 1);
    });

    test('markDebtAsPaid sets status to lunas', () {
      final provider = AppProvider();
      
      provider.addDebt({
        'title': 'Utang Test',
        'amount': 100000,
        'type': 'utang',
        'date': 'Hari ini',
      });

      provider.updateDebtPayment(0, 50000);
      provider.markDebtAsPaid(0);

      expect(provider.debts.first['paidAmount'], 100000);
      expect(provider.debts.first['status'], 'lunas');
    });

    test('totalActiveDebt only counts berjalan/ongoing debts', () {
      final provider = AppProvider();
      final initialDebt = provider.totalActiveDebt; // Default 'Utang Andi'
      
      provider.addDebt({
        'title': 'Utang 1',
        'amount': 100000,
        'type': 'utang',
        'date': 'Hari ini',
      });

      provider.addDebt({
        'title': 'Utang 2',
        'amount': 50000,
        'type': 'utang',
        'date': 'Hari ini',
      });

      // Utang 2 (at index 0): pay 50000 → fully paid → lunas
      provider.updateDebtPayment(0, 50000);
      
      // Utang 1 (at index 1): pay 30000 → paidAmount 30000, remaining 70000 → berjalan
      provider.updateDebtPayment(1, 30000);

      // Should be: initialDebt (150000) + 70000 (Utang 1 remaining) + 0 (Utang 2 paid)
      expect(provider.totalActiveDebt, initialDebt + 70000);
    });
  });

  group('AppProvider transaction utilities', () {
    test('detects potential duplicate expense in short window', () {
      final provider = AppProvider();
      provider.addExpense({
        'title': 'Makan Siang',
        'amount': 50000,
        'category': 'Makan',
        'time': 'Hari ini',
        'icon': 'restaurant',
      });

      final duplicated = provider.hasPotentialDuplicateExpense(
        title: 'Makan Siang',
        amount: 50000,
        category: 'Makan',
      );
      expect(duplicated, isTrue);
    });

    test('update/remove expense works', () {
      final provider = AppProvider();
      provider.addExpense({
        'title': 'Grab',
        'amount': 20000,
        'category': 'Transport',
        'time': 'Hari ini',
        'icon': 'directions_car',
      });
      provider.updateExpenseAt(0, {
        ...provider.expenses[0],
        'title': 'Grab Car',
        'amount': 25000,
      });
      expect(provider.expenses[0]['title'], 'Grab Car');
      expect(provider.expenses[0]['amount'], 25000);

      provider.removeExpenseAt(0);
      expect(provider.expenses, isEmpty);
    });
  });
}
