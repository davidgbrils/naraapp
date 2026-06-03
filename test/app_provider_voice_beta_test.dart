import 'package:flutter_test/flutter_test.dart';
import 'package:nara/providers/app_provider.dart';
import 'package:nara/services/voice_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeVoiceService implements VoiceServiceContract {
  int speakCalls = 0;
  int startListeningCalls = 0;
  String lastSpokenText = '';
  final List<void Function(String recognizedWords, bool isFinal)> _onResults = [];
  final List<void Function(String status)> _onStatuses = [];

  @override
  Future<void> dispose() async {}

  @override
  Future<void> speak(String text, {double speed = 1.0}) async {
    speakCalls++;
    lastSpokenText = text;
  }

  @override
  Future<bool> startListening({
    required String localeId,
    required void Function(String recognizedWords, bool isFinal) onResult,
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) async {
    startListeningCalls++;
    _onResults.add(onResult);
    if (onStatus != null) _onStatuses.add(onStatus);
    return true;
  }

  void emitResult(String recognizedWords, {bool isFinal = true}) {
    emitResultForSession(_onResults.length - 1, recognizedWords, isFinal: isFinal);
  }

  void emitResultForSession(int index, String recognizedWords, {bool isFinal = true}) {
    if (index < 0 || index >= _onResults.length) return;
    _onResults[index].call(recognizedWords, isFinal);
  }

  void emitStatus(String status) {
    emitStatusForSession(_onStatuses.length - 1, status);
  }

  void emitStatusForSession(int index, String status) {
    if (index < 0 || index >= _onStatuses.length) return;
    _onStatuses[index].call(status);
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

    test('stopListening prevents session restart from delayed self-speech result', () async {
      SharedPreferences.setMockInitialValues({});
      final fakeVoice = _FakeVoiceService();
      final provider = AppProvider(voiceService: fakeVoice);

      await provider.setVoiceBetaEnabled(true);
      await provider.startListening(greet: true);
      expect(provider.isListening, true);
      expect(fakeVoice.startListeningCalls, 1);
      expect(fakeVoice.lastSpokenText.trim().isNotEmpty, true);

      await provider.stopListening();
      expect(provider.isListening, false);

      fakeVoice.emitResult(fakeVoice.lastSpokenText, isFinal: true);
      await Future<void>.delayed(const Duration(milliseconds: 260));

      expect(provider.isListening, false);
      expect(fakeVoice.startListeningCalls, 1);
    });

    test('stopListening prevents follow-up restart on delayed done status', () async {
      SharedPreferences.setMockInitialValues({});
      final fakeVoice = _FakeVoiceService();
      final provider = AppProvider(voiceService: fakeVoice);

      await provider.setVoiceBetaEnabled(true);
      await provider.startListening();
      expect(provider.isListening, true);
      expect(fakeVoice.startListeningCalls, 1);

      await provider.simulateVoiceCommand('ingatkan bayar listrik besok');
      provider.clearPendingVoiceAction();

      await provider.stopListening();
      expect(provider.isListening, false);

      fakeVoice.emitStatus('done');
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(provider.isListening, false);
      expect(fakeVoice.startListeningCalls, 1);
    });

    test('startListening works again after cancel and ignores stale callbacks', () async {
      SharedPreferences.setMockInitialValues({});
      final fakeVoice = _FakeVoiceService();
      final provider = AppProvider(voiceService: fakeVoice);

      await provider.setVoiceBetaEnabled(true);
      await provider.startListening(greet: true);
      expect(provider.isListening, true);
      expect(fakeVoice.speakCalls, 1);

      await provider.stopListening();
      expect(provider.isListening, false);

      await provider.startListening(greet: true);
      expect(provider.isListening, true);
      expect(fakeVoice.startListeningCalls, 2);
      expect(fakeVoice.speakCalls, 2);

      fakeVoice.emitStatusForSession(0, 'done');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(provider.isListening, true);

      fakeVoice.emitResult('catat pengeluaran makan 10 ribu', isFinal: true);
      await Future<void>.delayed(Duration.zero);

      expect(provider.pendingVoiceAction, isNotNull);
      expect(provider.pendingVoiceAction?['type'], 'expense');
      expect(provider.isListening, false);
    });

    test('bare catat asks what to record then parses the follow-up answer', () async {
      SharedPreferences.setMockInitialValues({});
      final fakeVoice = _FakeVoiceService();
      final provider = AppProvider(voiceService: fakeVoice);

      await provider.setVoiceBetaEnabled(true);
      await provider.startListening();
      expect(fakeVoice.startListeningCalls, 1);

      fakeVoice.emitResult('catat', isFinal: true);
      await Future<void>.delayed(const Duration(milliseconds: 700));

      expect(fakeVoice.lastSpokenText, 'Ingin mencatat apa?');
      expect(provider.pendingVoiceAction, isNull);
      expect(fakeVoice.startListeningCalls, 2);
      expect(provider.isListening, true);

      fakeVoice.emitResult('makan 10 ribu', isFinal: true);
      await Future<void>.delayed(Duration.zero);

      expect(provider.pendingVoiceAction, isNotNull);
      expect(provider.pendingVoiceAction?['type'], 'expense');
      expect(provider.pendingVoiceAction?['title'], 'Makan');
      expect(provider.pendingVoiceAction?['amount'], 10000);
    });

    test('follow-up answer is processed when speech ends after partial result', () async {
      SharedPreferences.setMockInitialValues({});
      final fakeVoice = _FakeVoiceService();
      final provider = AppProvider(voiceService: fakeVoice);

      await provider.setVoiceBetaEnabled(true);
      await provider.startListening();

      fakeVoice.emitResult('catat', isFinal: true);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(fakeVoice.startListeningCalls, 2);
      expect(provider.isListening, true);

      fakeVoice.emitResult('makan 10 ribu', isFinal: false);
      fakeVoice.emitStatus('done');
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(provider.pendingVoiceAction, isNotNull);
      expect(provider.pendingVoiceAction?['type'], 'expense');
      expect(provider.pendingVoiceAction?['amount'], 10000);
      expect(provider.isListening, false);
    });

    test('stopListening clears follow-up draft so next session starts fresh', () async {
      SharedPreferences.setMockInitialValues({});
      final fakeVoice = _FakeVoiceService();
      final provider = AppProvider(voiceService: fakeVoice);

      await provider.setVoiceBetaEnabled(true);
      await provider.startListening();

      fakeVoice.emitResult('catat', isFinal: true);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(provider.hasVoiceFollowUpDraft, true);

      await provider.stopListening();
      expect(provider.hasVoiceFollowUpDraft, false);
      expect(provider.pendingVoiceAction, isNull);

      await provider.startListening(greet: true);
      expect(fakeVoice.lastSpokenText, 'Halo Budi, ada yang bisa NARA bantu?');
      expect(provider.isListening, true);
    });
  });
}
