import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';
import 'reminder_alert_screen.dart';
import 'create_reminder_screen.dart';

class ReminderListScreen extends StatefulWidget {
  const ReminderListScreen({super.key});

  @override
  State<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> {
  String _selectedFilter = 'Semua';

  final List<String> _filters = const [
    'Semua',
    'Hari ini',
    'Mendatang',
    'Selesai',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Reminders', style: AppTheme.h3),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.surfaceContainerHigh,
              child: Text(
                'N',
                style: AppTheme.label.copyWith(color: AppTheme.primary),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final activeReminders = provider.activeRemindersList;
          final completedReminders = provider.completedRemindersList;
          final filteredActiveReminders = _filterReminders(activeReminders);
          final filteredCompletedReminders = _filterReminders(completedReminders);
          final heroReminder = filteredActiveReminders.isNotEmpty
              ? filteredActiveReminders.first
              : (provider.reminders.isNotEmpty ? provider.reminders.first : null);

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Reminder', style: AppTheme.h1),
                              const SizedBox(height: 4),
                              Text(
                                'Kelola jadwal dan pengingat Anda.',
                                style: AppTheme.body.copyWith(color: AppTheme.outline),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/create-reminder'),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text('Buat Baru', style: AppTheme.label.copyWith(color: AppTheme.onPrimaryContainer)),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryContainer,
                            foregroundColor: AppTheme.onPrimaryContainer,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _HeroReminderCard(
                      reminder: heroReminder,
                      reminderIndex: filteredActiveReminders.isNotEmpty
                          ? provider.reminders.indexOf(filteredActiveReminders.first)
                          : null,
                      onEdit: filteredActiveReminders.isNotEmpty
                          ? () {
                              final reminderToEdit = filteredActiveReminders.first;
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => CreateReminderScreen(
                                    editIndex: provider.reminders.indexOf(reminderToEdit),
                                  ),
                                ),
                              );
                            }
                          : null,
                      onDismiss: filteredActiveReminders.isNotEmpty
                          ? () {
                              final reminderIndex = provider.reminders.indexOf(filteredActiveReminders.first);
                              provider.toggleReminderStatus(reminderIndex);
                              setState(() {});
                            }
                          : null,
                    ),
                    const SizedBox(height: 18),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.map((filter) {
                          final isSelected = filter == _selectedFilter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(filter),
                              selected: isSelected,
                              showCheckmark: false,
                              selectedColor: AppTheme.primaryContainer,
                              backgroundColor: AppTheme.surfaceContainer,
                              labelStyle: AppTheme.label.copyWith(
                                color: isSelected ? AppTheme.onPrimaryContainer : AppTheme.outline,
                              ),
                              side: BorderSide(
                                color: isSelected ? AppTheme.primaryContainer : Colors.transparent,
                              ),
                              onSelected: (_) => setState(() => _selectedFilter = filter),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (filteredActiveReminders.isNotEmpty) ...[
                      Text('Aktif', style: AppTheme.label.copyWith(color: AppTheme.outline)),
                      const SizedBox(height: 10),
                      ...filteredActiveReminders.asMap().entries.map(
                            (entry) => Padding(
                              padding: EdgeInsets.only(bottom: entry.key == filteredActiveReminders.length - 1 ? 0 : 10),
                              child: _ReminderCard(
                                reminder: entry.value,
                                accentColor: _accentColorForIndex(entry.key),
                                onToggle: () => provider.toggleReminderStatus(provider.reminders.indexOf(entry.value)),
                                onDelete: () => provider.removeReminderAt(provider.reminders.indexOf(entry.value)),
                                onAlert: () async {
                                  if (!mounted) return;
                                  // ignore: use_build_context_synchronously
                                  final result = await Navigator.of(context).push<dynamic>(
                                    MaterialPageRoute(
                                      builder: (context) => ReminderAlertScreen(
                                        reminder: entry.value,
                                        reminderIndex: provider.reminders.indexOf(entry.value),
                                      ),
                                    ),
                                  );
                                  if (!mounted) return;
                                  if (result == true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Reminder ditandai selesai', style: AppTheme.body),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                    provider.toggleReminderStatus(provider.reminders.indexOf(entry.value));
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
                    ],
                    if (filteredCompletedReminders.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Text('Selesai', style: AppTheme.label.copyWith(color: AppTheme.outline)),
                      const SizedBox(height: 10),
                      ...filteredCompletedReminders.asMap().entries.map(
                            (entry) => Padding(
                              padding: EdgeInsets.only(bottom: entry.key == filteredCompletedReminders.length - 1 ? 0 : 10),
                              child: _ReminderCard(
                                reminder: entry.value,
                                accentColor: AppTheme.outlineVariant,
                                isCompleted: true,
                                onToggle: () => provider.toggleReminderStatus(provider.reminders.indexOf(entry.value)),
                                onDelete: () => provider.removeReminderAt(provider.reminders.indexOf(entry.value)),
                              ),
                            ),
                          ),
                    ],
                    if (filteredActiveReminders.isEmpty && filteredCompletedReminders.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 48),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(Icons.notifications_none_rounded, size: 52, color: AppTheme.outline),
                              const SizedBox(height: 12),
                              Text('Belum ada reminder', style: AppTheme.h3),
                              const SizedBox(height: 6),
                              Text(
                                'Buat reminder baru untuk tampil seperti kartu di gambar.',
                                textAlign: TextAlign.center,
                                style: AppTheme.body.copyWith(color: AppTheme.outline),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/create-reminder'),
        backgroundColor: AppTheme.primaryContainer,
        foregroundColor: AppTheme.onPrimaryContainer,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  List<Map<String, dynamic>> _filterReminders(List<Map<String, dynamic>> reminders) {
    if (_selectedFilter == 'Semua') {
      return reminders;
    }

    return reminders.where((reminder) {
      final dateLabel = (reminder['date'] as String? ?? '').toLowerCase();
      switch (_selectedFilter) {
        case 'Hari ini':
          return dateLabel.contains('hari ini') || dateLabel.contains('today');
        case 'Mendatang':
          return dateLabel.contains('besok') || dateLabel.contains('minggu') || dateLabel.contains('bulan');
        case 'Selesai':
          return (reminder['status'] as String? ?? '') == 'selesai';
        default:
          return true;
      }
    }).toList();
  }

  Color _accentColorForIndex(int index) {
    const colors = [
      AppTheme.secondary,
      AppTheme.primaryContainer,
      AppTheme.danger,
      AppTheme.success,
    ];
    return colors[index % colors.length];
  }
}

class _HeroReminderCard extends StatelessWidget {
  final Map<String, dynamic>? reminder;
  final int? reminderIndex;
  final VoidCallback? onEdit;
  final VoidCallback? onDismiss;

  const _HeroReminderCard({
    required this.reminder,
    this.reminderIndex,
    this.onEdit,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final title = reminder?['title'] as String? ?? 'Bayar tagihan listrik';
    final date = reminder?['date'] as String? ?? 'Besok, 20:00';
    final tag = reminder?['type'] as String? ?? 'Peringatan Aktif';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceContainerHigh.withValues(alpha: 0.95),
            AppTheme.surfaceContainer.withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryContainer.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'BERIKUTNYA DALAM 2 JAM',
                style: AppTheme.label.copyWith(color: AppTheme.outline, letterSpacing: 0.4),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTheme.h2.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(date, style: AppTheme.body.copyWith(color: AppTheme.onSurfaceVariant)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _TagPill(label: tag),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: Text('Edit', style: AppTheme.label.copyWith(color: AppTheme.onSurface)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                  foregroundColor: AppTheme.onSurface,
                ),
              ),
              OutlinedButton.icon(
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded, size: 16),
                label: Text('Dismiss', style: AppTheme.label.copyWith(color: AppTheme.onSurface)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                  foregroundColor: AppTheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Map<String, dynamic> reminder;
  final Color accentColor;
  final bool isCompleted;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onAlert;
  final VoidCallback? onEdit;

  const _ReminderCard({
    required this.reminder,
    required this.accentColor,
    required this.onToggle,
    required this.onDelete,
    this.onAlert,
    this.onEdit,
    this.isCompleted = false,
  });
  Widget build(BuildContext context) {
    final title = reminder['title'] as String? ?? '-';
    final date = reminder['date'] as String? ?? '-';
    final note = reminder['note'] as String? ?? (reminder['type'] as String? ?? '');
    final subtitle = reminder['subtitle'] as String? ?? date;
    final icon = reminder['icon'] as IconData? ?? Icons.notifications_active_rounded;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: accentColor),
        ),
        title: Text(
          title,
          style: AppTheme.label.copyWith(
            color: isCompleted ? AppTheme.outline : AppTheme.onSurface,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subtitle, style: AppTheme.body.copyWith(color: AppTheme.outline, fontSize: 12)),
              if (note.isNotEmpty) ...[
                const SizedBox(height: 8),
                _TagPill(label: note, compact: true, backgroundColor: AppTheme.surfaceContainer),
              ],
            ],
          ),
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            if (!isCompleted && onAlert != null)
              IconButton(
                onPressed: onAlert,
                icon: const Icon(Icons.play_circle_outline_rounded, color: AppTheme.tertiary),
              ),
            if (!isCompleted && onEdit != null)
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryContainer),
              ),
            IconButton(
              onPressed: onToggle,
              icon: Icon(
                isCompleted ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
                color: isCompleted ? AppTheme.outline : AppTheme.success,
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String label;
  final bool compact;
  final Color? backgroundColor;

  const _TagPill({
    required this.label,
    this.compact = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: compact ? 5 : 7),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.tertiary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        label,
        style: AppTheme.label.copyWith(
          color: backgroundColor == null ? AppTheme.tertiary : AppTheme.outline,
          fontSize: compact ? 11 : 12,
        ),
      ),
    );
  }
}
