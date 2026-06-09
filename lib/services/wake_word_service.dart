import 'package:flutter/services.dart';

class WakeWordService {
  WakeWordService._();

  static const MethodChannel _channel = MethodChannel('nara/wake_word');

  static void registerWakeWordHandler(Future<void> Function() handler) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onWakeWordDetected') {
        await handler();
      }
    });
  }

  static Future<bool> start() async {
    try {
      return await _channel.invokeMethod<bool>('startWakeWordService') ?? false;
    } on MissingPluginException {
      // Unit/widget tests do not load the Android wake-word channel.
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> stop() async {
    try {
      return await _channel.invokeMethod<bool>('stopWakeWordService') ?? false;
    } on MissingPluginException {
      // Unit/widget tests do not load the Android wake-word channel.
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> isRunning() async {
    try {
      return await _channel.invokeMethod<bool>('isWakeWordServiceRunning') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> consumePendingDetection() async {
    try {
      return await _channel.invokeMethod<bool>('consumePendingWakeWord') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
