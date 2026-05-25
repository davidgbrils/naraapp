import 'package:flutter/material.dart';
import '../core/theme/nara_colors.dart';
import '../core/theme/nara_radius.dart';
import '../core/theme/nara_spacing.dart';
import '../core/theme/nara_text_styles.dart';

class NaraChip extends StatefulWidget {
  final String label;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? textColor;
  final bool selected;

  const NaraChip({
    super.key,
    required this.label,
    this.onRemove,
    this.onTap,
    this.backgroundColor,
    this.textColor,
    this.selected = false,
  });

  @override
  State<NaraChip> createState() => _NaraChipState();
}

class _NaraChipState extends State<NaraChip> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }

    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NaraSpacing.md,
        vertical: NaraSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: widget.selected ? NaraColors.primaryLight : (widget.backgroundColor ?? NaraColors.surfaceCard),
        borderRadius: BorderRadius.circular(NaraRadius.pill),
        border: widget.selected
            ? Border.all(color: NaraColors.primary, width: 1.5)
            : Border.all(color: NaraColors.textHint.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: NaraTextStyles.bodySmall.copyWith(
                color: widget.textColor ?? (widget.selected ? NaraColors.primary : NaraColors.textPrimary),
                fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (widget.onRemove != null) ...[
              const SizedBox(width: NaraSpacing.sm),
              GestureDetector(
                onTap: widget.onRemove,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: widget.textColor ?? (widget.selected ? NaraColors.primary : NaraColors.textSecondary),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (widget.onTap == null) {
      return chip;
    }

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: chip,
      ),
    );
  }
}

