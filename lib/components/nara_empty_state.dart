import 'package:flutter/material.dart';

import '../core/theme/nara_colors.dart';
import '../core/theme/nara_radius.dart';
import '../core/theme/nara_spacing.dart';
import '../core/theme/nara_text_styles.dart';
import 'nara_card.dart';

class NaraEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final Color? accentColor;

  const NaraEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? NaraColors.primary;

    return NaraCard(
      borderRadius: NaraRadius.lg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: color),
          ),
          const SizedBox(height: NaraSpacing.lg),
          Text(title, style: NaraTextStyles.h3, textAlign: TextAlign.center),
          const SizedBox(height: NaraSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: NaraTextStyles.body.copyWith(color: NaraColors.textSecondary),
          ),
          if (action != null) ...[
            const SizedBox(height: NaraSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}

