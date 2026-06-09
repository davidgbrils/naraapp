import 'package:flutter/services.dart';

import 'notification_service.dart';

class StartupPermissionService {
  StartupPermissionService._();

  static const MethodChannel _channel = MethodChannel('nara/startup_permissions');

  static Future<void> requestEssentialPermissions() async {
    try {
      await _channel.invokeMethod<void>('requestRuntimePermissions');
    } on MissingPluginException {
      // Tests and non-Android platforms do not load this native channel.
    } on PlatformException {
      // The reminder permission flow below still gives users recovery paths.
    }

    await NotificationService().requestReminderPermissions();
  }
}
