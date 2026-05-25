import 'package:flutter/material.dart';
import '../core/theme/nara_colors.dart';
import '../core/theme/nara_radius.dart';
import '../core/theme/nara_shadows.dart';
import '../core/theme/nara_spacing.dart';

class NaraCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final List<BoxShadow>? customShadow;
  final bool elevated;

  const NaraCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(NaraSpacing.lg),
    this.margin,
    this.borderRadius = NaraRadius.md,
    this.onTap,
    this.backgroundColor,
    this.customShadow,
    this.elevated = false,
  });

  @override
  State<NaraCard> createState() => _NaraCardState();
}

class _NaraCardState extends State<NaraCard> {
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultShadow = isDark
        ? <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: widget.elevated ? 20 : 14,
              offset: const Offset(0, 8),
            ),
          ]
        : (widget.elevated ? NaraShadows.card : NaraShadows.cardSmall);
    final shadow = widget.customShadow ?? defaultShadow;
    final card = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? theme.cardTheme.color ?? NaraColors.surfaceWhite,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: shadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Padding(
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );

    if (widget.onTap == null) {
      return card;
    }

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: card,
      ),
    );
  }
}
