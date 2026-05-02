import 'package:flutter/material.dart';
import '../../core/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Cukup Ngomong, Beres!',
      'description': 'Catat utang, buat reminder, lacak pengeluaran — semua cukup dengan suara. Tanpa ribet, tanpa ketik.',
      'image': 'onboarding_1',
    },
    {
      'title': 'Asisten Suara Cerdas',
      'description': 'NARA memahami konteks percakapan. Bilang "bayar listrik bulan ini" dan NARA tahu apa yang harus dilakukan.',
      'image': 'onboarding_2',
    },
    {
      'title': 'Semua dalam Satu Tempat',
      'description': 'Kelola keuangan, utang-piutang, dan jadwalmu di satu aplikasi. Mulai sekarang dan rasakan bedanya!',
      'image': 'onboarding_3',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
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
                color: AppTheme.primaryContainer.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryContainer.withValues(alpha: 0.2),
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
                color: AppTheme.secondary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondary.withValues(alpha: 0.2),
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
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _OnboardingPage(
                        title: _pages[index]['title'],
                        description: _pages[index]['description'],
                        pageIndex: index,
                      );
                    },
                  ),
                ),
                
                // Bottom card
                GlassContainer(
                  borderRadius: 28,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 32 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index 
                                ? AppTheme.primaryContainer 
                                : AppTheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: _currentPage == index
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryContainer.withValues(alpha: 0.4),
                                      blurRadius: 10,
                                    )
                                  ]
                                : null,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                      
                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                            child: Text(
                              'Skip',
                              style: AppTheme.label.copyWith(color: AppTheme.outline),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryContainer,
                              foregroundColor: AppTheme.onPrimaryContainer,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Lanjut', style: AppTheme.label),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
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
      padding: const EdgeInsets.all(24),
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
                  AppTheme.primaryContainer.withValues(alpha: 0.3),
                  AppTheme.secondary.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Icon(
                pageIndex == 0 
                  ? Icons.record_voice_over_rounded
                  : pageIndex == 1 
                    ? Icons.psychology_rounded
                    : Icons.dashboard_rounded,
                size: 80,
                color: AppTheme.primaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: AppTheme.h1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: AppTheme.body.copyWith(color: AppTheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}