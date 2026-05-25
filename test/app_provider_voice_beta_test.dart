import 'package:flutter_test/flutter_test.dart';
import 'package:nara/providers/app_provider.dart';
import 'package:nara/services/voice_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeVoiceService implements VoiceServiceContract {
  int speakCalls = 0;

  @override
  Future<void> dispose() async {}

  @override
  Future<void> speak(String text, {double speed = 1.0}) async {
    speakCalls++;
  }

  @override
  Future<bool> startListening({
    required String localeId,
    required void Function(String recognizedWords, bool isFinal) onResult,
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) async {
    return true;
  }

  @override
  Future<void> stopListening() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppProvider voice beta toggle', () {
    test('setVoiceBetaEnabled persists after loadAppData', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();

      await provider.setVoiceBetaEnabled(false);
      expect(provider.voiceBetaEnabled, false);

      final reloaded = AppProvider();
      await reloaded.loadAppData();
      expect(reloaded.voiceBetaEnabled, false);
    });

    test('simulateVoiceCommand is blocked when voice beta is disabled', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();

      await provider.setVoiceBetaEnabled(false);
      await provider.simulateVoiceCommand('catat pengeluaran makan 10 ribu');

      expect(provider.pendingVoiceAction, isNull);
      expect(provider.voiceErrorMessage.isNotEmpty, true);
    });

    test('simulateVoiceCommand creates pending action when voice beta is enabled', () async {
      SharedPreferences.setMockInitialValues({});
      final fakeVoice = _FakeVoiceService();
      final provider = AppProvider(voiceService: fakeVoice);

      await provider.setVoiceBetaEnabled(true);
      await provider.simulateVoiceCommand('catat pengeluaran makan 10 ribu');

      expect(provider.pendingVoiceAction, isNotNull);
      expect(provider.pendingVoiceAction?['type'], 'expense');
      expect(fakeVoice.speakCalls, greaterThan(0));
    });

    test('setVoiceConfirmEnabled persists after loadAppData', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();

      await provider.setVoiceConfirmEnabled(false);
      expect(provider.voiceConfirmEnabled, false);

      final reloaded = AppProvider();
      await reloaded.loadAppData();
      expect(reloaded.voiceConfirmEnabled, false);
    });
  });
}
