import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

  const localNotificationsChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  const popupAlarmChannel = MethodChannel('nara/reminder_popup_alarm');
  const timezoneChannel = MethodChannel('flutter_timezone');

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(localNotificationsChannel, (call) async {
    switch (call.method) {
      case 'canScheduleExactNotifications':
        return true;
      case 'areNotificationsEnabled':
        return true;
      case 'pendingNotificationRequests':
        return <Map<String, Object?>>[];
      case 'zonedSchedule':
      case 'show':
      case 'cancel':
      case 'cancelAll':
      case 'initialize':
      case 'requestNotificationsPermission':
      case 'requestExactAlarmsPermission':
      case 'requestFullScreenIntentPermission':
        return null;
      case 'getNotificationAppLaunchDetails':
        return <String, Object?>{
          'notificationLaunchedApp': false,
          'notificationResponse': null,
        };
      default:
        return null;
    }
  });

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    popupAlarmChannel,
    (call) async => null,
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(timezoneChannel, (call) async {
    if (call.method == 'getLocalTimezone') return 'Asia/Jakarta';
    return null;
  });

  await testMain();
}
