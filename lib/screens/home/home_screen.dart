import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/formatters.dart';
import '../../core/i18n.dart';
import '../../core/snackbar_utils.dart';
import '../../core/theme/nara_colors.dart';
import '../../core/theme/nara_radius.dart';
import '../../core/theme/nara_spacing.dart';
import '../../core/theme/nara_text_styles.dart';
import '../../components/index.dart';
import '../../providers/app_provider.dart';
import '../reminder/reminder_list_screen.dart';
import '../reminder/reminder_alert_screen.dart';
import '../voice_overlay/voice_overlay.dart';
import '../transaction/transaction_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeShell();
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> with WidgetsBindingObserver {
  double? _dragStartX;
  double _dragDx = 0;
  bool _isEdgeSwipe = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<AppProvider>().setAppInForeground(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isForeground = state == AppLifecycleState.resumed;
    context.read<AppProvider>().setAppInForeground(isForeground);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final safeIndex = provider.selectedNavIndex.clamp(0, 3);
        return Scaffold(
          backgroundColor: NaraColors.background,
          bottomNavigationBar: const SafeArea(
            minimum: EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _BottomNavBar(),
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (details) {
              final width = MediaQuery.of(context).size.width;
              _dragStartX = details.globalPosition.dx;
              _dragDx = 0;
              _isEdgeSwipe = _dragStartX! <= 24 || _dragStartX! >= (width - 24);
            },
            onHorizontalDragUpdate: (details) {
              if (!_isEdgeSwipe) return;
              _dragDx += details.delta.dx;
            },
            onHorizontalDragEnd: (_) {
              if (!_isEdgeSwipe) return;
              const swipeThreshold = 42.0;
              if (_dragDx.abs() < swipeThreshold) {
                _dragDx = 0;
                _isEdgeSwipe = false;
                _dragStartX = null;
                return;
              }

              final current = provider.selectedNavIndex.clamp(0, 3);
              // Swipe left => next menu, swipe right => previous menu.
              final next = _dragDx < 0
                  ? (current + 1).clamp(0, 3)
                  : (current - 1).clamp(0, 3);
              if (next != current) {
                provider.setNavIndex(next);
              }

              _dragDx = 0;
              _isEdgeSwipe = false;
              _dragStartX = null;
            },
            child: Stack(
              children: [
                IndexedStack(
                  index: safeIndex,
                  children: [
                    const _HomeContent(),
                    const TransactionScreen(),
                    const ReminderListScreen(),
                    const _ProfileContent(),
                  ],
                ),
                const _ReminderAlertLauncher(),
                const _VoiceActionLauncher(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String _greetingKey() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'good_morning';
    if (hour < 15) return 'good_afternoon';
    if (hour < 19) return 'good_evening';
    return 'good_night';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              toolbarHeight: 92,
              floating: true,
              pinned: true,
              backgroundColor: NaraColors.background,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    color: NaraColors.background,
                  ),
                ),
              ),
              title: Consumer<AppProvider>(
                builder: (context, provider, _) {
                  final userName = provider.userName.trim().isEmpty ? I18n.t(context, 'guest_user') : provider.userName.trim();
                  final initials = userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'U';

                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: NaraColors.primaryLight,
                            shape: BoxShape.circle,
                            border: Border.all(color: NaraColors.primary, width: 1.5),
                          ),
                          child: ClipOval(
                            child: provider.profileImagePath.isNotEmpty
                                ? Image.file(
                                    File(provider.profileImagePath),
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  )
                                : Center(
                                    child: Text(
                                      initials,
                                      style: NaraTextStyles.h3.copyWith(color: NaraColors.primary),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(I18n.t(context, _greetingKey()), style: NaraTextStyles.h3),
                            Text(
                              I18n.t(context, 'hello_user', params: {'name': userName}),
                              style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, right: 8),
                  child: NotificationBellButton(
                    iconColor: NaraColors.textPrimary,
                    tooltip: I18n.t(context, 'notifications'),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),
                    NaraReveal(
                      delay: Duration(milliseconds: 40),
                      child: _VoiceActivationCard(),
                    ),
                  const SizedBox(height: 20),
                    NaraReveal(
                      delay: Duration(milliseconds: 110),
                      child: _QuickStatsRow(),
                    ),
                  const SizedBox(height: 20),
                    NaraReveal(
                      delay: Duration(milliseconds: 180),
                      child: _QuickActionsGrid(),
                    ),
                  const SizedBox(height: 20),
                    NaraReveal(
                      delay: Duration(milliseconds: 250),
                      child: _RecentActivityList(),
                    ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
        const VoiceOverlay(),
      ],
    );
  }
}

class _ReminderAlertLauncher extends StatefulWidget {
  const _ReminderAlertLauncher();

  @override
  State<_ReminderAlertLauncher> createState() => _ReminderAlertLauncherState();
}

class _ReminderAlertLauncherState extends State<_ReminderAlertLauncher> {
  int? _lastReminderIndex;
  bool _isShowing = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final activeAlert = provider.activeAlert;
        final reminderIndex = activeAlert?['index'] as int?;
        if (!_isShowing && activeAlert != null && reminderIndex != _lastReminderIndex) {
          _lastReminderIndex = reminderIndex;
          _isShowing = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted || reminderIndex == null) {
              _isShowing = false;
              return;
            }

            final result = await Navigator.of(context).push<dynamic>(
              MaterialPageRoute(
                builder: (context) => ReminderAlertScreen(
                  reminder: activeAlert,
                  reminderIndex: reminderIndex,
                ),
              ),
            );

            if (!mounted) return;
            if (result == true) {
              provider.toggleReminderStatus(reminderIndex);
            }
            _isShowing = false;
          });
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _VoiceActivationCard extends StatefulWidget {
  @override
  State<_VoiceActivationCard> createState() => _VoiceActivationCardState();
}

class _VoiceActivationCardState extends State<_VoiceActivationCard> {
  static const String _voiceCommandHistoryKey = 'voice_command_history_v1';
  String? _selectedVoiceSample;
  String? _editableVoiceSample;
  final List<String> _recentVoiceCommands = <String>[];
  DateTime? _lastVoiceDisabledSnackAt;
  bool _isVoiceDisabledSnackVisible = false;
  late final TextEditingController _manualCommandController;
  Map<String, dynamic>? _manualCommandPreview;

  @override
  void initState() {
    super.initState();
    _manualCommandController = TextEditingController();
    _manualCommandController.addListener(_refreshManualPreview);
    _loadRecentVoiceCommands();
  }

  @override
  void dispose() {
    _manualCommandController.removeListener(_refreshManualPreview);
    _manualCommandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final isEnglish = Localizations.localeOf(context).languageCode == 'en';
        return NaraCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: provider.voiceBetaEnabled
                          ? NaraColors.primary.withValues(alpha: 0.14)
                          : NaraColors.textHint.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(NaraRadius.pill),
                      border: Border.all(
                        color: provider.voiceBetaEnabled
                            ? NaraColors.primary.withValues(alpha: 0.4)
                            : NaraColors.textHint.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      provider.voiceBetaEnabled ? 'BETA' : 'OFF',
                      style: NaraTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: provider.voiceBetaEnabled
                            ? NaraColors.primary
                            : NaraColors.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: NaraColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: NaraColors.success.withValues(alpha: 0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    label: I18n.t(context, 'voice_ready_semantics'),
                    child: Text(
                      provider.voiceBetaEnabled
                          ? I18n.t(context, 'ready_listening')
                          : I18n.t(context, 'voice_beta_off'),
                      style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    I18n.t(context, 'voice_beta'),
                    style: NaraTextStyles.caption.copyWith(
                      color: NaraColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: provider.voiceBetaEnabled,
                    onChanged: (value) => provider.setVoiceBetaEnabled(value),
                    activeThumbColor: NaraColors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              if (provider.voiceBetaEnabled) ...[
                const SizedBox(height: 4),
                Text(
                  Localizations.localeOf(context).languageCode == 'en'
                      ? 'Confirmation: ${provider.voiceConfirmEnabled ? 'ON' : 'OFF'}'
                      : 'Konfirmasi: ${provider.voiceConfirmEnabled ? 'ON' : 'OFF'}',
                  style: NaraTextStyles.caption.copyWith(
                    color: NaraColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (!provider.voiceBetaEnabled) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                  icon: const Icon(Icons.settings_rounded, size: 16),
                  label: Text(
                    I18n.t(context, 'enable_voice_beta'),
                    style: NaraTextStyles.caption,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Semantics(
                button: true,
                enabled: true,
                label: I18n.t(context, 'voice_button_semantics'),
                child: GestureDetector(
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    if (!provider.voiceBetaEnabled) {
                      _showVoiceDisabledSnackBar(context);
                      return;
                    }
                    if (provider.isListening) {
                      await provider.stopListening();
                      return;
                    }
                    await provider.startListening(
                      greet: !provider.hasVoiceFollowUpDraft,
                    );
                  },
                  child: Tooltip(
                    message: I18n.t(context, 'tap_to_talk'),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOut,
                      scale: provider.isListening ? 1.06 : 1.0,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (provider.isListening)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 116,
                              height: 116,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: NaraColors.primary.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: NaraColors.primary.withValues(alpha: 0.45),
                                  width: 2,
                                ),
                              ),
                            ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            curve: Curves.easeOut,
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: provider.voiceBetaEnabled
                                  ? (provider.isListening ? NaraColors.primary : NaraColors.primaryLight)
                                  : NaraColors.surfaceCard,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: provider.voiceBetaEnabled
                                    ? NaraColors.primary
                                    : NaraColors.textHint,
                                width: provider.isListening ? 3 : 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (provider.voiceBetaEnabled
                                          ? NaraColors.primary
                                          : NaraColors.textHint)
                                      .withValues(alpha: provider.isListening ? 0.5 : 0.35),
                                  blurRadius: provider.isListening ? 26 : 20,
                                  spreadRadius: provider.isListening ? 5 : 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.mic_rounded,
                              size: 40,
                              color: provider.voiceBetaEnabled
                                  ? (provider.isListening ? NaraColors.textOnPrimary : NaraColors.primary)
                                  : NaraColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (provider.voiceBetaEnabled && provider.isListening) ...[
                const SizedBox(height: 10),
                Text(
                  I18n.t(context, 'listening'),
                  style: NaraTextStyles.caption.copyWith(
                    color: NaraColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (provider.voiceBetaEnabled && provider.isRestartingVoiceFollowUp) ...[
                const SizedBox(height: 6),
                Text(
                  isEnglish ? 'Continuing your answer...' : 'Melanjutkan jawaban kamu...',
                  style: NaraTextStyles.caption.copyWith(
                    color: NaraColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (!provider.voiceBetaEnabled) ...[
                const SizedBox(height: 16),
                Text(
                  I18n.t(context, 'voice_beta_tools_hint'),
                  textAlign: TextAlign.center,
                  style: NaraTextStyles.caption.copyWith(
                    color: NaraColors.textSecondary,
                  ),
                ),
              ],
              if (provider.voiceBetaEnabled) ...[
              const SizedBox(height: 20),
              VoiceWaveform(isAnimating: provider.isListening),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'en'
                            ? I18n.t(context, 'example_voice_commands')
                            : I18n.t(context, 'example_voice_commands'),
                        style: NaraTextStyles.caption.copyWith(
                          color: NaraColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        if (!provider.voiceBetaEnabled) {
                          _showVoiceDisabledSnackBar(context);
                          return;
                        }
                        final samples = _voiceExamples(context);
                        if (samples.isEmpty) return;
                        final randomExample = samples[Random().nextInt(samples.length)];
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedVoiceSample = randomExample;
                          _editableVoiceSample = randomExample;
                          _addRecentVoiceCommand(randomExample);
                        });
                        await _saveRecentVoiceCommands();
                        await provider.simulateVoiceCommand(randomExample);
                      },
                      icon: const Icon(Icons.shuffle_rounded, size: 16),
                      label: Text(
                        Localizations.localeOf(context).languageCode == 'en'
                            ? 'Try Random'
                            : 'Coba Acak',
                        style: NaraTextStyles.caption,
                      ),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _voiceExamples(context).map((example) {
                  return GestureDetector(
                    onTap: () async {
                      if (!provider.voiceBetaEnabled) {
                        _showVoiceDisabledSnackBar(context);
                        return;
                      }
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedVoiceSample = example;
                        _editableVoiceSample = example;
                        _addRecentVoiceCommand(example);
                      });
                      await _saveRecentVoiceCommands();
                      await provider.simulateVoiceCommand(example);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: NaraColors.surfaceCard,
                        borderRadius: BorderRadius.circular(NaraRadius.pill),
                        border: Border.all(
                          color: NaraColors.textHint.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        example,
                        style: NaraTextStyles.caption.copyWith(
                          color: NaraColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _manualCommandController,
                minLines: 1,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) async {
                  if (!provider.voiceBetaEnabled) {
                    _showVoiceDisabledSnackBar(context);
                    return;
                  }
                  final command = _manualCommandController.text.trim();
                  if (command.isEmpty) return;
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedVoiceSample = command;
                    _editableVoiceSample = command;
                    _addRecentVoiceCommand(command);
                  });
                  await _saveRecentVoiceCommands();
                  await provider.simulateVoiceCommand(command);
                },
                decoration: InputDecoration(
                  hintText: isEnglish
                      ? 'Type command here, e.g. add expense coffee 25k'
                      : 'Ketik perintah, contoh: catat pengeluaran kopi 25 ribu',
                  isDense: true,
                  filled: true,
                  fillColor: NaraColors.surfaceCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(NaraRadius.md),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_manualCommandController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _manualPreviewText(context, _manualCommandPreview),
                    style: NaraTextStyles.caption.copyWith(
                      color: _manualCommandPreview == null
                          ? NaraColors.danger
                          : NaraColors.success,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: !provider.voiceBetaEnabled || _selectedVoiceSample == null
                          ? null
                          : () {
                        HapticFeedback.selectionClick();
                        _manualCommandController.text = _selectedVoiceSample!;
                        _refreshManualPreview();
                      },
                      icon: const Icon(Icons.content_copy_rounded, size: 16),
                      label: Text(
                        I18n.t(context, 'use_selected'),
                        style: NaraTextStyles.caption,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        if (!provider.voiceBetaEnabled) {
                          _showVoiceDisabledSnackBar(context);
                          return;
                        }
                        final command = _manualCommandController.text.trim();
                        if (command.isEmpty) return;
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedVoiceSample = command;
                          _editableVoiceSample = command;
                          _addRecentVoiceCommand(command);
                        });
                        await _saveRecentVoiceCommands();
                        await provider.simulateVoiceCommand(command);
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                      label: Text(
                        I18n.t(context, 'run_typed_command'),
                        style: NaraTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedVoiceSample != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    I18n.t(
                      context,
                      'selected_command',
                      params: {'command': _selectedVoiceSample ?? ''},
                    ),
                    style: NaraTextStyles.caption.copyWith(
                      color: NaraColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          if (!provider.voiceBetaEnabled) {
                            _showVoiceDisabledSnackBar(context);
                            return;
                          }
                          final sample = _editableVoiceSample ?? _selectedVoiceSample;
                          if (sample == null) return;
                          HapticFeedback.selectionClick();
                          await provider.simulateVoiceCommand(sample);
                        },
                        icon: const Icon(Icons.replay_rounded, size: 16),
                        label: Text(
                          I18n.t(context, 'run_again'),
                          style: NaraTextStyles.caption,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          if (!provider.voiceBetaEnabled) {
                            _showVoiceDisabledSnackBar(context);
                            return;
                          }
                          final current = _editableVoiceSample ?? _selectedVoiceSample;
                          if (current == null) return;
                          final edited = await _showEditVoiceCommandDialog(
                            context,
                            initialValue: current,
                            isEnglish: isEnglish,
                          );
                          if (!mounted || edited == null || edited.trim().isEmpty) return;
                          final nextValue = edited.trim();
                          setState(() {
                            _selectedVoiceSample = nextValue;
                            _editableVoiceSample = nextValue;
                            _addRecentVoiceCommand(nextValue);
                          });
                          await _saveRecentVoiceCommands();
                          HapticFeedback.selectionClick();
                          await provider.simulateVoiceCommand(nextValue);
                        },
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: Text(
                          I18n.t(context, 'edit_and_run'),
                          style: NaraTextStyles.caption,
                        ),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedVoiceSample = null;
                            _editableVoiceSample = null;
                          });
                        },
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        label: Text(
                          isEnglish ? 'Clear' : 'Bersihkan',
                          style: NaraTextStyles.caption,
                        ),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_recentVoiceCommands.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          I18n.t(context, 'recent_voice_commands'),
                          style: NaraTextStyles.caption.copyWith(
                            color: NaraColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          HapticFeedback.selectionClick();
                          final removedItems = List<String>.from(_recentVoiceCommands);
                          setState(() {
                            _recentVoiceCommands.clear();
                            _selectedVoiceSample = null;
                            _editableVoiceSample = null;
                          });
                          await _saveRecentVoiceCommands();
                          if (!context.mounted) return;
                          final isEnglish = Localizations.localeOf(context).languageCode == 'en';
                          showAppSnackBar(
                            context,
                            duration: const Duration(seconds: 3),
                            content: Text(
                              I18n.t(context, 'history_cleared'),
                            ),
                            action: SnackBarAction(
                              label: isEnglish ? 'Undo' : 'Urungkan',
                              onPressed: () async {
                                setState(() {
                                  _recentVoiceCommands
                                    ..clear()
                                    ..addAll(removedItems.take(5));
                                });
                                await _saveRecentVoiceCommands();
                              },
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_outline_rounded, size: 16),
                        label: Text(
                          I18n.t(context, 'clear_history'),
                          style: NaraTextStyles.caption,
                        ),
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    I18n.t(context, 'long_press_delete_tip'),
                    style: NaraTextStyles.caption.copyWith(
                      color: NaraColors.textHint,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _recentVoiceCommands.map((command) {
                    final isActive = command == _selectedVoiceSample;
                    return GestureDetector(
                      onLongPress: () async {
                        HapticFeedback.mediumImpact();
                        final isEnglish = Localizations.localeOf(context).languageCode == 'en';
                        final remove = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: Text(
                              I18n.t(context, 'delete_command_title'),
                              style: NaraTextStyles.h3,
                            ),
                            content: Text(
                              command,
                              style: NaraTextStyles.body,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext, false),
                                child: Text(I18n.t(dialogContext, 'cancel')),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(dialogContext, true),
                                child: Text(isEnglish ? 'Delete' : 'Hapus'),
                              ),
                            ],
                          ),
                        );
                        if (remove != true) return;
                        final removedCommand = command;
                        setState(() {
                          _recentVoiceCommands.remove(command);
                          if (_selectedVoiceSample == command) {
                            _selectedVoiceSample = null;
                            _editableVoiceSample = null;
                          }
                        });
                        await _saveRecentVoiceCommands();
                        if (!context.mounted) return;
                        showAppSnackBar(
                          context,
                          content: Text(
                            I18n.t(context, 'command_deleted'),
                          ),
                          action: SnackBarAction(
                            label: isEnglish ? 'Undo' : 'Urungkan',
                            onPressed: () async {
                              setState(() {
                                _addRecentVoiceCommand(removedCommand);
                              });
                              await _saveRecentVoiceCommands();
                            },
                          ),
                        );
                      },
                      onTap: () async {
                        if (!provider.voiceBetaEnabled) {
                          _showVoiceDisabledSnackBar(context);
                          return;
                        }
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedVoiceSample = command;
                          _editableVoiceSample = command;
                          _addRecentVoiceCommand(command);
                        });
                        await _saveRecentVoiceCommands();
                        await provider.simulateVoiceCommand(command);
                      },
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 260),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? NaraColors.primaryLight
                              : NaraColors.surfaceCard,
                          borderRadius: BorderRadius.circular(NaraRadius.pill),
                          border: Border.all(
                            color: isActive
                                ? NaraColors.primary.withValues(alpha: 0.5)
                                : NaraColors.textHint.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          command,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: NaraTextStyles.caption.copyWith(
                            color: isActive ? NaraColors.primary : NaraColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              ],
            ],
          ),
        );
      },
    );
  }

  List<String> _voiceExamples(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    if (isEnglish) {
      return const [
        'Add expense lunch 50k',
        'Add income freelance 1.5 million',
        'Remind me pay electricity at 20:30 tomorrow',
      ];
    }
    return const [
      'Catat pengeluaran makan 50 ribu',
      'Catat pemasukan freelance 1.5 juta',
      'Ingatkan bayar listrik jam 20:30 besok',
    ];
  }

  Future<String?> _showEditVoiceCommandDialog(
    BuildContext context, {
    required String initialValue,
    required bool isEnglish,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isEnglish ? 'Edit Voice Command' : 'Ubah Perintah Suara',
          style: NaraTextStyles.h3,
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: isEnglish
                ? 'Type command text...'
                : 'Ketik teks perintah...',
          ),
          minLines: 1,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(I18n.t(dialogContext, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(isEnglish ? 'Run' : 'Jalankan'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _loadRecentVoiceCommands() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_voiceCommandHistoryKey) ?? const <String>[];
    if (!mounted) return;
    setState(() {
      _recentVoiceCommands
        ..clear()
        ..addAll(items.where((item) => item.trim().isNotEmpty).take(5));
    });
  }

  Future<void> _saveRecentVoiceCommands() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _voiceCommandHistoryKey,
      _recentVoiceCommands.take(5).toList(),
    );
  }

  void _addRecentVoiceCommand(String command) {
    final normalized = command.trim();
    if (normalized.isEmpty) return;
    _recentVoiceCommands.removeWhere(
      (item) => item.toLowerCase() == normalized.toLowerCase(),
    );
    _recentVoiceCommands.insert(0, normalized);
    if (_recentVoiceCommands.length > 5) {
      _recentVoiceCommands.removeRange(5, _recentVoiceCommands.length);
    }
  }

  void _refreshManualPreview() {
    final provider = context.read<AppProvider>();
    final preview = provider.previewVoiceCommand(_manualCommandController.text);
    if (!mounted) return;
    setState(() {
      _manualCommandPreview = preview;
    });
  }

  String _manualPreviewText(BuildContext context, Map<String, dynamic>? preview) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    if (preview == null) {
      return isEnglish
          ? 'Parser preview: command not recognized yet.'
          : 'Preview parser: perintah belum dikenali.';
    }
    final type = preview['type'] as String? ?? '';
    if (type == 'expense') {
      final title = preview['title'] as String? ?? (isEnglish ? 'Expense' : 'Pengeluaran');
      final amount = (preview['amount'] as int?) ?? 0;
      final category = preview['category'] as String? ?? (isEnglish ? 'Others' : 'Lainnya');
      return isEnglish
          ? 'Detected: Expense • $title • ${formatRupiah(amount)} • $category'
          : 'Terdeteksi: Pengeluaran • $title • ${formatRupiah(amount)} • $category';
    }
    if (type == 'income') {
      final title = preview['title'] as String? ?? (isEnglish ? 'Income' : 'Pemasukan');
      final amount = (preview['amount'] as int?) ?? 0;
      final category = preview['category'] as String? ?? (isEnglish ? 'Others' : 'Lainnya');
      return isEnglish
          ? 'Detected: Income • $title • ${formatRupiah(amount)} • $category'
          : 'Terdeteksi: Pemasukan • $title • ${formatRupiah(amount)} • $category';
    }
    if (type == 'reminder') {
      final title = preview['title'] as String? ?? 'Reminder';
      final mode = preview['mode'] as String? ?? 'Notification';
      final at = preview['scheduledAt'] as DateTime?;
      final when = at == null
          ? '-'
          : '${at.day}/${at.month}/${at.year} ${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
      return isEnglish
          ? 'Detected: Reminder • $title • $mode • $when'
          : 'Terdeteksi: Reminder • $title • $mode • $when';
    }
    return isEnglish
        ? 'Parser preview: unknown action.'
        : 'Preview parser: aksi tidak dikenal.';
  }

  void _showVoiceDisabledSnackBar(BuildContext context) {
    final provider = context.read<AppProvider>();
    if (provider.voiceBetaEnabled) {
      provider.clearVoiceError();
      return;
    }
    if (_isVoiceDisabledSnackVisible) return;
    const cooldown = Duration(seconds: 8);
    const snackDuration = Duration(seconds: 3);
    final now = DateTime.now();
    final lastShownAt = _lastVoiceDisabledSnackAt;
    if (lastShownAt != null && now.difference(lastShownAt) < cooldown) {
      return;
    }
    _lastVoiceDisabledSnackAt = now;
    _isVoiceDisabledSnackVisible = true;
    showAppSnackBar(
      context,
      content: Text(
        I18n.t(context, 'voice_beta_disabled_settings'),
      ),
      duration: snackDuration,
    );
    Future.delayed(snackDuration, () {
      if (!mounted) return;
      _isVoiceDisabledSnackVisible = false;
    });
  }
}

class _QuickStatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              NaraStatCard(
                title: I18n.t(context, 'expense'),
                value: provider.todayExpense,
                isCurrency: true,
                accentColor: NaraColors.accentOrange,
              ),
              const SizedBox(width: 12),
              NaraStatCard(
                title: I18n.t(context, 'active_debt'),
                value: provider.totalActiveDebt,
                isCurrency: true,
                accentColor: NaraColors.primary,
              ),
              const SizedBox(width: 12),
              NaraStatCard(
                title: I18n.t(context, 'active_reminder'),
                value: provider.activeReminders,
                accentColor: NaraColors.success,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(I18n.t(context, 'quick_action'), style: NaraTextStyles.h3),
        const SizedBox(height: NaraSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: NaraSpacing.md,
          crossAxisSpacing: NaraSpacing.md,
          childAspectRatio: 2.2,
          children: [
            NaraReveal(
              delay: Duration(milliseconds: 40),
              child: _ActionButton(
              icon: Icons.add_circle_outline_rounded,
              label: I18n.t(context, 'expense'),
              color: NaraColors.accentOrange,
              onTap: () => Navigator.pushNamed(context, '/add-expense'),
              ),
            ),
            NaraReveal(
              delay: Duration(milliseconds: 80),
              child: _ActionButton(
              icon: Icons.arrow_downward_rounded,
              label: I18n.t(context, 'income'),
              color: NaraColors.success,
              onTap: () => Navigator.pushNamed(context, '/add-income'),
              ),
            ),
            NaraReveal(
              delay: Duration(milliseconds: 120),
              child: _ActionButton(
              icon: Icons.currency_exchange_rounded,
              label: I18n.t(context, 'debt_receivable'),
              color: NaraColors.primary,
              onTap: () => Navigator.pushNamed(context, '/add-debt'),
              ),
            ),
            NaraReveal(
              delay: Duration(milliseconds: 160),
              child: _ActionButton(
              icon: Icons.notifications_active_rounded,
              label: 'Reminder',
              color: NaraColors.accentPurple,
              onTap: () => Navigator.pushNamed(context, '/reminders'),
              ),
            ),
            NaraReveal(
              delay: Duration(milliseconds: 200),
              child: _ActionButton(
              icon: Icons.bar_chart_rounded,
              label: I18n.t(context, 'view_recap'),
              color: NaraColors.success,
              onTap: () => Navigator.pushNamed(context, '/report'),
              ),
            ),
            NaraReveal(
              delay: Duration(milliseconds: 240),
              child: _ActionButton(
              icon: Icons.settings_rounded,
              label: I18n.t(context, 'settings'),
              color: NaraColors.textSecondary,
              onTap: () => Navigator.pushNamed(context, '/settings'),
              ),
            ),
            NaraReveal(
              delay: Duration(milliseconds: 280),
              child: _ActionButton(
              icon: Icons.history_rounded,
              label: 'Histori Transaksi',
              color: NaraColors.primary,
              onTap: () => Navigator.pushNamed(context, '/history'),
              ),
            ),
            NaraReveal(
              delay: Duration(milliseconds: 320),
              child: _ActionButton(
              icon: Icons.calendar_month_rounded,
              label: 'Kalender Perencanaan',
              color: NaraColors.accentPurple,
              onTap: () => context.read<AppProvider>().setNavIndex(2),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NaraCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: NaraSpacing.lg, vertical: NaraSpacing.md),
      child: Tooltip(
        message: label,
        child: Semantics(
          button: true,
          enabled: true,
          label: label,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: NaraSpacing.sm),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: NaraTextStyles.label,
                    maxLines: 1,
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

class _RecentActivityItemData {
  final String id;
  final String type;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String time;
  final String amount;
  final Color amountColor;
  final DateTime createdAt;

  const _RecentActivityItemData({
    required this.id,
    required this.type,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.time,
    required this.amount,
    required this.amountColor,
    required this.createdAt,
  });
}

class _VoiceActionLauncher extends StatefulWidget {
  const _VoiceActionLauncher();

  @override
  State<_VoiceActionLauncher> createState() => _VoiceActionLauncherState();
}

class _VoiceActionLauncherState extends State<_VoiceActionLauncher> {
  String? _lastFingerprint;
  bool _isShowing = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final action = provider.pendingVoiceAction;
        if (action == null || _isShowing) return const SizedBox.shrink();

        final fingerprint = '${action['type']}_${action['title']}_${action['amount']}_${action['scheduledAt']}';
        if (_lastFingerprint == fingerprint) return const SizedBox.shrink();
        _lastFingerprint = fingerprint;
        _isShowing = true;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) {
            _isShowing = false;
            return;
          }

          final isEnglish = Localizations.localeOf(context).languageCode == 'en';
          var workingAction = Map<String, dynamic>.from(action);
          var preValidation = provider.validateVoiceAction(workingAction);
          if (preValidation['isValid'] != true) {
            final needsEdit = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(
                  isEnglish ? 'Incomplete voice command' : 'Perintah suara belum lengkap',
                  style: NaraTextStyles.h3,
                ),
                content: Text(
                  (preValidation['message'] as String?) ??
                      (isEnglish ? 'Please complete missing fields.' : 'Lengkapi data yang kurang.'),
                  style: NaraTextStyles.body,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(I18n.t(dialogContext, 'cancel'), style: NaraTextStyles.label),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: Text(isEnglish ? 'Edit' : 'Edit', style: NaraTextStyles.label),
                  ),
                ],
              ),
            );
            if (needsEdit == true) {
              if (!mounted) return;
              final edited = await _showEditVoiceActionDialog(this.context, workingAction, isEnglish);
              if (!context.mounted) return;
              if (edited != null) {
                workingAction = edited;
                provider.replacePendingVoiceAction(workingAction);
                preValidation = provider.validateVoiceAction(workingAction);
              }
            }
          }

          if (preValidation['isValid'] != true) {
            if (!context.mounted) return;
            _isShowing = false;
            showAppSnackBar(
              context,
              content: Text(
                (preValidation['message'] as String?) ??
                    (isEnglish ? 'Please complete missing fields.' : 'Lengkapi data yang kurang.'),
              ),
            );
            return;
          }

          bool approved = true;
          if (provider.voiceConfirmEnabled) {
            if (!context.mounted) return;
            final decision = await showDialog<String>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(
                  isEnglish ? 'Confirm voice command' : 'Konfirmasi perintah suara',
                  style: NaraTextStyles.h3,
                ),
                content: Text(_voiceActionSummary(workingAction, isEnglish), style: NaraTextStyles.body),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, 'cancel'),
                    child: Text(I18n.t(dialogContext, 'cancel'), style: NaraTextStyles.label),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, 'edit'),
                    child: Text(isEnglish ? 'Edit' : 'Edit', style: NaraTextStyles.label),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, 'save'),
                    child: Text(I18n.t(dialogContext, 'save'), style: NaraTextStyles.label),
                  ),
                ],
              ),
            );

            if (decision == 'edit') {
              if (!context.mounted) return;
              final edited = await _showEditVoiceActionDialog(context, workingAction, isEnglish);
              if (!context.mounted) return;
              if (edited != null) {
                workingAction = edited;
                provider.replacePendingVoiceAction(workingAction);
                final reValidation = provider.validateVoiceAction(workingAction);
                if (reValidation['isValid'] != true) {
                  if (!context.mounted) return;
                  _isShowing = false;
                  showAppSnackBar(
                    context,
                    content: Text(
                      (reValidation['message'] as String?) ??
                          (isEnglish ? 'Please complete missing fields.' : 'Lengkapi data yang kurang.'),
                    ),
                  );
                  return;
                }
                approved = true;
              } else {
                approved = false;
              }
            } else {
              approved = decision == 'save';
            }
          }

          final saved = await provider.applyPendingVoiceAction(approved: approved);
          if (!context.mounted) return;
          _isShowing = false;
          showAppSnackBar(
            context,
            content: Text(
              approved
                  ? (saved
                      ? (isEnglish ? 'Voice command saved.' : 'Perintah suara berhasil disimpan.')
                      : (isEnglish ? 'Voice command failed to save.' : 'Perintah suara gagal disimpan.'))
                  : (isEnglish ? 'Voice command canceled.' : 'Perintah suara dibatalkan.'),
            ),
          );
        });

        return const SizedBox.shrink();
      },
    );
  }

  String _voiceActionSummary(Map<String, dynamic> action, bool isEnglish) {
    final type = action['type'] as String? ?? '';
    if (type == 'expense') {
      final amount = (action['amount'] as int?) ?? 0;
      final title = action['title'] as String? ?? (isEnglish ? 'Expense' : 'Pengeluaran');
      final category = (action['category'] as String?)?.trim();
      final hasCategory = category != null && category.isNotEmpty;
      return isEnglish
          ? (hasCategory
              ? 'Save expense "$title" amount ${formatRupiah(amount)} in category $category?'
              : 'Save expense "$title" amount ${formatRupiah(amount)}?')
          : (hasCategory
              ? 'Simpan pengeluaran "$title" sebesar ${formatRupiah(amount)} pada kategori $category?'
              : 'Simpan pengeluaran "$title" sebesar ${formatRupiah(amount)}?');
    }
    if (type == 'income') {
      final amount = (action['amount'] as int?) ?? 0;
      final title = action['title'] as String? ?? (isEnglish ? 'Income' : 'Pemasukan');
      final category = (action['category'] as String?)?.trim();
      final hasCategory = category != null && category.isNotEmpty;
      return isEnglish
          ? (hasCategory
              ? 'Save income "$title" amount ${formatRupiah(amount)} in category $category?'
              : 'Save income "$title" amount ${formatRupiah(amount)}?')
          : (hasCategory
              ? 'Simpan pemasukan "$title" sebesar ${formatRupiah(amount)} pada kategori $category?'
              : 'Simpan pemasukan "$title" sebesar ${formatRupiah(amount)}?');
    }
    if (type == 'reminder') {
      final title = action['title'] as String? ?? 'Reminder';
      final when = action['scheduledAt'] as DateTime?;
      final mode = action['mode'] as String? ?? 'Notification';
      final timeText = when == null
          ? '-'
          : '${when.day}/${when.month}/${when.year} ${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
      return isEnglish
          ? 'Create reminder "$title" at $timeText with $mode?'
          : 'Buat reminder "$title" pada $timeText dengan $mode?';
    }
    if (type == 'debt') {
      final amount = (action['amount'] as int?) ?? 0;
      final title = action['title'] as String? ?? '-';
      final debtType = action['debtType'] as String? ?? 'utang';
      final typeLabel = debtType == 'piutang'
          ? (isEnglish ? 'receivable' : 'piutang')
          : (isEnglish ? 'debt' : 'utang');
      return isEnglish
          ? 'Save $typeLabel "$title" amount ${formatRupiah(amount)}?'
          : 'Simpan $typeLabel "$title" sebesar ${formatRupiah(amount)}?';
    }
    if (type == 'debt_payment') {
      final amount = (action['amount'] as int?) ?? 0;
      final debtId = action['debtId'] as int?;
      final target = debtId == null
          ? null
          : context.read<AppProvider>().debts.cast<Map<String, dynamic>?>().firstWhere(
                (item) => (item?['debtId'] as int?) == debtId,
                orElse: () => null,
              );
      final title = (target?['title'] as String?)?.trim();
      return isEnglish
          ? 'Save partial debt payment${title == null || title.isEmpty ? '' : ' for "$title"'} amount ${formatRupiah(amount)}?'
          : 'Simpan pembayaran sebagian${title == null || title.isEmpty ? '' : ' untuk "$title"'} sebesar ${formatRupiah(amount)}?';
    }
    return isEnglish ? 'Save this voice command?' : 'Simpan perintah suara ini?';
  }

  Future<Map<String, dynamic>?> _showEditVoiceActionDialog(
    BuildContext context,
    Map<String, dynamic> action,
    bool isEnglish,
  ) async {
    final type = action['type'] as String? ?? '';
    final provider = context.read<AppProvider>();
    final titleController = TextEditingController(text: (action['title'] as String?) ?? '');
    final amountController = TextEditingController(
      text: ((action['amount'] as int?) ?? 0) > 0 ? '${action['amount']}' : '',
    );
    DateTime? reminderAt = action['scheduledAt'] as DateTime?;
    String reminderMode = (action['mode'] as String?) ?? 'Notification';
    String debtType = (action['debtType'] as String?) ?? 'utang';
    final categoryOptions = type == 'income'
        ? provider.incomeCategories.toList()
        : provider.expenseCategories.toList();
    String selectedCategory = ((action['category'] as String?) ?? '').trim();
    if (type == 'expense' || type == 'income') {
      if (selectedCategory.isEmpty) {
        selectedCategory = type == 'income' ? 'Lainnya' : 'Lainnya';
      }
      if (!categoryOptions.contains(selectedCategory)) {
        categoryOptions.add(selectedCategory);
      }
      if (categoryOptions.isEmpty) {
        categoryOptions.add('Lainnya');
      }
    }

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text(isEnglish ? 'Edit command' : 'Edit perintah', style: NaraTextStyles.h3),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (type == 'expense' || type == 'income' || type == 'debt' || type == 'reminder') ...[
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: isEnglish ? 'Title' : 'Judul',
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (type == 'expense' || type == 'income' || type == 'debt' || type == 'debt_payment') ...[
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [RupiahInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Nominal',
                      prefixText: 'Rp ',
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (type == 'expense' || type == 'income') ...[
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    items: categoryOptions
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(I18n.translateCategory(context, item)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null || value.trim().isEmpty) return;
                      setLocalState(() => selectedCategory = value);
                    },
                    decoration: InputDecoration(
                      labelText: isEnglish ? 'Category' : 'Kategori',
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (type == 'reminder') ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final now = DateTime.now();
                            final firstAllowedDate = DateTime(now.year, now.month, now.day);
                            final safeInitialDate = reminderAt != null &&
                                    !DateTime(reminderAt!.year, reminderAt!.month, reminderAt!.day)
                                        .isBefore(firstAllowedDate)
                                ? reminderAt!
                                : firstAllowedDate;
                            final pickedDate = await showDatePicker(
                              context: dialogContext,
                              initialDate: safeInitialDate,
                              firstDate: firstAllowedDate,
                              lastDate: now.add(const Duration(days: 365)),
                            );
                            if (pickedDate == null) return;
                            if (!context.mounted) return;
                            final pickedTime = await showTimePicker(
                              context: dialogContext,
                              initialTime: TimeOfDay.fromDateTime(reminderAt ?? now),
                            );
                            if (pickedTime == null) return;
                            setLocalState(() {
                              reminderAt = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          },
                          icon: const Icon(Icons.schedule_rounded, size: 16),
                          label: Text(
                            reminderAt == null
                                ? (isEnglish ? 'Set time' : 'Atur waktu')
                                : '${MaterialLocalizations.of(context).formatShortDate(reminderAt!)} '
                                    '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(reminderAt!), alwaysUse24HourFormat: true)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: reminderMode,
                    items: const [
                      DropdownMenuItem(value: 'Notification', child: Text('Notification')),
                      DropdownMenuItem(value: 'Loud Alarm', child: Text('Loud Alarm')),
                      DropdownMenuItem(value: 'Fake Call', child: Text('Fake Call')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setLocalState(() => reminderMode = value);
                    },
                    decoration: InputDecoration(
                      labelText: isEnglish ? 'Type' : 'Jenis',
                    ),
                  ),
                ],
                if (type == 'debt') ...[
                  DropdownButtonFormField<String>(
                    initialValue: debtType,
                    items: [
                      DropdownMenuItem(value: 'utang', child: Text(isEnglish ? 'Debt' : 'Utang')),
                      DropdownMenuItem(value: 'piutang', child: Text(isEnglish ? 'Receivable' : 'Piutang')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setLocalState(() => debtType = value);
                    },
                    decoration: InputDecoration(
                      labelText: isEnglish ? 'Type' : 'Jenis',
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(I18n.t(dialogContext, 'cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                final updated = Map<String, dynamic>.from(action);
                if (type == 'expense' || type == 'income' || type == 'debt' || type == 'reminder') {
                  updated['title'] = titleController.text.trim();
                }
                if (type == 'expense' || type == 'income' || type == 'debt' || type == 'debt_payment') {
                  updated['amount'] = parseRupiahInput(amountController.text);
                }
                if (type == 'expense' || type == 'income') {
                  updated['category'] = selectedCategory;
                }
                if (type == 'reminder') {
                  updated['scheduledAt'] = reminderAt;
                  updated['mode'] = reminderMode;
                }
                if (type == 'debt') {
                  updated['debtType'] = debtType;
                }
                Navigator.pop(dialogContext, updated);
              },
              child: Text(I18n.t(dialogContext, 'save')),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityList extends StatefulWidget {
  @override
  State<_RecentActivityList> createState() => _RecentActivityListState();
}

class _RecentActivityListState extends State<_RecentActivityList> {
  static const String _hiddenActivityIdsKey = 'recent_activity_hidden_ids_v1';
  bool _showAll = false;
  String _selectedType = 'all';
  Set<String> _hiddenIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadHiddenIds();
  }

  Future<void> _loadHiddenIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_hiddenActivityIdsKey) ?? <String>[];
    if (!mounted) return;
    setState(() => _hiddenIds = ids.toSet());
  }

  Future<void> _saveHiddenIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_hiddenActivityIdsKey, _hiddenIds.toList());
  }

  Future<void> _hideActivity(String id) async {
    if (_hiddenIds.contains(id)) return;
    setState(() => _hiddenIds = {..._hiddenIds, id});
    await _saveHiddenIds();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final activities = <_RecentActivityItemData>[
          ...provider.expenses.map(
            (expense) => _RecentActivityItemData(
              id: 'expense:${_coerceDate(expense['createdAt']).toIso8601String()}:${expense['title']}:${expense['amount']}',
              type: 'expense',
              icon: Icons.shopping_bag_rounded,
              iconColor: NaraColors.accentOrange,
              title: expense['title'] as String? ?? '-',
              time: _activityTimeLabel(context, expense['createdAt']),
              amount: '-${formatRupiah((expense['amount'] as num?) ?? 0)}',
              amountColor: NaraColors.danger,
              createdAt: _coerceDate(expense['createdAt']),
            ),
          ),
          ...provider.incomes.map(
            (income) => _RecentActivityItemData(
              id: 'income:${_coerceDate(income['createdAt']).toIso8601String()}:${income['title']}:${income['amount']}',
              type: 'income',
              icon: Icons.account_balance_wallet_rounded,
              iconColor: NaraColors.success,
              title: income['title'] as String? ?? '-',
              time: _activityTimeLabel(context, income['createdAt']),
              amount: '+${formatRupiah((income['amount'] as num?) ?? 0)}',
              amountColor: NaraColors.success,
              createdAt: _coerceDate(income['createdAt']),
            ),
          ),
          ...provider.debts.map(
            (debt) => _RecentActivityItemData(
              id: 'debt:${_coerceDate(debt['createdAt']).toIso8601String()}:${debt['debtId'] ?? debt['title']}:${debt['amount']}',
              type: 'debt',
              icon: Icons.currency_exchange_rounded,
              iconColor: NaraColors.primary,
              title: I18n.translateDebtTitle(context, debt['title'] as String? ?? '-'),
              time: _activityTimeLabel(context, debt['createdAt']),
              amount: formatRupiah((debt['amount'] as num?) ?? 0),
              amountColor: NaraColors.primary,
              createdAt: _coerceDate(debt['createdAt']),
            ),
          ),
        ];

        activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final visibleBase = activities.where((a) => !_hiddenIds.contains(a.id)).toList();
        final filteredActivities = _selectedType == 'all'
            ? visibleBase
            : visibleBase.where((a) => a.type == _selectedType).toList();
        final visibleActivities = _showAll ? filteredActivities : filteredActivities.take(4).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(I18n.t(context, 'recent_activity'), style: NaraTextStyles.h3),
            const SizedBox(height: NaraSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _activityFilterChip(context, 'all', I18n.t(context, 'all')),
                  const SizedBox(width: NaraSpacing.sm),
                  _activityFilterChip(context, 'expense', I18n.t(context, 'expense')),
                  const SizedBox(width: NaraSpacing.sm),
                  _activityFilterChip(context, 'income', I18n.t(context, 'income')),
                  const SizedBox(width: NaraSpacing.sm),
                  _activityFilterChip(context, 'debt', I18n.t(context, 'debt_receivable')),
                ],
              ),
            ),
            const SizedBox(height: NaraSpacing.md),
            if (filteredActivities.isEmpty)
              NaraReveal(
                delay: const Duration(milliseconds: 60),
                child: NaraEmptyState(
                  icon: Icons.inbox_rounded,
                  title: I18n.t(context, 'no_notifications'),
                  message: I18n.t(context, 'recent_activity_empty_msg'),
                  accentColor: NaraColors.primary,
                ),
              )
            else
              ...visibleActivities.asMap().entries.map(
                    (entry) => NaraReveal(
                      delay: Duration(milliseconds: 50 * entry.key),
                      child: _ActivityItem(
                        id: entry.value.id,
                        icon: entry.value.icon,
                        iconColor: entry.value.iconColor,
                        title: entry.value.title,
                        time: entry.value.time,
                        amount: entry.value.amount,
                        amountColor: entry.value.amountColor,
                        onDismissed: _hideActivity,
                        onTap: () {
                          final transactionTabIndex = switch (entry.value.type) {
                            'income' => 1,
                            'debt' => 2,
                            _ => 0,
                          };
                          provider.setTransactionTabIndex(transactionTabIndex);
                          provider.setNavIndex(1);
                          showAppSnackBar(
                            context,
                            content: Text(I18n.t(context, 'opening_transaction_menu')),
                          );
                        },
                      ),
                    ),
                  ),
            if (filteredActivities.length > 4)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _showAll = !_showAll),
                  child: Text(
                    _showAll ? I18n.t(context, 'show_less') : I18n.t(context, 'see_more'),
                    style: NaraTextStyles.label.copyWith(color: NaraColors.primary),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _activityFilterChip(BuildContext context, String value, String label) {
    return NaraChip(
      label: label,
      selected: _selectedType == value,
      onTap: () => setState(() => _selectedType = value),
    );
  }

  DateTime _coerceDate(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }

  String _activityTimeLabel(BuildContext context, dynamic rawCreatedAt) {
    final createdAt = _coerceDate(rawCreatedAt);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final dayDiff = today.difference(day).inDays;
    final dayLabel = switch (dayDiff) {
      0 => I18n.t(context, 'today'),
      1 => I18n.t(context, 'yesterday'),
      _ => MaterialLocalizations.of(context).formatShortDate(createdAt),
    };
    final timeLabel = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: createdAt.hour, minute: createdAt.minute),
      alwaysUse24HourFormat: true,
    );
    return '$dayLabel • $timeLabel';
  }
}

class _ActivityItem extends StatelessWidget {
  final String id;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String time;
  final String amount;
  final Color amountColor;
  final Future<void> Function(String id) onDismissed;
  final VoidCallback onTap;

  const _ActivityItem({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.time,
    required this.amount,
    required this.amountColor,
    required this.onDismissed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: NaraSpacing.md),
        decoration: BoxDecoration(
          color: NaraColors.danger.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(NaraRadius.md),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: NaraSpacing.lg),
        child: const Icon(Icons.hide_source_rounded, color: NaraColors.danger),
      ),
      onDismissed: (_) async {
        await onDismissed(id);
        if (!context.mounted) return;
        showAppSnackBar(
          context,
          content: Text(I18n.t(context, 'activity_hidden_from_feed')),
        );
      },
      child: NaraCard(
        onTap: onTap,
        padding: const EdgeInsets.all(NaraSpacing.md),
        margin: const EdgeInsets.only(bottom: NaraSpacing.md),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(NaraRadius.md),
                color: iconColor.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: NaraSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NaraTextStyles.label,
                  ),
                  Text(
                    time,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NaraTextStyles.bodySmall.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                amount,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: NaraTextStyles.label.copyWith(color: amountColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return NaraCard(
          borderRadius: NaraRadius.xl,
          padding: const EdgeInsets.symmetric(horizontal: NaraSpacing.sm, vertical: NaraSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home_outlined,
                  isActive: provider.selectedNavIndex == 0,
                  label: I18n.t(context, 'home'),
                  onTap: () => provider.setNavIndex(0),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.receipt_long_outlined,
                  isActive: provider.selectedNavIndex == 1,
                  label: I18n.t(context, 'transaction'),
                  onTap: () => provider.setNavIndex(1),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.calendar_month_outlined,
                  isActive: provider.selectedNavIndex == 2,
                  label: I18n.t(context, 'planning'),
                  onTap: () => provider.setNavIndex(2),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.person_outline_rounded,
                  isActive: provider.selectedNavIndex == 3,
                  label: I18n.t(context, 'profile'),
                  onTap: () => provider.setNavIndex(3),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final userName = provider.userName.trim().isEmpty ? 'Pengguna' : provider.userName.trim();
        final isEnglish = Localizations.localeOf(context).languageCode == 'en';
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(NaraSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(I18n.t(context, 'profile'), style: NaraTextStyles.h1),
                const SizedBox(height: NaraSpacing.sm),
                Text(
                  I18n.t(context, 'profile_desc'),
                  style: NaraTextStyles.body.copyWith(color: NaraColors.textSecondary),
                ),
                const SizedBox(height: NaraSpacing.xl),
                NaraCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: NaraColors.primaryLight,
                        backgroundImage: provider.profileImagePath.isNotEmpty
                            ? FileImage(File(provider.profileImagePath))
                            : null,
                        child: provider.profileImagePath.isEmpty
                            ? Text(
                                userName.substring(0, 1).toUpperCase(),
                                style: NaraTextStyles.h2.copyWith(color: NaraColors.primary),
                              )
                            : null,
                      ),
                      const SizedBox(width: NaraSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(userName, style: NaraTextStyles.h3),
                            Text(
                              provider.language,
                              style: NaraTextStyles.bodySmall.copyWith(color: NaraColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: NaraSpacing.lg),
                NaraCard(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.tune_rounded, color: NaraColors.primary),
                        title: Text(
                          isEnglish ? 'Quick Access' : 'Akses Cepat',
                          style: NaraTextStyles.label,
                        ),
                      ),
                      const Divider(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.edit_rounded, color: NaraColors.primary),
                        title: Text(I18n.t(context, 'edit_profile'), style: NaraTextStyles.body),
                        subtitle: Text(
                          isEnglish ? 'Change name and photo' : 'Ubah nama dan foto',
                          style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const _ProfileEditScreen()),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.notifications_rounded, color: NaraColors.primary),
                        title: Text(I18n.t(context, 'notifications'), style: NaraTextStyles.body),
                        subtitle: Text(
                          isEnglish ? 'View all reminders and alerts' : 'Lihat semua reminder dan peringatan',
                          style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.pushNamed(context, '/notifications'),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.settings_rounded, color: NaraColors.primary),
                        title: Text(I18n.t(context, 'settings'), style: NaraTextStyles.body),
                        subtitle: Text(
                          isEnglish ? 'Open app preferences' : 'Buka preferensi aplikasi',
                          style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.pushNamed(context, '/settings'),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.bar_chart_rounded, color: NaraColors.primary),
                        title: Text(I18n.t(context, 'financial_report'), style: NaraTextStyles.body),
                        subtitle: Text(
                          isEnglish ? 'View monthly summary' : 'Lihat ringkasan bulanan',
                          style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.pushNamed(context, '/report'),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.language_rounded, color: NaraColors.primary),
                        title: Text(I18n.t(context, 'language'), style: NaraTextStyles.body),
                        subtitle: Text(
                          isEnglish ? 'Set app language' : 'Atur bahasa aplikasi',
                          style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const _ProfileLanguageScreen()),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.backup_rounded, color: NaraColors.primary),
                        title: Text(I18n.t(context, 'backup_data'), style: NaraTextStyles.body),
                        subtitle: Text(
                          isEnglish ? 'Backup your local data' : 'Backup data lokal kamu',
                          style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const _ProfileBackupScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: NaraSpacing.lg),
                NaraCard(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_rounded, color: NaraColors.primary),
                        title: Text(
                          isEnglish ? 'Account' : 'Akun',
                          style: NaraTextStyles.label,
                        ),
                      ),
                      const Divider(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.info_outline_rounded, color: NaraColors.primary),
                        title: Text(I18n.t(context, 'about'), style: NaraTextStyles.body),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _ProfileInfoScreen(
                              title: I18n.t(context, 'about_nara'),
                              message: I18n.t(context, 'about_nara_message'),
                            ),
                          ),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.help_outline_rounded, color: NaraColors.primary),
                        title: Text(I18n.t(context, 'help'), style: NaraTextStyles.body),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _ProfileInfoScreen(
                              title: I18n.t(context, 'help'),
                              message: I18n.t(context, 'help_message'),
                            ),
                          ),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.privacy_tip_outlined, color: NaraColors.primary),
                        title: Text(I18n.t(context, 'privacy'), style: NaraTextStyles.body),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _ProfileInfoScreen(
                              title: I18n.t(context, 'privacy'),
                              message: I18n.t(context, 'privacy_message'),
                            ),
                          ),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.logout_rounded, color: NaraColors.danger),
                        title: Text(
                          I18n.t(context, 'logout'),
                          style: NaraTextStyles.body.copyWith(color: NaraColors.danger),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileEditScreen extends StatefulWidget {
  const _ProfileEditScreen();

  @override
  State<_ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<_ProfileEditScreen> {
  late TextEditingController _nameController;
  String _imagePath = '';

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _nameController = TextEditingController(text: provider.userName);
    _imagePath = provider.profileImagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _imagePath = picked.path);
  }

  Future<void> _save() async {
    final provider = context.read<AppProvider>();
    await provider.setUserName(_nameController.text.trim());
    await provider.setProfileImagePath(_imagePath);
    if (!mounted) return;
    showAppSnackBar(
      context,
      content: Text(Localizations.localeOf(context).languageCode == 'en' ? 'Profile updated' : 'Profil berhasil diperbarui'),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final initial = _nameController.text.trim().isEmpty ? 'P' : _nameController.text.trim().substring(0, 1).toUpperCase();
    return _ProfilePageScaffold(
      title: I18n.t(context, 'edit_profile'),
      subtitle: isEnglish ? 'Update your identity and photo' : 'Perbarui identitas dan foto profil',
      icon: Icons.person_rounded,
      iconColor: NaraColors.primary,
      child: NaraCard(
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 44,
                backgroundColor: NaraColors.primaryLight,
                backgroundImage: _imagePath.isNotEmpty ? FileImage(File(_imagePath)) : null,
                child: _imagePath.isEmpty ? Text(initial, style: NaraTextStyles.h1.copyWith(color: NaraColors.primary)) : null,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isEnglish ? 'Tap image to change photo' : 'Tap gambar untuk ganti foto',
              style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
            ),
            const SizedBox(height: NaraSpacing.lg),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: isEnglish ? 'Display Name' : 'Nama Tampilan',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(NaraRadius.md)),
              ),
            ),
            const SizedBox(height: NaraSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(I18n.t(context, 'save')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileLanguageScreen extends StatelessWidget {
  const _ProfileLanguageScreen();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    return _ProfilePageScaffold(
      title: I18n.t(context, 'language'),
      subtitle: isEnglish ? 'Choose app language' : 'Pilih bahasa aplikasi',
      icon: Icons.language_rounded,
      iconColor: NaraColors.success,
      child: NaraCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                provider.language == 'Indonesia'
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: NaraColors.primary,
              ),
              title: const Text('Indonesia'),
              onTap: () => provider.setLanguage('Indonesia'),
            ),
            ListTile(
              leading: Icon(
                provider.language == 'English'
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: NaraColors.primary,
              ),
              title: const Text('English'),
              onTap: () => provider.setLanguage('English'),
            ),
            const SizedBox(height: 8),
            Text(
              isEnglish ? 'Language changes immediately.' : 'Perubahan bahasa diterapkan langsung.',
              style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBackupScreen extends StatelessWidget {
  const _ProfileBackupScreen();

  Future<void> _backup(BuildContext context) async {
    await context.read<AppProvider>().saveAllData();
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      content: Text(I18n.t(context, 'backup_success')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    return _ProfilePageScaffold(
      title: I18n.t(context, 'backup_data'),
      subtitle: isEnglish ? 'Protect your local data' : 'Lindungi data lokal kamu',
      icon: Icons.backup_rounded,
      iconColor: NaraColors.warning,
      child: NaraCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEnglish
                  ? 'Save your latest transactions, reminders, and settings to local storage.'
                  : 'Simpan transaksi, reminder, dan pengaturan terbaru ke penyimpanan lokal.',
              style: NaraTextStyles.body.copyWith(color: NaraColors.textSecondary),
            ),
            const SizedBox(height: NaraSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _backup(context),
                child: Text(I18n.t(context, 'backup_data')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoScreen extends StatelessWidget {
  final String title;
  final String message;

  const _ProfileInfoScreen({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    return _ProfilePageScaffold(
      title: title,
      subtitle: isEnglish ? 'Information' : 'Informasi',
      icon: Icons.info_outline_rounded,
      iconColor: NaraColors.primary,
      child: NaraCard(
        child: Text(
          message,
          style: NaraTextStyles.body.copyWith(color: NaraColors.textSecondary, height: 1.4),
        ),
      ),
    );
  }
}

class _ProfilePageScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _ProfilePageScaffold({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NaraColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(NaraSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(NaraRadius.md),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: NaraSpacing.sm),
            Text(
              subtitle,
              style: NaraTextStyles.body.copyWith(color: NaraColors.textSecondary),
            ),
            const SizedBox(height: NaraSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final bool isActive;
  final String label;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.label,
    this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }

    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isActive ? NaraColors.primaryLight : Colors.transparent,
                borderRadius: BorderRadius.circular(NaraRadius.pill),
              ),
              child: Icon(
                widget.icon,
                color: isActive ? NaraColors.primary : NaraColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(height: NaraSpacing.xs),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              style: NaraTextStyles.caption.copyWith(
                color: isActive ? NaraColors.primary : NaraColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



