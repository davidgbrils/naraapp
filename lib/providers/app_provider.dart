import 'package:flutter/material.dart';

class AppProvider extends ChangeNotifier {
  bool _isOnboardingComplete = false;
  bool _isLoggedIn = false;
  String _userName = 'Budi';
  
  bool get isOnboardingComplete => _isOnboardingComplete;
  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  
  void completeOnboarding() {
    _isOnboardingComplete = true;
    notifyListeners();
  }
  
  void setUserName(String name) {
    _userName = name;
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
    {'title': 'Makan Siang', 'amount': 45000, 'category': 'Makan', 'time': 'Hari ini, 12:30', 'icon': 'restaurant'},
    {'title': 'Grab', 'amount': 40000, 'category': 'Transport', 'time': 'Hari ini, 09:15', 'icon': 'directions_car'},
  ];
  
  final List<Map<String, dynamic>> _incomes = [];
  
  final List<Map<String, dynamic>> _debts = [
    {'title': 'Utang Andi', 'amount': 150000, 'type': 'utang', 'date': 'Kemarin'},
  ];
  
  final List<Map<String, dynamic>> _reminders = [
    {'title': 'Bayar Listrik', 'date': 'Besok', 'status': 'menunggu'},
  ];
  
  List<Map<String, dynamic>> get expenses => _expenses;
  List<Map<String, dynamic>> get incomes => _incomes;
  List<Map<String, dynamic>> get debts => _debts;
  List<Map<String, dynamic>> get reminders => _reminders;
  
  double get todayExpense => _expenses.fold(0, (sum, item) => sum + (item['amount'] as int));
  double get totalActiveDebt => _debts.where((d) => d['type'] == 'utang').fold(0, (sum, item) => sum + (item['amount'] as int));
  int get activeReminders => _reminders.where((r) => r['status'] == 'menunggu').length;
  
  void addExpense(Map<String, dynamic> expense) {
    _expenses.insert(0, expense);
    notifyListeners();
  }
  
  void addIncome(Map<String, dynamic> income) {
    _incomes.insert(0, income);
    notifyListeners();
  }
  
  void addDebt(Map<String, dynamic> debt) {
    _debts.insert(0, debt);
    notifyListeners();
  }
  
  void addReminder(Map<String, dynamic> reminder) {
    _reminders.insert(0, reminder);
    notifyListeners();
  }
}