import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../../core/i18n.dart';
import '../../core/theme/nara_colors.dart';
import '../../core/theme/nara_radius.dart';
import '../../core/theme/nara_spacing.dart';
import '../../core/theme/nara_text_styles.dart';
import 'package:nara/providers/app_provider.dart';

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
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _countdownController;
  Timer? _loudAlarmHapticTimer;
  Timer? _fullscreenHapticTimer;
  Timer? _autoActionTimer;
  static const int _autoSnoozeSeconds = 300;
  int _countdown = 0;
  int _autoActionSeconds = 0;
  bool _showFakeCall = false;
  bool _isFullscreenMode = false;
  bool _isLoudAlarmMode = false;
  bool _hasHandledAction = false;
  final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();

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

    final mode = (widget.reminder['mode'] as String?) ?? 'Notification';
    _showFakeCall = mode == 'Fake Call';
    _isFullscreenMode = mode == 'Fullscreen Alert';
    _isLoudAlarmMode = mode == 'Loud Alarm';
    _autoActionSeconds = _isLoudAlarmMode
        ? 90
        : (_isFullscreenMode ? 75 : (_showFakeCall ? 60 : 0));
    _countdown = _autoActionSeconds;

    _countdownController = AnimationController(
      duration: Duration(seconds: _autoActionSeconds > 0 ? _autoActionSeconds : 1),
      vsync: this,
    );

    _countdownController.addListener(() {
      setState(() {
        _countdown = (_autoActionSeconds -
                (_countdownController.value * _autoActionSeconds))
            .toInt()
            .clamp(0, _autoActionSeconds);
      });
    });

    if (_autoActionSeconds > 0) {
      _countdownController.forward();
    }

    if (_isLoudAlarmMode) {
      _loudAlarmHapticTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
        HapticFeedback.heavyImpact();
      });
    } else if (_isFullscreenMode) {
      _fullscreenHapticTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        HapticFeedback.mediumImpact();
      });
    }
    _startAlertSound();

    if (_autoActionSeconds > 0) {
      _autoActionTimer = Timer(Duration(seconds: _autoActionSeconds), () {
        if (!mounted) return;
        _handleAutoSnooze();
      });
    }
  }

  @override
  void dispose() {
    _stopAlertSound();
    _autoActionTimer?.cancel();
    _loudAlarmHapticTimer?.cancel();
    _fullscreenHapticTimer?.cancel();
    _pulseController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  void _handleSnooze() {
    if (_hasHandledAction || !mounted) return;
    _hasHandledAction = true;
    _autoActionTimer?.cancel();
    _stopAlertSound();
    final provider = context.read<AppProvider>();
    provider.snoozeAlert(300);
    provider.dismissAlert();
    Navigator.of(context).pop(false);
  }

  void _handleAnswer() {
    if (_hasHandledAction || !mounted) return;
    _hasHandledAction = true;
    _autoActionTimer?.cancel();
    _stopAlertSound();
    final provider = context.read<AppProvider>();
    provider.dismissAlert();
    Navigator.of(context).pop(true);
  }

  void _handleAutoSnooze() {
    if (_hasHandledAction || !mounted) return;
    _hasHandledAction = true;
    _autoActionTimer?.cancel();
    _stopAlertSound();
    final provider = context.read<AppProvider>();
    provider.snoozeAlert(_autoSnoozeSeconds);
    provider.dismissAlert();
    Navigator.of(context).pop(false);
  }

  void _startAlertSound() {
    if (_isLoudAlarmMode) {
      _ringtonePlayer.play(
        android: AndroidSounds.alarm,
        ios: IosSounds.alarm,
        looping: true,
        volume: 1.0,
        asAlarm: true,
      );
      return;
    }
    if (_isFullscreenMode) {
      _ringtonePlayer.play(
        android: AndroidSounds.alarm,
        ios: IosSounds.glass,
        looping: true,
        volume: 0.75,
        asAlarm: true,
      );
      return;
    }
    if (_showFakeCall) {
      _ringtonePlayer.play(
        android: AndroidSounds.ringtone,
        ios: IosSounds.glass,
        looping: true,
        volume: 0.55,
        asAlarm: false,
      );
    }
  }

  void _stopAlertSound() {
    _ringtonePlayer.stop();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.reminder['title'] as String? ?? I18n.t(context, 'pay_electricity_bill');

    if (_showFakeCall) {
      return _buildFakeCallAlert(title);
    }

    final headerText = _isFullscreenMode
        ? I18n.t(context, 'reminder_mode_loud_alarm')
        : _isLoudAlarmMode
            ? I18n.t(context, 'reminder_mode_loud_alarm')
            : I18n.t(context, 'reminder_mode_notification');
    final accentColor = _isLoudAlarmMode ? NaraColors.danger : NaraColors.warning;
    final foregroundTextColor = _isFullscreenMode ? NaraColors.surfaceWhite : NaraColors.textPrimary;
    final secondaryTextColor = _isFullscreenMode ? NaraColors.surfaceWhite.withValues(alpha: 0.8) : NaraColors.textSecondary;

    return Scaffold(
      backgroundColor: (_isFullscreenMode ? NaraColors.textPrimary : NaraColors.background).withValues(alpha: 0.98),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: NaraSpacing.lg),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: NaraSpacing.lg, vertical: NaraSpacing.sm),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(NaraRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: NaraColors.warning,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: NaraColors.warning.withValues(alpha: 0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: NaraSpacing.sm),
                      Text(
                        headerText.toUpperCase(),
                        style: NaraTextStyles.label.copyWith(
                          color: accentColor,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: NaraSpacing.xxl),
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          NaraColors.warning.withValues(alpha: 0.3),
                          NaraColors.warning.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: NaraColors.warning.withValues(alpha: 0.2),
                        ),
                        child: Icon(
                          Icons.notifications_active_rounded,
                          size: 50,
                          color: NaraColors.warning,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: NaraSpacing.xxxl),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: NaraSpacing.lg),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: NaraTextStyles.h1.copyWith(fontWeight: FontWeight.w700, color: foregroundTextColor),
                  ),
                ),
                const SizedBox(height: NaraSpacing.md),
                if (_autoActionSeconds > 0) ...[
                  Text(I18n.t(context, 'snooze_in_sec', params: {'sec': '$_countdown'}), style: NaraTextStyles.body.copyWith(color: secondaryTextColor)),
                  const SizedBox(height: NaraSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: NaraSpacing.xxl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(NaraRadius.xs),
                      child: LinearProgressIndicator(
                        value: _countdownController.value,
                        minHeight: 4,
                        backgroundColor: NaraColors.surfaceCard,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          NaraColors.warning.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: NaraSpacing.xxxl),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: NaraSpacing.lg),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: FilledButton.icon(
                          onPressed: _handleAnswer,
                          icon: const Icon(Icons.notifications_active_rounded, size: 24),
                          label: Text(
                            I18n.t(context, 'complete'),
                            style: NaraTextStyles.label.copyWith(
                              color: NaraColors.textOnPrimary,
                              fontSize: 16,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: NaraColors.warning,
                            foregroundColor: NaraColors.textOnPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(NaraRadius.md),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: NaraSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _handleSnooze,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _isFullscreenMode
                                ? NaraColors.surfaceWhite.withValues(alpha: 0.12)
                                : NaraColors.surfaceWhite,
                            padding: const EdgeInsets.symmetric(vertical: NaraSpacing.md),
                            side: BorderSide(
                              color: _isFullscreenMode
                                  ? NaraColors.surfaceWhite.withValues(alpha: 0.45)
                                  : NaraColors.textHint.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            I18n.t(context, 'snooze_5_minutes'),
                            style: NaraTextStyles.label.copyWith(color: foregroundTextColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: NaraSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFakeCallAlert(String reminderTitle) {
    return Scaffold(
      backgroundColor: NaraColors.textPrimary,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  NaraColors.primary.withValues(alpha: 0.1),
                  NaraColors.background,
                ],
                radius: 1.5,
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final ringSize = (constraints.maxWidth * 0.48).clamp(140.0, 180.0);
                final innerSize = (ringSize * 0.78).clamp(110.0, 140.0);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: NaraSpacing.lg, vertical: NaraSpacing.lg),
                      child: Column(
                        children: [
                          Text(
                            I18n.t(context, 'incoming_call'),
                            style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary),
                          ),
                          const SizedBox(height: NaraSpacing.sm),
                          Text(
                            'NARA Reminder',
                            style: NaraTextStyles.h2.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: NaraSpacing.xs),
                          Text(
                            reminderTitle,
                            textAlign: TextAlign.center,
                            style: NaraTextStyles.body.copyWith(color: NaraColors.textSecondary),
                          ),
                          const SizedBox(height: NaraSpacing.xs),
                          Text(
                            'Fake Call',
                            style: NaraTextStyles.caption.copyWith(
                              color: NaraColors.textSecondary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          height: ringSize,
                          width: ringSize,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ScaleTransition(
                                scale: _pulseAnimation,
                                child: Container(
                                  width: ringSize,
                                  height: ringSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: NaraColors.primary.withValues(alpha: 0.4),
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: innerSize,
                                height: innerSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      NaraColors.primary.withValues(alpha: 0.2),
                                      NaraColors.primary.withValues(alpha: 0.05),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.call_rounded,
                                    size: innerSize * 0.42,
                                    color: NaraColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(NaraSpacing.lg, NaraSpacing.lg, NaraSpacing.lg, NaraSpacing.xl),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _handleAnswer,
                              icon: const Icon(Icons.call_rounded, size: 20),
                              label: Text(I18n.t(context, 'answer')),
                              style: FilledButton.styleFrom(
                                backgroundColor: NaraColors.success,
                                foregroundColor: NaraColors.textOnPrimary,
                                padding: const EdgeInsets.symmetric(vertical: NaraSpacing.md),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(NaraRadius.md),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: NaraSpacing.sm),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _handleSnooze,
                              icon: const Icon(Icons.snooze_rounded, size: 20),
                              label: Text(I18n.t(context, 'snooze_5_minutes')),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: NaraColors.surfaceWhite,
                                side: BorderSide(
                                  color: NaraColors.surfaceWhite.withValues(alpha: 0.35),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: NaraSpacing.md),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(NaraRadius.md),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}




