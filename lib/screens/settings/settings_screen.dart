import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../components/index.dart';
import '../../core/i18n.dart';
import '../../core/snackbar_utils.dart';
import '../../core/theme/nara_colors.dart';
import '../../core/theme/nara_radius.dart';
import '../../core/theme/nara_spacing.dart';
import '../../core/theme/nara_text_styles.dart';
import '../../providers/app_provider.dart';
import '../../services/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  static const String _hiddenActivityIdsKey = 'recent_activity_hidden_ids_v1';

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title, style: NaraTextStyles.h3),
        content: Text(message, style: NaraTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(I18n.t(context, 'close'), style: NaraTextStyles.label),
          ),
        ],
      ),
    );
  }

  Future<void> _showLanguageDialog(BuildContext context, AppProvider provider) async {
    const options = ['Indonesia', 'English'];
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(I18n.t(context, 'choose_language'), style: NaraTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (lang) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    provider.language == lang
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: provider.language == lang ? NaraColors.primary : NaraColors.textSecondary,
                  ),
                  title: Text(lang, style: NaraTextStyles.body),
                  onTap: () async {
                    await provider.setLanguage(lang);
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<void> _showVoiceDialog(BuildContext context, AppProvider provider) async {
    double tempSpeed = provider.voiceSpeed;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(I18n.t(context, 'voice_title'), style: NaraTextStyles.h3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                I18n.t(context, 'voice_speed_label', params: {'value': '${tempSpeed.toStringAsFixed(1)}x'}),
                style: NaraTextStyles.body,
              ),
              Slider(
                value: tempSpeed,
                min: 0.5,
                max: 2.0,
                divisions: 15,
                onChanged: (value) => setState(() => tempSpeed = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(I18n.t(context, 'cancel'), style: NaraTextStyles.label),
            ),
            ElevatedButton(
              onPressed: () async {
                await provider.setVoiceSpeed(tempSpeed);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: Text(I18n.t(context, 'save'), style: NaraTextStyles.label),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReminderHealthDialog(BuildContext context) async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final service = NotificationService();
    ReminderHealthStatus status = await service.getReminderHealthStatus();

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            isEnglish ? 'Reminder Health Check' : 'Cek Kesehatan Reminder',
            style: NaraTextStyles.h3,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _healthRow(
                context,
                isEnglish ? 'Notifications enabled' : 'Izin notifikasi aktif',
                status.notificationsEnabled,
              ),
              const SizedBox(height: NaraSpacing.sm),
              _healthRow(
                context,
                isEnglish ? 'Exact alarm allowed' : 'Izin exact alarm aktif',
                status.exactAlarmAllowed,
              ),
              const SizedBox(height: NaraSpacing.sm),
              _healthRow(
                context,
                isEnglish
                    ? 'Fullscreen intent status'
                    : 'Status fullscreen intent',
                status.fullScreenIntentGranted,
                unknownLabel: isEnglish ? 'Needs manual grant' : 'Perlu izin manual',
              ),
              const SizedBox(height: NaraSpacing.sm),
              _healthRow(
                context,
                isEnglish
                    ? 'Battery optimization ignored'
                    : 'Optimasi baterai diabaikan',
                status.batteryOptimizationIgnored,
                unknownLabel: isEnglish ? 'Unknown' : 'Tidak diketahui',
              ),
              const SizedBox(height: NaraSpacing.md),
              Text(
                isEnglish
                    ? 'If any item is disabled, tap "Request Permissions", then allow in system settings.'
                    : 'Jika ada yang nonaktif, tap "Minta Izin", lalu izinkan di pengaturan sistem.',
                style: NaraTextStyles.bodySmall.copyWith(
                  color: NaraColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                I18n.t(context, 'close'),
                style: NaraTextStyles.label,
              ),
            ),
            TextButton(
              onPressed: () async {
                final refreshed = await service.getReminderHealthStatus();
                setState(() => status = refreshed);
              },
              child: Text(
                isEnglish ? 'Recheck' : 'Cek Ulang',
                style: NaraTextStyles.label,
              ),
            ),
            TextButton(
              onPressed: () => service.openReminderSystemSettings('notification'),
              child: Text(
                isEnglish ? 'Notif Settings' : 'Setelan Notif',
                style: NaraTextStyles.label,
              ),
            ),
            TextButton(
              onPressed: () => service.openReminderSystemSettings('exact_alarm'),
              child: Text(
                isEnglish ? 'Exact Alarm' : 'Exact Alarm',
                style: NaraTextStyles.label,
              ),
            ),
            TextButton(
              onPressed: () => service.openReminderSystemSettings('fullscreen'),
              child: Text(
                isEnglish ? 'Fullscreen' : 'Fullscreen',
                style: NaraTextStyles.label,
              ),
            ),
            TextButton(
              onPressed: () => service.openReminderSystemSettings('battery'),
              child: Text(
                isEnglish ? 'Battery' : 'Baterai',
                style: NaraTextStyles.label,
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await service.requestReminderPermissions();
                final refreshed = await service.getReminderHealthStatus();
                setState(() => status = refreshed);
              },
              child: Text(
                isEnglish ? 'Request Permissions' : 'Minta Izin',
                style: NaraTextStyles.label,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _healthRow(
    BuildContext context,
    String label,
    bool? value, {
    String? unknownLabel,
  }) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final statusText = value == null
        ? (unknownLabel ?? '-')
        : (value ? 'OK' : (isEnglish ? 'Needs Fix' : 'Perlu Diperbaiki'));
    final statusColor = value == null
        ? NaraColors.textSecondary
        : (value ? NaraColors.success : NaraColors.danger);
    return Row(
      children: [
        Expanded(
          child: Text(label, style: NaraTextStyles.body),
        ),
        Text(
          statusText,
          style: NaraTextStyles.label.copyWith(color: statusColor),
        ),
      ],
    );
  }

  Future<void> _backupData(BuildContext context, AppProvider provider) async {
    await provider.saveAllData();
    if (context.mounted) {
      showAppSnackBar(
        context,
        backgroundColor: NaraColors.surfaceWhite,
        content: Text(
          I18n.t(context, 'backup_success'),
          style: NaraTextStyles.body.copyWith(color: NaraColors.textPrimary),
        ),
      );
    }
  }

  Future<void> _confirmClearData(BuildContext context, AppProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(I18n.t(context, 'clear_all_title'), style: NaraTextStyles.h3.copyWith(color: NaraColors.danger)),
        content: Text(
          I18n.t(context, 'clear_data_warning'),
          style: NaraTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(I18n.t(context, 'cancel'), style: NaraTextStyles.label),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(I18n.t(context, 'delete'), style: NaraTextStyles.label),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.clearAllData();
      if (context.mounted) {
        showAppSnackBar(
          context,
          backgroundColor: NaraColors.surfaceWhite,
          content: Text(
            I18n.t(context, 'clear_success'),
            style: NaraTextStyles.body.copyWith(color: NaraColors.textPrimary),
          ),
        );
      }
    }
  }

  Future<void> _resetActivityFeed(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hiddenActivityIdsKey);
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      backgroundColor: NaraColors.surfaceWhite,
      content: Text(
        'Feed histori aktivitas berhasil direset.',
        style: NaraTextStyles.body.copyWith(color: NaraColors.textPrimary),
      ),
    );
  }

  Future<void> _showEditProfileDialog(BuildContext context, AppProvider provider) async {
    final controller = TextEditingController(text: provider.userName);
    String tempImagePath = provider.profileImagePath;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) => TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.96, end: 1.0),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            final safeOpacity = ((value - 0.96) / 0.04).clamp(0.0, 1.0);
            return Opacity(
              opacity: safeOpacity,
              child: Transform.scale(scale: value, child: child),
            );
          },
          child: AlertDialog(
            backgroundColor: NaraColors.surfaceCard,
            title: Text(I18n.t(context, 'edit_profile'), style: NaraTextStyles.h3),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                    if (picked == null) return;
                    setLocalState(() => tempImagePath = picked.path);
                  },
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: NaraColors.primaryLight,
                    backgroundImage: tempImagePath.isNotEmpty ? FileImage(File(tempImagePath)) : null,
                    child: tempImagePath.isEmpty
                        ? Text(
                            (provider.userName.trim().isEmpty ? 'P' : provider.userName.trim().substring(0, 1)).toUpperCase(),
                            style: NaraTextStyles.h2.copyWith(color: NaraColors.primary),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: NaraSpacing.sm),
                Text(I18n.t(context, 'tap_change_photo'), style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary)),
                const SizedBox(height: NaraSpacing.md),
                TextField(
                  controller: controller,
                  style: NaraTextStyles.body,
                  decoration: InputDecoration(
                    hintText: I18n.t(context, 'save_name'),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(I18n.t(context, 'cancel'), style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newName = controller.text.trim();
                  if (newName.isNotEmpty) {
                    await provider.setUserName(newName);
                  }
                  await provider.setProfileImagePath(tempImagePath);
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                },
                child: Text(I18n.t(context, 'save'), style: NaraTextStyles.label),
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NaraColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(I18n.t(context, 'settings'), style: NaraTextStyles.h2),
            const SizedBox(height: 2),
            Text(
              I18n.t(context, 'settings_subtitle'),
              style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(NaraSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile section
            Consumer<AppProvider>(
              builder: (context, provider, _) {
                final userName = provider.userName.trim().isEmpty ? I18n.t(context, 'guest_user') : provider.userName.trim();
                return InkWell(
                  onTap: () => _showEditProfileDialog(context, provider),
                  borderRadius: BorderRadius.circular(NaraRadius.lg),
                  child: NaraCard(
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: NaraColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: provider.profileImagePath.isNotEmpty
                                ? Image.file(
                                    File(provider.profileImagePath),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  )
                                : Center(
                                    child: Text(
                                      userName.substring(0, 1).toUpperCase(),
                                      style: NaraTextStyles.h2.copyWith(color: NaraColors.primary),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: NaraSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userName, style: NaraTextStyles.h3),
                              Text(
                                I18n.t(context, 'tap_edit_name_photo'),
                                style: NaraTextStyles.body.copyWith(color: NaraColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit_rounded, color: NaraColors.textSecondary),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: NaraSpacing.xl),

            // Settings list
            Text(I18n.t(context, 'preferences'), style: NaraTextStyles.h3),
            const SizedBox(height: NaraSpacing.lg),
            
            Consumer<AppProvider>(
              builder: (context, provider, _) => Column(
                children: [
                  _SettingsItem(
                    icon: Icons.dark_mode_rounded,
                    title: I18n.t(context, 'dark_mode'),
                    subtitle: provider.isDarkMode ? I18n.t(context, 'active_label') : I18n.t(context, 'inactive_label'),
                    trailing: Switch(
                      value: provider.isDarkMode,
                      onChanged: (value) => provider.setDarkMode(value),
                      activeThumbColor: NaraColors.primary,
                    ),
                  ),
                  const SizedBox(height: NaraSpacing.md),
                  _SettingsItem(
                    icon: Icons.notifications_rounded,
                    title: I18n.t(context, 'notif'),
                    subtitle: provider.notificationsEnabled ? I18n.t(context, 'active_label') : I18n.t(context, 'inactive_label'),
                    trailing: Switch(
                      value: provider.notificationsEnabled,
                      onChanged: (value) => provider.setNotificationsEnabled(value),
                      activeThumbColor: NaraColors.primary,
                    ),
                  ),
                  const SizedBox(height: NaraSpacing.md),
                  _SettingsItem(
                    icon: Icons.alarm_rounded,
                    title: I18n.t(context, 'notif_reminder_type'),
                    subtitle: provider.reminderNotificationsEnabled ? I18n.t(context, 'active_label') : I18n.t(context, 'inactive_label'),
                    trailing: Switch(
                      value: provider.reminderNotificationsEnabled,
                      onChanged: provider.notificationsEnabled
                          ? (value) => provider.setReminderNotificationsEnabled(value)
                          : null,
                      activeThumbColor: NaraColors.primary,
                    ),
                  ),
                  const SizedBox(height: NaraSpacing.md),
                  _SettingsItem(
                    icon: Icons.handshake_rounded,
                    title: I18n.t(context, 'notif_debt_type'),
                    subtitle: provider.debtNotificationsEnabled ? I18n.t(context, 'active_label') : I18n.t(context, 'inactive_label'),
                    trailing: Switch(
                      value: provider.debtNotificationsEnabled,
                      onChanged: provider.notificationsEnabled
                          ? (value) => provider.setDebtNotificationsEnabled(value)
                          : null,
                      activeThumbColor: NaraColors.primary,
                    ),
                  ),
                  const SizedBox(height: NaraSpacing.md),
                  _SettingsItem(
                    icon: Icons.swap_horiz_rounded,
                    title: I18n.t(context, 'notif_transaction_type'),
                    subtitle: provider.transactionNotificationsEnabled ? I18n.t(context, 'active_label') : I18n.t(context, 'inactive_label'),
                    trailing: Switch(
                      value: provider.transactionNotificationsEnabled,
                      onChanged: provider.notificationsEnabled
                          ? (value) => provider.setTransactionNotificationsEnabled(value)
                          : null,
                      activeThumbColor: NaraColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingsItem(
                    icon: Icons.language_rounded,
                    title: I18n.t(context, 'language'),
                    subtitle: provider.language,
                    onTap: () => _showLanguageDialog(context, provider),
                  ),
                  const SizedBox(height: 12),
                  _SettingsItem(
                    icon: Icons.mic_rounded,
                    title: I18n.t(context, 'voice_settings'),
                    subtitle: '${I18n.t(context, 'speed')} ${provider.voiceSpeed.toStringAsFixed(1)}x',
                    onTap: () => _showVoiceDialog(context, provider),
                  ),
                  const SizedBox(height: 12),
                  _SettingsItem(
                    icon: Icons.record_voice_over_rounded,
                    title: I18n.t(context, 'voice_beta'),
                    subtitle: provider.voiceBetaEnabled
                        ? I18n.t(context, 'active_label')
                        : I18n.t(context, 'inactive_label'),
                    trailing: Switch(
                      value: provider.voiceBetaEnabled,
                      onChanged: (value) => provider.setVoiceBetaEnabled(value),
                      activeThumbColor: NaraColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingsItem(
                    icon: Icons.rule_rounded,
                    title: I18n.t(context, 'voice_confirm'),
                    subtitle: I18n.t(context, 'voice_confirm_subtitle'),
                    trailing: Switch(
                      value: provider.voiceConfirmEnabled,
                      onChanged: provider.voiceBetaEnabled
                          ? (value) => provider.setVoiceConfirmEnabled(value)
                          : null,
                      activeThumbColor: NaraColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingsItem(
                    icon: Icons.health_and_safety_rounded,
                    title: Localizations.localeOf(context).languageCode == 'en'
                        ? 'Reminder Health Check'
                        : 'Cek Kesehatan Reminder',
                    subtitle: Localizations.localeOf(context).languageCode == 'en'
                        ? 'Permissions and schedule readiness'
                        : 'Izin dan kesiapan jadwal',
                    onTap: () => _showReminderHealthDialog(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: NaraSpacing.xl),

            Text(I18n.t(context, 'data_privacy'), style: NaraTextStyles.h3),
            const SizedBox(height: NaraSpacing.lg),
            
            Consumer<AppProvider>(
              builder: (context, provider, _) => _SettingsItem(
                icon: Icons.backup_rounded,
                title: I18n.t(context, 'backup_data'),
                subtitle: I18n.t(context, 'backup_local'),
                onTap: () => _backupData(context, provider),
              ),
            ),
            const SizedBox(height: 12),
            _SettingsItem(
              icon: Icons.history_toggle_off_rounded,
              title: 'Reset Feed Histori',
              subtitle: 'Tampilkan kembali aktivitas yang disembunyikan',
              onTap: () => _resetActivityFeed(context),
            ),
            const SizedBox(height: 12),
            Consumer<AppProvider>(
              builder: (context, provider, _) => _SettingsItem(
                icon: Icons.delete_outline_rounded,
                title: I18n.t(context, 'delete_data'),
                subtitle: I18n.t(context, 'delete_all_local'),
                onTap: () => _confirmClearData(context, provider),
                isDanger: true,
              ),
            ),

            const SizedBox(height: NaraSpacing.xl),

            Text(I18n.t(context, 'about'), style: NaraTextStyles.h3),
            const SizedBox(height: NaraSpacing.lg),
            
            _SettingsItem(
              icon: Icons.info_outline_rounded,
              title: I18n.t(context, 'about_nara'),
              subtitle: I18n.t(context, 'version_1_0_0'),
              onTap: () => _showInfoDialog(
                context,
                I18n.t(context, 'about_nara'),
                I18n.t(context, 'about_nara_message'),
              ),
            ),
            const SizedBox(height: 12),
            _SettingsItem(
              icon: Icons.help_outline_rounded,
              title: I18n.t(context, 'help'),
              subtitle: I18n.t(context, 'help_subtitle'),
              onTap: () => _showInfoDialog(
                context,
                I18n.t(context, 'help'),
                I18n.t(context, 'help_message'),
              ),
            ),
            const SizedBox(height: 12),
            _SettingsItem(
              icon: Icons.privacy_tip_outlined,
              title: I18n.t(context, 'privacy'),
              subtitle: I18n.t(context, 'privacy_subtitle'),
              onTap: () => _showInfoDialog(
                context,
                I18n.t(context, 'privacy'),
                I18n.t(context, 'privacy_message'),
              ),
            ),

            const SizedBox(height: NaraSpacing.xxl),

            // Sign out button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: NaraColors.danger,
                  side: BorderSide(color: NaraColors.danger.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(NaraRadius.md),
                  ),
                ),
                child: Text(I18n.t(context, 'logout'), style: NaraTextStyles.label.copyWith(color: NaraColors.danger)),
              ),
            ),

            const SizedBox(height: NaraSpacing.xxxl),

            Center(
              child: Text(
                I18n.t(context, 'made_with_love'),
                style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDanger;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return NaraCard(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NaraRadius.lg),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDanger 
                  ? NaraColors.danger.withValues(alpha: 0.15)
                  : NaraColors.primaryLight,
                borderRadius: BorderRadius.circular(NaraRadius.sm),
              ),
              child: Icon(
                icon,
                color: isDanger ? NaraColors.danger : NaraColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: NaraSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: NaraTextStyles.label.copyWith(
                      color: isDanger ? NaraColors.danger : NaraColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: NaraTextStyles.bodySmall.copyWith(
                      color: NaraColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right_rounded, color: NaraColors.textSecondary),
          ],
        ),
      ),
    );
  }
}




