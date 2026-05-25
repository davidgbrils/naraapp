import 'package:flutter/material.dart';
import 'nara_colors.dart';

class NaraShadows {
  // Shadow standar untuk NaraCard biasa
  static List<BoxShadow> get card => [
    BoxShadow(
      color: NaraColors.shadowDark,
      offset: const Offset(6, 6),
      blurRadius: 14,
    ),
    BoxShadow(
      color: NaraColors.shadowLight,
      offset: const Offset(-4, -4),
      blurRadius: 10,
    ),
  ];

  // Shadow lebih ringan untuk card kecil / nested
  static List<BoxShadow> get cardSmall => [
    BoxShadow(
      color: NaraColors.shadowDark,
      offset: const Offset(4, 4),
      blurRadius: 10,
    ),
    BoxShadow(
      color: NaraColors.shadowLight,
      offset: const Offset(-3, -3),
      blurRadius: 8,
    ),
  ];

  // Shadow untuk tombol primary (biru)
  static List<BoxShadow> get primaryButton => [
    BoxShadow(
      color: NaraColors.primary.withValues(alpha: 0.4),
      offset: const Offset(0, 4),
      blurRadius: 14,
    ),
  ];

  // Inner shadow decoration (untuk text field, input)
  static BoxDecoration get inputDecoration => BoxDecoration(
    color: NaraColors.surfaceCard,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: NaraColors.shadowDark.withValues(alpha: 0.6),
        offset: const Offset(2, 2),
        blurRadius: 6,
      ),
      BoxShadow(
        color: NaraColors.shadowLight,
        offset: const Offset(-1, -1),
        blurRadius: 4,
      ),
    ],
  );

  // Shadow untuk floating bubble overlay
  static List<BoxShadow> get floatingBubble => [
    BoxShadow(
      color: NaraColors.primary.withValues(alpha: 0.35),
      offset: const Offset(0, 6),
      blurRadius: 20,
    ),
    BoxShadow(
      color: NaraColors.shadowDark,
      offset: const Offset(4, 4),
      blurRadius: 12,
    ),
    BoxShadow(
      color: NaraColors.shadowLight,
      offset: const Offset(-3, -3),
      blurRadius: 10,
    ),
  ];
}

