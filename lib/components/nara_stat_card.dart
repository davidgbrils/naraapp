import 'package:flutter/material.dart';
import 'nara_card.dart';
import '../core/theme/nara_colors.dart';
import '../core/theme/nara_radius.dart';
import '../core/theme/nara_spacing.dart';
import '../core/theme/nara_text_styles.dart';
import '../core/formatters.dart';

class NaraStatCard extends StatelessWidget {
  final String title;
  final dynamic value; // int, double, String
  final String? subtitle;
  final Color? accentColor;
  final Widget? icon;
  final VoidCallback? onTap;
  final bool isCurrency;
  final bool isPercentage;

  const NaraStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.accentColor,
    this.icon,
    this.onTap,
    this.isCurrency = false,
    this.isPercentage = false,
  });

  String _formatValue() {
    if (isCurrency && value is num) {
      return formatRupiah(value);
    } else if (isPercentage && value is num) {
      return '${value.toStringAsFixed(1)}%';
    } else {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? NaraColors.primary;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 170,
        maxWidth: 240,
      ),
      child: NaraCard(
        onTap: onTap,
        padding: const EdgeInsets.all(NaraSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: NaraTextStyles.bodySmall.copyWith(
                          color: NaraColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: NaraSpacing.sm),
                      Text(
                        _formatValue(),
                        style: isCurrency || isPercentage
                            ? NaraTextStyles.amountLarge.copyWith(color: accent)
                            : NaraTextStyles.amountMedium.copyWith(color: accent),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (icon != null)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(NaraRadius.md),
                    ),
                    child: Center(
                      child: icon,
                    ),
                  ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: NaraSpacing.md),
              Text(
                subtitle!,
                style: NaraTextStyles.caption.copyWith(
                  color: NaraColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

