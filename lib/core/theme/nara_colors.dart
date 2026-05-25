import 'package:flutter/material.dart';

class NaraColors {
  // === BACKGROUND ===
  static const Color background = Color(0xFFE8ECF0); // abu soft, warna screen utama
  static const Color surfaceCard = Color(0xFFEEF1F5); // card neumorphic
  static const Color surfaceWhite = Color(0xFFFFFFFF); // card putih elevated

  // === SHADOWS (untuk neumorphism) ===
  static const Color shadowDark = Color(0xFFC8CDD4); // bayangan gelap (kanan-bawah)
  static const Color shadowLight = Color(0xFFFFFFFF); // bayangan terang (kiri-atas)

  // === PRIMARY ===
  static const Color primary = Color(0xFF3B82F6); // biru utama (tombol, active state)
  static const Color primaryLight = Color(0xFFDBEAFE); // biru sangat muda (background badge)
  static const Color primaryDark = Color(0xFF1D4ED8); // biru gelap (pressed state)

  // === ACCENTS ===
  static const Color accentOrange = Color(0xFFF97316); // accent hangat (icon revenue, dll)
  static const Color accentPink = Color(0xFFEC4899); // accent user/profile
  static const Color accentPurple = Color(0xFF8B5CF6); // accent analytics/insight

  // === SEMANTIC ===
  static const Color success = Color(0xFF22C55E); // hijau sukses/positif
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B); // amber peringatan
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFEF4444); // merah bahaya
  static const Color dangerLight = Color(0xFFFEE2E2);

  // === TEXT ===
  static const Color textPrimary = Color(0xFF1A202C); // teks utama (hampir hitam)
  static const Color textSecondary = Color(0xFF718096); // teks sekunder (abu medium)
  static const Color textHint = Color(0xFFA0AEC0); // placeholder/hint
  static const Color textOnPrimary = Color(0xFFFFFFFF); // teks di atas tombol biru

  // === CHART COLORS (untuk grafik) ===
  static const Color chartBlue = Color(0xFF3B82F6);
  static const Color chartBlueLight = Color(0xFFBFDBFE);
  static const Color chartOrange = Color(0xFFF97316);
  static const Color chartGreen = Color(0xFF22C55E);
  static const Color chartPurple = Color(0xFF8B5CF6);
}
