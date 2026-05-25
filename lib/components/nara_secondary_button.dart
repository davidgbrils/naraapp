import 'package:flutter/material.dart';
import '../core/theme/nara_colors.dart';
import '../core/theme/nara_radius.dart';
import '../core/theme/nara_spacing.dart';
import '../core/theme/nara_text_styles.dart';

class NaraSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double? width;
  final double height;
  final TextStyle? textStyle;
  final Widget? icon;
  final bool fullWidth;
  final Color? backgroundColor;

  const NaraSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width,
    this.height = 44,
    this.textStyle,
    this.icon,
    this.fullWidth = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth.isFinite && constraints.maxWidth < 170;
        final horizontalPadding = compact ? NaraSpacing.md : NaraSpacing.lg;
        final iconSpacing = compact ? NaraSpacing.xs : NaraSpacing.sm;
        final baseStyle = textStyle ??
            NaraTextStyles.body.copyWith(
              color: NaraColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 13 : NaraTextStyles.body.fontSize,
            );

        return Container(
          width: fullWidth ? double.infinity : width,
          constraints: BoxConstraints(minHeight: height),
          decoration: BoxDecoration(
            color: backgroundColor ?? NaraColors.surfaceCard,
            borderRadius: BorderRadius.circular(NaraRadius.pill),
            border: Border.all(
              color: NaraColors.primary,
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(NaraRadius.pill),
              onTap: onPressed,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: NaraSpacing.md,
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        icon!,
                        SizedBox(width: iconSpacing),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: baseStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
