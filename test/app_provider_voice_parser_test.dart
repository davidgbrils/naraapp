import 'package:flutter_test/flutter_test.dart';
import 'package:nara/providers/app_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppProvider voice parser', () {
    test('previewVoiceCommand parses expense with category and amount', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();

      final result = provider.previewVoiceCommand('catat pengeluaran makan 50 ribu');
      expect(result, isNotNull);
      expect(result!['type'], 'expense');
      expect(result['category'], 'Makan');
      expect(result['amount'], 50000);
    });

    test('previewVoiceCommand parses income with category and amount', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();

      final result = provider.previewVoiceCommand('catat pemasukan freelance 1.5 juta');
      expect(result, isNotNull);
      expect(result!['type'], 'income');
      expect(result['category'], 'Freelance');
      expect(result['amount'], 1500000);
    });

    test('previewVoiceCommand parses debt command', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();

      final result = provider.previewVoiceCommand('catat utang ke andi 200 ribu');
      expect(result, isNotNull);
      expect(result!['type'], 'debt');
      expect(result['debtType'], 'utang');
      expect(result['title'], 'Andi');
      expect(result['amount'], 200000);
    });

    test('previewVoiceCommand keeps zero amount for validation flow', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();

      final result = provider.previewVoiceCommand('catat pengeluaran makan 0');
      expect(result, isNotNull);
      expect(result!['type'], 'expense');
      expect(result['amount'], 0);
    });

    test('previewVoiceCommand parses negative amount', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();

      final result = provider.previewVoiceCommand(
        'catat pengeluaran makan minus 50 ribu',
      );
      expect(result, isNotNull);
      expect(result!['type'], 'expense');
      expect(result['amount'], -50000);
    });

    test('previewVoiceCommand parses reminder mode fake call', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();

      final result = provider.previewVoiceCommand(
        'ingatkan bayar listrik jam 20:30 besok fake call',
      );
      expect(result, isNotNull);
      expect(result!['type'], 'reminder');
      expect(result['mode'], 'Fake Call');
      expect(result['scheduledAt'], isA<DateTime>());
    });

    test('previewVoiceCommand parses natural phrase "nanti malam"', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();

      final result = provider.previewVoiceCommand(
        'ingatkan minum obat nanti malam',
      );
      expect(result, isNotNull);
      expect(result!['type'], 'reminder');
      final scheduledAt = result['scheduledAt'] as DateTime;
      expect(scheduledAt.hour, 20);
      expect(scheduledAt.minute, 0);
    });

    test('previewVoiceCommand parses weekday phrase', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();

      final result = provider.previewVoiceCommand(
        'ingatkan rapat senin jam 9',
      );
      expect(result, isNotNull);
      expect(result!['type'], 'reminder');
      final scheduledAt = result['scheduledAt'] as DateTime;
      expect(scheduledAt.weekday, DateTime.monday);
      expect(scheduledAt.hour, 9);
    });

    test('validateVoiceAction rejects invalid reminder mode', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();
      final now = DateTime.now();

      final validation = provider.validateVoiceAction({
        'type': 'reminder',
        'title': 'Tes',
        'mode': 'Unknown Mode',
        'scheduledAt': now.add(const Duration(minutes: 5)),
      }, now: now);

      expect(validation['isValid'], false);
    });

    test('validateVoiceAction rejects non-positive expense amount', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();

      final validation = provider.validateVoiceAction({
        'type': 'expense',
        'title': 'Makan',
        'amount': 0,
        'category': 'Makan',
      });

      expect(validation['isValid'], false);
    });

    test('applyPendingVoiceAction saves parsed expense when approved', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();

      await provider.simulateVoiceCommand('catat pengeluaran makan 25 ribu');
      final applied = await provider.applyPendingVoiceAction(approved: true);

      expect(applied, true);
      expect(provider.expenses.isNotEmpty, true);
      expect(provider.expenses.first['amount'], 25000);
    });

    test('applyPendingVoiceAction saves parsed debt when approved', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();

      await provider.simulateVoiceCommand('catat piutang budi 300 ribu besok');
      final applied = await provider.applyPendingVoiceAction(approved: true);

      expect(applied, true);
      expect(provider.debts.isNotEmpty, true);
      expect(provider.debts.first['type'], 'piutang');
      expect(provider.debts.first['amount'], 300000);
    });

    test('applyPendingVoiceAction pays partial debt from voice command', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();

      provider.addDebt({
        'title': 'Andi',
        'amount': 500000,
        'type': 'utang',
        'date': 'Hari ini',
        'dueDate': '',
        'note': '',
      });
      final debtId = provider.debts.first['debtId'] as int;

      await provider.simulateVoiceCommand('bayar sebagian andi 200 ribu');
      final preview = provider.pendingVoiceAction;
      expect(preview, isNotNull);
      expect(preview!['type'], 'debt_payment');
      expect(preview['debtId'], debtId);
      expect(preview['amount'], 200000);

      final applied = await provider.applyPendingVoiceAction(approved: true);
      expect(applied, true);
      expect(provider.debts.first['paidAmount'], 200000);
      expect(provider.debts.first['status'], 'berjalan');
    });
  });
}
