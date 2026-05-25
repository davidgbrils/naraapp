import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/nara_colors.dart';
import '../core/theme/nara_radius.dart';
import '../core/theme/nara_spacing.dart';
import '../core/theme/nara_text_styles.dart';
import '../providers/app_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    
    _controller.forward();
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final appProvider = context.read<AppProvider>();
        Navigator.pushReplacementNamed(
          context,
          appProvider.isOnboardingComplete ? '/home' : '/onboarding',
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NaraColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            NaraColors.primary,
                            NaraColors.primaryLight,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(NaraRadius.xl),
                        boxShadow: [
                          BoxShadow(
                            color: NaraColors.primary.withValues(alpha: 0.35),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        size: 60,
                        color: NaraColors.textOnPrimary,
                      ),
                    ),
                    const SizedBox(height: NaraSpacing.xl),
                    Text(
                      'NARA',
                      style: NaraTextStyles.h1.copyWith(fontSize: 40, letterSpacing: 4),
                    ),
                    const SizedBox(height: NaraSpacing.sm),
                    Text(
                      'Smart Voice Life Assistant',
                      style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

