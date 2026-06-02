import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import '../core/formatters.dart';
import '../core/i18n.dart';
import '../services/notification_service.dart';
import '../services/telemetry_service.dart';
import '../services/voice_service.dart';

class AppProvider extends ChangeNotifier {
  static bool verboseLogs = false;

  AppProvider({VoiceServiceContract? voiceService})
      : _voiceService = voiceService ?? VoiceService();

  void _log(String message) {
    if (kDebugMode && verboseLogs) {
      debugPrint(message);
    }
  }

  void _trackEvent(String name, {Map<String, Object?> extras = const {}}) {
    unawaited(TelemetryService.instance.trackEvent(name, extras: extras));
  }

  void _trackError(
    Object error,
    StackTrace stackTrace, {
    String? hint,
    Map<String, Object?> extras = const {},
  }) {
    unawaited(
      TelemetryService.instance.trackError(
        error,
        stackTrace,
        hint: hint,
        extras: extras,
      ),
    );
  }

  bool _isOnboardingComplete = false;
  final bool _isLoggedIn = false;
  String _userName = 'Budi';
  int _selectedNavIndex = 0;
  int _transactionTabIndex = 0;
  final NotificationService _notificationService = NotificationService();
  final VoiceServiceContract _voiceService;
  int _nextNotificationId = 0;
  int _nextDebtId = 0;
  Timer? _reminderFallbackTimer;
  bool _isRunningReminderFallback = false;
  static const String _onboardingKey = 'onboarding_complete';
  static const String _userNameKey = 'user_name';
  static const String _isDarkModeKey = 'is_dark_mode';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _languageKey = 'language';
  static const String _voiceSpeedKey = 'voice_speed';
  static const String _voiceBetaEnabledKey = 'voice_beta_enabled';
  static const String _voiceConfirmEnabledKey = 'voice_confirm_enabled';
  static const String _voiceGreetingEnabledKey = 'voice_greeting_enabled';
  static const String _profileImagePathKey = 'profile_image_path';
  static const String _reminderNotifsEnabledKey = 'notif_reminder_enabled';
  static const String _debtNotifsEnabledKey = 'notif_debt_enabled';
  static const String _transactionNotifsEnabledKey = 'notif_transaction_enabled';
  static const String _transactionSwipeEnabledKey = 'transaction_swipe_enabled';
  static const String _monthlyBudgetKey = 'monthly_budget';
  static const String _expenseCategoriesKey = 'expense_categories';
  static const String _incomeCategoriesKey = 'income_categories';
  static const List<String> _defaultExpenseCategories = <String>[
    'Makan',
    'Transport',
    'Belanja',
    'Kesehatan',
    'Hiburan',
    'Lainnya',
  ];
  static const List<String> _defaultIncomeCategories = <String>[
    'Gaji',
    'Freelance',
    'Bisnis',
    'Investasi',
    'Lainnya',
  ];

  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _isAppInForeground = true;
  String _language = 'Indonesia';
  double _voiceSpeed = 1.0;
  bool _voiceBetaEnabled = true;
  bool _voiceConfirmEnabled = true;
  bool _voiceGreetingEnabled = true;
  String _profileImagePath = '';
  bool _reminderNotificationsEnabled = true;
  bool _debtNotificationsEnabled = true;
  bool _transactionNotificationsEnabled = true;
  bool _transactionSwipeEnabled = true;
  int _monthlyBudget = 0;
  int _notificationFeedVersion = 0;
  List<String> _expenseCategories = List<String>.from(_defaultExpenseCategories);
  List<String> _incomeCategories = List<String>.from(_defaultIncomeCategories);
  
  bool get isOnboardingComplete => _isOnboardingComplete;
  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  int get selectedNavIndex => _selectedNavIndex;
  int get transactionTabIndex => _transactionTabIndex;
  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isAppInForeground => _isAppInForeground;
  String get language => _language;
  double get voiceSpeed => _voiceSpeed;
  bool get voiceBetaEnabled => _voiceBetaEnabled;
  bool get voiceConfirmEnabled => _voiceConfirmEnabled;
  bool get voiceGreetingEnabled => _voiceGreetingEnabled;
  String get profileImagePath => _profileImagePath;
  bool get reminderNotificationsEnabled => _reminderNotificationsEnabled;
  bool get debtNotificationsEnabled => _debtNotificationsEnabled;
  bool get transactionNotificationsEnabled => _transactionNotificationsEnabled;
  bool get transactionSwipeEnabled => _transactionSwipeEnabled;
  int get monthlyBudget => _monthlyBudget;
  int get notificationFeedVersion => _notificationFeedVersion;
  List<String> get expenseCategories => List<String>.unmodifiable(_expenseCategories);
  List<String> get incomeCategories => List<String>.unmodifiable(_incomeCategories);

  Future<void> addExpenseCategory(String value) async {
    final next = value.trim();
    if (next.isEmpty) return;
    final exists = _expenseCategories.any(
      (item) => item.toLowerCase() == next.toLowerCase(),
    );
    if (exists) return;
    _expenseCategories.add(next);
    await _saveCategorySettings();
    notifyListeners();
  }

  Future<void> addIncomeCategory(String value) async {
    final next = value.trim();
    if (next.isEmpty) return;
    final exists = _incomeCategories.any(
      (item) => item.toLowerCase() == next.toLowerCase(),
    );
    if (exists) return;
    _incomeCategories.add(next);
    await _saveCategorySettings();
    notifyListeners();
  }

  Future<void> removeExpenseCategory(String value) async {
    final target = value.trim();
    if (target.isEmpty) return;
    if (target.toLowerCase() == 'lainnya') return;
    _expenseCategories.removeWhere(
      (item) => item.toLowerCase() == target.toLowerCase(),
    );
    if (_expenseCategories.isEmpty) {
      _expenseCategories = List<String>.from(_defaultExpenseCategories);
    }
    await _saveCategorySettings();
    notifyListeners();
  }

  Future<void> removeIncomeCategory(String value) async {
    final target = value.trim();
    if (target.isEmpty) return;
    if (target.toLowerCase() == 'lainnya') return;
    _incomeCategories.removeWhere(
      (item) => item.toLowerCase() == target.toLowerCase(),
    );
    if (_incomeCategories.isEmpty) {
      _incomeCategories = List<String>.from(_defaultIncomeCategories);
    }
    await _saveCategorySettings();
    notifyListeners();
  }
  
  Future<void> completeOnboarding() async {
    _isOnboardingComplete = true;
    await _saveOnboardingState();
    notifyListeners();
  }
  
  Future<void> setUserName(String name) async {
    _userName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, _userName);
    notifyListeners();
  }

  void setNavIndex(int index) {
    _selectedNavIndex = index.clamp(0, 3);
    notifyListeners();
  }

  void setTransactionTabIndex(int index, {bool notify = true}) {
    final safe = index.clamp(0, 2);
    if (_transactionTabIndex == safe) return;
    _transactionTabIndex = safe;
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isDarkModeKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, _notificationsEnabled);
    if (!_notificationsEnabled) {
      await _notificationService.cancelAllReminders();
    } else {
      await rescheduleAllReminders();
    }
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, _language);
    notifyListeners();
  }

  Future<void> setVoiceSpeed(double value) async {
    _voiceSpeed = value.clamp(0.5, 2.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_voiceSpeedKey, _voiceSpeed);
    notifyListeners();
  }

  Future<void> setVoiceBetaEnabled(bool value) async {
    _voiceBetaEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_voiceBetaEnabledKey, _voiceBetaEnabled);
    if (!_voiceBetaEnabled) {
      await stopListening();
      clearPendingVoiceAction();
    } else {
      clearVoiceError();
    }
    notifyListeners();
  }

  Future<void> setVoiceConfirmEnabled(bool value) async {
    _voiceConfirmEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_voiceConfirmEnabledKey, _voiceConfirmEnabled);
    notifyListeners();
  }

  Future<void> setVoiceGreetingEnabled(bool value) async {
    _voiceGreetingEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_voiceGreetingEnabledKey, _voiceGreetingEnabled);
    notifyListeners();
  }

  Future<void> setProfileImagePath(String path) async {
    _profileImagePath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImagePathKey, _profileImagePath);
    notifyListeners();
  }

  Future<void> setReminderNotificationsEnabled(bool value) async {
    _reminderNotificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderNotifsEnabledKey, value);
    if (!value) {
      for (final reminder in _reminders) {
        final notificationId = _getReminderNotificationId(reminder);
        await _notificationService.cancelReminder(notificationId);
        await _notificationService.cancelPopupAlarm(notificationId);
      }
    } else if (_notificationsEnabled) {
      await rescheduleAllReminders();
    }
    notifyListeners();
  }

  Future<void> setDebtNotificationsEnabled(bool value) async {
    _debtNotificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_debtNotifsEnabledKey, value);
    if (!value) {
      for (final debt in _debts) {
        final debtId = debt['debtId'] as int?;
        if (debtId == null) continue;
        final instantId = 2000000 + debtId;
        final scheduleBase = 2100000 + debtId * 10;
        await _notificationService.cancelReminder(instantId);
        await _notificationService.cancelReminder(scheduleBase);
        await _notificationService.cancelReminder(scheduleBase + 1);
      }
    }
    notifyListeners();
  }

  Future<void> setTransactionNotificationsEnabled(bool value) async {
    _transactionNotificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_transactionNotifsEnabledKey, value);
    notifyListeners();
  }

  Future<void> setTransactionSwipeEnabled(bool value) async {
    _transactionSwipeEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_transactionSwipeEnabledKey, value);
    notifyListeners();
  }

  void setAppInForeground(bool value) {
    _isAppInForeground = value;
    if (value) {
      unawaited(_runReminderFallbackCheck());
    }
  }

  void bumpNotificationFeedVersion() {
    _notificationFeedVersion++;
    notifyListeners();
  }

  Future<void> setMonthlyBudget(int value) async {
    _monthlyBudget = value < 0 ? 0 : value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_monthlyBudgetKey, _monthlyBudget);
    notifyListeners();
  }
  
  // Voice state
  bool _isListening = false;
  bool _isProcessing = false;
  String _lastIntent = '';
  String _voiceErrorMessage = '';
  Map<String, dynamic>? _pendingVoiceAction;
  Map<String, dynamic>? _voiceDraftAction;
  String? _voiceAwaitingField;
  bool _isRestartingVoiceFollowUp = false;
  bool _voiceSessionCancelled = false;
  int _voiceSessionId = 0;
  String _lastVoicePrompt = '';
  DateTime? _lastVoicePromptAt;
  DateTime? _voiceSuppressInputUntil;
  String _carriedVoiceText = '';
  bool _resumeWithCarry = false;
  
  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  String get lastIntent => _lastIntent;
  String get voiceErrorMessage => _voiceErrorMessage;
  Map<String, dynamic>? get pendingVoiceAction => _pendingVoiceAction;
  bool get isRestartingVoiceFollowUp => _isRestartingVoiceFollowUp;
  bool get hasVoiceFollowUpDraft =>
      _voiceAwaitingField != null && _voiceDraftAction != null;
  
  Future<void> startListening({bool greet = false}) async {
    if (!_voiceBetaEnabled) {
      _voiceErrorMessage = I18n.tByCode(
        _language == 'English' ? 'en' : 'id',
        'voice_beta_disabled_settings',
      );
      notifyListeners();
      return;
    }
    if (_isListening) return;
    _voiceSessionCancelled = false;
    final sessionId = ++_voiceSessionId;
    _isListening = true;
    _isProcessing = false;
    if (_resumeWithCarry && _carriedVoiceText.trim().isNotEmpty) {
      _lastIntent = _carriedVoiceText.trim();
    } else {
      _lastIntent = '';
      _carriedVoiceText = '';
      _resumeWithCarry = false;
    }
    _voiceErrorMessage = '';
    notifyListeners();

    final isEnglish = _language == 'English';
    final shouldGreet = greet && _voiceGreetingEnabled && !hasVoiceFollowUpDraft;
    if (shouldGreet) {
      final displayName = _userName.trim().isEmpty ? (isEnglish ? 'there' : 'kamu') : _userName.trim();
      final greeting = isEnglish
          ? 'Hello $displayName, what can NARA help you with?'
          : 'Halo $displayName, ada yang bisa NARA bantu?';
      await _voiceService.speak(
        greeting,
        speed: (_voiceSpeed / 2).clamp(0.3, 1.0),
      );
      _rememberVoicePrompt(greeting);
      await Future.delayed(const Duration(milliseconds: 350));
      if (_voiceSessionCancelled || sessionId != _voiceSessionId) return;
    }
    _voiceSuppressInputUntil = null;
    final localeId = isEnglish ? 'en_US' : 'id_ID';
    final isReady = await _voiceService.startListening(
      localeId: localeId,
      onStatus: (status) {
        if (sessionId != _voiceSessionId) return;
        if (status == 'notListening' || status == 'done') {
          Future.delayed(const Duration(milliseconds: 250), () {
            if (_voiceSessionCancelled || sessionId != _voiceSessionId) {
              _isRestartingVoiceFollowUp = false;
              _isListening = false;
              _isProcessing = false;
              notifyListeners();
              return;
            }
            if (_isProcessing) return;
            if (_pendingVoiceAction != null) return;
            final hasFollowUpDraft =
                _voiceAwaitingField != null && _voiceDraftAction != null;
            if (hasFollowUpDraft && !_isRestartingVoiceFollowUp) {
              _isRestartingVoiceFollowUp = true;
              _isListening = false;
              _isProcessing = false;
              notifyListeners();
              Future.delayed(const Duration(milliseconds: 180), () async {
                if (_voiceSessionCancelled || sessionId != _voiceSessionId) {
                  _isRestartingVoiceFollowUp = false;
                  return;
                }
                try {
                  await startListening();
                } finally {
                  _isRestartingVoiceFollowUp = false;
                }
              });
              return;
            }
            _isListening = false;
            _isProcessing = false;
            notifyListeners();
          });
        }
      },
      onError: (error) {
        if (sessionId != _voiceSessionId) return;
        _voiceErrorMessage = error;
        _isListening = false;
        _isProcessing = false;
        notifyListeners();
      },
      onResult: (recognizedWords, isFinal) async {
        if (_voiceSessionCancelled || sessionId != _voiceSessionId) return;
        final text = recognizedWords.trim();
        if (text.isEmpty) return;
        final suppressUntil = _voiceSuppressInputUntil;
        if (suppressUntil != null && DateTime.now().isBefore(suppressUntil)) {
          return;
        }
        final hasCarry = _carriedVoiceText.trim().isNotEmpty;
        final mergedText = hasCarry ? '${_carriedVoiceText.trim()} $text'.trim() : text;
        _lastIntent = mergedText;
        _isProcessing = !isFinal;
        notifyListeners();

        if (!isFinal) return;
        if (_isLikelySelfSpeech(text) || _isLikelySelfSpeech(mergedText)) {
          _isListening = false;
          _isProcessing = false;
          notifyListeners();
          await Future.delayed(const Duration(milliseconds: 180));
          if (_voiceSessionCancelled || sessionId != _voiceSessionId) return;
          _resumeWithCarry = _carriedVoiceText.trim().isNotEmpty;
          await startListening();
          return;
        }
        _isListening = false;
        _isProcessing = false;
        final finalText = mergedText;
        _carriedVoiceText = '';
        _resumeWithCarry = false;
        Map<String, dynamic>? candidate;
        if (_voiceAwaitingField != null && _voiceDraftAction != null) {
          candidate = _applyFollowUpAnswer(
            draft: _voiceDraftAction!,
            field: _voiceAwaitingField!,
            answer: finalText,
          );
        } else {
          candidate = _buildPendingVoiceAction(finalText);
        }
        final missingField = candidate == null ? null : _nextMissingField(candidate);
        if (candidate != null && missingField != null) {
          _voiceDraftAction = candidate;
          _voiceAwaitingField = missingField;
          _pendingVoiceAction = null;
          final prompt = _friendlyPromptForField(missingField, isEnglish);
          _voiceErrorMessage = prompt;
          notifyListeners();
          await _voiceService.speak(
            prompt,
            speed: (_voiceSpeed / 2).clamp(0.3, 1.0),
          );
          _rememberVoicePrompt(prompt);
          await Future.delayed(const Duration(milliseconds: 500));
          if (_voiceSessionCancelled || sessionId != _voiceSessionId) return;
          await startListening();
          return;
        }

        _voiceDraftAction = null;
        _voiceAwaitingField = null;
        _pendingVoiceAction = candidate;
        final validation = _pendingVoiceAction == null
            ? {'isValid': false, 'message': ''}
            : validateVoiceAction(_pendingVoiceAction!);
        notifyListeners();
        if (_pendingVoiceAction != null && validation['isValid'] == true) {
          final prompt = isEnglish
              ? 'Data is ready and added to draft. Please confirm on screen.'
              : 'Data sudah berhasil ditambahkan, silakan konfirmasi di layar.';
          await _voiceService.speak(
            prompt,
            speed: (_voiceSpeed / 2).clamp(0.3, 1.0),
          );
          _rememberVoicePrompt(prompt);
        } else if (_pendingVoiceAction != null) {
          final msg = (validation['message'] as String?)?.trim();
          final prompt = msg?.isNotEmpty == true
              ? msg!
              : (isEnglish
                  ? 'Please complete missing information.'
                  : 'Lengkapi informasi yang kurang ya.');
          await _voiceService.speak(
            prompt,
            speed: (_voiceSpeed / 2).clamp(0.3, 1.0),
          );
          _rememberVoicePrompt(prompt);
        } else {
          final prompt = isEnglish
              ? 'I heard: $finalText. Command not recognized yet.'
              : 'Saya dengar: $finalText. Perintah belum dikenali.';
          await _voiceService.speak(
            prompt,
            speed: (_voiceSpeed / 2).clamp(0.3, 1.0),
          );
          _rememberVoicePrompt(prompt);
        }
      },
    );

    if (isReady) return;
    if (sessionId != _voiceSessionId) return;
    _voiceErrorMessage = isEnglish
        ? 'Microphone permission is denied or speech service is unavailable.'
        : 'Izin mikrofon ditolak atau layanan suara tidak tersedia.';
    _isListening = false;
    _isProcessing = false;
    _isRestartingVoiceFollowUp = false;
    notifyListeners();
  }

  void _rememberVoicePrompt(String text) {
    _lastVoicePrompt = text.trim().toLowerCase();
    final now = DateTime.now();
    _lastVoicePromptAt = now;
    // Guard window to avoid immediate self-capture from TTS tail.
    _voiceSuppressInputUntil = now.add(const Duration(milliseconds: 1800));
  }

  bool _isLikelySelfSpeech(String text) {
    final normalized = text.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    final promptAt = _lastVoicePromptAt;
    if (promptAt == null) return false;
    final elapsed = DateTime.now().difference(promptAt);
    if (elapsed > const Duration(seconds: 6)) return false;

    if (_lastVoicePrompt.isNotEmpty &&
        (normalized == _lastVoicePrompt ||
            normalized.contains(_lastVoicePrompt) ||
            _lastVoicePrompt.contains(normalized))) {
      return true;
    }
    if (_lastVoicePrompt.isNotEmpty &&
        _tokenOverlapRatio(normalized, _lastVoicePrompt) >= 0.6) {
      return true;
    }

    final user = _userName.trim().toLowerCase();
    final systemPhrases = <String>[
      'nara bantu',
      'silakan konfirmasi',
      'please confirm',
      'perintah belum dikenali',
      'command not recognized',
      'lengkapi informasi',
      'complete missing information',
      'ingin mencatat apa',
      'what would you like to record',
      'halo $user',
      'hello $user',
      'kamu maunya',
      'which reminder type',
      'notifikasi loud alarm',
      'notification loud alarm',
      'notifikasi alarm keras',
    ];
    return systemPhrases.any((phrase) =>
        phrase.isNotEmpty &&
        (normalized == phrase || normalized.contains(phrase)));
  }

  double _tokenOverlapRatio(String source, String target) {
    Set<String> tokensOf(String value) {
      final cleaned = value
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
          .split(RegExp(r'\s+'))
          .where((e) => e.trim().isNotEmpty)
          .toSet();
      return cleaned;
    }

    final a = tokensOf(source);
    final b = tokensOf(target);
    if (a.isEmpty || b.isEmpty) return 0;
    final intersection = a.intersection(b).length;
    final base = a.length > b.length ? a.length : b.length;
    return intersection / base;
  }
  
  Future<void> stopListening() async {
    _voiceSessionCancelled = true;
    _voiceSessionId++;
    _carriedVoiceText = '';
    _resumeWithCarry = false;
    _isRestartingVoiceFollowUp = false;
    await _voiceService.stopListening();
    _isListening = false;
    _isProcessing = false;
    notifyListeners();
  }
  
  void setProcessing(bool value) {
    _isProcessing = value;
    _isListening = false;
    notifyListeners();
  }
  
  void setLastIntent(String intent) {
    _lastIntent = intent;
    notifyListeners();
  }

  void clearVoiceError() {
    if (_voiceErrorMessage.isEmpty) return;
    _voiceErrorMessage = '';
    notifyListeners();
  }

  void clearPendingVoiceAction() {
    _pendingVoiceAction = null;
    _voiceDraftAction = null;
    _voiceAwaitingField = null;
    _isRestartingVoiceFollowUp = false;
    _carriedVoiceText = '';
    _resumeWithCarry = false;
    notifyListeners();
  }

  void replacePendingVoiceAction(Map<String, dynamic> action) {
    _pendingVoiceAction = Map<String, dynamic>.from(action);
    _voiceDraftAction = null;
    _voiceAwaitingField = null;
    _voiceErrorMessage = '';
    notifyListeners();
  }

  Future<void> simulateVoiceCommand(String commandText) async {
    if (!_voiceBetaEnabled) {
      _trackEvent('voice_command_failed', extras: {
        'reason': 'voice_beta_disabled',
      });
      _voiceErrorMessage = I18n.tByCode(
        _language == 'English' ? 'en' : 'id',
        'voice_beta_disabled_settings',
      );
      notifyListeners();
      return;
    }
    final text = commandText.trim();
    if (text.isEmpty) return;
    _lastIntent = text;
    _voiceErrorMessage = '';
    _pendingVoiceAction = _buildPendingVoiceAction(text);
    notifyListeners();

    final isEnglish = _language == 'English';
    if (_pendingVoiceAction != null) {
      _trackEvent('voice_command_success', extras: {
        'recognized_type': _pendingVoiceAction?['type']?.toString() ?? 'unknown',
      });
      await _voiceService.speak(
        isEnglish
            ? 'Data is ready and added to draft. Please confirm on screen.'
            : 'Data sudah berhasil ditambahkan, silakan konfirmasi di layar.',
        speed: (_voiceSpeed / 2).clamp(0.3, 1.0),
      );
      return;
    }
    await _voiceService.speak(
      isEnglish
          ? 'Command not recognized yet.'
          : 'Perintah belum dikenali.',
      speed: (_voiceSpeed / 2).clamp(0.3, 1.0),
    );
    _trackEvent('voice_command_failed', extras: {
      'reason': 'not_recognized',
    });
  }

  Map<String, dynamic>? previewVoiceCommand(String commandText) {
    final text = commandText.trim();
    if (text.isEmpty) return null;
    return _buildPendingVoiceAction(text);
  }

  Map<String, dynamic> validateVoiceAction(
    Map<String, dynamic> action, {
    DateTime? now,
  }) {
    final type = action['type'] as String?;
    final current = now ?? DateTime.now();
    final isEnglish = _language == 'English';

    if (type == 'expense' || type == 'income') {
      final title = (action['title'] as String?)?.trim() ?? '';
      final amount = (action['amount'] as int?) ?? 0;
      if (title.isEmpty || _isWeakVoiceTitle(title)) {
        return {
          'isValid': false,
          'message': isEnglish
              ? 'Please mention a specific title for this transaction.'
              : 'Sebutkan judul transaksi yang lebih spesifik.',
        };
      }
      if (amount <= 0) {
        return {
          'isValid': false,
          'message': isEnglish
              ? 'Amount must be greater than zero.'
              : 'Nominal harus lebih besar dari nol.',
        };
      }
      return {'isValid': true, 'message': ''};
    }

    if (type == 'debt') {
      final title = (action['title'] as String?)?.trim() ?? '';
      final amount = (action['amount'] as int?) ?? 0;
      final debtType = (action['debtType'] as String?) ?? 'utang';
      if (title.isEmpty) {
        return {
          'isValid': false,
          'message': isEnglish
              ? 'Debt person name cannot be empty.'
              : 'Nama orang untuk utang/piutang tidak boleh kosong.',
        };
      }
      if (amount <= 0) {
        return {
          'isValid': false,
          'message': isEnglish
              ? 'Debt amount must be greater than zero.'
              : 'Nominal utang/piutang harus lebih besar dari nol.',
        };
      }
      if (debtType != 'utang' && debtType != 'piutang') {
        return {
          'isValid': false,
          'message': isEnglish
              ? 'Debt type is not valid.'
              : 'Tipe utang/piutang tidak valid.',
        };
      }
      return {'isValid': true, 'message': ''};
    }

    if (type == 'debt_payment') {
      final debtId = action['debtId'] as int?;
      final amount = (action['amount'] as int?) ?? 0;
      if (debtId == null || _indexOfDebtId(debtId) == -1) {
        return {
          'isValid': false,
          'message': isEnglish
              ? 'Debt target was not found.'
              : 'Target utang/piutang tidak ditemukan.',
        };
      }
      if (amount <= 0) {
        return {
          'isValid': false,
          'message': isEnglish
              ? 'Payment amount must be greater than zero.'
              : 'Nominal pembayaran harus lebih besar dari nol.',
        };
      }
      return {'isValid': true, 'message': ''};
    }

    if (type == 'reminder') {
      final title = (action['title'] as String?)?.trim() ?? '';
      final mode = (action['mode'] as String?) ?? '';
      final scheduledAt = action['scheduledAt'] as DateTime?;
      if (title.isEmpty || title.toLowerCase() == 'reminder') {
        return {
          'isValid': false,
          'message': isEnglish
              ? 'Please mention reminder title. Example: remind me to pay electricity.'
              : 'Sebutkan judul reminder dulu. Contoh: ingatkan bayar listrik.',
        };
      }
      if (scheduledAt == null) {
        return {
          'isValid': false,
          'message': isEnglish
              ? 'Please mention reminder time. Example: tomorrow 8 PM or in 10 minutes.'
              : 'Sebutkan waktu reminder. Contoh: besok jam 8 malam atau 10 menit lagi.',
        };
      }
      if (!scheduledAt.isAfter(current.subtract(const Duration(seconds: 1)))) {
        return {
          'isValid': false,
          'message': isEnglish
              ? 'Reminder time must be in the future.'
              : 'Waktu reminder harus di masa depan.',
        };
      }
      const allowedModes = <String>{'Notification', 'Loud Alarm'};
      if (!allowedModes.contains(mode)) {
        return {
          'isValid': false,
          'message': isEnglish
              ? 'Reminder mode is not valid.'
              : 'Mode reminder tidak valid.',
        };
      }
      return {'isValid': true, 'message': ''};
    }

    return {
      'isValid': false,
      'message': isEnglish
          ? 'Voice command type is not recognized.'
          : 'Jenis perintah suara tidak dikenali.',
    };
  }

  Future<bool> applyPendingVoiceAction({required bool approved}) async {
    final action = _pendingVoiceAction;
    _pendingVoiceAction = null;
    notifyListeners();
    if (!approved || action == null) {
      _trackEvent('voice_command_failed', extras: {
        'reason': !approved ? 'user_rejected' : 'empty_action',
      });
      return false;
    }
    final validation = validateVoiceAction(action);
    if (validation['isValid'] != true) {
      _trackEvent('voice_command_failed', extras: {
        'reason': 'validation_failed',
        'type': action['type']?.toString() ?? 'unknown',
      });
      _voiceErrorMessage = validation['message'] as String? ??
          (_language == 'English'
              ? 'Voice command data is invalid.'
              : 'Data perintah suara tidak valid.');
      notifyListeners();
      return false;
    }

    final type = action['type'] as String?;
    if (type == 'expense') {
      addExpense({
        'title': action['title'] as String? ?? 'Pengeluaran',
        'amount': action['amount'] as int? ?? 0,
        'category': action['category'] as String? ?? 'Lainnya',
        'time': _language == 'English' ? 'Today' : 'Hari ini',
        'icon': 'shopping_bag',
      });
      _trackEvent('voice_command_success', extras: {'type': 'expense'});
      await _voiceService.speak(
        _language == 'English'
            ? 'Expense added successfully.'
            : 'Pengeluaran berhasil ditambahkan.',
        speed: (_voiceSpeed / 2).clamp(0.3, 1.0),
      );
      return true;
    }
    if (type == 'income') {
      addIncome({
        'title': action['title'] as String? ?? 'Pemasukan',
        'amount': action['amount'] as int? ?? 0,
        'category': action['category'] as String? ?? 'Lainnya',
        'time': _language == 'English' ? 'Today' : 'Hari ini',
      });
      _trackEvent('voice_command_success', extras: {'type': 'income'});
      await _voiceService.speak(
        _language == 'English'
            ? 'Income added successfully.'
            : 'Pemasukan berhasil ditambahkan.',
        speed: (_voiceSpeed / 2).clamp(0.3, 1.0),
      );
      return true;
    }
    if (type == 'debt') {
      final dueDate = action['dueDate'] as String? ?? '';
      addDebt({
        'title': action['title'] as String? ?? '-',
        'amount': action['amount'] as int? ?? 0,
        'type': action['debtType'] as String? ?? 'utang',
        'date': _language == 'English' ? 'Today' : 'Hari ini',
        'dueDate': dueDate,
        'note': action['note'] as String? ?? '',
      });
      _trackEvent('voice_command_success', extras: {'type': 'debt'});
      await _voiceService.speak(
        _language == 'English'
            ? 'Debt or receivable added successfully.'
            : 'Utang atau piutang berhasil ditambahkan.',
        speed: (_voiceSpeed / 2).clamp(0.3, 1.0),
      );
      return true;
    }
    if (type == 'debt_payment') {
      final debtId = action['debtId'] as int?;
      final amount = (action['amount'] as int?) ?? 0;
      if (debtId == null || amount <= 0) return false;
      updateDebtPaymentById(debtId, amount);
      _trackEvent('voice_command_success', extras: {'type': 'debt_payment'});
      await _voiceService.speak(
        _language == 'English'
            ? 'Payment saved successfully.'
            : 'Pembayaran berhasil disimpan.',
        speed: (_voiceSpeed / 2).clamp(0.3, 1.0),
      );
      return true;
    }
    if (type == 'reminder') {
      final when = action['scheduledAt'] as DateTime? ?? DateTime.now().add(const Duration(minutes: 1));
      final mode = action['mode'] as String? ?? 'Notification';
      addReminder({
        'title': action['title'] as String? ?? 'Reminder',
        'type': _language == 'English' ? 'Notification' : 'Notifikasi',
        'note': action['note'] as String? ?? '',
        'date': '${when.day}/${when.month}/${when.year} • ${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}',
        'scheduledAt': when.toIso8601String(),
        'subtitle': '${when.day}/${when.month}/${when.year} • ${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}',
        'mode': mode,
        'repeatEnabled': false,
        'repeatDays': const <int>[],
        'linkedToNote': true,
        'icon': Icons.notifications_rounded,
        'soundUri': null,
        'soundName': null,
        'status': 'menunggu',
      });
      _trackEvent('voice_command_success', extras: {'type': 'reminder'});
      await _voiceService.speak(
        _language == 'English'
            ? 'Reminder added successfully.'
            : 'Reminder berhasil ditambahkan.',
        speed: (_voiceSpeed / 2).clamp(0.3, 1.0),
      );
      return true;
    }
    _trackEvent('voice_command_failed', extras: {
      'reason': 'unknown_type',
      'type': type ?? 'null',
    });
    return false;
  }

  Map<String, dynamic>? _buildPendingVoiceAction(String rawText) {
    final text = rawText.toLowerCase().trim();
    if (text.isEmpty) return null;
    if (_isBareRecordIntent(text)) {
      return {
        'type': 'record',
      };
    }

    final amount = _parseVoiceAmount(text);
    final isDebtPayment = _containsAny(text, const [
      'bayar sebagian',
      'cicil utang',
      'cicil hutang',
      'bayar cicilan',
      'bayar utang',
      'bayar hutang',
      'bayar piutang',
      'pay debt',
      'partial payment',
    ]);
    final isDebt = text.contains('utang') ||
        text.contains('hutang') ||
        text.contains('piutang') ||
        text.contains('pinjam ') ||
        text.contains('meminjam') ||
        text.contains('ngutang');
    final isExpense = text.contains('pengeluaran') ||
        text.contains('expense') ||
        text.contains('beli ') ||
        text.contains('bayar ');
    final isIncome = text.contains('pemasukan') ||
        text.contains('income') ||
        text.contains('gaji') ||
        text.contains('dapat ');
    final isReminder = text.contains('reminder') ||
        text.contains('ingatkan') ||
        text.contains('ingat ');

    if (isReminder) {
      final mode = _detectReminderModeOrNull(text);
      final scheduledAt = _hasReminderTimeCue(text) ? _extractReminderDateTime(text) : null;
      return {
        'type': 'reminder',
        'title': _extractReminderTitle(text),
        'note': '',
        'mode': mode,
        'scheduledAt': scheduledAt,
      };
    }
    if (isDebtPayment) {
      return {
        'type': 'debt_payment',
        'debtId': _findDebtIdFromText(text),
        'amount': amount,
      };
    }
    if (isDebt) {
      return {
        'type': 'debt',
        'title': _extractDebtPerson(text),
        'amount': amount,
        'debtType': _detectDebtType(text),
        'note': '',
        'dueDate': _extractDebtDueDateLabel(text),
      };
    }
    if (isExpense) {
      final category = _detectExpenseCategory(text);
      return {
        'type': 'expense',
        'title': _extractVoiceTitle(text, fallback: 'Pengeluaran'),
        'amount': amount,
        'category': category,
      };
    }
    if (isIncome) {
      final category = _detectIncomeCategory(text);
      return {
        'type': 'income',
        'title': _extractVoiceTitle(text, fallback: 'Pemasukan'),
        'amount': amount,
        'category': category,
      };
    }
    return null;
  }

  bool _isBareRecordIntent(String text) {
    final normalized = text
        .replaceAll(RegExp(r'[^a-zA-Z\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return normalized == 'catat' ||
        normalized == 'catatin' ||
        normalized == 'tolong catat' ||
        normalized == 'record' ||
        normalized == 'please record';
  }

  Map<String, dynamic>? _buildRecordDetailAction(String answer) {
    final detail = answer.trim();
    if (detail.isEmpty) return null;

    final direct = _buildPendingVoiceAction(detail);
    if (direct != null && direct['type'] != 'record') return direct;

    final withRecordVerb = _buildPendingVoiceAction('catat $detail');
    if (withRecordVerb != null && withRecordVerb['type'] != 'record') {
      return withRecordVerb;
    }

    final amount = _parseVoiceAmount(detail.toLowerCase());
    if (amount > 0) {
      final category = _detectExpenseCategory(detail);
      return {
        'type': 'expense',
        'title': _extractVoiceTitle(detail, fallback: 'Pengeluaran'),
        'amount': amount,
        'category': category,
      };
    }
    return null;
  }

  int? _findDebtIdFromText(String text) {
    if (_debts.isEmpty) return null;
    final cleaned = text
        .replaceAll('bayar', '')
        .replaceAll('sebagian', '')
        .replaceAll('cicil', '')
        .replaceAll('cicilan', '')
        .replaceAll('utang', '')
        .replaceAll('hutang', '')
        .replaceAll('piutang', '')
        .replaceAll('debt', '')
        .replaceAll('payment', '')
        .replaceAll('rp', '')
        .replaceAll(RegExp(r'\d+[.,]?\d*\s*(ribu|juta|k)?'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return _debts.first['debtId'] as int?;
    final normalized = cleaned.toLowerCase();
    for (final debt in _debts) {
      final title = (debt['title'] as String? ?? '').toLowerCase();
      if (title.isNotEmpty && (normalized.contains(title) || title.contains(normalized))) {
        return debt['debtId'] as int?;
      }
    }
    return _debts.first['debtId'] as int?;
  }

  String _detectDebtType(String text) {
    if (_containsAny(text, const [
      'piutang',
      'pinjam ke saya',
      'minjam ke saya',
      'hutang ke saya',
      'utang ke saya',
    ])) {
      return 'piutang';
    }
    return 'utang';
  }

  String _extractDebtPerson(String text) {
    final cleaned = text
        .replaceAll('catat', '')
        .replaceAll('tambah', '')
        .replaceAll('tambahkan', '')
        .replaceAll('utang', '')
        .replaceAll('hutang', '')
        .replaceAll('piutang', '')
        .replaceAll('pinjam', '')
        .replaceAll('meminjam', '')
        .replaceAll('ngutang', '')
        .replaceAll('ke saya', '')
        .replaceAll(RegExp(r'\bke\b'), '')
        .replaceAll('saya', '')
        .replaceAll('sebesar', '')
        .replaceAll('rp', '')
        .replaceAll(RegExp(r'\d+[.,]?\d*\s*(ribu|juta|k)?'), '')
        .replaceAll(RegExp(r'(jatuh tempo|tempo|tanggal|tgl).*$'), '')
        .trim();
    final normalized = _stripLeadingConnectorWords(cleaned)
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[\-\.,:;]+'), '')
        .replaceAll(RegExp(r'[\-\.,:;]+$'), '')
        .trim();
    if (normalized.isEmpty) return '-';
    return normalized
        .split(RegExp(r'\s+'))
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String _extractDebtDueDateLabel(String text) {
    final now = DateTime.now();
    DateTime? dueDate;
    if (text.contains('lusa')) {
      dueDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 2));
    } else if (text.contains('besok')) {
      dueDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    } else if (text.contains('hari ini')) {
      dueDate = DateTime(now.year, now.month, now.day);
    }
    if (dueDate == null) return '';
    const bulan = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dueDate.day} ${bulan[dueDate.month - 1]} ${dueDate.year}';
  }

  int _parseVoiceAmount(String text) {
    final isNegative = text.contains('minus') ||
        text.contains('negatif') ||
        RegExp(r'-\s*\d').hasMatch(text);

    final compactK = RegExp(r'(\d+[.,]?\d*)\s*k\b').firstMatch(text);
    if (compactK != null) {
      final raw = compactK.group(1)?.replaceAll(',', '.') ?? '0';
      final value = double.tryParse(raw) ?? 0;
      final amount = (value * 1000).round();
      return isNegative ? -amount : amount;
    }
    final juta = RegExp(r'(\d+[.,]?\d*)\s*juta').firstMatch(text);
    if (juta != null) {
      final raw = juta.group(1)?.replaceAll(',', '.') ?? '0';
      final value = double.tryParse(raw) ?? 0;
      final amount = (value * 1000000).round();
      return isNegative ? -amount : amount;
    }
    final ribu = RegExp(r'(\d+[.,]?\d*)\s*ribu').firstMatch(text);
    if (ribu != null) {
      final raw = ribu.group(1)?.replaceAll(',', '.') ?? '0';
      final value = double.tryParse(raw) ?? 0;
      final amount = (value * 1000).round();
      return isNegative ? -amount : amount;
    }
    final plain = RegExp(r'(\d[\d.]*)').firstMatch(text);
    if (plain == null) return 0;
    final normalized = plain.group(1)?.replaceAll('.', '') ?? '0';
    final amount = int.tryParse(normalized) ?? 0;
    return isNegative ? -amount : amount;
  }

  String _extractVoiceTitle(String text, {required String fallback}) {
    final cleaned = text
        .replaceAll('catat', '')
        .replaceAll('tambahkan', '')
        .replaceAll('pengeluaran', '')
        .replaceAll('pemasukan', '')
        .replaceAll('expense', '')
        .replaceAll('income', '')
        .replaceAll('saya', '')
        .replaceAll('aku', '')
        .replaceAll('gue', '')
        .replaceAll('gw', '')
        .replaceAll('sya', '')
        .replaceAll('me', '')
        .replaceAll('my', '')
        .replaceAll('beli', '')
        .replaceAll('bayar', '')
        .replaceAll('untuk', '')
        .replaceAll('buat', '')
        .replaceAll('sebesar', '')
        .replaceAll('rp', '')
        .replaceAll(RegExp(r'\d+[.,]?\d*\s*(ribu|juta)?'), '')
        .trim();
    final normalized = _stripLeadingConnectorWords(cleaned)
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[\-\.,:;]+'), '')
        .replaceAll(RegExp(r'[\-\.,:;]+$'), '')
        .trim();
    if (normalized.isEmpty) return fallback;
    return normalized
        .split(RegExp(r'\s+'))
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  bool _isWeakVoiceTitle(String title) {
    final normalized = title.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    const blocked = <String>{
      'saya',
      'aku',
      'gue',
      'gw',
      'me',
      'my',
      'i',
      'pengeluaran',
      'pemasukan',
      'expense',
      'income',
      'lainnya',
      'others',
      'other',
      '-',
    };
    if (blocked.contains(normalized)) return true;
    if (normalized.length <= 2) return true;
    return false;
  }

  String _extractReminderTitle(String text) {
    final cleaned = text
        .replaceAll('buatkan', '')
        .replaceAll('buat', '')
        .replaceAll('setel', '')
        .replaceAll('set', '')
        .replaceAll('tolong', '')
        .replaceAll('please', '')
        .replaceAll('saya', '')
        .replaceAll('ingatkan', '')
        .replaceAll('reminder', '')
        .replaceAll('ingat', '')
        .replaceAll('mode', '')
        .replaceAll('alarm', '')
        .replaceAll('notifikasi', '')
        .replaceAll(RegExp(r'\d+\s*(menit|minute|jam|hour)\s+lagi'), '')
        .replaceAll(RegExp(r'(dalam|in)\s+\d+\s*(menit|minute|jam|hour)'), '')
        .replaceAll(RegExp(r'(jam|pukul)\s+\d{1,2}([:.]\d{1,2})?'), '')
        .replaceAll('hari ini', '')
        .replaceAll('besok', '')
        .replaceAll('lusa', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final normalized = _stripLeadingConnectorWords(cleaned).trim();
    if (normalized.isEmpty) return 'Reminder';
    return normalized
        .split(RegExp(r'\s+'))
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String _stripLeadingConnectorWords(String value) {
    var result = value.trim();
    result = result.replaceFirst(RegExp(r'^[\-\.,:;]+'), '').trim();
    while (result.isNotEmpty) {
      final updated = result.replaceFirst(
        RegExp(r'^(sama|dengan|ke|untuk)\b[\s\-\.,:;]*', caseSensitive: false),
        '',
      ).trim();
      if (updated == result) break;
      result = updated;
    }
    return result;
  }

  DateTime _extractReminderDateTime(String text) {
    final now = DateTime.now();
    final relativeMinute = RegExp(r'(\d{1,3})\s*(menit|minute)\s+lagi').firstMatch(text);
    if (relativeMinute != null) {
      final minutes = int.tryParse(relativeMinute.group(1) ?? '') ?? 1;
      return now.add(Duration(minutes: minutes.clamp(1, 180)));
    }
    final relativeHour = RegExp(r'(\d{1,2})\s*(jam|hour)\s+lagi').firstMatch(text);
    if (relativeHour != null) {
      final hours = int.tryParse(relativeHour.group(1) ?? '') ?? 1;
      return now.add(Duration(hours: hours.clamp(1, 24)));
    }

    final match = RegExp(r'(jam|pukul)\s+(\d{1,2})([:.](\d{1,2}))?').firstMatch(text);
    int hour = now.hour;
    int minute = (now.minute + 1) % 60;
    var hasExplicitTime = false;
    if (match != null) {
      hasExplicitTime = true;
      hour = int.tryParse(match.group(2) ?? '') ?? hour;
      minute = int.tryParse(match.group(4) ?? '') ?? 0;
      if (hour >= 1 && hour <= 11 && text.contains('malam')) {
        hour += 12;
      }
      if (hour == 12 && (text.contains('pagi') || text.contains('siang'))) {
        hour = 0;
      }
    }

    if (!hasExplicitTime) {
      if (_containsAny(text, const ['pagi', 'morning'])) {
        hour = 8;
        minute = 0;
      } else if (_containsAny(text, const ['siang', 'afternoon'])) {
        hour = 13;
        minute = 0;
      } else if (_containsAny(text, const ['sore'])) {
        hour = 17;
        minute = 0;
      } else if (_containsAny(text, const ['malam', 'evening', 'night'])) {
        hour = 20;
        minute = 0;
      }
    }

    var target = DateTime(now.year, now.month, now.day, hour, minute);
    final weekDay = _extractWeekday(text);
    if (weekDay != null) {
      target = _nextWeekdayDate(now, weekDay, hour, minute);
      if (target.isBefore(now)) {
        target = target.add(const Duration(days: 7));
      }
    } else if (text.contains('lusa')) {
      target = target.add(const Duration(days: 2));
    } else if (text.contains('besok')) {
      target = target.add(const Duration(days: 1));
    } else if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }
    return target;
  }

  String? _detectReminderModeOrNull(String text) {
    if (text.contains('alarm') || text.contains('keras')) {
      return 'Loud Alarm';
    }
    if (text.contains('notifikasi') || text.contains('notification')) {
      return 'Notification';
    }
    return null;
  }

  bool _hasReminderTimeCue(String text) {
    return RegExp(r'(jam|pukul)\s+\d{1,2}([:.]\d{1,2})?').hasMatch(text) ||
        RegExp(r'\d{1,3}\s*(menit|minute|jam|hour)\s+lagi').hasMatch(text) ||
        _containsAny(text, const [
          'hari ini',
          'besok',
          'lusa',
          'nanti',
          'pagi',
          'siang',
          'sore',
          'malam',
          'morning',
          'afternoon',
          'evening',
          'night',
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday',
          'senin',
          'selasa',
          'rabu',
          'kamis',
          'jumat',
          'sabtu',
          'minggu',
        ]);
  }

  String? _nextMissingField(Map<String, dynamic> action) {
    final type = action['type'] as String? ?? '';
    if (type == 'record') return 'record_detail';
    if (type == 'reminder') {
      final title = (action['title'] as String?)?.trim() ?? '';
      final scheduledAt = action['scheduledAt'] as DateTime?;
      final mode = (action['mode'] as String?) ?? '';
      if (title.isEmpty || title.toLowerCase() == 'reminder') return 'reminder_title';
      if (scheduledAt == null) return 'reminder_time';
      if (mode.isEmpty) return 'reminder_mode';
      return null;
    }
    if (type == 'expense' || type == 'income') {
      final title = (action['title'] as String?)?.trim() ?? '';
      final amount = (action['amount'] as int?) ?? 0;
      if (title.isEmpty || _isWeakVoiceTitle(title)) return '${type}_title';
      if (amount <= 0) return '${type}_amount';
      return null;
    }
    if (type == 'debt') {
      final title = (action['title'] as String?)?.trim() ?? '';
      final amount = (action['amount'] as int?) ?? 0;
      final debtType = (action['debtType'] as String?) ?? '';
      if (title.isEmpty || title == '-') return 'debt_title';
      if (amount <= 0) return 'debt_amount';
      if (debtType != 'utang' && debtType != 'piutang') return 'debt_type';
      return null;
    }
    if (type == 'debt_payment') {
      final debtId = action['debtId'] as int?;
      final amount = (action['amount'] as int?) ?? 0;
      if (debtId == null || _indexOfDebtId(debtId) == -1) return 'debt_payment_target';
      if (amount <= 0) return 'debt_payment_amount';
      return null;
    }
    return null;
  }

  String _friendlyPromptForField(String field, bool isEnglish) {
    switch (field) {
      case 'record_detail':
        return isEnglish
            ? 'What would you like to record?'
            : 'Ingin mencatat apa?';
      case 'reminder_title':
        return isEnglish
            ? 'Sure. What should I remind you about? For example: pay electricity bill.'
            : 'Siap. Mau diingatkan tentang apa? Contohnya: bayar listrik.';
      case 'reminder_time':
        return isEnglish
            ? 'Nice. When should I remind you? You can say tomorrow at 8 PM, or in 10 minutes.'
            : 'Oke. Ingatkannya kapan? Kamu bisa bilang besok jam 8 malam, atau 10 menit lagi.';
      case 'reminder_mode':
        return isEnglish
            ? 'Which reminder type do you prefer: Notification or Alarm?'
            : 'Untuk jenis pengingatnya mau yang mana: Notifikasi atau Alarm?';
      case 'expense_title':
        return isEnglish
            ? 'What is this expense for?'
            : 'Pengeluarannya untuk apa ya?';
      case 'expense_amount':
        return isEnglish
            ? 'How much is the expense amount?'
            : 'Nominal pengeluarannya berapa?';
      case 'income_title':
        return isEnglish
            ? 'What is the income source?'
            : 'Sumber pemasukannya dari mana?';
      case 'income_amount':
        return isEnglish
            ? 'How much is the income amount?'
            : 'Nominal pemasukannya berapa?';
      case 'debt_title':
        return isEnglish
            ? 'Who is this debt or receivable with?'
            : 'Ini utang atau piutang dengan siapa ya?';
      case 'debt_amount':
        return isEnglish
            ? 'How much is the debt or receivable amount?'
            : 'Nominal utang atau piutangnya berapa?';
      case 'debt_type':
        return isEnglish
            ? 'Is this your debt, or your receivable?'
            : 'Ini termasuk utang kamu, atau piutang kamu?';
      case 'debt_payment_target':
        return isEnglish
            ? 'Which debt do you want to pay first? Please mention the name.'
            : 'Mau bayar utang yang mana dulu? Sebutkan namanya ya.';
      case 'debt_payment_amount':
        return isEnglish
            ? 'How much do you want to pay?'
            : 'Mau bayar berapa dulu?';
      default:
        return isEnglish
            ? 'Please complete the missing information.'
            : 'Lengkapi informasi yang masih kurang ya.';
    }
  }

  Map<String, dynamic> _applyFollowUpAnswer({
    required Map<String, dynamic> draft,
    required String field,
    required String answer,
  }) {
    final next = Map<String, dynamic>.from(draft);
    final text = answer.toLowerCase().trim();
    switch (field) {
      case 'record_detail':
        return _buildRecordDetailAction(answer) ?? next;
      case 'reminder_title':
        next['title'] = _extractReminderTitle(text);
        break;
      case 'reminder_time':
        next['scheduledAt'] = _extractReminderDateTime(text);
        break;
      case 'reminder_mode':
        next['mode'] = _detectReminderModeOrNull(text);
        break;
      case 'expense_title':
      case 'income_title':
        final extractedTitle = _extractVoiceTitle(
          text,
          fallback: field.startsWith('expense') ? 'Pengeluaran' : 'Pemasukan',
        );
        next['title'] = extractedTitle;
        if (field == 'expense_title') {
          next['category'] = _detectExpenseCategory(text);
        } else {
          next['category'] = _detectIncomeCategory(text);
        }
        break;
      case 'expense_amount':
      case 'income_amount':
        next['amount'] = _parseVoiceAmount(text);
        break;
      case 'debt_title':
        next['title'] = _extractDebtPerson(text);
        break;
      case 'debt_amount':
        next['amount'] = _parseVoiceAmount(text);
        break;
      case 'debt_type':
        next['debtType'] = _detectDebtType(text);
        break;
      case 'debt_payment_target':
        next['debtId'] = _findDebtIdFromText(text);
        break;
      case 'debt_payment_amount':
        next['amount'] = _parseVoiceAmount(text);
        break;
    }
    return next;
  }

  String _detectExpenseCategory(String text) {
    final normalized = text.toLowerCase();
    for (final category in _expenseCategories) {
      final key = category.trim().toLowerCase();
      if (key.isEmpty || key == 'lainnya') continue;
      if (normalized.contains(key)) return category;
    }

    if (_containsAny(normalized, const [
      'makan',
      'kopi',
      'resto',
      'restoran',
      'sarapan',
      'makan siang',
      'makan malam',
      'ketoprak',
      'tetoprak',
      'nasi',
      'gorengan',
      'bakso',
      'mie',
      'soto',
      'pecel',
      'gado',
      'ayam',
      'lauk',
      'jajan',
      'snack',
      'cafe',
      'warung',
    ])) {
      return 'Makan';
    }
    if (_containsAny(normalized, const [
      'transport',
      'bensin',
      'ojek',
      'grab',
      'gojek',
      'parkir',
      'tol',
      'bus',
      'kereta',
      'taksi',
      'angkot',
      'bbm',
      'solar',
      'pertalite',
      'pertamax',
    ])) {
      return 'Transport';
    }
    if (_containsAny(normalized, const [
      'belanja',
      'shopping',
      'toko',
      'baju',
      'sepatu',
      'celana',
      'tas',
      'kosmetik',
      'skincare',
      'minimarket',
      'supermarket',
      'marketplace',
      'online shop',
    ])) {
      return 'Belanja';
    }
    if (_containsAny(normalized, const [
      'obat',
      'dokter',
      'rumah sakit',
      'klinik',
      'kesehatan',
      'apotek',
      'vitamin',
      'medical',
      'bpjs',
      'checkup',
    ])) {
      return 'Kesehatan';
    }
    if (_containsAny(normalized, const [
      'hiburan',
      'film',
      'bioskop',
      'game',
      'netflix',
      'spotify',
      'youtube',
      'rekreasi',
      'wisata',
      'konser',
    ])) {
      return 'Hiburan';
    }
    return 'Lainnya';
  }

  String _detectIncomeCategory(String text) {
    final normalized = text.toLowerCase();
    for (final category in _incomeCategories) {
      final key = category.trim().toLowerCase();
      if (key.isEmpty || key == 'lainnya') continue;
      if (normalized.contains(key)) return category;
    }

    if (_containsAny(normalized, const ['gaji', 'salary', 'payroll', 'kantor', 'bonus'])) {
      return 'Gaji';
    }
    if (_containsAny(normalized, const ['freelance', 'project', 'proyek', 'client', 'jasa'])) {
      return 'Freelance';
    }
    if (_containsAny(normalized, const ['bisnis', 'usaha', 'jualan', 'toko', 'omzet', 'penjualan'])) {
      return 'Bisnis';
    }
    if (_containsAny(normalized, const ['investasi', 'dividen', 'saham', 'crypto', 'reksa', 'obligasi'])) {
      return 'Investasi';
    }
    return 'Lainnya';
  }

  bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  int? _extractWeekday(String text) {
    const mapping = <String, int>{
      'senin': DateTime.monday,
      'selasa': DateTime.tuesday,
      'rabu': DateTime.wednesday,
      'kamis': DateTime.thursday,
      'jumat': DateTime.friday,
      'jum\'at': DateTime.friday,
      'sabtu': DateTime.saturday,
      'minggu': DateTime.sunday,
      'sunday': DateTime.sunday,
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sun': DateTime.sunday,
      'mon': DateTime.monday,
      'tue': DateTime.tuesday,
      'wed': DateTime.wednesday,
      'thu': DateTime.thursday,
      'fri': DateTime.friday,
      'sat': DateTime.saturday,
    };
    for (final entry in mapping.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    return null;
  }

  DateTime _nextWeekdayDate(
    DateTime now,
    int targetWeekday,
    int hour,
    int minute,
  ) {
    var delta = (targetWeekday - now.weekday) % 7;
    if (delta < 0) delta += 7;
    return DateTime(
      now.year,
      now.month,
      now.day + delta,
      hour,
      minute,
    );
  }

  // Transactions
  final List<Map<String, dynamic>> _expenses = [];
  
  final List<Map<String, dynamic>> _incomes = [];
  
  final List<Map<String, dynamic>> _debts = [];
  
  final List<Map<String, dynamic>> _reminders = [
    {
      'title': 'Pay Electricity',
      'date': 'Tomorrow',
      'status': 'menunggu',
      'createdAt': DateTime.now(),
    },
  ];
  
  List<Map<String, dynamic>> get expenses => _expenses;
  List<Map<String, dynamic>> get incomes => _incomes;
  List<Map<String, dynamic>> get debts => _debts;
  List<Map<String, dynamic>> get reminders => _reminders;
  List<Map<String, dynamic>> get activeRemindersList => _reminders.where((r) => r['status'] == 'menunggu').toList();
  List<Map<String, dynamic>> get completedRemindersList => _reminders.where((r) => r['status'] == 'selesai').toList();
  
  double get todayExpense => _expenses.fold(0, (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0));
  double get totalActiveDebt => _debts
      .where((debt) => debt['type'] == 'utang')
      .fold(0, (sum, debt) => sum + _remainingDebtAmount(debt));
  int get activeReminders => _reminders.where((r) => r['status'] == 'menunggu').length;

  double _remainingDebtAmount(Map<String, dynamic> debt) {
    final amount = (debt['amount'] as num?)?.toDouble() ?? 0;
    final paidAmount = (debt['paidAmount'] as num?)?.toDouble() ?? 0;
    final remaining = amount - paidAmount;
    return remaining < 0 ? 0 : remaining;
  }

  static const String _expensesKey = 'expenses';
  static const String _incomesKey = 'incomes';
  static const String _debtsKey = 'debts';
  static const String _remindersKey = 'reminders';
  
  void addExpense(Map<String, dynamic> expense) {
    expense['createdAt'] = expense['createdAt'] ?? DateTime.now();
    _expenses.insert(0, expense);
    _saveExpenses();
    notifyListeners();
  }

  void updateExpenseAt(int index, Map<String, dynamic> updatedExpense) {
    if (index < 0 || index >= _expenses.length) return;
    updatedExpense['createdAt'] = _expenses[index]['createdAt'] ?? DateTime.now();
    updatedExpense['updatedAt'] = DateTime.now();
    _expenses[index] = updatedExpense;
    _saveExpenses();
    notifyListeners();
  }

  void removeExpenseAt(int index) {
    if (index < 0 || index >= _expenses.length) return;
    _expenses.removeAt(index);
    _saveExpenses();
    notifyListeners();
  }

  void restoreExpenseAt(int index, Map<String, dynamic> expense) {
    final safeIndex = index.clamp(0, _expenses.length);
    _expenses.insert(safeIndex, Map<String, dynamic>.from(expense));
    _saveExpenses();
    notifyListeners();
  }
  
  void addIncome(Map<String, dynamic> income) {
    income['createdAt'] = income['createdAt'] ?? DateTime.now();
    _incomes.insert(0, income);
    _saveIncomes();
    notifyListeners();
  }
  
  void addDebt(Map<String, dynamic> debt) {
    debt['createdAt'] = debt['createdAt'] ?? DateTime.now();
    debt['paidAmount'] = debt['paidAmount'] ?? 0;
    debt['status'] = debt['status'] ?? 'berjalan';
    _ensureDebtId(debt);
    _debts.insert(0, debt);
    _saveDebts();
    notifyListeners();
  }

  void removeIncomeAt(int index) {
    if (index < 0 || index >= _incomes.length) return;
    _incomes.removeAt(index);
    _saveIncomes();
    notifyListeners();
  }

  void restoreIncomeAt(int index, Map<String, dynamic> income) {
    final safeIndex = index.clamp(0, _incomes.length);
    _incomes.insert(safeIndex, Map<String, dynamic>.from(income));
    _saveIncomes();
    notifyListeners();
  }

  void updateDebtAt(int index, Map<String, dynamic> updatedDebt) {
    if (index < 0 || index >= _debts.length) return;

    final current = _debts[index];
    final totalAmount = ((updatedDebt['amount'] as num?)?.toInt() ?? 0).clamp(0, 1 << 30);
    final currentPaid = (current['paidAmount'] as num?)?.toInt() ?? 0;
    final nextPaid = currentPaid.clamp(0, totalAmount);

    updatedDebt['createdAt'] = current['createdAt'] ?? DateTime.now();
    updatedDebt['updatedAt'] = DateTime.now();
    updatedDebt['debtId'] = current['debtId'] ?? updatedDebt['debtId'];
    updatedDebt['paidAmount'] = nextPaid;
    updatedDebt['status'] = nextPaid >= totalAmount ? 'lunas' : 'berjalan';
    updatedDebt['paymentHistory'] = current['paymentHistory'] ?? updatedDebt['paymentHistory'] ?? <Map<String, dynamic>>[];

    _debts[index] = updatedDebt;
    _saveDebts();
    notifyListeners();
  }

  void updateDebtPaymentById(int debtId, int paymentAmount) {
    final index = _indexOfDebtId(debtId);
    if (index == -1) return;

    updateDebtPayment(index, paymentAmount);
  }

  void markDebtAsPaidById(int debtId) {
    final index = _indexOfDebtId(debtId);
    if (index == -1) return;

    markDebtAsPaid(index);
  }

  void removeDebtAt(int index) {
    if (index < 0 || index >= _debts.length) return;
    _debts.removeAt(index);
    _saveDebts();
    notifyListeners();
  }

  void restoreDebtAt(int index, Map<String, dynamic> debt) {
    final safeIndex = index.clamp(0, _debts.length);
    _debts.insert(safeIndex, Map<String, dynamic>.from(debt));
    _saveDebts();
    notifyListeners();
  }

  void updateDebtPayment(int index, int paymentAmount) {
    if (index < 0 || index >= _debts.length || paymentAmount <= 0) return;

    final debt = _debts[index];
    final totalAmount = (debt['amount'] as num?)?.toInt() ?? 0;
    final currentPaidAmount = (debt['paidAmount'] as num?)?.toInt() ?? 0;
    final nextPaidAmount = (currentPaidAmount + paymentAmount).clamp(0, totalAmount);
    final appliedPayment = nextPaidAmount - currentPaidAmount;

    debt['paidAmount'] = nextPaidAmount;
    debt['status'] = nextPaidAmount >= totalAmount ? 'lunas' : 'berjalan';
    if (appliedPayment > 0) {
      _appendDebtPaymentHistory(debt, appliedPayment, isFinalSettlement: nextPaidAmount >= totalAmount);
      _trackEvent('debt_payment_saved', extras: {
        'debt_id': debt['debtId'] as Object? ?? index,
        'payment_amount': appliedPayment,
        'remaining_amount': (totalAmount - nextPaidAmount).clamp(0, totalAmount),
        'is_final_settlement': nextPaidAmount >= totalAmount,
      });
    }
    _saveDebts();
    notifyListeners();
  }

  void markDebtAsPaid(int index) {
    if (index < 0 || index >= _debts.length) return;

    final debt = _debts[index];
    final totalAmount = (debt['amount'] as num?)?.toInt() ?? 0;
    final currentPaidAmount = (debt['paidAmount'] as num?)?.toInt() ?? 0;
    final appliedPayment = (totalAmount - currentPaidAmount).clamp(0, totalAmount);
    debt['paidAmount'] = totalAmount;
    debt['status'] = 'lunas';
    if (appliedPayment > 0) {
      _appendDebtPaymentHistory(debt, appliedPayment, isFinalSettlement: true);
    }
    _saveDebts();
    notifyListeners();
  }

  void _appendDebtPaymentHistory(
    Map<String, dynamic> debt,
    int amount, {
    required bool isFinalSettlement,
  }) {
    final history = (debt['paymentHistory'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        <Map<String, dynamic>>[];
    history.insert(0, {
      'amount': amount,
      'at': DateTime.now().toIso8601String(),
      'type': isFinalSettlement ? 'lunas' : 'sebagian',
    });
    debt['paymentHistory'] = history.take(20).toList();
  }
  
  void addReminder(Map<String, dynamic> reminder) {
    reminder['createdAt'] = reminder['createdAt'] ?? DateTime.now();
    _ensureReminderNotificationId(reminder);
    _reminders.insert(0, reminder);
    _scheduleReminderNotification(reminder);
    _trackEvent('reminder_created', extras: {
      'reminder_id': reminder['notificationId'] as Object? ?? -1,
      'mode': (reminder['mode'] as String?) ?? (reminder['type'] as String?) ?? 'Notification',
      'has_repeat': reminder['repeatEnabled'] as Object? ?? false,
    });
    _saveReminders();
    notifyListeners();
  }

  void updateReminder(int index, Map<String, dynamic> updatedReminder) {
    if (index < 0 || index >= _reminders.length) return;

    updatedReminder['createdAt'] = _reminders[index]['createdAt'] ?? DateTime.now();
    updatedReminder['notificationId'] = _reminders[index]['notificationId'] ?? updatedReminder['notificationId'];
    _ensureReminderNotificationId(updatedReminder);
    _reminders[index] = updatedReminder;
    final updatedNotificationId = _getReminderNotificationId(updatedReminder);
    _notificationService.cancelReminder(updatedNotificationId);
    _notificationService.cancelPopupAlarm(updatedNotificationId);
    _scheduleReminderNotification(updatedReminder);
    _saveReminders();
    notifyListeners();
  }

  void toggleReminderStatus(int index) {
    if (index < 0 || index >= _reminders.length) return;

    final currentStatus = _reminders[index]['status'] as String? ?? 'menunggu';
    final reminder = _reminders[index];
    final isRoutine = _hasRoutineSchedule(reminder);
    final nextStatus = currentStatus == 'menunggu' ? 'selesai' : 'menunggu';

    if (nextStatus == 'selesai') {
      if (isRoutine) {
        final moved = _moveRoutineToNextOccurrence(reminder, DateTime.now());
        if (moved) {
          _scheduleReminderNotification(reminder);
        } else {
          reminder['status'] = 'selesai';
          final notificationId = _getReminderNotificationId(reminder);
          _notificationService.cancelReminder(notificationId);
          _notificationService.cancelPopupAlarm(notificationId);
        }
      } else {
        reminder['status'] = 'selesai';
        final notificationId = _getReminderNotificationId(reminder);
        _notificationService.cancelReminder(notificationId);
        _notificationService.cancelPopupAlarm(notificationId);
      }
    } else {
      reminder['status'] = 'menunggu';
      _normalizeReminderScheduleOnReactivation(reminder);
      _scheduleReminderNotification(reminder);
    }

    _saveReminders();
    notifyListeners();
  }

  Future<bool> sendDebtReminderById(int debtId) async {
    if (!_notificationsEnabled || !_debtNotificationsEnabled) return false;
    final index = _indexOfDebtId(debtId);
    if (index == -1) return false;

    final debt = _debts[index];
    final isDebtOwed = (debt['type'] as String?) == 'utang';
    final person = (debt['title'] as String?)?.trim().isNotEmpty == true
        ? (debt['title'] as String).trim()
        : 'Kontak';
    final dueDate = (debt['dueDate'] as String?)?.trim() ?? '';
    final amount = (debt['amount'] as num?)?.toInt() ?? 0;
    final paidAmount = (debt['paidAmount'] as num?)?.toInt() ?? 0;
    final remaining = (amount - paidAmount).clamp(0, amount);
    final title = isDebtOwed
        ? 'Pengingat Utang ke $person'
        : 'Pengingat Piutang dari $person';
    final body = dueDate.isNotEmpty
        ? 'Sisa ${formatRupiah(remaining)} • Jatuh tempo: $dueDate'
        : 'Sisa ${formatRupiah(remaining)}';
    final id = 2000000 + (debt['debtId'] as int? ?? index);

    await _notificationService.showReminderNow(
      id,
      title,
      body,
      payload: 'debt:${debt['debtId'] ?? index}',
      mode: 'Notification',
    );
    return true;
  }

  Future<bool> scheduleDebtReminderById(
    int debtId, {
    required int daysBeforeDue,
  }) async {
    if (!_notificationsEnabled || !_debtNotificationsEnabled) return false;
    final index = _indexOfDebtId(debtId);
    if (index == -1) return false;

    final debt = _debts[index];
    final dueDate = _parseDebtDueDate((debt['dueDate'] as String?)?.trim() ?? '');
    if (dueDate == null) return false;

    final now = DateTime.now();
    final scheduledDate = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day - daysBeforeDue,
      9,
      0,
    );
    if (!scheduledDate.isAfter(now)) return false;

    final isDebtOwed = (debt['type'] as String?) == 'utang';
    final person = (debt['title'] as String?)?.trim().isNotEmpty == true
        ? (debt['title'] as String).trim()
        : 'Kontak';
    final amount = (debt['amount'] as num?)?.toInt() ?? 0;
    final paidAmount = (debt['paidAmount'] as num?)?.toInt() ?? 0;
    final remaining = (amount - paidAmount).clamp(0, amount);
    final title = isDebtOwed
        ? 'Pengingat Utang ke $person'
        : 'Pengingat Piutang dari $person';
    final bodyPrefix = daysBeforeDue == 1 ? 'H-1' : 'Hari ini';
    final body = '$bodyPrefix • Sisa ${formatRupiah(remaining)} • Jatuh tempo: ${debt['dueDate']}';
    final idBase = 2100000 + (debt['debtId'] as int? ?? index) * 10;
    final id = idBase + (daysBeforeDue == 1 ? 1 : 0);

    await _notificationService.cancelReminder(id);
    await _notificationService.scheduleReminder(
      id,
      title,
      body,
      scheduledDate: scheduledDate,
      payload: 'debt:${debt['debtId'] ?? index}',
      mode: 'Notification',
    );
    final scheduleKey = daysBeforeDue == 1 ? 'debtReminderH1At' : 'debtReminderH0At';
    debt[scheduleKey] = scheduledDate.toIso8601String();
    _saveDebts();
    notifyListeners();
    return true;
  }

  Future<bool> cancelDebtReminderById(
    int debtId, {
    required int daysBeforeDue,
  }) async {
    final index = _indexOfDebtId(debtId);
    if (index == -1) return false;

    final debt = _debts[index];
    final idBase = 2100000 + (debt['debtId'] as int? ?? index) * 10;
    final id = idBase + (daysBeforeDue == 1 ? 1 : 0);
    await _notificationService.cancelReminder(id);

    final scheduleKey = daysBeforeDue == 1 ? 'debtReminderH1At' : 'debtReminderH0At';
    debt.remove(scheduleKey);
    _saveDebts();
    notifyListeners();
    return true;
  }

  DateTime? _parseDebtDueDate(String raw) {
    if (raw.isEmpty) return null;

    final direct = DateTime.tryParse(raw);
    if (direct != null) return direct;

    final normalized = raw.replaceAll(',', '').trim();
    final match = RegExp(r'^(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})').firstMatch(normalized);
    if (match == null) return null;
    final day = int.tryParse(match.group(1) ?? '');
    final monthName = (match.group(2) ?? '').toLowerCase();
    final year = int.tryParse(match.group(3) ?? '');
    if (day == null || year == null) return null;

    const months = <String, int>{
      'jan': 1,
      'januari': 1,
      'feb': 2,
      'februari': 2,
      'mar': 3,
      'maret': 3,
      'apr': 4,
      'april': 4,
      'mei': 5,
      'jun': 6,
      'juni': 6,
      'jul': 7,
      'juli': 7,
      'agu': 8,
      'agustus': 8,
      'sep': 9,
      'september': 9,
      'okt': 10,
      'oktober': 10,
      'nov': 11,
      'november': 11,
      'des': 12,
      'desember': 12,
    };
    final month = months[monthName];
    if (month == null) return null;
    return DateTime(year, month, day);
  }

  void updateIncomeAt(int index, Map<String, dynamic> updatedIncome) {
    if (index < 0 || index >= _incomes.length) return;
    updatedIncome['createdAt'] = _incomes[index]['createdAt'] ?? DateTime.now();
    updatedIncome['updatedAt'] = DateTime.now();
    _incomes[index] = updatedIncome;
    _saveIncomes();
    notifyListeners();
  }


  bool hasPotentialDuplicateExpense({
    required String title,
    required int amount,
    required String category,
    Duration within = const Duration(minutes: 10),
  }) {
    final now = DateTime.now();
    final normalizedTitle = title.trim().toLowerCase();
    return _expenses.any((expense) {
      final existingTitle = (expense['title'] as String? ?? '').trim().toLowerCase();
      final existingAmount = (expense['amount'] as num?)?.toInt() ?? 0;
      final existingCategory = (expense['category'] as String? ?? '').trim();
      final createdAt = expense['createdAt'] as DateTime?;
      if (createdAt == null) return false;
      return existingTitle == normalizedTitle &&
          existingAmount == amount &&
          existingCategory == category &&
          now.difference(createdAt).abs() <= within;
    });
  }

  bool hasPotentialDuplicateIncome({
    required String title,
    required int amount,
    required String category,
    Duration within = const Duration(minutes: 10),
  }) {
    final now = DateTime.now();
    final normalizedTitle = title.trim().toLowerCase();
    return _incomes.any((income) {
      final existingTitle = (income['title'] as String? ?? '').trim().toLowerCase();
      final existingAmount = (income['amount'] as num?)?.toInt() ?? 0;
      final existingCategory = (income['category'] as String? ?? '').trim();
      final createdAt = income['createdAt'] as DateTime?;
      if (createdAt == null) return false;
      return existingTitle == normalizedTitle &&
          existingAmount == amount &&
          existingCategory == category &&
          now.difference(createdAt).abs() <= within;
    });
  }

  void removeReminderAt(int index) {
    if (index < 0 || index >= _reminders.length) return;
    final notificationId = _getReminderNotificationId(_reminders[index]);
    _notificationService.cancelReminder(notificationId);
    _notificationService.cancelPopupAlarm(notificationId);
    _reminders.removeAt(index);
    _saveReminders();
    notifyListeners();
  }

  // Notification Scheduling
  Future<void> _scheduleReminderNotification(Map<String, dynamic> reminder) async {
    try {
      final notificationId = _getReminderNotificationId(reminder);
      if (!_notificationsEnabled || !_reminderNotificationsEnabled) {
        await _notificationService.cancelReminder(notificationId);
        await _notificationService.cancelPopupAlarm(notificationId);
        return;
      }
      final scheduledDateTime = _nextReminderOccurrence(reminder);
      if (scheduledDateTime == null || scheduledDateTime.isBefore(DateTime.now())) return;

      final title = reminder['title'] as String? ?? 'Reminder';
      final body = _buildReminderNotificationBody(reminder);
      final mode = _normalizeReminderMode(
        (reminder['mode'] as String?) ?? (reminder['type'] as String?) ?? 'Notification',
      );
      final soundUri = reminder['soundUri'] as String?;
      reminder['mode'] = mode;
      reminder['scheduledAt'] = scheduledDateTime.toIso8601String();

      if (mode == 'Notification') {
        await _notificationService.scheduleReminder(
          notificationId,
          title,
          body,
          scheduledDate: scheduledDateTime,
          payload: 'reminder:$notificationId',
          mode: mode,
          soundUri: soundUri,
        );
        await _notificationService.cancelPopupAlarm(notificationId);
      } else {
        await _notificationService.cancelReminder(notificationId);
        await _notificationService.schedulePopupAlarm(
          notificationId,
          scheduledDateTime,
          mode: mode,
          title: title,
          body: body,
        );
      }
    } catch (e, st) {
      _trackError(e, st, hint: 'schedule_reminder_notification');
      _log('Error scheduling notification: $e');
    }
  }

  void snoozeReminderByIndex(int index, {int seconds = 300}) {
    if (index < 0 || index >= _reminders.length) return;
    _snoozeReminderAt(index, seconds);
    notifyListeners();
  }

  Future<void> previewReminderAt(int index) async {
    if (index < 0 || index >= _reminders.length) return;
    if (!_notificationsEnabled || !_reminderNotificationsEnabled) return;

    final reminder = _reminders[index];
    final mode = _normalizeReminderMode(
      (reminder['mode'] as String?) ?? (reminder['type'] as String?) ?? 'Notification',
    );
    final notificationId = _getReminderNotificationId(reminder);
    final previewId = notificationId + 1000000;
    await _notificationService.cancelReminder(previewId);
    await _notificationService.showReminderNow(
      previewId,
      reminder['title'] as String? ?? 'Reminder',
      _buildReminderNotificationBody(reminder),
      payload: 'reminder:$notificationId',
      mode: mode,
      soundUri: reminder['soundUri'] as String?,
    );
  }

  DateTime? _parseDateString(String dateString) {
    try {
      final isoDateTime = DateTime.tryParse(dateString);
      if (isoDateTime != null) {
        return isoDateTime;
      }

      // Expected format: "DD MonthName YYYY Ã¢â‚¬Â¢ HH:MM" (legacy broken bullet also handled)
      final normalizedBullet = dateString
          .replaceAll('ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢', '•')
          .replaceAll('Ã¢â‚¬Â¢', '•')
          .replaceAll('â€¢', '•');
      if (!normalizedBullet.contains('•')) return null;

      final parts = normalizedBullet.split('•');
      if (parts.length != 2) return null;

      final datePart = parts[0].trim(); // "DD MonthName YYYY"
      final timePart = parts[1].trim(); // "HH:MM"

      final dateComponents = datePart.split(' ');
      if (dateComponents.length != 3) return null;

      final day = int.tryParse(dateComponents[0]);
      final monthName = dateComponents[1];
      final year = int.tryParse(dateComponents[2]);

      if (day == null || year == null) return null;

      final month = _getMonthNumber(monthName);
      if (month == null) return null;

      final timeComponents = timePart.split(':');
      if (timeComponents.length != 2) return null;

      final hour = int.tryParse(timeComponents[0]);
      final minute = int.tryParse(timeComponents[1]);

      if (hour == null || minute == null) return null;

      return DateTime(year, month, day, hour, minute);
    } catch (e, st) {
      _trackError(e, st, hint: 'parse_date_string');
      _log('Error parsing date: $e');
      return null;
    }
  }

  DateTime? _extractScheduledDateTime(Map<String, dynamic> reminder) {
    final scheduledAt = DateTime.tryParse(reminder['scheduledAt'] as String? ?? '');
    if (scheduledAt != null) {
      return scheduledAt;
    }

    final dateString = reminder['date'] as String?;
    if (dateString == null || dateString.isEmpty) {
      return null;
    }

    return _parseDateString(dateString);
  }

  DateTime? _nextReminderOccurrence(Map<String, dynamic> reminder) {
    final baseDateTime = _extractScheduledDateTime(reminder);
    if (baseDateTime == null) return null;

    final now = DateTime.now();
    final repeatEnabled = reminder['repeatEnabled'] as bool? ?? false;
    final rawRepeatDays = reminder['repeatDays'];
    final repeatDays = rawRepeatDays is List ? rawRepeatDays.whereType<int>().toSet() : <int>{};

    if (!repeatEnabled || repeatDays.isEmpty) {
      // If user sets reminder close to current time and seconds already pass,
      // keep it firing immediately instead of silently skipping.
      if (!baseDateTime.isAfter(now)) {
        return now.add(const Duration(seconds: 2));
      }
      return baseDateTime;
    }

    for (int offset = 0; offset <= 14; offset++) {
      final candidate = DateTime(
        now.year,
        now.month,
        now.day + offset,
        baseDateTime.hour,
        baseDateTime.minute,
      );
      if (repeatDays.contains(candidate.weekday % 7) && candidate.isAfter(now)) {
        return candidate;
      }
    }

    return baseDateTime;
  }

  int? _getMonthNumber(String monthName) {
    const months = {
      'Januari': 1,
      'Februari': 2,
      'Maret': 3,
      'April': 4,
      'Mei': 5,
      'Juni': 6,
      'Juli': 7,
      'Agustus': 8,
      'September': 9,
      'Oktober': 10,
      'November': 11,
      'Desember': 12,
      'January': 1,
      'February': 2,
      'March': 3,
      'May': 5,
      'June': 6,
      'July': 7,
      'August': 8,
      'October': 10,
      'December': 12,
    };
    return months[monthName];
  }

  Future<void> initializeNotifications() async {
    await _notificationService.initialize();
    _notificationService.registerNotificationTapHandler(_handleNotificationTapPayload);
    _startReminderFallbackWatcher();
  }

  void _startReminderFallbackWatcher() {
    _reminderFallbackTimer?.cancel();
    _reminderFallbackTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _runReminderFallbackCheck(),
    );
  }

  Future<void> _runReminderFallbackCheck() async {
    if (_isRunningReminderFallback || !_notificationsEnabled || !_reminderNotificationsEnabled) return;
    _isRunningReminderFallback = true;
    try {
      final now = DateTime.now();
      var hasMutation = false;

      for (int index = 0; index < _reminders.length; index++) {
        final reminder = _reminders[index];
        final status = (reminder['status'] as String? ?? 'menunggu').toLowerCase();
        if (status != 'menunggu') continue;

        final mode = _normalizeReminderMode(
          (reminder['mode'] as String?) ?? (reminder['type'] as String?) ?? 'Notification',
        );
        final scheduledAt = DateTime.tryParse(reminder['scheduledAt'] as String? ?? '');
        if (scheduledAt == null || scheduledAt.isAfter(now)) continue;

        if (mode == 'Notification') {
          if (now.difference(scheduledAt) > const Duration(minutes: 30)) continue;
          final scheduledKey = reminder['scheduledAt'] as String?;
          final lastDeliveredScheduleAt = reminder['lastDeliveredScheduleAt'] as String?;
          if (scheduledKey != null && scheduledKey == lastDeliveredScheduleAt) continue;

          final notificationId = _getReminderNotificationId(reminder);
          await _notificationService.showReminderNow(
            notificationId,
            reminder['title'] as String? ?? 'Reminder',
            _buildReminderNotificationBody(reminder),
            payload: 'reminder:$notificationId',
            mode: 'Notification',
            soundUri: reminder['soundUri'] as String?,
          );
          reminder['status'] = 'selesai';
          reminder['lastDeliveredAt'] = now.toIso8601String();
          reminder['lastDeliveredScheduleAt'] = scheduledKey;
          reminder['snoozedUntil'] = null;
          hasMutation = true;
          continue;
        }

        if (now.difference(scheduledAt) > const Duration(minutes: 30)) continue;

        final scheduledKey = reminder['scheduledAt'] as String?;
        final lastDeliveredScheduleAt = reminder['lastDeliveredScheduleAt'] as String?;
        if (scheduledKey != null && scheduledKey == lastDeliveredScheduleAt) continue;

        final notificationId = _getReminderNotificationId(reminder);
        await _notificationService.cancelReminder(notificationId);
        await _notificationService.schedulePopupAlarm(
          notificationId,
          now.add(const Duration(seconds: 1)),
          mode: mode,
          title: reminder['title'] as String? ?? 'Reminder',
          body: _buildReminderNotificationBody(reminder),
        );

        reminder['lastDeliveredScheduleAt'] = scheduledKey;
        reminder['lastDeliveredAt'] = now.toIso8601String();
        if (_hasRoutineSchedule(reminder)) {
          final moved = _moveRoutineToNextOccurrence(
            reminder,
            now.add(const Duration(seconds: 1)),
          );
          if (moved) {
            await _scheduleReminderNotification(reminder);
          }
        }
        hasMutation = true;
      }

      if (hasMutation) {
        await _saveReminders();
        notifyListeners();
      }
    } finally {
      _isRunningReminderFallback = false;
    }
  }

  @visibleForTesting
  Future<void> runReminderFallbackCheckForTest() => _runReminderFallbackCheck();

  Future<void> rescheduleAllReminders() async {
    for (int i = 0; i < _reminders.length; i++) {
      final reminder = _reminders[i];
      final status = reminder['status'] as String? ?? 'menunggu';
      if (status == 'menunggu') {
        _ensureReminderNotificationId(reminder);
        await _scheduleReminderNotification(reminder);
      }
    }
  }

  void _handleNotificationTapPayload(String payload) {
    if (payload.startsWith('report_action:')) {
      _handleReportNotificationAction(payload);
      return;
    }

    if (payload.startsWith('report_file:')) {
      final encodedPath = payload.replaceFirst('report_file:', '');
      final filePath = Uri.decodeComponent(encodedPath);
      _openDownloadedReportFile(filePath);
      return;
    }

    if (payload.startsWith('reminder_action:')) {
      final parts = payload.split(':');
      if (parts.length < 3) return;
      final action = parts[1];
      final notificationId = int.tryParse(parts[2]);
      if (notificationId == null) return;
      final reminderIndex = _reminders.indexWhere(
        (reminder) => (reminder['notificationId'] as int?) == notificationId,
      );
      if (reminderIndex == -1) return;

      if (action == 'snooze') {
        _snoozeReminderAt(reminderIndex, 300);
      } else if (action == 'complete') {
        _completeReminderFromAction(reminderIndex);
      }
      return;
    }

    if (!payload.startsWith('reminder:')) return;
    final idString = payload.split(':').last;
    final notificationId = int.tryParse(idString);
    if (notificationId == null) return;

    final reminderIndex = _reminders.indexWhere(
      (reminder) => (reminder['notificationId'] as int?) == notificationId,
    );
    if (reminderIndex == -1) return;

    final reminder = _reminders[reminderIndex];
    final mode = _normalizeReminderMode(
      (reminder['mode'] as String?) ?? (reminder['type'] as String?) ?? 'Notification',
    );

    // Notification mode should behave like a regular system notification.
    if (mode == 'Notification') {
      _completeNotificationReminder(reminderIndex, DateTime.now());
      _saveReminders();
      notifyListeners();
      return;
    }
    // Popup modes are handled by native full-screen alarm flow.
    // Avoid launching in-app alert to prevent double-flow and instant dismiss.
    return;
  }

  void _completeNotificationReminder(int index, DateTime completedAt) {
    if (index < 0 || index >= _reminders.length) return;
    final reminder = _reminders[index];
    final notificationId = _getReminderNotificationId(reminder);
    reminder['status'] = 'selesai';
    reminder['lastDeliveredAt'] = completedAt.toIso8601String();
    reminder['lastDeliveredScheduleAt'] = reminder['scheduledAt'] as String?;
    reminder['snoozedUntil'] = null;
    _notificationService.cancelPopupAlarm(notificationId);
  }

  void _completeReminderFromAction(int index) {
    if (index < 0 || index >= _reminders.length) return;
    final reminder = _reminders[index];
    final currentStatus = (reminder['status'] as String? ?? 'menunggu').toLowerCase();
    final notificationId = _getReminderNotificationId(reminder);
    final isRoutine = _hasRoutineSchedule(reminder);

    if (currentStatus == 'selesai' && !isRoutine) {
      _notificationService.cancelReminder(notificationId);
      _notificationService.cancelPopupAlarm(notificationId);
      return;
    }

    if (isRoutine) {
      final moved = _moveRoutineToNextOccurrence(reminder, DateTime.now());
      if (moved) {
        _scheduleReminderNotification(reminder);
      } else {
        reminder['status'] = 'selesai';
        _notificationService.cancelReminder(notificationId);
        _notificationService.cancelPopupAlarm(notificationId);
      }
    } else {
      reminder['status'] = 'selesai';
      reminder['lastDeliveredAt'] = DateTime.now().toIso8601String();
      reminder['lastDeliveredScheduleAt'] = reminder['scheduledAt'] as String?;
      reminder['snoozedUntil'] = null;
      _notificationService.cancelReminder(notificationId);
      _notificationService.cancelPopupAlarm(notificationId);
    }
    _saveReminders();
    notifyListeners();
  }

  Future<void> _handleReportNotificationAction(String payload) async {
    final parts = payload.split(':');
    if (parts.length < 4) return;
    final action = parts[1];
    final encodedPayload = parts.sublist(2).join(':');
    if (!encodedPayload.startsWith('report_file:')) return;
    final encodedPath = encodedPayload.replaceFirst('report_file:', '');
    final filePath = Uri.decodeComponent(encodedPath);

    if (action == 'open') {
      await _openDownloadedReportFile(filePath);
      return;
    }
    if (action == 'share') {
      await _shareDownloadedReportFile(filePath);
    }
  }

  Future<void> _openDownloadedReportFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      await _notificationService.showInfoNow(
        id: DateTime.now().millisecondsSinceEpoch.remainder(2147480000),
        title: 'File tidak ditemukan',
        body: 'Laporan sudah tidak ada di penyimpanan. Silakan unduh ulang.',
      );
      return;
    }
    await OpenFilex.open(filePath);
  }

  Future<void> _shareDownloadedReportFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      await _notificationService.showInfoNow(
        id: DateTime.now().millisecondsSinceEpoch.remainder(2147480000),
        title: 'File tidak ditemukan',
        body: 'Laporan tidak bisa dibagikan karena file sudah terhapus.',
      );
      return;
    }
    await Share.shareXFiles([XFile(filePath)], text: 'Laporan keuangan NARA');
  }

  void _snoozeReminderAt(int index, int seconds) {
    if (seconds <= 0 || index < 0 || index >= _reminders.length) return;

    final reminder = _reminders[index];
    final notificationId = _getReminderNotificationId(reminder);
    final snoozeDate = DateTime.now().add(Duration(seconds: seconds));

    reminder['scheduledAt'] = snoozeDate.toIso8601String();
    reminder['status'] = 'menunggu';
    reminder['snoozedUntil'] = snoozeDate.toIso8601String();
    _trackEvent('reminder_snoozed', extras: {
      'reminder_id': reminder['notificationId'] as Object? ?? index,
      'seconds': seconds,
      'mode': (reminder['mode'] as String?) ?? (reminder['type'] as String?) ?? 'Notification',
    });
    _notificationService.cancelReminder(notificationId);
    _notificationService.cancelPopupAlarm(notificationId);
    final mode = _normalizeReminderMode(
      (reminder['mode'] as String?) ?? (reminder['type'] as String?) ?? 'Notification',
    );
    if (mode == 'Notification') {
      _notificationService.scheduleReminder(
        notificationId,
        reminder['title'] as String? ?? 'Reminder',
        _buildReminderNotificationBody(reminder),
        scheduledDate: snoozeDate,
        payload: 'reminder:$notificationId',
        mode: mode,
        soundUri: reminder['soundUri'] as String?,
      );
    } else {
      _notificationService.schedulePopupAlarm(
        notificationId,
        snoozeDate,
        mode: mode,
        title: reminder['title'] as String? ?? 'Reminder',
        body: _buildReminderNotificationBody(reminder),
      );
    }
    _saveReminders();
  }

  String _normalizeReminderMode(String raw) {
    switch (raw) {
      case 'Notifikasi':
      case 'Notification':
        return 'Notification';
      case 'Alarm Keras':
      case 'Loud Alarm':
        return 'Loud Alarm';
      case 'Fullscreen Alert':
        return 'Loud Alarm';
      default:
        return 'Notification';
    }
  }

  String normalizeReminderModePublic(String raw) => _normalizeReminderMode(raw);

  bool _hasRoutineSchedule(Map<String, dynamic> reminder) {
    final repeatEnabled = reminder['repeatEnabled'] as bool? ?? false;
    final rawRepeatDays = reminder['repeatDays'];
    final repeatDays = rawRepeatDays is List
        ? rawRepeatDays.whereType<int>().toSet()
        : <int>{};
    return repeatEnabled && repeatDays.isNotEmpty;
  }

  bool _moveRoutineToNextOccurrence(
    Map<String, dynamic> reminder,
    DateTime fromTime,
  ) {
    if (!_hasRoutineSchedule(reminder)) return false;
    final baseDateTime = _extractScheduledDateTime(reminder);
    if (baseDateTime == null) return false;

    final rawRepeatDays = reminder['repeatDays'];
    final repeatDays = rawRepeatDays is List
        ? rawRepeatDays.whereType<int>().toSet()
        : <int>{};
    if (repeatDays.isEmpty) return false;

    for (int offset = 0; offset <= 14; offset++) {
      final candidate = DateTime(
        fromTime.year,
        fromTime.month,
        fromTime.day + offset,
        baseDateTime.hour,
        baseDateTime.minute,
      );
      if (!repeatDays.contains(candidate.weekday % 7)) continue;
      if (!candidate.isAfter(fromTime)) continue;

      reminder['scheduledAt'] = candidate.toIso8601String();
      reminder['status'] = 'menunggu';
      reminder['snoozedUntil'] = null;
      return true;
    }

    return false;
  }

  String _buildReminderNotificationBody(Map<String, dynamic> reminder) {
    final note = (reminder['note'] as String?)?.trim() ?? '';
    if (note.isNotEmpty) return note;
    final type = (reminder['type'] as String?)?.trim() ?? '';
    if (type.isNotEmpty && type != 'Notification' && type != 'Notifikasi') {
      return 'Reminder: $type';
    }
    return 'Ada pengingat baru untukmu.';
  }

  // Persistent Storage Methods
  Future<void> _saveExpenses() async {
    await _saveJsonList(_expensesKey, _expenses);
  }

  Future<void> _saveIncomes() async {
    await _saveJsonList(_incomesKey, _incomes);
  }

  Future<void> _saveDebts() async {
    await _saveJsonList(_debtsKey, _debts);
  }

  Future<void> _saveReminders() async {
    await _saveJsonList(_remindersKey, _reminders);
  }

  Future<void> _saveJsonList(String key, List<Map<String, dynamic>> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data.map(_serializeMap).toList());
      await prefs.setString(key, jsonString);
    } catch (e, st) {
      _trackError(e, st, hint: 'save_json_list', extras: {'key': key});
      _log('Error saving $key: $e');
    }
  }

  Map<String, dynamic> _serializeMap(Map<String, dynamic> value) {
    return value.map((key, entry) => MapEntry(key, _serializeValue(entry)));
  }

  dynamic _serializeValue(dynamic value) {
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is IconData) {
      return {
        '__type': 'icon_data',
        'codePoint': value.codePoint,
        'fontFamily': value.fontFamily,
        'fontPackage': value.fontPackage,
        'matchTextDirection': value.matchTextDirection,
      };
    }
    if (value is Map<String, dynamic>) {
      return _serializeMap(value);
    }
    if (value is List) {
      return value.map(_serializeValue).toList();
    }
    return value;
  }

  Map<String, dynamic> _deserializeMap(Map<String, dynamic> value) {
    return value.map((key, entry) => MapEntry(key, _deserializeValue(key, entry)));
  }

  dynamic _deserializeValue(String key, dynamic value) {
    if (key == 'createdAt' && value is String) {
      return DateTime.tryParse(value) ?? value;
    }
    if (value is Map<String, dynamic> && value['__type'] == 'icon_data') {
      return _deserializeIconData(value);
    }
    if (value is Map<String, dynamic>) {
      return _deserializeMap(value);
    }
    if (value is List) {
      return value.map((item) => item is Map<String, dynamic> ? _deserializeMap(item) : item).toList();
    }
    return value;
  }

  Future<void> _loadJsonList(String key, List<Map<String, dynamic>> target) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);

    if (jsonString == null || jsonString.isEmpty) {
      return;
    }

    final List<dynamic> decodedList = jsonDecode(jsonString);
    target
      ..clear()
      ..addAll(
        decodedList
            .map((item) => _deserializeMap(Map<String, dynamic>.from(item as Map<dynamic, dynamic>)))
            .toList(),
      );
  }

  Future<void> loadAppData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isOnboardingComplete = prefs.getBool(_onboardingKey) ?? false;
      _userName = prefs.getString(_userNameKey) ?? _userName;
      _isDarkMode = prefs.getBool(_isDarkModeKey) ?? false;
      _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
      _language = prefs.getString(_languageKey) ?? 'Indonesia';
      _voiceSpeed = prefs.getDouble(_voiceSpeedKey) ?? 1.0;
      _voiceBetaEnabled = prefs.getBool(_voiceBetaEnabledKey) ?? true;
      _voiceConfirmEnabled = prefs.getBool(_voiceConfirmEnabledKey) ?? true;
      _voiceGreetingEnabled = prefs.getBool(_voiceGreetingEnabledKey) ?? true;
      _profileImagePath = prefs.getString(_profileImagePathKey) ?? '';
      _reminderNotificationsEnabled = prefs.getBool(_reminderNotifsEnabledKey) ?? true;
      _debtNotificationsEnabled = prefs.getBool(_debtNotifsEnabledKey) ?? true;
      _transactionNotificationsEnabled = prefs.getBool(_transactionNotifsEnabledKey) ?? true;
      _transactionSwipeEnabled = prefs.getBool(_transactionSwipeEnabledKey) ?? true;
      _monthlyBudget = prefs.getInt(_monthlyBudgetKey) ?? 0;
      _expenseCategories = prefs.getStringList(_expenseCategoriesKey) ??
          List<String>.from(_defaultExpenseCategories);
      _incomeCategories = prefs.getStringList(_incomeCategoriesKey) ??
          List<String>.from(_defaultIncomeCategories);
      if (_expenseCategories.isEmpty) {
        _expenseCategories = List<String>.from(_defaultExpenseCategories);
      }
      if (_incomeCategories.isEmpty) {
        _incomeCategories = List<String>.from(_defaultIncomeCategories);
      }
      if (!_expenseCategories.any((item) => item.toLowerCase() == 'lainnya')) {
        _expenseCategories.add('Lainnya');
      }
      if (!_incomeCategories.any((item) => item.toLowerCase() == 'lainnya')) {
        _incomeCategories.add('Lainnya');
      }
      await _loadJsonList(_expensesKey, _expenses);
      await _loadJsonList(_incomesKey, _incomes);
      await _loadJsonList(_debtsKey, _debts);
      await loadReminders();

      _normalizeDebtIds();
      if (_reminders.isNotEmpty) {
        _normalizeReminderNotificationIds();
      }
    } catch (e, st) {
      _trackError(e, st, hint: 'load_app_data');
      _log('Error loading app data: $e');
    }
  }

  Future<void> loadReminders() async {
    try {
      await _loadJsonList(_remindersKey, _reminders);
      var hasMigration = false;
      for (final reminder in _reminders) {
        final scheduledAt = DateTime.tryParse(reminder['scheduledAt'] as String? ?? '');
        if (scheduledAt != null) continue;

        final recovered = _recoverScheduledAtFromLegacy(reminder);
        if (recovered == null) continue;

        reminder['scheduledAt'] = recovered.toIso8601String();
        hasMigration = true;
      }
      _normalizeReminderNotificationIds();
      if (hasMigration) {
        await _saveReminders();
      }
      notifyListeners();
    } catch (e, st) {
      _trackError(e, st, hint: 'load_reminders');
      _log('Error loading reminders: $e');
    }
  }

  DateTime? _recoverScheduledAtFromLegacy(Map<String, dynamic> reminder) {
    final parsedLegacy = _extractScheduledDateTime(reminder);
    if (parsedLegacy != null) return parsedLegacy;

    final dateLabel = (reminder['date'] as String? ?? '').toLowerCase();
    final now = DateTime.now();
    var dayOffset = 0;
    if (dateLabel.contains('besok') || dateLabel.contains('tomorrow')) {
      dayOffset = 1;
    }

    var hour = now.hour;
    var minute = now.minute;
    final timeSource = '${reminder['date'] ?? ''} ${reminder['subtitle'] ?? ''}';
    final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(timeSource);
    if (timeMatch != null) {
      hour = int.tryParse(timeMatch.group(1) ?? '') ?? hour;
      minute = int.tryParse(timeMatch.group(2) ?? '') ?? minute;
    }

    return DateTime(now.year, now.month, now.day + dayOffset, hour, minute);
  }

  void _ensureReminderNotificationId(Map<String, dynamic> reminder) {
    final existingId = reminder['notificationId'];
    if (existingId is int) {
      if (existingId >= _nextNotificationId) {
        _nextNotificationId = existingId + 1;
      }
      return;
    }

    reminder['notificationId'] = _nextNotificationId;
    _nextNotificationId++;
  }

  int _getReminderNotificationId(Map<String, dynamic> reminder) {
    final notificationId = reminder['notificationId'];
    if (notificationId is int) {
      return notificationId;
    }

    _ensureReminderNotificationId(reminder);
    return reminder['notificationId'] as int;
  }

  void _normalizeReminderNotificationIds() {
    for (final reminder in _reminders) {
      _ensureReminderNotificationId(reminder);
    }
  }

  void _ensureDebtId(Map<String, dynamic> debt) {
    final existingId = debt['debtId'];
    if (existingId is int) {
      if (existingId >= _nextDebtId) {
        _nextDebtId = existingId + 1;
      }
      return;
    }

    debt['debtId'] = _nextDebtId;
    _nextDebtId++;
  }

  int _indexOfDebtId(int debtId) {
    return _debts.indexWhere((debt) => (debt['debtId'] as int?) == debtId);
  }

  void _normalizeDebtIds() {
    for (final debt in _debts) {
      _ensureDebtId(debt);
    }
  }

  Future<void> saveAllData() async {
    await _saveExpenses();
    await _saveIncomes();
    await _saveDebts();
    await _saveReminders();
  }

  IconData _deserializeIconData(Map<String, dynamic> value) {
    final codePoint = value['codePoint'] as int?;
    if (codePoint == null) return Icons.notifications_active_rounded;
    if (codePoint == Icons.notifications_rounded.codePoint) {
      return Icons.notifications_rounded;
    }
    if (codePoint == Icons.notifications_active_rounded.codePoint) {
      return Icons.notifications_active_rounded;
    }
    if (codePoint == Icons.volume_up_rounded.codePoint) {
      return Icons.volume_up_rounded;
    }
    // Legacy fullscreen icon from older reminder mode now maps to loud alarm.
    if (codePoint == Icons.fullscreen_rounded.codePoint) {
      return Icons.volume_up_rounded;
    }
    if (codePoint == Icons.call_rounded.codePoint) {
      return Icons.call_rounded;
    }
    return Icons.notifications_active_rounded;
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();

    for (final reminder in _reminders) {
      final notificationId = _getReminderNotificationId(reminder);
      _notificationService.cancelReminder(notificationId);
      _notificationService.cancelPopupAlarm(notificationId);
    }

    _expenses.clear();
    _incomes.clear();
    _debts.clear();
    _reminders.clear();
    _nextNotificationId = 0;
    _nextDebtId = 0;

    await prefs.remove(_expensesKey);
    await prefs.remove(_incomesKey);
    await prefs.remove(_debtsKey);
    await prefs.remove(_remindersKey);
    await prefs.remove(_expenseCategoriesKey);
    await prefs.remove(_incomeCategoriesKey);
    _expenseCategories = List<String>.from(_defaultExpenseCategories);
    _incomeCategories = List<String>.from(_defaultIncomeCategories);
    notifyListeners();
  }

  void _normalizeReminderScheduleOnReactivation(Map<String, dynamic> reminder) {
    final repeatEnabled = reminder['repeatEnabled'] as bool? ?? false;
    final rawRepeatDays = reminder['repeatDays'];
    final repeatDays = rawRepeatDays is List ? rawRepeatDays.whereType<int>().toSet() : <int>{};
    if (repeatEnabled && repeatDays.isNotEmpty) {
      return;
    }

    final scheduledAt = DateTime.tryParse(reminder['scheduledAt'] as String? ?? '');
    if (scheduledAt == null) return;
    final now = DateTime.now();
    if (scheduledAt.isAfter(now)) return;

    // When re-activating a completed reminder with past time, move it forward
    // so it does not fire immediately before user has chance to adjust.
    var next = DateTime(
      now.year,
      now.month,
      now.day,
      scheduledAt.hour,
      scheduledAt.minute,
    );
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    reminder['scheduledAt'] = next.toIso8601String();
  }

  Future<void> _saveCategorySettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_expenseCategoriesKey, _expenseCategories);
    await prefs.setStringList(_incomeCategoriesKey, _incomeCategories);
  }

  @override
  void dispose() {
    _reminderFallbackTimer?.cancel();
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _saveOnboardingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, _isOnboardingComplete);
    } catch (e, st) {
      _trackError(e, st, hint: 'save_onboarding_state');
      _log('Error saving onboarding state: $e');
    }
  }
}






