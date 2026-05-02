import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
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
                  color: AppTheme.primary.withValues(alpha: opacity),
                  borderRadius: BorderRadius.circular(3),
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
              color: AppTheme.background.withValues(alpha: 0.95),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Status text
                    Text(
                      provider.isListening ? 'Mendengarkan...' : 'Memproses...',
                      style: AppTheme.h2,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.isListening 
                        ? 'Katakan sesuatu kepada NARA'
                        : 'Sedang memahami permintaanmu',
                      style: AppTheme.body.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 40),
                    
                    // Voice visualization
                    VoiceWaveform(isAnimating: provider.isListening),
                    
                    const SizedBox(height: 40),
                    
                    // Stop button
                    GestureDetector(
                      onTap: () => provider.stopListening(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.danger.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stop_rounded, color: AppTheme.danger, size: 20),
                            const SizedBox(width: 8),
                            Text('Batal', style: AppTheme.label.copyWith(color: AppTheme.danger)),
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