import 'package:flutter_test/flutter_test.dart';
import 'package:nara/providers/app_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppProvider settings persistence', () {
    test('setDarkMode persists after loadAppData', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();

      await provider.setDarkMode(true);
      expect(provider.isDarkMode, true);

      final reloadedProvider = AppProvider();
      await reloadedProvider.loadAppData();
      expect(reloadedProvider.isDarkMode, true);
    });

    test('setUserName persists after loadAppData', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();

      await provider.setUserName('Nara User');
      expect(provider.userName, 'Nara User');

      final reloadedProvider = AppProvider();
      await reloadedProvider.loadAppData();
      expect(reloadedProvider.userName, 'Nara User');
    });

    test('clearAllData clears transaction and reminder lists', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();

      provider.addExpense({
        'title': 'Test Expense',
        'amount': 10000,
        'category': 'Test',
      });
      provider.addIncome({
        'title': 'Test Income',
        'amount': 20000,
        'category': 'Test',
      });
      provider.addReminder({
        'title': 'Test Reminder',
        'type': 'Notifikasi',
        'date': '${DateTime.now().day} Mei ${DateTime.now().year} • 21:00',
        'scheduledAt': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        'status': 'menunggu',
      });

      expect(provider.expenses.isNotEmpty, true);
      expect(provider.incomes.isNotEmpty, true);
      expect(provider.reminders.isNotEmpty, true);

      await provider.clearAllData();

      expect(provider.expenses, isEmpty);
      expect(provider.incomes, isEmpty);
      expect(provider.debts, isEmpty);
      expect(provider.reminders, isEmpty);
    });
  });

  group('AppProvider reminder behavior', () {
    test('snoozeAlert updates scheduledAt and snoozedUntil', () {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();

      provider.addReminder({
        'title': 'Snooze Test',
        'type': 'Notifikasi',
        'date': '${DateTime.now().day} Mei ${DateTime.now().year} • 21:00',
        'scheduledAt': DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
        'status': 'menunggu',
      });

      provider.triggerReminderAlert(0);
      provider.snoozeAlert(300);

      final reminder = provider.reminders[0];
      expect(reminder['snoozedUntil'], isNotNull);
      expect(reminder['scheduledAt'], isNotNull);
    });
  });
}

