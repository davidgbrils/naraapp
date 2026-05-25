import 'package:flutter/material.dart';
import '../core/theme/nara_colors.dart';
import '../core/theme/nara_radius.dart';
import '../core/theme/nara_spacing.dart';
import '../core/theme/nara_text_styles.dart';

class NaraBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final Widget? icon;
  final double? width;

  const NaraBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.width,
  });

  Color _getBackgroundColor() {
    switch (label.toLowerCase()) {
      case 'selesai':
      case 'paid':
        return NaraColors.successLight;
      case 'menunggu':
      case 'pending':
        return NaraColors.warningLight;
      case 'hutang':
      case 'debt':
        return NaraColors.dangerLight;
      default:
        return backgroundColor ?? NaraColors.primaryLight;
    }
  }

  Color _getTextColor() {
    switch (label.toLowerCase()) {
      case 'selesai':
      case 'paid':
        return NaraColors.success;
      case 'menunggu':
      case 'pending':
        return NaraColors.warning;
      case 'hutang':
      case 'debt':
        return NaraColors.danger;
      default:
        return textColor ?? NaraColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(
        horizontal: NaraSpacing.md,
        vertical: NaraSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(NaraRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: icon!,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: NaraTextStyles.caption.copyWith(
              color: _getTextColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
