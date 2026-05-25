import 'package:flutter/material.dart';

class AppProvider extends ChangeNotifier {
  bool _isOnboardingComplete = false;
  final bool _isLoggedIn = false;
  String _userName = 'Budi';
  int _selectedNavIndex = 1;
  int _nextDebtId = 1;
  final bool _notificationsEnabled = true;
  final bool _debtNotificationsEnabled = true;
  final bool _reminderNotificationsEnabled = true;
  final bool _transactionNotificationsEnabled = true;
  
  bool get isOnboardingComplete => _isOnboardingComplete;
  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  int get selectedNavIndex => _selectedNavIndex;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get debtNotificationsEnabled => _debtNotificationsEnabled;
  bool get reminderNotificationsEnabled => _reminderNotificationsEnabled;
  bool get transactionNotificationsEnabled => _transactionNotificationsEnabled;
  
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
  
  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  String get lastIntent => _lastIntent;
  
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
  List<Map<String, dynamic>> get activeRemindersList =>
      _reminders.where((r) => (r['status'] as String? ?? 'menunggu') == 'menunggu').toList();
  List<Map<String, dynamic>> get completedRemindersList =>
      _reminders.where((r) => (r['status'] as String? ?? '') == 'selesai').toList();
  
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
    debt['debtId'] = debt['debtId'] ?? _nextDebtId++;
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

  void markDebtAsPaidById(int debtId) {
    final index = _debts.indexWhere((d) => (d['debtId'] as int?) == debtId);
    if (index == -1) return;
    markDebtAsPaid(index);
  }
  
  void addReminder(Map<String, dynamic> reminder) {
    reminder['createdAt'] = reminder['createdAt'] ?? DateTime.now();
    _reminders.insert(0, reminder);
    notifyListeners();
  }

  void toggleReminderStatus(int index) {
    if (index < 0 || index >= _reminders.length) return;

    final currentStatus = _reminders[index]['status'] as String? ?? 'menunggu';
    _reminders[index]['status'] = currentStatus == 'menunggu' ? 'selesai' : 'menunggu';
    notifyListeners();
  }

  void removeReminderAt(int index) {
    if (index < 0 || index >= _reminders.length) return;
    _reminders.removeAt(index);
    notifyListeners();
  }

  void snoozeReminderByIndex(int index, {int seconds = 300}) {
    if (index < 0 || index >= _reminders.length) return;
    final until = DateTime.now().add(Duration(seconds: seconds));
    _reminders[index]['snoozedUntil'] = until.toIso8601String();
    _reminders[index]['status'] = 'menunggu';
    notifyListeners();
  }

  Future<bool> sendDebtReminderById(int debtId) async {
    if (!_notificationsEnabled || !_debtNotificationsEnabled) return false;
    final index = _debts.indexWhere((d) => (d['debtId'] as int?) == debtId);
    return index != -1;
  }

  Future<bool> scheduleDebtReminderById(
    int debtId, {
    required int daysBeforeDue,
  }) async {
    if (!_notificationsEnabled || !_debtNotificationsEnabled) return false;
    final index = _debts.indexWhere((d) => (d['debtId'] as int?) == debtId);
    if (index == -1) return false;
    final due = _parseDebtDueDate((_debts[index]['dueDate'] as String?) ?? '');
    if (due == null) return false;
    final schedule = DateTime(due.year, due.month, due.day - daysBeforeDue, 9, 0);
    if (!schedule.isAfter(DateTime.now())) return false;
    final key = daysBeforeDue == 1 ? 'debtReminderH1At' : 'debtReminderH0At';
    _debts[index][key] = schedule.toIso8601String();
    notifyListeners();
    return true;
  }

  Future<bool> cancelDebtReminderById(
    int debtId, {
    required int daysBeforeDue,
  }) async {
    final index = _debts.indexWhere((d) => (d['debtId'] as int?) == debtId);
    if (index == -1) return false;
    final key = daysBeforeDue == 1 ? 'debtReminderH1At' : 'debtReminderH0At';
    _debts[index].remove(key);
    notifyListeners();
    return true;
  }

  DateTime? _parseDebtDueDate(String raw) {
    if (raw.trim().isEmpty) return null;
    final direct = DateTime.tryParse(raw);
    if (direct != null) return direct;
    final match = RegExp(r'^(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})$').firstMatch(raw.trim());
    if (match == null) return null;
    final day = int.tryParse(match.group(1) ?? '');
    final year = int.tryParse(match.group(3) ?? '');
    const months = <String, int>{
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'mei': 5, 'jun': 6, 'jul': 7, 'agu': 8, 'sep': 9, 'okt': 10, 'nov': 11, 'des': 12,
    };
    final month = months[(match.group(2) ?? '').toLowerCase()];
    if (day == null || year == null || month == null) return null;
    return DateTime(year, month, day);
  }
}

