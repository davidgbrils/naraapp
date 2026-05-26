import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nara/providers/app_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const popupAlarmChannel = MethodChannel('nara/reminder_popup_alarm');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('foreground reminder fallback triggers in-app alert for loud alarm', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(popupAlarmChannel, (call) async {
      calls.add(call);
      return null;
    });

    final provider = AppProvider();
    provider.reminders.insert(0, {
      'title': 'Tes Loud Alarm',
      'type': 'Notifikasi',
      'note': '',
      'date': 'Hari ini',
      'scheduledAt': DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String(),
      'subtitle': 'Tes',
      'mode': 'Loud Alarm',
      'repeatEnabled': false,
      'repeatDays': const <int>[],
      'linkedToNote': true,
      'icon': null,
      'notificationId': 1001,
      'soundUri': null,
      'soundName': null,
      'status': 'menunggu',
    });
    provider.setAppInForeground(true);
    calls.clear();

    await provider.runReminderFallbackCheckForTest();

    expect(provider.activeAlert, isNotNull);
    expect((provider.activeAlert?['mode'] as String?) ?? '', 'Loud Alarm');
    expect(calls.where((c) => c.method == 'schedulePopupAlarm'), isEmpty);
  });

  test('background reminder fallback schedules popup alarm (system)', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(popupAlarmChannel, (call) async {
      calls.add(call);
      return null;
    });

    final provider = AppProvider();
    provider.reminders.insert(0, {
      'title': 'Tes Fake Call',
      'type': 'Notifikasi',
      'note': '',
      'date': 'Hari ini',
      'scheduledAt': DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String(),
      'subtitle': 'Tes',
      'mode': 'Fake Call',
      'repeatEnabled': false,
      'repeatDays': const <int>[],
      'linkedToNote': true,
      'icon': null,
      'notificationId': 1002,
      'soundUri': null,
      'soundName': null,
      'status': 'menunggu',
    });
    provider.setAppInForeground(false);

    await provider.runReminderFallbackCheckForTest();

    expect(provider.activeAlert, isNull);
    expect(calls.any((c) => c.method == 'schedulePopupAlarm'), isTrue);
  });

  test('reloaded app can reschedule popup reminders (reboot-like flow)', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(popupAlarmChannel, (call) async {
      calls.add(call);
      return null;
    });

    final provider = AppProvider();
    provider.addReminder({
      'title': 'Tes reboot',
      'type': 'Notifikasi',
      'note': '',
      'date': 'Hari ini',
      'scheduledAt': DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
      'subtitle': 'Tes',
      'mode': 'Loud Alarm',
      'repeatEnabled': false,
      'repeatDays': const <int>[],
      'linkedToNote': true,
      'icon': null,
      'soundUri': null,
      'soundName': null,
      'status': 'menunggu',
    });

    final reloaded = AppProvider();
    await reloaded.loadAppData();
    await reloaded.rescheduleAllReminders();

    expect(calls.any((c) => c.method == 'schedulePopupAlarm'), isTrue);
  });
}
