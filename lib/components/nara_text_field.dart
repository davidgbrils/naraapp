import 'package:flutter/material.dart';
import '../core/theme/nara_colors.dart';
import '../core/theme/nara_radius.dart';
import '../core/theme/nara_shadows.dart';
import '../core/theme/nara_spacing.dart';
import '../core/theme/nara_text_styles.dart';

class NaraTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final int maxLines;
  final int minLines;
  final bool obscureText;
  final String? errorText;

  const NaraTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines = 1,
    this.obscureText = false,
    this.errorText,
  });

  @override
  State<NaraTextField> createState() => _NaraTextFieldState();
}

class _NaraTextFieldState extends State<NaraTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fieldBackground = theme.inputDecorationTheme.fillColor ?? NaraColors.surfaceCard;
    final hintColor = theme.inputDecorationTheme.hintStyle?.color ?? NaraColors.textHint;
    final textColor = isDark ? Colors.white : NaraColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: NaraTextStyles.label.copyWith(
              color: _isFocused ? NaraColors.primary : NaraColors.textSecondary,
            ),
          ),
          const SizedBox(height: NaraSpacing.sm),
        ],
        Container(
          decoration: BoxDecoration(
            color: fieldBackground,
            borderRadius: BorderRadius.circular(NaraRadius.md),
            border: Border.all(
              color: _isFocused ? NaraColors.primary : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: NaraShadows.cardSmall,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            minLines: widget.minLines,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: widget.hint,
              hintStyle: NaraTextStyles.bodySmall.copyWith(
                color: hintColor,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.all(NaraSpacing.md),
                      child: widget.prefixIcon,
                    )
                  : null,
              suffixIcon: widget.suffixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.all(NaraSpacing.md),
                      child: widget.suffixIcon,
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: NaraSpacing.lg,
                vertical: NaraSpacing.md,
              ),
            ),
            style: NaraTextStyles.body.copyWith(color: textColor),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: NaraSpacing.sm),
          Text(
            widget.errorText!,
            style: NaraTextStyles.caption.copyWith(
              color: NaraColors.danger,
            ),
          ),
        ],
      ],
    );
  }
}
