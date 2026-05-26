import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class TelemetryService {
  TelemetryService._internal();
  static final TelemetryService instance = TelemetryService._internal();

  bool _isInitialized = false;
  bool _enabled = false;

  bool get isEnabled => _enabled;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    const dsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
    if (dsn.trim().isEmpty) {
      _enabled = false;
      return;
    }

    await SentryFlutter.init((options) {
      options.dsn = dsn;
      options.environment = kReleaseMode ? 'production' : 'debug';
      options.tracesSampleRate = kReleaseMode ? 0.1 : 0.0;
      options.sendDefaultPii = false;
    });
    _enabled = true;
  }

  Future<void> trackEvent(
    String name, {
    Map<String, Object?> extras = const <String, Object?>{},
  }) async {
    if (!_enabled) return;
    await Sentry.captureMessage(
      'event:$name',
      level: SentryLevel.info,
      withScope: (scope) {
        scope.setTag('event_name', name);
        scope.setContexts('event_data', extras);
      },
    );
  }

  Future<void> trackError(
    Object error,
    StackTrace stackTrace, {
    String? hint,
    Map<String, Object?> extras = const <String, Object?>{},
  }) async {
    if (!_enabled) return;
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (hint != null && hint.isNotEmpty) {
          scope.setTag('error_hint', hint);
        }
        scope.setContexts('error_data', extras);
      },
    );
  }
}
