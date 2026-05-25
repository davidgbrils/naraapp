import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n.dart';
import '../../core/theme/nara_colors.dart';
import '../../core/theme/nara_radius.dart';
import '../../core/theme/nara_spacing.dart';
import '../../core/theme/nara_text_styles.dart';
import '../../providers/app_provider.dart';

class VoiceWaveform extends StatefulWidget {
  final bool isAnimating;

  const VoiceWaveform({super.key, required this.isAnimating});

  @override
  State<VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(5, (index) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 600 + (index * 100)),
      );
    });
    
    if (widget.isAnimating) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(VoiceWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !oldWidget.isAnimating) {
      _startAnimation();
    } else if (!widget.isAnimating && oldWidget.isAnimating) {
      _stopAnimation();
    }
  }

  void _startAnimation() {
    for (var controller in _controllers) {
      controller.repeat(reverse: true);
    }
  }

  void _stopAnimation() {
    for (var controller in _controllers) {
      controller.stop();
      controller.reset();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(5, (index) {
          return AnimatedBuilder(
            animation: _controllers[index],
            builder: (context, child) {
              double height = widget.isAnimating 
                ? 8 + (_controllers[index].value * 16)
                : 8.0;
              double opacity = widget.isAnimating 
                ? 0.5 + (_controllers[index].value * 0.5)
                : 0.6;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 6,
                height: height,
                decoration: BoxDecoration(
                  color: NaraColors.primary.withValues(alpha: opacity),
                  borderRadius: BorderRadius.circular(NaraRadius.xs),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class VoiceOverlay extends StatelessWidget {
  const VoiceOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (!provider.isListening && !provider.isProcessing) {
          return const SizedBox.shrink();
        }

        return Positioned.fill(
          child: GestureDetector(
            onTap: () => provider.stopListening(),
            child: Container(
              color: NaraColors.background.withValues(alpha: 0.95),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Status text
                    Text(
                      provider.isListening ? I18n.t(context, 'listening') : I18n.t(context, 'processing'),
                      style: NaraTextStyles.h2,
                    ),
                    const SizedBox(height: NaraSpacing.sm),
                    Text(
                      provider.isListening 
                        ? I18n.t(context, 'say_something_to_nara')
                        : I18n.t(context, 'understanding_request'),
                      style: NaraTextStyles.body.copyWith(color: NaraColors.textSecondary),
                    ),
                    if (provider.voiceErrorMessage.isNotEmpty) ...[
                      const SizedBox(height: NaraSpacing.sm),
                      Text(
                        provider.voiceErrorMessage,
                        style: NaraTextStyles.caption.copyWith(color: NaraColors.danger),
                        textAlign: TextAlign.center,
                      ),
                    ] else if (provider.lastIntent.trim().isNotEmpty) ...[
                      const SizedBox(height: NaraSpacing.sm),
                      Text(
                        '"${provider.lastIntent.trim()}"',
                        style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: NaraSpacing.xxl),
                    
                    // Voice visualization
                    VoiceWaveform(isAnimating: provider.isListening),
                    
                    const SizedBox(height: NaraSpacing.xxl),
                    
                    // Stop button
                    GestureDetector(
                      onTap: () => provider.stopListening(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: NaraSpacing.xl, vertical: NaraSpacing.md),
                        decoration: BoxDecoration(
                          color: NaraColors.danger.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(NaraRadius.pill),
                          border: Border.all(color: NaraColors.danger.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stop_rounded, color: NaraColors.danger, size: 20),
                            const SizedBox(width: NaraSpacing.sm),
                            Text(I18n.t(context, 'cancel'), style: NaraTextStyles.label.copyWith(color: NaraColors.danger)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
