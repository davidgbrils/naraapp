import 'package:flutter/material.dart';
import '../core/theme/nara_colors.dart';
import '../core/theme/nara_radius.dart';
import '../core/theme/nara_shadows.dart';
import '../core/theme/nara_spacing.dart';
import '../core/theme/nara_text_styles.dart';

class NaraPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final double? width;
  final double height;
  final TextStyle? textStyle;
  final Widget? icon;
  final bool fullWidth;

  const NaraPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 48,
    this.textStyle,
    this.icon,
    this.fullWidth = true,
  });

  @override
  State<NaraPrimaryButton> createState() => _NaraPrimaryButtonState();
}

class _NaraPrimaryButtonState extends State<NaraPrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: widget.fullWidth ? double.infinity : widget.width,
        constraints: BoxConstraints(minHeight: widget.height),
        decoration: BoxDecoration(
          color: widget.isLoading ? NaraColors.primary.withValues(alpha: 0.8) : NaraColors.primary,
          borderRadius: BorderRadius.circular(NaraRadius.pill),
          boxShadow: NaraShadows.primaryButton,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(NaraRadius.pill),
            onTap: widget.isLoading ? null : widget.onPressed,
            onHighlightChanged: (isHighlighted) {
              if (isHighlighted) {
                _animationController.forward();
              } else {
                _animationController.reverse();
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: NaraSpacing.lg,
                vertical: NaraSpacing.md,
              ),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            NaraColors.textOnPrimary,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            widget.icon!,
                            const SizedBox(width: NaraSpacing.sm),
                          ],
                          Flexible(
                            child: Text(
                              widget.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: widget.textStyle ??
                                  NaraTextStyles.body.copyWith(
                                    color: NaraColors.textOnPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

