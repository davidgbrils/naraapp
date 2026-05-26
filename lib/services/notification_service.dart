import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class ReminderHealthStatus {
  final bool notificationsEnabled;
  final bool exactAlarmAllowed;
  final bool? fullScreenIntentGranted;
  final bool? batteryOptimizationIgnored;

  const ReminderHealthStatus({
    required this.notificationsEnabled,
    required this.exactAlarmAllowed,
    required this.fullScreenIntentGranted,
    required this.batteryOptimizationIgnored,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();
  static bool verboseReminderLogs = false;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const MethodChannel _popupAlarmChannel = MethodChannel(
    'nara/reminder_popup_alarm',
  );
  static const String _defaultNotificationSoundUri =
      'content://settings/system/notification_sound';
  static const String _defaultAlarmSoundUri =
      'content://settings/system/alarm_alert';
  static const String _defaultRingtoneSoundUri =
      'content://settings/system/ringtone';
  void Function(String payload)? _onNotificationTap;
  String? _pendingLaunchPayload;

  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      try {
        tz.setLocalLocation(tz.getLocation(timezoneName));
      } catch (_) {
        // Some devices return non-IANA names; use Jakarta as regional fallback.
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      }
    } catch (e) {
      debugPrint('Error setting local timezone: $e');
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      } catch (_) {}
    }

    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings darwinInitializationSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: androidInitializationSettings,
          iOS: darwinInitializationSettings,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
    _popupAlarmChannel.setMethodCallHandler(_handlePopupAlarmMethodCall);
    await _consumePendingPopupAlarm();
    await _consumePendingPopupAction();

    // Keep notification permissions in sync with device settings (Android 13+).
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestFullScreenIntentPermission();

    final launchDetails = await _flutterLocalNotificationsPlugin
        .getNotificationAppLaunchDetails();
    final launchPayload = launchDetails?.notificationResponse?.payload;
    if (launchPayload != null && launchPayload.isNotEmpty) {
      if (_onNotificationTap != null) {
        _onNotificationTap!.call(launchPayload);
      } else {
        _pendingLaunchPayload = launchPayload;
      }
    }
  }

  void registerNotificationTapHandler(void Function(String payload) handler) {
    _onNotificationTap = handler;
    if (_pendingLaunchPayload != null && _pendingLaunchPayload!.isNotEmpty) {
      _onNotificationTap?.call(_pendingLaunchPayload!);
      _pendingLaunchPayload = null;
    }
  }

  Future<void> scheduleReminder(
    int id,
    String title,
    String body, {
    required DateTime scheduledDate,
    required String payload,
    String mode = 'Notification',
    String? soundUri,
  }) async {
    try {
      final details = _buildNotificationDetails(
        body: body,
        mode: mode,
        soundUri: soundUri,
      );
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final canExact =
          await androidPlugin?.canScheduleExactNotifications() ?? true;
      final scheduleMode = canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      final pending = await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
      final isRegistered = pending.any((request) => request.id == id);
      if (!kReleaseMode && verboseReminderLogs) {
        debugPrint(
          'Reminder schedule id=$id mode=$mode canExact=$canExact target=$scheduledDate registered=$isRegistered pending=${pending.length}',
        );
      }
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> showReminderNow(
    int id,
    String title,
    String body, {
    required String payload,
    String mode = 'Notification',
    String? soundUri,
  }) async {
    try {
      final details = _buildNotificationDetails(
        body: body,
        mode: mode,
        soundUri: soundUri,
      );
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing notification immediately: $e');
    }
  }

  Future<void> showDownloadSuccessNow({
    required int id,
    required String title,
    required String body,
    required String filePath,
  }) async {
    try {
      final encodedPath = Uri.encodeComponent(filePath);
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          'report_download_channel_v1',
          'Report Downloads',
          channelDescription: 'Status notifikasi untuk hasil unduhan laporan',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.status,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction('open_report_file', 'Buka File'),
            AndroidNotificationAction('share_report_file', 'Bagikan'),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
        ),
      );

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        details,
        payload: 'report_file:$encodedPath',
      );
    } catch (e) {
      debugPrint('Error showing download success notification: $e');
    }
  }

  Future<void> showInfoNow({
    required int id,
    required String title,
    required String body,
    String payload = 'info:status',
  }) async {
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'general_info_channel_v1',
          'General Info',
          channelDescription: 'Notifikasi info umum aplikasi',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
        ),
      );
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing info notification: $e');
    }
  }

  Future<void> cancelReminder(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }

  Future<void> cancelAllReminders() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error canceling all notifications: $e');
    }
  }

  Future<void> schedulePopupAlarm(
    int id,
    DateTime scheduledDate, {
    String mode = 'Loud Alarm',
    String title = 'Reminder',
    String body = 'Ada pengingat baru untukmu.',
  }) async {
    try {
      await cancelReminder(id);
      await _popupAlarmChannel.invokeMethod('schedulePopupAlarm', {
        'id': id,
        'triggerAtMillis': scheduledDate.millisecondsSinceEpoch,
        'mode': mode,
        'title': title,
        'body': body,
      });
    } catch (e) {
      debugPrint('Error scheduling popup alarm: $e');
    }
  }

  Future<void> cancelPopupAlarm(int id) async {
    try {
      await _popupAlarmChannel.invokeMethod('cancelPopupAlarm', {
        'id': id,
      });
    } catch (e) {
      debugPrint('Error canceling popup alarm: $e');
    }
  }

  Future<ReminderHealthStatus> getReminderHealthStatus() async {
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) {
      return const ReminderHealthStatus(
        notificationsEnabled: true,
        exactAlarmAllowed: true,
        fullScreenIntentGranted: null,
        batteryOptimizationIgnored: null,
      );
    }

    final notificationsEnabled =
        await androidPlugin.areNotificationsEnabled() ?? false;
    final exactAlarmAllowed =
        await androidPlugin.canScheduleExactNotifications() ?? false;
    bool? fullScreenIntentGranted;
    bool? batteryOptimizationIgnored;
    try {
      final nativeStatus = await _popupAlarmChannel.invokeMethod<Map<dynamic, dynamic>>(
        'getNativeReminderHealth',
      );
      if (nativeStatus != null) {
        final fullScreenValue = nativeStatus['fullScreenIntentGranted'];
        final batteryValue = nativeStatus['batteryOptimizationIgnored'];
        if (fullScreenValue is bool) fullScreenIntentGranted = fullScreenValue;
        if (batteryValue is bool) batteryOptimizationIgnored = batteryValue;
      }
    } catch (_) {}

    return ReminderHealthStatus(
      notificationsEnabled: notificationsEnabled,
      exactAlarmAllowed: exactAlarmAllowed,
      fullScreenIntentGranted: fullScreenIntentGranted,
      batteryOptimizationIgnored: batteryOptimizationIgnored,
    );
  }

  Future<void> requestReminderPermissions() async {
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
    await androidPlugin?.requestFullScreenIntentPermission();
  }

  Future<void> openReminderSystemSettings(String target) async {
    try {
      await _popupAlarmChannel.invokeMethod('openReminderSystemSettings', {
        'target': target,
      });
    } catch (e) {
      debugPrint('Error opening reminder system settings: $e');
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload ?? '';
    if (payload.isEmpty) return;
    final actionId = response.actionId ?? '';
    if (actionId == 'open_report_file') {
      _onNotificationTap?.call('report_action:open:$payload');
      return;
    }
    if (actionId == 'share_report_file') {
      _onNotificationTap?.call('report_action:share:$payload');
      return;
    }
    _onNotificationTap?.call(payload);
  }

  Future<void> _handlePopupAlarmMethodCall(MethodCall call) async {
    if (call.method == 'onPopupAlarmTriggered') {
      final args = call.arguments;
      if (args is! Map) return;
      final id = args['id'];
      final reminderId = id is int ? id : int.tryParse(id?.toString() ?? '');
      if (reminderId == null) return;
      _onNotificationTap?.call('reminder:$reminderId');
      return;
    }

    if (call.method == 'onPopupAlarmAction') {
      final args = call.arguments;
      if (args is! Map) return;
      final id = args['id'];
      final action = args['action']?.toString();
      final reminderId = id is int ? id : int.tryParse(id?.toString() ?? '');
      if (reminderId == null || action == null || action.isEmpty) return;
      _onNotificationTap?.call('reminder_action:$action:$reminderId');
    }
  }

  Future<void> _consumePendingPopupAlarm() async {
    try {
      final id = await _popupAlarmChannel.invokeMethod<int>(
        'consumePendingPopupAlarm',
      );
      if (id == null) return;
      final payload = 'reminder:$id';
      if (_onNotificationTap != null) {
        _onNotificationTap!.call(payload);
      } else {
        _pendingLaunchPayload = payload;
      }
    } catch (_) {}
  }

  Future<void> _consumePendingPopupAction() async {
    try {
      final args = await _popupAlarmChannel.invokeMethod<Map<dynamic, dynamic>>(
        'consumePendingPopupAction',
      );
      if (args == null) return;
      final id = args['id'];
      final action = args['action']?.toString();
      final reminderId = id is int ? id : int.tryParse(id?.toString() ?? '');
      if (reminderId == null || action == null || action.isEmpty) return;
      final payload = 'reminder_action:$action:$reminderId';
      if (_onNotificationTap != null) {
        _onNotificationTap!.call(payload);
      } else {
        _pendingLaunchPayload = payload;
      }
    } catch (_) {}
  }

  NotificationDetails _buildNotificationDetails({
    required String body,
    required String mode,
    String? soundUri,
  }) {
    final isPopupMode = mode == 'Loud Alarm' || mode == 'Fake Call';
    const int insistentFlag = 4; // Notification.FLAG_INSISTENT
    final effectiveSoundUri = (soundUri != null && soundUri.isNotEmpty)
        ? soundUri
        : _fallbackSoundUriForMode(mode);

    var channelId = switch (mode) {
      'Loud Alarm' => 'reminders_loud_alarm_channel_v4',
      'Fake Call' => 'reminders_fake_call_channel_v4',
      _ => 'reminders_message_channel_v4',
    };
    var channelName = switch (mode) {
      'Loud Alarm' => 'Reminder Loud Alarm',
      'Fake Call' => 'Reminder Fake Calls',
      _ => 'Reminder Notifications',
    };
    if (soundUri != null && soundUri.isNotEmpty) {
      channelId = 'reminders_custom_${effectiveSoundUri.hashCode.abs()}';
      channelName = 'Reminder Custom Sound';
    }

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Scheduled reminder notifications by reminder mode',
        importance: Importance.max,
        priority: Priority.max,
        visibility: NotificationVisibility.public,
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(body),
        category: mode == 'Fake Call'
            ? AndroidNotificationCategory.call
            : (mode == 'Notification'
                  ? AndroidNotificationCategory.message
                  : AndroidNotificationCategory.alarm),
        fullScreenIntent: mode == 'Fake Call' || mode == 'Loud Alarm',
        audioAttributesUsage: mode == 'Loud Alarm'
            ? AudioAttributesUsage.alarm
            : (mode == 'Fake Call'
                  ? AudioAttributesUsage.notificationRingtone
                  : AudioAttributesUsage.notification),
        onlyAlertOnce: mode == 'Notification',
        autoCancel: mode == 'Notification',
        ongoing: isPopupMode,
        additionalFlags: isPopupMode
            ? Int32List.fromList(const <int>[insistentFlag])
            : null,
        sound: UriAndroidNotificationSound(effectiveSoundUri),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      ),
    );
  }

  String _fallbackSoundUriForMode(String mode) {
    return switch (mode) {
      'Loud Alarm' => _defaultAlarmSoundUri,
      'Fake Call' => _defaultRingtoneSoundUri,
      _ => _defaultNotificationSoundUri,
    };
  }
}
