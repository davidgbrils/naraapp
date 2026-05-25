import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/nara_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/expense/add_expense_screen.dart';
import 'screens/income/catat_pemasukan_screen.dart';
import 'screens/debt/add_debt_screen.dart';
import 'screens/reminder/reminder_list_screen.dart';
import 'screens/reminder/create_reminder_screen.dart';
import 'screens/notifications/notification_center_screen.dart';
import 'screens/report/report_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'providers/app_provider.dart';

Route<dynamic> _buildRoute(RouteSettings settings, WidgetBuilder builder) {
  return PageRouteBuilder<dynamic>(
    settings: settings,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (context, animation, secondaryAnimation) {
      return builder(context);
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeCurve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0.04, 0.04),
        end: Offset.zero,
      ).animate(fadeCurve);

      return FadeTransition(
        opacity: fadeCurve,
        child: SlideTransition(
          position: slideAnimation,
          child: child,
        ),
      );
    },
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  // Initialize provider and load reminders
  final appProvider = AppProvider();
  await appProvider.loadAppData();
  await appProvider.initializeNotifications();
  
  // Reschedule all active reminders
  await appProvider.rescheduleAllReminders();
  
  runApp(NaraApp(appProvider: appProvider));
}

class NaraApp extends StatelessWidget {
  final AppProvider appProvider;
  
  const NaraApp({super.key, required this.appProvider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appProvider,
      child: Consumer<AppProvider>(
        builder: (context, provider, _) => MaterialApp(
          title: 'NARA',
          debugShowCheckedModeBanner: false,
          locale: provider.language == 'English' ? const Locale('en') : const Locale('id'),
          supportedLocales: const [Locale('id'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: NaraTheme.lightTheme,
          darkTheme: NaraTheme.darkTheme,
          themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
          onGenerateRoute: (settings) {
            final routes = <String, WidgetBuilder>{
              '/onboarding': (_) => const OnboardingScreen(),
              '/home': (_) => const HomeScreen(),
              '/add-expense': (_) => const AddExpenseScreen(),
              '/add-income': (_) => const CatatPemasukanScreen(),
              '/add-debt': (_) => const AddDebtScreen(),
              '/reminders': (_) => const ReminderListScreen(),
              '/create-reminder': (_) => const CreateReminderScreen(),
              '/notifications': (_) => const NotificationCenterScreen(),
              '/report': (_) => const ReportScreen(),
              '/settings': (_) => const SettingsScreen(),
            };

            final builder = routes[settings.name];
            if (builder == null) {
              return null;
            }

            return _buildRoute(settings, builder);
          },
        ),
      ),
    );
  }
}
