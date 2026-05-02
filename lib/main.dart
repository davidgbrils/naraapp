import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/expense/add_expense_screen.dart';
import 'screens/income/catat_pemasukan_screen.dart';
import 'screens/debt/add_debt_screen.dart';
import 'screens/reminder/reminder_list_screen.dart';
import 'screens/reminder/create_reminder_screen.dart';
import 'screens/report/report_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'providers/app_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const NaraApp());
}

class NaraApp extends StatelessWidget {
  const NaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'NARA',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/home': (context) => const HomeScreen(),
          '/add-expense': (context) => const AddExpenseScreen(),
          '/add-income': (context) => const CatatPemasukanScreen(),
          '/add-debt': (context) => const AddDebtScreen(),
          '/reminders': (context) => const ReminderListScreen(),
          '/create-reminder': (context) => const CreateReminderScreen(),
          '/report': (context) => const ReportScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}