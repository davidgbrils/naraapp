import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF131319);
  static const Color surface = Color(0xFF131319);
  static const Color surfaceContainerLowest = Color(0xFF0E0D14);
  static const Color surfaceContainerLow = Color(0xFF1C1B22);
  static const Color surfaceContainer = Color(0xFF201F26);
  static const Color surfaceContainerHigh = Color(0xFF2A2930);
  static const Color surfaceContainerHighest = Color(0xFF35343B);
  
  static const Color primary = Color(0xFFC7BFFF);
  static const Color primaryContainer = Color(0xFF9B8FFF);
  static const Color onPrimary = Color(0xFF2C178A);
  static const Color onPrimaryContainer = Color(0xFF301E8E);
  
  static const Color secondary = Color(0xFFFFB59D);
  static const Color secondaryContainer = Color(0xFF76321A);
  static const Color onSecondary = Color(0xFF591D06);
  static const Color onSecondaryContainer = Color(0xFFFC9D7D);
  
  static const Color tertiary = Color(0xFFE6C438);
  static const Color tertiaryContainer = Color(0xFFBA9B00);
  static const Color onTertiary = Color(0xFF3B2F00);
  static const Color onTertiaryContainer = Color(0xFF403400);
  
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onError = Color(0xFF690005);
  static const Color onErrorContainer = Color(0xFFFFDAD6);
  
  static const Color onSurface = Color(0xFFE5E1EB);
  static const Color onSurfaceVariant = Color(0xFFC9C4D4);
  static const Color outline = Color(0xFF928F9E);
  static const Color outlineVariant = Color(0xFF474552);
  
  static const Color success = Color(0xFF6FCFB0);
  static const Color warning = Color(0xFFFFB86A);
  static const Color danger = Color(0xFFFF7B7B);

  static const double radiusSm = 8.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 28.0;
  static const double radiusFull = 9999.0;

  static const double spacingXs = 8.0;
  static const double spacingSm = 12.0;
  static const double spacingMd = 20.0;
  static const double spacingLg = 32.0;
  static const double spacingXl = 48.0;

  static TextStyle get h1 => GoogleFonts.nunito(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: onSurface,
  );

  static TextStyle get h2 => GoogleFonts.nunito(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: onSurface,
  );

  static TextStyle get h3 => GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: onSurface,
  );

  static TextStyle get body => GoogleFonts.nunito(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: onSurface,
  );

  static TextStyle get label => GoogleFonts.nunito(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.02,
    color: onSurface,
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
    ),
    textTheme: TextTheme(
      displayLarge: h1,
      displayMedium: h2,
      displaySmall: h3,
      bodyLarge: body,
      bodyMedium: body,
      bodySmall: label,
      labelLarge: label,
      labelMedium: label,
      labelSmall: label,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: h2,
      iconTheme: const IconThemeData(color: onSurface),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryContainer,
        foregroundColor: onPrimaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusXl)),
        textStyle: label,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceContainer,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusXl),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusXl),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusXl),
        borderSide: const BorderSide(color: primaryContainer, width: 1),
      ),
      hintStyle: body.copyWith(color: outline),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
  );
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double borderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius = AppTheme.radiusLg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryContainer.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}