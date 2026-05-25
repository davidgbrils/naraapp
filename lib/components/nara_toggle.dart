import 'package:flutter/material.dart';
import '../core/theme/nara_colors.dart';
import '../core/theme/nara_spacing.dart';
import '../core/theme/nara_text_styles.dart';

class NaraToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;

  const NaraToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  @override
  State<NaraToggle> createState() => _NaraToggleState();
}

class _NaraToggleState extends State<NaraToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: widget.value ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(NaraToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      widget.value
          ? _controller.forward()
          : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onChanged(!widget.value),
      onTapDown: (_) {
        if (!_isPressed) {
          setState(() => _isPressed = true);
        }
      },
      onTapUp: (_) {
        if (_isPressed) {
          setState(() => _isPressed = false);
        }
      },
      onTapCancel: () {
        if (_isPressed) {
          setState(() => _isPressed = false);
        }
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  width: 48,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      NaraColors.surfaceCard,
                      NaraColors.primary,
                      _controller.value,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: NaraColors.primary.withValues(alpha: _controller.value * 0.3),
                        blurRadius: 8,
                        offset: Offset(0, _controller.value * 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: NaraColors.textSecondary
                                .withValues(alpha: 1 - _controller.value),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.check,
                            size: 14,
                            color: NaraColors.primary
                                .withValues(alpha: _controller.value),
                          ),
                        ),
                      ),
                      Positioned(
                        left: _controller.value * 20,
                        top: 2,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: NaraColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (widget.label != null) ...[
              const SizedBox(width: NaraSpacing.md),
              Text(
                widget.label!,
                style: NaraTextStyles.body,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

