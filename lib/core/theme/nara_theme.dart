import 'package:flutter/material.dart';
import 'nara_colors.dart';
import 'nara_text_styles.dart';

class NaraTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: NaraTextStyles.fontFamily,
      scaffoldBackgroundColor: NaraColors.background,
      colorScheme: ColorScheme.light(
        primary: NaraColors.primary,
        secondary: NaraColors.accentOrange,
        surface: NaraColors.surfaceWhite,
        error: NaraColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: NaraColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: NaraTextStyles.h3,
        iconTheme: IconThemeData(color: NaraColors.textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: NaraColors.background,
        elevation: 0,
        selectedItemColor: NaraColors.primary,
        unselectedItemColor: NaraColors.textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: const CardThemeData(
        color: NaraColors.surfaceWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NaraColors.surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: NaraColors.primary,
            width: 1.5,
          ),
        ),
        hintStyle: NaraTextStyles.bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? NaraColors.primary : NaraColors.textHint),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? NaraColors.primaryLight : NaraColors.surfaceCard),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: NaraColors.primary,
        elevation: 0,
        shape: StadiumBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: NaraColors.surfaceWhite,
        contentTextStyle: NaraTextStyles.body.copyWith(color: NaraColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData get darkTheme {
    const darkBg = Color(0xFF0F172A);
    const darkSurface = Color(0xFF111827);
    const darkCard = Color(0xFF1F2937);
    const darkText = Color(0xFFE5E7EB);
    const darkTextSecondary = Color(0xFF9CA3AF);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: NaraTextStyles.fontFamily,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: NaraColors.primary,
        secondary: NaraColors.accentOrange,
        surface: darkSurface,
        error: NaraColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: NaraTextStyles.h3,
        iconTheme: IconThemeData(color: darkText),
      ),
      cardTheme: const CardThemeData(
        color: darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: NaraColors.primary,
            width: 1.5,
          ),
        ),
        hintStyle: NaraTextStyles.bodySmall.copyWith(color: darkTextSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      textTheme: ThemeData.dark().textTheme.apply(bodyColor: darkText, displayColor: darkText),
      iconTheme: const IconThemeData(color: darkText),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: NaraColors.primary,
        elevation: 0,
        shape: StadiumBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkCard,
        contentTextStyle: NaraTextStyles.body.copyWith(color: darkText),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
