import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/i18n.dart';
import '../core/theme/nara_colors.dart';
import '../core/theme/nara_radius.dart';
import '../core/theme/nara_spacing.dart';
import '../core/theme/nara_text_styles.dart';
import '../providers/app_provider.dart';
import '../services/startup_permission_service.dart';

class StartupPermissionsScreen extends StatefulWidget {
  const StartupPermissionsScreen({super.key});

  @override
  State<StartupPermissionsScreen> createState() => _StartupPermissionsScreenState();
}

class _StartupPermissionsScreenState extends State<StartupPermissionsScreen> {
  bool _isRequesting = false;

  Future<void> _continue({required bool requestPermissions}) async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);
    final provider = context.read<AppProvider>();
    if (requestPermissions) {
      await StartupPermissionService.requestEssentialPermissions();
    }
    await provider.completeStartupPermissions();
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      provider.isOnboardingComplete ? '/home' : '/onboarding',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = context.watch<AppProvider>().language == 'English';
    return Scaffold(
      backgroundColor: NaraColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(NaraSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: NaraColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(NaraRadius.xl),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: NaraColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: NaraSpacing.xl),
              Text(
                I18n.t(context, 'startup_permissions_title'),
                style: NaraTextStyles.h1,
              ),
              const SizedBox(height: NaraSpacing.sm),
              Text(
                I18n.t(context, 'startup_permissions_desc'),
                style: NaraTextStyles.body.copyWith(color: NaraColors.textSecondary),
              ),
              const SizedBox(height: NaraSpacing.xl),
              _PermissionPoint(
                icon: Icons.mic_rounded,
                title: I18n.t(context, 'startup_permission_microphone'),
                body: I18n.t(context, 'startup_permission_microphone_desc'),
              ),
              _PermissionPoint(
                icon: Icons.notifications_active_rounded,
                title: I18n.t(context, 'startup_permission_notification'),
                body: I18n.t(context, 'startup_permission_notification_desc'),
              ),
              _PermissionPoint(
                icon: Icons.alarm_rounded,
                title: I18n.t(context, 'startup_permission_alarm'),
                body: I18n.t(context, 'startup_permission_alarm_desc'),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isRequesting ? null : () => _continue(requestPermissions: true),
                  style: FilledButton.styleFrom(
                    backgroundColor: NaraColors.primary,
                    foregroundColor: NaraColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: NaraSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(NaraRadius.lg),
                    ),
                  ),
                  child: _isRequesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(I18n.t(context, 'allow_all_permissions')),
                ),
              ),
              const SizedBox(height: NaraSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: _isRequesting ? null : () => _continue(requestPermissions: false),
                  child: Text(
                    isEnglish ? 'Skip for now' : 'Lewati dulu',
                    style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionPoint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _PermissionPoint({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: NaraSpacing.sm),
      padding: const EdgeInsets.all(NaraSpacing.md),
      decoration: BoxDecoration(
        color: NaraColors.surfaceWhite,
        borderRadius: BorderRadius.circular(NaraRadius.lg),
        border: Border.all(color: NaraColors.shadowDark.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: NaraColors.primary),
          const SizedBox(width: NaraSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: NaraTextStyles.label),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
