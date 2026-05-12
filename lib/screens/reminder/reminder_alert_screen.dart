import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class ReminderAlertScreen extends StatefulWidget {
  final Map<String, dynamic> reminder;
  final int reminderIndex;

  const ReminderAlertScreen({
    super.key,
    required this.reminder,
    required this.reminderIndex,
  });

  @override
  State<ReminderAlertScreen> createState() => _ReminderAlertScreenState();
}

class _ReminderAlertScreenState extends State<ReminderAlertScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _countdownController;
  int _countdown = 10;
  bool _showFakeCall = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start countdown
    _countdownController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _countdownController.addListener(() {
      setState(() {
        _countdown = (10 - (_countdownController.value * 10)).toInt().clamp(0, 10);
      });
    });

    _countdownController.forward();

    // Set fake call mode based on reminder type
    _showFakeCall = (widget.reminder['mode'] as String? ?? 'Notifikasi') == 'Fake Call';

    // Auto-answer after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && context.mounted) {
        _handleAnswer();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  void _handleDecline() {
    final provider = context.read<AppProvider>();
    provider.dismissAlert();
    Navigator.of(context).pop(false);
  }

  void _handleSnooze() {
    final provider = context.read<AppProvider>();
    provider.snoozeAlert(300); // 5 minutes
    provider.dismissAlert();
    Navigator.of(context).pop('snooze');
  }

  void _handleAnswer() {
    final provider = context.read<AppProvider>();
    provider.dismissAlert();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.reminder['title'] as String? ?? 'Bayar tagihan listrik';

    if (_showFakeCall) {
      return _buildFakeCallAlert(title);
    }

    return Scaffold(
      backgroundColor: AppTheme.background.withValues(alpha: 0.98),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.tertiary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.tertiary.withValues(alpha: 0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'PENGINGATKAN',
                        style: AppTheme.label.copyWith(
                          color: AppTheme.tertiary,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Animated pulse circle with icon
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.tertiary.withValues(alpha: 0.3),
                          AppTheme.tertiary.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.tertiary.withValues(alpha: 0.2),
                        ),
                        child: Icon(
                          Icons.notifications_active_rounded,
                          size: 50,
                          color: AppTheme.tertiary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTheme.h1.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),

                // Countdown
                Text(
                  'Snooze dalam $_countdown detik',
                  style: AppTheme.body.copyWith(color: AppTheme.outline),
                ),
                const SizedBox(height: 8),

                // Countdown progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _countdownController.value,
                      minHeight: 4,
                      backgroundColor: AppTheme.surfaceContainer,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.tertiary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Main answer button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: FilledButton.icon(
                          onPressed: _handleAnswer,
                          icon: const Icon(Icons.notifications_active_rounded, size: 24),
                          label: Text(
                            'Mengingatkan',
                            style: AppTheme.label.copyWith(
                              color: AppTheme.onTertiaryContainer,
                              fontSize: 16,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.tertiary,
                            foregroundColor: AppTheme.onTertiary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Secondary buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _handleSnooze,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Text(
                                'Snooze',
                                style: AppTheme.label.copyWith(color: AppTheme.onSurface),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _handleDecline,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(
                                  color: AppTheme.danger.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                'Dismiss',
                                style: AppTheme.label.copyWith(color: AppTheme.danger),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFakeCallAlert(String reminderTitle) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryContainer.withValues(alpha: 0.1),
                  AppTheme.background,
                ],
                radius: 1.5,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header with call info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    children: [
                      Text(
                        'Incoming Call...',
                        style: AppTheme.label.copyWith(color: AppTheme.outline),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'NARA Reminder 📱',
                        style: AppTheme.h2.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reminderTitle,
                        textAlign: TextAlign.center,
                        style: AppTheme.body.copyWith(color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),

                // Animated pulse ring
                Column(
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryContainer.withValues(alpha: 0.4),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.primaryContainer.withValues(alpha: 0.2),
                            AppTheme.primaryContainer.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.call_rounded,
                          size: 60,
                          color: AppTheme.primaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),

                // Action buttons - Call style
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Decline button (red)
                          Column(
                            children: [
                              GestureDetector(
                                onTap: _handleDecline,
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: AppTheme.danger,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.danger.withValues(alpha: 0.4),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.call_end_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Decline',
                                style: AppTheme.label.copyWith(color: AppTheme.outline),
                              ),
                            ],
                          ),

                          // Snooze button (gray)
                          Column(
                            children: [
                              GestureDetector(
                                onTap: _handleSnooze,
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceContainerHigh,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.snooze_rounded,
                                    color: AppTheme.outline,
                                    size: 32,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Snooze',
                                style: AppTheme.label.copyWith(color: AppTheme.outline),
                              ),
                            ],
                          ),

                          // Answer button (green)
                          Column(
                            children: [
                              GestureDetector(
                                onTap: _handleAnswer,
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: AppTheme.success,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.success.withValues(alpha: 0.4),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.call_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Answer',
                                style: AppTheme.label.copyWith(color: AppTheme.outline),
                              ),
                            ],
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
