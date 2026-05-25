import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/index.dart';
import '../../core/i18n.dart';
import '../../core/theme/nara_colors.dart';
import '../../core/theme/nara_radius.dart';
import '../../core/theme/nara_spacing.dart';
import '../../core/theme/nara_text_styles.dart';
import '../../providers/app_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCompleting = false;
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    if (_isCompleting) {
      return;
    }

    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      setState(() {
        _isCompleting = true;
      });

      await context.read<AppProvider>().completeOnboarding();

      if (!mounted) {
        return;
      }

      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NaraColors.background,
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: 100,
            left: 50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: NaraColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: NaraColors.primary.withValues(alpha: 0.15),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: 50,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: NaraColors.accentOrange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: NaraColors.accentOrange.withValues(alpha: 0.15),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return _OnboardingPage(
                        title: I18n.t(context, 'onboarding_title_$index'),
                        description: I18n.t(context, 'onboarding_desc_$index'),
                        pageIndex: index,
                      );
                    },
                  ),
                ),
                
                // Bottom card
                NaraCard(
                  borderRadius: NaraRadius.xl,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: NaraSpacing.xs),
                            width: _currentPage == index ? 32 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index 
                                ? NaraColors.primary 
                                : NaraColors.textHint.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(NaraRadius.xs),
                              boxShadow: _currentPage == index
                                ? [
                                    BoxShadow(
                                      color: NaraColors.primary.withValues(alpha: 0.35),
                                      blurRadius: 10,
                                    )
                                  ]
                                : null,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: NaraSpacing.xl),
                      
                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _isCompleting
                                ? null
                                : () async {
                              setState(() {
                                _isCompleting = true;
                              });

                              await context.read<AppProvider>().completeOnboarding();

                              if (!context.mounted) {
                                return;
                              }

                              Navigator.pushReplacementNamed(context, '/home');
                            },
                            child: AnimatedOpacity(
                              opacity: _isCompleting ? 0.5 : 1,
                              duration: const Duration(milliseconds: 150),
                              child: Text(
                                _isCompleting ? I18n.t(context, 'saving') : I18n.t(context, 'skip'),
                                style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary),
                              ),
                            ),
                          ),
                          NaraPrimaryButton(
                            label: _currentPage < 2 ? I18n.t(context, 'continue') : I18n.t(context, 'enter_nara'),
                            onPressed: _nextPage,
                            isLoading: _isCompleting,
                            fullWidth: false,
                            icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: NaraColors.textOnPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final int pageIndex;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.pageIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(NaraSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Character placeholder
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  NaraColors.primary.withValues(alpha: 0.25),
                  NaraColors.accentOrange.withValues(alpha: 0.18),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(NaraRadius.lg),
            ),
            child: Center(
              child: Icon(
                pageIndex == 0 
                  ? Icons.record_voice_over_rounded
                  : pageIndex == 1 
                    ? Icons.psychology_rounded
                    : Icons.dashboard_rounded,
                size: 80,
                color: NaraColors.primary,
              ),
            ),
          ),
          const SizedBox(height: NaraSpacing.xxl),
          Text(
            title,
            style: NaraTextStyles.h1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: NaraSpacing.md),
          Text(
            description,
            style: NaraTextStyles.body.copyWith(color: NaraColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


