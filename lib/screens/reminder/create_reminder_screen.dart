import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/index.dart';
import '../../core/i18n.dart';
import '../../core/snackbar_utils.dart';
import '../../core/theme/nara_colors.dart';
import '../../core/theme/nara_radius.dart';
import '../../core/theme/nara_spacing.dart';
import '../../core/theme/nara_text_styles.dart';
import 'package:nara/providers/app_provider.dart';
import 'package:nara/services/notification_service.dart';

class CreateReminderScreen extends StatefulWidget {
  final int? editIndex;

  const CreateReminderScreen({super.key, this.editIndex});

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _selectedType;
  late bool _isRoutineEnabled;
  late bool _isLinkedToNote;
  late Set<int> _selectedWeekDays;
  bool _useDefaultSound = true;
  String? _selectedSoundUri;
  String? _selectedSoundName;
  bool _didInitLocalizedDefaults = false;
  ReminderHealthStatus? _reminderHealthStatus;
  bool _isLoadingReminderHealth = false;

  final List<Map<String, dynamic>> _types = [
    {
      'mode': 'Notification',
      'nameKey': 'reminder_mode_notification',
      'icon': Icons.notifications_rounded,
      'color': NaraColors.primary,
    },
    {
      'mode': 'Loud Alarm',
      'nameKey': 'reminder_mode_loud_alarm',
      'icon': Icons.volume_up_rounded,
      'color': NaraColors.warning,
    },
    {
      'mode': 'Fake Call',
      'nameKey': 'reminder_mode_fake_call',
      'icon': Icons.call_rounded,
      'color': NaraColors.danger,
    },
  ];

  final List<int> _weekDayIndexes = const [0, 1, 2, 3, 4, 5, 6];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    // Keep default date/time anchored to "today" to avoid jumping to tomorrow.
    _selectedDate = DateTime(
      now.year,
      now.month,
      now.day,
    );
    _selectedTime = TimeOfDay(
      hour: now.hour,
      minute: now.minute,
    );
    _selectedType = 'Notification';
    _isRoutineEnabled = false;
    _isLinkedToNote = false;
    _selectedWeekDays = {1, 2, 3, 4, 5};
    _useDefaultSound = false;

    if (widget.editIndex != null) {
      final provider = context.read<AppProvider>();
      final reminder = provider.reminders[widget.editIndex!];

      _titleController.text = reminder['title'] as String? ?? '';
      _noteController.text = reminder['note'] as String? ?? '';
      _selectedType = _normalizeReminderType(
        (reminder['mode'] as String?) ??
            (reminder['type'] as String?) ??
            'Notification',
      );
      _selectedSoundUri = reminder['soundUri'] as String?;
      _selectedSoundName = reminder['soundName'] as String?;
      _useDefaultSound =
          _selectedSoundUri == null || _selectedSoundUri!.isEmpty;
      _isLinkedToNote = reminder['linkedToNote'] as bool? ?? true;
      _isRoutineEnabled = reminder['repeatEnabled'] as bool? ?? false;

      final scheduledAt = DateTime.tryParse(
        reminder['scheduledAt'] as String? ?? '',
      );
      if (scheduledAt != null) {
        _selectedDate = DateTime(
          scheduledAt.year,
          scheduledAt.month,
          scheduledAt.day,
        );
        _selectedTime = TimeOfDay(
          hour: scheduledAt.hour,
          minute: scheduledAt.minute,
        );
      }

      if (reminder['repeatDays'] is List) {
        _selectedWeekDays = Set<int>.from(reminder['repeatDays'] as List);
      }
    }
    _refreshReminderHealthIfNeeded();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );

    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (pickedTime != null) {
      setState(() => _selectedTime = pickedTime);
    }
  }

  Future<void> _pickCustomSound() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'wav', 'ogg', 'm4a'],
    );
    if (!mounted || result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    if (picked.path == null || picked.path!.isEmpty) return;

    setState(() {
      _selectedSoundUri = Uri.file(picked.path!).toString();
      _selectedSoundName = picked.name;
      _useDefaultSound = false;
    });
  }

  String _formatDate(BuildContext context, DateTime dateTime) {
    return MaterialLocalizations.of(context).formatMediumDate(dateTime);
  }

  String _formatTime(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _saveReminder() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      showAppSnackBar(
        context,
        backgroundColor: NaraColors.surfaceWhite,
        content: Text(
          I18n.t(context, 'reminder_title'),
          style: NaraTextStyles.body.copyWith(color: NaraColors.textPrimary),
        ),
      );
      return;
    }

    var effectiveType = _selectedType;
    final isPopupMode =
        effectiveType == 'Loud Alarm' || effectiveType == 'Fake Call';
    if (isPopupMode) {
      final status = await NotificationService().getReminderHealthStatus();
      final hasNotif = status.notificationsEnabled;
      final hasExact = status.exactAlarmAllowed;
      final hasFullScreen = status.fullScreenIntentGranted != false;
      if (!hasNotif || !hasExact || !hasFullScreen) {
        if (!mounted) return;
        final action = await _showPopupPermissionDialog(
          hasNotif: hasNotif,
          hasExact: hasExact,
          hasFullScreen: hasFullScreen,
        );
        if (!mounted) return;
        if (action == 'open_notification') {
          await NotificationService().openReminderSystemSettings('notification');
          return;
        }
        if (action == 'open_exact') {
          await NotificationService().openReminderSystemSettings('exact_alarm');
          return;
        }
        if (action == 'open_fullscreen') {
          await NotificationService().openReminderSystemSettings('fullscreen');
          return;
        }
        if (action == 'fallback_notification') {
          effectiveType = 'Notification';
          setState(() => _selectedType = 'Notification');
        } else {
          return;
        }
      }
    }

    if (!mounted) return;
    final provider = context.read<AppProvider>();
    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final reminderData = {
      'title': title,
      'type': _labelForType(context, effectiveType),
      'note': _isLinkedToNote ? _noteController.text.trim() : '',
      'date':
          '${_formatDate(context, _selectedDate)} • ${_formatTime(_selectedTime)}',
      'scheduledAt': scheduledAt.toIso8601String(),
      'subtitle':
          '${_formatDate(context, _selectedDate)} • ${_formatTime(_selectedTime)}',
      'mode': effectiveType,
      'repeatEnabled': _isRoutineEnabled,
      'repeatDays': _selectedWeekDays.toList()..sort(),
      'linkedToNote': _isLinkedToNote,
      'icon': _iconForType(effectiveType),
      'soundUri': _useDefaultSound ? null : _selectedSoundUri,
      'soundName': _useDefaultSound ? null : _selectedSoundName,
      'status': 'menunggu',
    };

    if (widget.editIndex != null) {
      provider.updateReminder(widget.editIndex!, reminderData);
    } else {
      provider.addReminder(reminderData);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _refreshReminderHealthIfNeeded() async {
    final isPopupMode = _selectedType == 'Loud Alarm' || _selectedType == 'Fake Call';
    if (!isPopupMode) return;
    setState(() => _isLoadingReminderHealth = true);
    final status = await NotificationService().getReminderHealthStatus();
    if (!mounted) return;
    setState(() {
      _reminderHealthStatus = status;
      _isLoadingReminderHealth = false;
    });
  }

  Widget _buildPermissionStatusCard() {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final status = _reminderHealthStatus;
    return NaraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isEnglish ? 'Popup permission status' : 'Status izin popup',
                  style: NaraTextStyles.h3,
                ),
              ),
              IconButton(
                onPressed: _isLoadingReminderHealth ? null : _refreshReminderHealthIfNeeded,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                tooltip: isEnglish ? 'Refresh' : 'Muat ulang',
              ),
            ],
          ),
          if (_isLoadingReminderHealth)
            Text(
              isEnglish ? 'Checking permissions...' : 'Mengecek izin...',
              style: NaraTextStyles.bodySmall.copyWith(color: NaraColors.textSecondary),
            )
          else ...[
            _permissionRow(
              label: isEnglish ? 'Notification' : 'Notifikasi',
              ok: status?.notificationsEnabled == true,
            ),
            _permissionRow(
              label: isEnglish ? 'Exact alarm' : 'Alarm presisi',
              ok: status?.exactAlarmAllowed == true,
            ),
            _permissionRow(
              label: isEnglish ? 'Full screen intent' : 'Full screen intent',
              ok: status?.fullScreenIntentGranted != false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _permissionRow({required String label, required bool ok}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 16,
            color: ok ? NaraColors.success : NaraColors.danger,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: NaraTextStyles.bodySmall.copyWith(color: NaraColors.textSecondary),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Loud Alarm':
        return Icons.volume_up_rounded;
      case 'Fake Call':
        return Icons.call_rounded;
      default:
        return Icons.notifications_rounded;
    }
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.editIndex != null
                  ? I18n.t(context, 'edit_reminder')
                  : I18n.t(context, 'create_reminder'),
              style: NaraTextStyles.h2,
            ),
            const SizedBox(height: 2),
            Text(
              I18n.t(context, 'set_schedule'),
              style: NaraTextStyles.caption.copyWith(
                color: NaraColors.textSecondary,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          NaraSpacing.lg,
          NaraSpacing.sm,
          NaraSpacing.lg,
          120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NaraCard(
              child: Column(
                children: [
                  Text(
                    _formatDate(context, _selectedDate),
                    style: NaraTextStyles.label.copyWith(
                      color: NaraColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: NaraSpacing.sm),
                  Text(
                    _formatTime(_selectedTime),
                    style: NaraTextStyles.h1.copyWith(letterSpacing: 1.5),
                  ),
                  const SizedBox(height: NaraSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.event_rounded, size: 18),
                          label: Text(
                            I18n.t(context, 'change_date'),
                            style: NaraTextStyles.label.copyWith(
                              color: NaraColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: NaraSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.schedule_rounded, size: 18),
                          label: Text(
                            I18n.t(context, 'change_time'),
                            style: NaraTextStyles.label.copyWith(
                              color: NaraColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: NaraSpacing.xl),
            Text(
              '${I18n.t(context, 'reminder_title')} *',
              style: NaraTextStyles.h3,
            ),
            const SizedBox(height: NaraSpacing.sm),
            TextField(
              controller: _titleController,
              style: NaraTextStyles.body,
              decoration: InputDecoration(
                hintText: I18n.t(context, 'reminder_title_hint'),
                hintStyle: NaraTextStyles.body.copyWith(
                  color: NaraColors.textSecondary,
                ),
                helperText: Localizations.localeOf(context).languageCode == 'en'
                    ? 'Required field'
                    : 'Wajib diisi',
                helperStyle: NaraTextStyles.bodySmall.copyWith(
                  color: NaraColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: NaraColors.surfaceWhite,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: NaraSpacing.md,
                  vertical: NaraSpacing.md,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(NaraRadius.lg),
                  borderSide: BorderSide(
                    color: NaraColors.primary.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(NaraRadius.lg),
                  borderSide: BorderSide(
                    color: NaraColors.primary.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(NaraRadius.lg),
                  borderSide: const BorderSide(
                    color: NaraColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: NaraSpacing.xl),
            Text(I18n.t(context, 'reminder_type'), style: NaraTextStyles.h3),
            const SizedBox(height: NaraSpacing.md),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: NaraSpacing.md,
              crossAxisSpacing: NaraSpacing.md,
              childAspectRatio: 0.72,
              children: _types.map((type) {
                final mode = type['mode'] as String;
                final isSelected = _selectedType == mode;
                final color = type['color'] as Color;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedType = mode);
                    _refreshReminderHealthIfNeeded();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(NaraSpacing.md),
                    decoration: BoxDecoration(
                      color: NaraColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(NaraRadius.lg),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : NaraColors.textHint.withValues(alpha: 0.15),
                        width: isSelected ? 1.4 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 18,
                            color: isSelected
                                ? color
                                : NaraColors.textSecondary,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(
                                  NaraRadius.md,
                                ),
                              ),
                              child: Icon(
                                type['icon'] as IconData,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: NaraSpacing.xs),
                            Text(
                              I18n.t(context, type['nameKey'] as String),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: NaraTextStyles.label.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _subtitleForType(mode),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: NaraTextStyles.bodySmall.copyWith(
                                color: NaraColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_selectedType == 'Loud Alarm' || _selectedType == 'Fake Call') ...[
              const SizedBox(height: NaraSpacing.lg),
              _buildPermissionStatusCard(),
            ],
            const SizedBox(height: NaraSpacing.lg),
            NaraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          I18n.t(context, 'repeat_routine'),
                          style: NaraTextStyles.h3,
                        ),
                      ),
                      NaraToggle(
                        value: _isRoutineEnabled,
                        onChanged: (value) =>
                            setState(() => _isRoutineEnabled = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: NaraSpacing.md),
                  Wrap(
                    spacing: NaraSpacing.sm,
                    runSpacing: NaraSpacing.sm,
                    children: _weekDayIndexes.map((index) {
                      final isSelected = _selectedWeekDays.contains(index);
                      return GestureDetector(
                        onTap: _isRoutineEnabled
                            ? () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedWeekDays.remove(index);
                                  } else {
                                    _selectedWeekDays.add(index);
                                  }
                                });
                              }
                            : null,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? NaraColors.primaryLight
                                : NaraColors.surfaceCard,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? NaraColors.primary
                                  : NaraColors.textHint,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _weekDayLabel(context, index),
                            style: NaraTextStyles.label.copyWith(
                              color: isSelected
                                  ? NaraColors.primary
                                  : NaraColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: NaraSpacing.lg),
            NaraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          I18n.t(context, 'link_to_note'),
                          style: NaraTextStyles.h3,
                        ),
                      ),
                      NaraToggle(
                        value: _isLinkedToNote,
                        onChanged: (value) =>
                            setState(() => _isLinkedToNote = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: NaraSpacing.sm),
                  NaraTextField(
                    controller: _noteController,
                    hint: I18n.t(context, 'reminder_note_hint'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: NaraSpacing.lg),
            NaraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          I18n.t(context, 'notification_sound'),
                          style: NaraTextStyles.h3,
                        ),
                      ),
                      NaraToggle(
                        value: _useDefaultSound,
                        onChanged: (value) {
                          setState(() {
                            _useDefaultSound = value;
                            if (value) {
                              _selectedSoundUri = null;
                              _selectedSoundName = null;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: NaraSpacing.xs),
                  Text(
                    _useDefaultSound
                        ? I18n.t(context, 'use_default_sound')
                        : (_selectedSoundName ??
                              I18n.t(context, 'custom_sound_selected')),
                    style: NaraTextStyles.bodySmall.copyWith(
                      color: NaraColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: NaraSpacing.sm),
                  NaraSecondaryButton(
                    label: _useDefaultSound
                        ? I18n.t(context, 'import_sound_file')
                        : I18n.t(context, 'change_sound_file'),
                    onPressed: _pickCustomSound,
                    icon: Icon(
                      _useDefaultSound
                          ? Icons.upload_file_rounded
                          : Icons.music_note_rounded,
                      size: 16,
                      color: NaraColors.primary,
                    ),
                    fullWidth: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: NaraSpacing.xl),
            NaraPrimaryButton(
              label: I18n.t(context, 'save_reminder'),
              onPressed: _saveReminder,
              icon: const Icon(
                Icons.notifications_active_rounded,
                size: 18,
                color: NaraColors.textOnPrimary,
              ),
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitLocalizedDefaults) return;
    _didInitLocalizedDefaults = true;
    // Keep note empty by default for new reminders.
  }

  Future<String?> _showPopupPermissionDialog({
    required bool hasNotif,
    required bool hasExact,
    required bool hasFullScreen,
  }) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isEnglish ? 'Popup reminder needs permission' : 'Popup butuh izin',
          ),
          content: Text(
            isEnglish
                ? 'Loud Alarm/Fake Call requires notification, exact alarm, and full-screen permissions to show on time.'
                : 'Alarm Keras/Fake Call butuh izin notifikasi, alarm presisi, dan full-screen agar muncul tepat waktu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: Text(isEnglish ? 'Cancel' : 'Batal'),
            ),
            if (!hasNotif)
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, 'open_notification'),
                child: Text(isEnglish ? 'Enable Notification' : 'Aktifkan Notifikasi'),
              ),
            if (!hasExact)
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, 'open_exact'),
                child: Text(isEnglish ? 'Enable Exact Alarm' : 'Aktifkan Alarm Presisi'),
              ),
            if (!hasFullScreen)
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, 'open_fullscreen'),
                child: Text(isEnglish ? 'Enable Full Screen' : 'Aktifkan Full Screen'),
              ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, 'fallback_notification'),
              child: Text(
                isEnglish
                    ? 'Save as Notification'
                    : 'Simpan sebagai Notifikasi',
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _subtitleForType(String type) {
    switch (type) {
      case 'Loud Alarm':
        return I18n.t(context, 'loud_sound');
      case 'Fake Call':
        return I18n.t(context, 'fake_call_simulation');
      default:
        return I18n.t(context, 'message_on_screen');
    }
  }

  String _normalizeReminderType(String raw) {
    switch (raw) {
      case 'Notifikasi':
      case 'Notification':
        return 'Notification';
      case 'Alarm Keras':
      case 'Loud Alarm':
        return 'Loud Alarm';
      case 'Fullscreen Alert':
        return 'Loud Alarm';
      case 'Fake Call':
        return 'Fake Call';
      default:
        return 'Notification';
    }
  }

  String _labelForType(BuildContext context, String mode) {
    switch (mode) {
      case 'Loud Alarm':
        return I18n.t(context, 'reminder_mode_loud_alarm');
      case 'Fake Call':
        return I18n.t(context, 'reminder_mode_fake_call');
      default:
        return I18n.t(context, 'reminder_mode_notification');
    }
  }

  String _weekDayLabel(BuildContext context, int index) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    if (isEnglish) {
      const labelsEn = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
      return labelsEn[index.clamp(0, 6)];
    }
    const labelsId = ['M', 'S', 'S', 'R', 'K', 'J', 'S'];
    return labelsId[index.clamp(0, 6)];
  }
}


