import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/notification_service.dart';

class AppProvider extends ChangeNotifier {
  bool _isOnboardingComplete = false;
  final bool _isLoggedIn = false;
  String _userName = 'Budi';
  int _selectedNavIndex = 1;
  final NotificationService _notificationService = NotificationService();
  
  bool get isOnboardingComplete => _isOnboardingComplete;
  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  int get selectedNavIndex => _selectedNavIndex;
  
  void completeOnboarding() {
    _isOnboardingComplete = true;
    notifyListeners();
  }
  
  void setUserName(String name) {
    _userName = name;
    notifyListeners();
  }

  void setNavIndex(int index) {
    _selectedNavIndex = index;
    notifyListeners();
  }
  
  // Voice state
  bool _isListening = false;
  bool _isProcessing = false;
  String _lastIntent = '';
  Map<String, dynamic>? _activeAlert;
  int _alertCountdown = 0;
  
  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  String get lastIntent => _lastIntent;
  Map<String, dynamic>? get activeAlert => _activeAlert;
  int get alertCountdown => _alertCountdown;
  
  void startListening() {
    _isListening = true;
    _isProcessing = false;
    _lastIntent = '';
    notifyListeners();
  }
  
  void stopListening() {
    _isListening = false;
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

  void triggerReminderAlert(int reminderIndex) {
    if (reminderIndex < 0 || reminderIndex >= _reminders.length) return;

    _activeAlert = Map<String, dynamic>.from(_reminders[reminderIndex])
      ..['index'] = reminderIndex;
    _alertCountdown = 10;
    notifyListeners();
  }

  void dismissAlert() {
    _activeAlert = null;
    _alertCountdown = 0;
    notifyListeners();
  }

  void snoozeAlert(int seconds) {
    _alertCountdown = seconds;
    notifyListeners();
  }

  void updateAlertCountdown() {
    if (_alertCountdown > 0) {
      _alertCountdown--;
      notifyListeners();
    }
  }
  
  // Transactions
  final List<Map<String, dynamic>> _expenses = [
    {
      'title': 'Makan Siang',
      'amount': 45000,
      'category': 'Makan',
      'time': 'Hari ini, 12:30',
      'icon': 'restaurant',
      'createdAt': DateTime.now().subtract(const Duration(hours: 5)),
    },
    {
      'title': 'Grab',
      'amount': 40000,
      'category': 'Transport',
      'time': 'Hari ini, 09:15',
      'icon': 'directions_car',
      'createdAt': DateTime.now().subtract(const Duration(hours: 8)),
    },
  ];
  
  final List<Map<String, dynamic>> _incomes = [];
  
  final List<Map<String, dynamic>> _debts = [
    {
      'title': 'Utang Andi',
      'amount': 150000,
      'type': 'utang',
      'date': 'Kemarin',
      'paidAmount': 0,
      'status': 'berjalan',
      'createdAt': DateTime.now().subtract(const Duration(days: 1)),
    },
  ];
  
  final List<Map<String, dynamic>> _reminders = [
    {
      'title': 'Bayar Listrik',
      'date': 'Besok',
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
  
  double get todayExpense => _expenses.fold(0, (sum, item) => sum + (item['amount'] as int));
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
  
  void addExpense(Map<String, dynamic> expense) {
    expense['createdAt'] = expense['createdAt'] ?? DateTime.now();
    _expenses.insert(0, expense);
    notifyListeners();
  }
  
  void addIncome(Map<String, dynamic> income) {
    income['createdAt'] = income['createdAt'] ?? DateTime.now();
    _incomes.insert(0, income);
    notifyListeners();
  }
  
  void addDebt(Map<String, dynamic> debt) {
    debt['createdAt'] = debt['createdAt'] ?? DateTime.now();
    debt['paidAmount'] = debt['paidAmount'] ?? 0;
    debt['status'] = debt['status'] ?? 'berjalan';
    _debts.insert(0, debt);
    notifyListeners();
  }

  void updateDebtPayment(int index, int paymentAmount) {
    if (index < 0 || index >= _debts.length || paymentAmount <= 0) return;

    final debt = _debts[index];
    final totalAmount = (debt['amount'] as num?)?.toInt() ?? 0;
    final currentPaidAmount = (debt['paidAmount'] as num?)?.toInt() ?? 0;
    final nextPaidAmount = (currentPaidAmount + paymentAmount).clamp(0, totalAmount);

    debt['paidAmount'] = nextPaidAmount;
    debt['status'] = nextPaidAmount >= totalAmount ? 'lunas' : 'berjalan';
    notifyListeners();
  }

  void markDebtAsPaid(int index) {
    if (index < 0 || index >= _debts.length) return;

    final debt = _debts[index];
    final totalAmount = (debt['amount'] as num?)?.toInt() ?? 0;
    debt['paidAmount'] = totalAmount;
    debt['status'] = 'lunas';
    notifyListeners();
  }
  
  void addReminder(Map<String, dynamic> reminder) {
    reminder['createdAt'] = reminder['createdAt'] ?? DateTime.now();
    _reminders.insert(0, reminder);
    _scheduleReminderNotification(0, reminder);
    _saveReminders();
    notifyListeners();
  }

  void updateReminder(int index, Map<String, dynamic> updatedReminder) {
    if (index < 0 || index >= _reminders.length) return;

    updatedReminder['createdAt'] = _reminders[index]['createdAt'] ?? DateTime.now();
    _reminders[index] = updatedReminder;
    _notificationService.cancelReminder(index);
    _scheduleReminderNotification(index, updatedReminder);
    _saveReminders();
    notifyListeners();
  }

  void toggleReminderStatus(int index) {
    if (index < 0 || index >= _reminders.length) return;

    final currentStatus = _reminders[index]['status'] as String? ?? 'menunggu';
    _reminders[index]['status'] = currentStatus == 'menunggu' ? 'selesai' : 'menunggu';
    _saveReminders();
    notifyListeners();
  }

  void removeReminderAt(int index) {
    if (index < 0 || index >= _reminders.length) return;
    _notificationService.cancelReminder(index);
    _reminders.removeAt(index);
    _saveReminders();
    notifyListeners();
  }

  // Notification Scheduling
  Future<void> _scheduleReminderNotification(int index, Map<String, dynamic> reminder) async {
    try {
      final dateString = reminder['date'] as String?;
      if (dateString == null || dateString.isEmpty) return;

      final scheduledDateTime = _parseDateString(dateString);
      if (scheduledDateTime == null || scheduledDateTime.isBefore(DateTime.now())) return;

      final title = reminder['title'] as String? ?? 'Reminder';
      final type = reminder['type'] as String? ?? 'Notifikasi';

      await _notificationService.scheduleReminder(
        index,
        title,
        'Reminder: $type',
        scheduledDate: scheduledDateTime,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  DateTime? _parseDateString(String dateString) {
    try {
      // Expected format: "DD MonthName YYYY • HH:MM"
      if (!dateString.contains('•')) return null;

      final parts = dateString.split('•');
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
    } catch (e) {
      debugPrint('Error parsing date: $e');
      return null;
    }
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
    };
    return months[monthName];
  }

  Future<void> initializeNotifications() async {
    await _notificationService.initialize();
  }

  Future<void> rescheduleAllReminders() async {
    for (int i = 0; i < _reminders.length; i++) {
      final reminder = _reminders[i];
      final status = reminder['status'] as String? ?? 'menunggu';
      if (status == 'menunggu') {
        await _scheduleReminderNotification(i, reminder);
      }
    }
  }

  // Persistent Storage Methods
  static const String _remindersKey = 'reminders';

  Future<void> _saveReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_reminders);
      await prefs.setString(_remindersKey, jsonString);
    } catch (e) {
      debugPrint('Error saving reminders: $e');
    }
  }

  Future<void> loadReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_remindersKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decodedList = jsonDecode(jsonString);
        _reminders.clear();
        _reminders.addAll(
          decodedList.map((item) => Map<String, dynamic>.from(item as Map<dynamic, dynamic>)).toList(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading reminders: $e');
    }
  }
}
