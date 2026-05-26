import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

abstract class VoiceServiceContract {
  Future<bool> startListening({
    required String localeId,
    required void Function(String recognizedWords, bool isFinal) onResult,
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  });

  Future<void> stopListening();
  Future<void> speak(String text, {double speed = 1.0});
  Future<void> dispose();
}

class VoiceService implements VoiceServiceContract {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  static bool verboseLogs = false;
  bool _isInitialized = false;

  void _log(String message) {
    if (kDebugMode && verboseLogs) {
      debugPrint(message);
    }
  }

  Future<bool> ensureInitialized({
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) async {
    if (_isInitialized) return true;

    try {
      final available = await _speech.initialize(
        onStatus: (status) => onStatus?.call(status),
        onError: (error) => onError?.call(error.errorMsg),
      );

      if (!available) {
        return false;
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      _log('Voice init error: $e');
      return false;
    }
  }

  @override
  Future<bool> startListening({
    required String localeId,
    required void Function(String recognizedWords, bool isFinal) onResult,
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) async {
    final ready = await ensureInitialized(onStatus: onStatus, onError: onError);
    if (!ready) return false;

    try {
      final resolvedLocaleId = await _resolveLocaleId(localeId);
      await _speech.listen(
        listenOptions: SpeechListenOptions(
          localeId: resolvedLocaleId,
          listenFor: const Duration(seconds: 20),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
        ),
        onResult: (result) => onResult(result.recognizedWords, result.finalResult),
      );
      return true;
    } catch (e) {
      _log('Voice listen error: $e');
      return false;
    }
  }

  Future<String> _resolveLocaleId(String preferredLocaleId) async {
    try {
      final locales = await _speech.locales();
      if (locales.isEmpty) return preferredLocaleId;

      final exact = locales.where((l) => l.localeId == preferredLocaleId);
      if (exact.isNotEmpty) return preferredLocaleId;

      final preferredLanguage = preferredLocaleId.split(RegExp('[-_]')).first.toLowerCase();
      final languageMatch = locales.where(
        (l) => l.localeId.toLowerCase().startsWith('${preferredLanguage}_') ||
            l.localeId.toLowerCase().startsWith('$preferredLanguage-'),
      );
      if (languageMatch.isNotEmpty) return languageMatch.first.localeId;

      final systemLocale = await _speech.systemLocale();
      if (systemLocale != null && systemLocale.localeId.isNotEmpty) {
        return systemLocale.localeId;
      }
    } catch (e) {
      _log('Voice locale resolve error: $e');
    }
    return preferredLocaleId;
  }

  @override
  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (e) {
      _log('Voice stop error: $e');
    }
  }

  @override
  Future<void> speak(String text, {double speed = 1.0}) async {
    final safeText = text.trim();
    if (safeText.isEmpty) return;
    try {
      await _tts.setSpeechRate(speed.clamp(0.3, 1.0));
      await _tts.speak(safeText);
    } on MissingPluginException {
      // Expected in widget/unit test environments without platform channels.
    } catch (e) {
      _log('Voice speak error: $e');
    }
  }

  @override
  Future<void> dispose() async {
    await stopListening();
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
