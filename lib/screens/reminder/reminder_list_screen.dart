import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'create_reminder_screen.dart';
import '../../components/index.dart';
import '../../core/i18n.dart';
import '../../core/theme/nara_colors.dart';
import '../../core/theme/nara_radius.dart';
import '../../core/theme/nara_spacing.dart';
import '../../core/theme/nara_text_styles.dart';
import '../../providers/app_provider.dart';
import 'reminder_alert_screen.dart';

class ReminderListScreen extends StatefulWidget {
  const ReminderListScreen({super.key});

  @override
  State<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> {
  String _selectedFilter = 'all';

  final List<String> _filters = const ['all', 'today', 'upcoming', 'done'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NaraColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : const SizedBox(width: 48),
        leadingWidth: 48,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(I18n.t(context, 'planning'), style: NaraTextStyles.h2),
            const SizedBox(height: 2),
            Text(
              I18n.t(context, 'manage_schedule'),
              style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Consumer<AppProvider>(
            builder: (context, provider, _) => IconButton(
              icon: const Icon(Icons.calendar_month_rounded),
              tooltip: Localizations.localeOf(context).languageCode == 'en'
                  ? 'Planning Calendar'
                  : 'Kalender Perencanaan',
              onPressed: () => _showPlanningCalendar(context, provider),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final activeReminders = provider.activeRemindersList;
          final completedReminders = provider.completedRemindersList;
          final filteredActiveReminders = _filterReminders(activeReminders);
          final filteredCompletedReminders = _filterReminders(completedReminders);
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(NaraSpacing.lg, NaraSpacing.sm, NaraSpacing.lg, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    NaraReveal(
                      delay: Duration(milliseconds: 40),
                      child: _ReminderHeader(onCreate: () => Navigator.pushNamed(context, '/create-reminder')),
                    ),
                    const SizedBox(height: NaraSpacing.lg),
                    NaraReveal(
                      delay: const Duration(milliseconds: 170),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _filters.map((filter) {
                            final isSelected = filter == _selectedFilter;
                            return Padding(
                              padding: const EdgeInsets.only(right: NaraSpacing.sm),
                              child: NaraChip(
                                label: I18n.t(context, filter),
                                selected: isSelected,
                                onTap: () => setState(() => _selectedFilter = filter),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: NaraSpacing.lg),
                    if (filteredActiveReminders.isNotEmpty) ...[
                      NaraReveal(
                        delay: Duration(milliseconds: 220),
                        child: _SectionTitle(label: I18n.t(context, 'active')),
                      ),
                      const SizedBox(height: NaraSpacing.sm),
                      ...filteredActiveReminders.asMap().entries.map(
                            (entry) => Padding(
                              padding: EdgeInsets.only(bottom: entry.key == filteredActiveReminders.length - 1 ? 0 : NaraSpacing.sm),
                              child: NaraReveal(
                                delay: Duration(milliseconds: 70 * entry.key),
                                child: _ReminderCard(
                                  reminder: entry.value,
                                  accentColor: _accentColorForIndex(entry.key),
                                  scheduleLabel: _scheduleLabel(context, entry.value),
                                  onToggle: () => provider.toggleReminderStatus(provider.reminders.indexOf(entry.value)),
                                  onDelete: () => provider.removeReminderAt(provider.reminders.indexOf(entry.value)),
                                  onAlert: () async {
                                    if (!context.mounted) return;
                                    final reminderIndex = provider.reminders.indexOf(entry.value);
                                    final mode = provider.normalizeReminderModePublic(
                                      (entry.value['mode'] as String?) ??
                                          (entry.value['type'] as String?) ??
                                          'Notification',
                                    );
                                    if (mode == 'Notification') {
                                      await provider.previewReminderAt(reminderIndex);
                                      return;
                                    }

                                    final result = await Navigator.of(context).push<dynamic>(
                                      MaterialPageRoute(
                                        builder: (context) => ReminderAlertScreen(
                                          reminder: entry.value,
                                          reminderIndex: reminderIndex,
                                        ),
                                      ),
                                    );
                                    if (!context.mounted) return;
                                    if (result == true) {
                                      provider.toggleReminderStatus(reminderIndex);
                                    }
                                  },
                                  onEdit: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => CreateReminderScreen(
                                          editIndex: provider.reminders.indexOf(entry.value),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                    ],
                    if (filteredCompletedReminders.isNotEmpty) ...[
                      const SizedBox(height: NaraSpacing.xl),
                      NaraReveal(
                        delay: Duration(milliseconds: 260),
                        child: _SectionTitle(label: I18n.t(context, 'done')),
                      ),
                      const SizedBox(height: NaraSpacing.sm),
                      ...filteredCompletedReminders.asMap().entries.map(
                            (entry) => Padding(
                              padding: EdgeInsets.only(bottom: entry.key == filteredCompletedReminders.length - 1 ? 0 : NaraSpacing.sm),
                              child: NaraReveal(
                                delay: Duration(milliseconds: 60 * entry.key),
                                child: _ReminderCard(
                                  reminder: entry.value,
                                  accentColor: NaraColors.textHint,
                                  isCompleted: true,
                                  scheduleLabel: _scheduleLabel(context, entry.value),
                                  onToggle: () => provider.toggleReminderStatus(provider.reminders.indexOf(entry.value)),
                                  onDelete: () => provider.removeReminderAt(provider.reminders.indexOf(entry.value)),
                                ),
                              ),
                            ),
                          ),
                    ],
                    if (filteredActiveReminders.isEmpty && filteredCompletedReminders.isEmpty)
                      NaraReveal(
                        delay: const Duration(milliseconds: 260),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 48),
                          child: NaraEmptyState(
                            icon: Icons.notifications_none_rounded,
                            title: I18n.t(context, 'no_reminder'),
                            message: I18n.t(context, 'no_reminder_msg'),
                            accentColor: NaraColors.accentOrange,
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: NaraSpacing.lg)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'reminder_fab_add',
        onPressed: () => Navigator.pushNamed(context, '/create-reminder'),
        backgroundColor: NaraColors.primary,
        foregroundColor: NaraColors.textOnPrimary,
        child: Text('+', style: NaraTextStyles.h2.copyWith(color: NaraColors.textOnPrimary)),
      ),
    );
  }

  List<Map<String, dynamic>> _filterReminders(List<Map<String, dynamic>> reminders) {
    if (_selectedFilter == 'all') {
      return reminders;
    }

    return reminders.where((reminder) {
      final scheduledAt = DateTime.tryParse(reminder['scheduledAt'] as String? ?? '');
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      final status = (reminder['status'] as String? ?? '').toLowerCase();
      final isDone = status == 'selesai' || status == 'done';

      switch (_selectedFilter) {
        case 'today':
          if (scheduledAt != null) {
            return !isDone && !scheduledAt.isBefore(todayStart) && scheduledAt.isBefore(todayEnd);
          }
          final dateLabel = (reminder['date'] as String? ?? '').toLowerCase();
          return !isDone && (dateLabel.contains('hari ini') || dateLabel.contains('today'));
        case 'upcoming':
          if (scheduledAt != null) {
            return !isDone && scheduledAt.isAfter(now);
          }
          final dateLabel = (reminder['date'] as String? ?? '').toLowerCase();
          return !isDone && (dateLabel.contains('besok') || dateLabel.contains('tomorrow') || dateLabel.contains('minggu') || dateLabel.contains('bulan'));
        case 'done':
          return isDone;
        default:
          return true;
      }
    }).toList();
  }

  Color _accentColorForIndex(int index) {
    const colors = [
      NaraColors.accentOrange,
      NaraColors.primary,
      NaraColors.danger,
      NaraColors.success,
    ];
    return colors[index % colors.length];
  }

  String _scheduleLabel(BuildContext context, Map<String, dynamic> reminder) {
    final scheduledAt = DateTime.tryParse(reminder['scheduledAt'] as String? ?? '');
    if (scheduledAt == null) {
      return I18n.t(context, 'scheduled');
    }
    // The main subtitle already shows day/date/time. Avoid duplicate lines.
    return '';
  }

  Future<void> _showPlanningCalendar(BuildContext context, AppProvider provider) async {
    DateTime selectedDate = DateTime.now();
    DateTime visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final entriesByDate = _buildPlanningEntries(provider);

    List<_PlanningCalendarEntry> entriesFor(DateTime date) {
      return entriesByDate[_dateKey(date)] ?? const <_PlanningCalendarEntry>[];
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) {
          final monthDays = _monthGridDays(visibleMonth);
          final selectedEntries = entriesFor(selectedDate);
          return AlertDialog(
            backgroundColor: NaraColors.surfaceWhite,
            title: Text(
              isEnglish ? 'Planning Calendar' : 'Kalender Perencanaan',
              style: NaraTextStyles.h3,
            ),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => setLocalState(() {
                          visibleMonth = DateTime(visibleMonth.year, visibleMonth.month - 1);
                        }),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: Text(
                          '${_monthName(context, visibleMonth.month)} ${visibleMonth.year}',
                          textAlign: TextAlign.center,
                          style: NaraTextStyles.label.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setLocalState(() {
                          visibleMonth = DateTime(visibleMonth.year, visibleMonth.month + 1);
                        }),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(7, (i) {
                      final labels = isEnglish
                          ? const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                          : const ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
                      return Expanded(
                        child: Center(
                          child: Text(
                            labels[i],
                            style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: monthDays.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      final day = monthDays[index];
                      final inMonth = day.month == visibleMonth.month;
                      final isSelected = _sameDate(day, selectedDate);
                      final entriesOnDay = entriesByDate[_dateKey(day)] ?? const <_PlanningCalendarEntry>[];
                      final hasReminder = entriesOnDay.any((e) => e.kind == 'reminder');
                      final hasDebt = entriesOnDay.any((e) => e.kind == 'debt');
                      return GestureDetector(
                        onTap: () => setLocalState(() => selectedDate = day),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? NaraColors.primaryLight : NaraColors.surfaceCard,
                            borderRadius: BorderRadius.circular(NaraRadius.sm),
                            border: Border.all(
                              color: isSelected
                                  ? NaraColors.primary
                                  : NaraColors.textHint.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${day.day}',
                                style: NaraTextStyles.caption.copyWith(
                                  color: inMonth ? NaraColors.textPrimary : NaraColors.textHint,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (hasReminder || hasDebt)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (hasReminder)
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: NaraColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    if (hasReminder && hasDebt) const SizedBox(width: 3),
                                    if (hasDebt)
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: NaraColors.warning,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isEnglish ? 'Entries on selected date' : 'Item pada tanggal terpilih',
                      style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (selectedEntries.isEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        isEnglish ? 'No planning/reminder/debt entries.' : 'Belum ada plan/reminder/utang-piutang.',
                        style: NaraTextStyles.bodySmall.copyWith(color: NaraColors.textSecondary),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: selectedEntries.length,
                        separatorBuilder: (_, index) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final item = selectedEntries[index];
                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: NaraColors.surfaceCard,
                              borderRadius: BorderRadius.circular(NaraRadius.sm),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item.kind == 'reminder' ? Icons.notifications_active_rounded : Icons.handshake_rounded,
                                  size: 16,
                                  color: item.kind == 'reminder' ? NaraColors.primary : NaraColors.warning,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: NaraTextStyles.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: NaraColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isEnglish ? 'Reminder' : 'Reminder',
                        style: NaraTextStyles.bodySmall.copyWith(color: NaraColors.textSecondary),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: NaraColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isEnglish ? 'Debt/Receivable' : 'Utang/Piutang',
                        style: NaraTextStyles.bodySmall.copyWith(color: NaraColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(I18n.t(context, 'close')),
              ),
            ],
          );
        },
      ),
    );
  }

  Map<String, List<_PlanningCalendarEntry>> _buildPlanningEntries(AppProvider provider) {
    final map = <String, List<_PlanningCalendarEntry>>{};

    void addEntry(DateTime date, _PlanningCalendarEntry entry) {
      final key = _dateKey(date);
      map.putIfAbsent(key, () => <_PlanningCalendarEntry>[]).add(entry);
    }

    for (final reminder in provider.reminders) {
      final scheduledAt = DateTime.tryParse(reminder['scheduledAt'] as String? ?? '');
      if (scheduledAt == null) continue;
      addEntry(
        DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day),
        _PlanningCalendarEntry(
          kind: 'reminder',
          title: (reminder['title'] as String?)?.trim().isNotEmpty == true
              ? (reminder['title'] as String).trim()
              : 'Reminder',
        ),
      );
    }

    for (final debt in provider.debts) {
      final dueDate = _parseDebtDueDate(debt['dueDate'] as String? ?? '');
      if (dueDate == null) continue;
      final title = (debt['title'] as String?)?.trim();
      final type = (debt['type'] as String?) == 'piutang' ? 'Piutang' : 'Utang';
      addEntry(
        DateTime(dueDate.year, dueDate.month, dueDate.day),
        _PlanningCalendarEntry(
          kind: 'debt',
          title: '$type • ${title == null || title.isEmpty ? '-' : title}',
        ),
      );
    }

    return map;
  }

  DateTime? _parseDebtDueDate(String raw) {
    final parts = raw.trim().split(RegExp(r'\s+'));
    if (parts.length < 3) return null;
    final day = int.tryParse(parts[0]);
    final month = _monthFromShort(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  int? _monthFromShort(String short) {
    const months = <String, int>{
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'mei': 5,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'agu': 8,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'okt': 10,
      'nov': 11,
      'dec': 12,
      'des': 12,
    };
    return months[short.toLowerCase()];
  }

  List<DateTime> _monthGridDays(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final start = first.subtract(Duration(days: first.weekday - 1));
    return List<DateTime>.generate(42, (i) => start.add(Duration(days: i)));
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _monthName(BuildContext context, int month) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    const id = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    const en = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final safe = month.clamp(1, 12) - 1;
    return isEnglish ? en[safe] : id[safe];
  }
}

class _PlanningCalendarEntry {
  final String kind;
  final String title;

  const _PlanningCalendarEntry({
    required this.kind,
    required this.title,
  });
}

class _ReminderHeader extends StatelessWidget {
  final VoidCallback onCreate;

  const _ReminderHeader({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reminder', style: NaraTextStyles.h1),
              const SizedBox(height: NaraSpacing.xs),
              Text(
                I18n.t(context, 'manage_schedule'),
                style: NaraTextStyles.body.copyWith(color: NaraColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary));
  }
}

class _ReminderCard extends StatelessWidget {
  final Map<String, dynamic> reminder;
  final Color accentColor;
  final String scheduleLabel;
  final bool isCompleted;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onAlert;
  final VoidCallback? onEdit;

  const _ReminderCard({
    required this.reminder,
    required this.accentColor,
    required this.scheduleLabel,
    required this.onToggle,
    required this.onDelete,
    this.onAlert,
    this.onEdit,
    this.isCompleted = false,
  });
  @override
  Widget build(BuildContext context) {
    final title = reminder['title'] as String? ?? '-';
    final date = _displayDate(context, reminder);
    final note = (reminder['note'] as String? ?? '').trim();
    final modeLabel = _modeLabel(context, reminder);
    final subtitle = date;
    final icon = reminder['icon'] as IconData? ?? Icons.notifications_active_rounded;

    return NaraCard(
      borderRadius: NaraRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(NaraRadius.md),
                ),
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(width: NaraSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: NaraTextStyles.label.copyWith(
                        color: isCompleted ? NaraColors.textSecondary : NaraColors.textPrimary,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(subtitle, style: NaraTextStyles.bodySmall),
                    const SizedBox(height: 2),
                    if (scheduleLabel.trim().isNotEmpty)
                      Text(
                        scheduleLabel,
                        style: NaraTextStyles.bodySmall.copyWith(
                          color: NaraColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              NaraBadge(label: isCompleted ? I18n.t(context, 'done') : I18n.t(context, 'waiting')),
            ],
          ),
          const SizedBox(height: NaraSpacing.md),
          Wrap(
            spacing: NaraSpacing.xs,
            runSpacing: NaraSpacing.xs,
            children: [
              NaraChip(label: modeLabel, selected: false),
              if (note.isNotEmpty) NaraChip(label: note, selected: false),
            ],
          ),
          const SizedBox(height: NaraSpacing.md),
          Wrap(
            spacing: NaraSpacing.xs,
            runSpacing: NaraSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (!isCompleted && onAlert != null)
                NaraSecondaryButton(
                  label: 'Tes',
                  onPressed: onAlert!,
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 16, color: NaraColors.primary),
                  fullWidth: false,
                ),
              if (!isCompleted && onEdit != null)
                NaraSecondaryButton(
                  label: 'Edit',
                  onPressed: onEdit!,
                  icon: const Icon(Icons.edit_outlined, size: 16, color: NaraColors.primary),
                  fullWidth: false,
                ),
              IconButton(
                onPressed: onToggle,
                icon: Icon(
                  isCompleted ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
                  color: isCompleted ? NaraColors.textSecondary : NaraColors.success,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, color: NaraColors.danger),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _displayDate(BuildContext context, Map<String, dynamic> reminder) {
    final scheduledAt = DateTime.tryParse(reminder['scheduledAt'] as String? ?? '');
    if (scheduledAt == null) {
      return I18n.translateRelativeDate(context, reminder['date'] as String? ?? '-');
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
    final dayDiff = target.difference(today).inDays;
    final timeText = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: scheduledAt.hour, minute: scheduledAt.minute),
      alwaysUse24HourFormat: true,
    );
    if (dayDiff == 0) {
      return '${I18n.t(context, 'today')} $timeText';
    }
    if (dayDiff == 1) {
      return '${I18n.t(context, 'tomorrow')} $timeText';
    }

    final weekdayName = _weekdayName(context, scheduledAt.weekday);
    final dateText = MaterialLocalizations.of(context).formatShortDate(scheduledAt);
    return '$weekdayName, $dateText $timeText';
  }

  String _weekdayName(BuildContext context, int weekday) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    const labelsId = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const labelsEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final index = (weekday - 1).clamp(0, 6);
    return isEnglish ? labelsEn[index] : labelsId[index];
  }

  String _modeLabel(BuildContext context, Map<String, dynamic> reminder) {
    final rawMode =
        (reminder['mode'] as String?) ?? (reminder['type'] as String?) ?? 'Notification';
    switch (rawMode) {
      case 'Loud Alarm':
      case 'Alarm Keras':
      case 'Fullscreen Alert':
        return I18n.t(context, 'reminder_mode_loud_alarm');
      case 'Fake Call':
        return I18n.t(context, 'reminder_mode_fake_call');
      default:
        return I18n.t(context, 'reminder_mode_notification');
    }
  }
}

