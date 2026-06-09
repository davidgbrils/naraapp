import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/formatters.dart';
import '../../core/i18n.dart';
import '../../core/snackbar_utils.dart';
import '../../core/theme/nara_colors.dart';
import '../../core/theme/nara_spacing.dart';
import '../../core/theme/nara_text_styles.dart';
import '../../components/index.dart';
import '../../providers/app_provider.dart';
import 'notification_feed_ids.dart';

enum _NotificationFilter { all, reminder, debt, transaction }

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  static const String _readIdsKey = 'notification_center_read_ids_v1';
  static const String _hiddenIdsKey = 'notification_center_hidden_ids_v1';
  _NotificationFilter _selectedFilter = _NotificationFilter.all;
  Set<String> _readIds = <String>{};
  Set<String> _hiddenIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadReadIds();
    _loadHiddenIds();
  }

  Future<void> _loadReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_readIdsKey) ?? <String>[];
    if (!mounted) return;
    setState(() => _readIds = list.toSet());
  }

  Future<void> _saveReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_readIdsKey, _readIds.toList());
    if (mounted) {
      context.read<AppProvider>().bumpNotificationFeedVersion();
    }
  }

  Future<void> _loadHiddenIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_hiddenIdsKey) ?? <String>[];
    if (!mounted) return;
    setState(() => _hiddenIds = list.toSet());
  }

  Future<void> _saveHiddenIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_hiddenIdsKey, _hiddenIds.toList());
    if (mounted) {
      context.read<AppProvider>().bumpNotificationFeedVersion();
    }
  }

  void _markAsRead(String id) {
    if (_readIds.contains(id)) return;
    setState(() => _readIds = {..._readIds, id});
    _saveReadIds();
  }

  Future<void> _markAllAsRead(List<_NotificationItem> items) async {
    final next = {..._readIds, ...items.map((e) => e.id)};
    setState(() => _readIds = next);
    await _saveReadIds();
  }

  Future<void> _hideNotification(String id) async {
    if (_hiddenIds.contains(id)) return;
    setState(() => _hiddenIds = {..._hiddenIds, id});
    await _saveHiddenIds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NaraColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: NaraColors.textPrimary),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(I18n.t(context, 'notifications'), style: NaraTextStyles.h3),
            const SizedBox(height: 2),
            Text(
              I18n.t(context, 'latest_messages'),
              style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final now = DateTime.now();
          final dueReminders = provider.activeRemindersList.where((r) {
            final scheduledAt = DateTime.tryParse(r['scheduledAt'] as String? ?? '');
            if (scheduledAt == null) return true;
            return !scheduledAt.isAfter(now);
          }).toList();

          final allItems = <_NotificationItem>[
            if (provider.reminderNotificationsEnabled) ...dueReminders.asMap().entries.map((entry) {
              final r = entry.value;
              final scheduledAt = DateTime.tryParse(r['scheduledAt'] as String? ?? '');
              final subtitle = scheduledAt == null
                  ? I18n.translateRelativeDate(
                      context,
                      r['date'] as String? ?? I18n.t(context, 'scheduled'),
                    )
                  : _formatReminderSubtitle(context, scheduledAt);
              final title = r['title'] as String? ?? 'Reminder';
              final detail = r['note'] as String? ?? r['type'] as String? ?? '-';
              final reminderIndex = provider.reminders.indexOf(r);
              final scheduleKey =
                  (r['scheduledAt'] as String?) ?? (r['date'] as String? ?? '');
              final id = NotificationFeedIds.reminderId(
                notificationId: r['notificationId'] as int? ?? reminderIndex,
                title: title,
                scheduleKey: scheduleKey,
                note: detail,
              );
              return _NotificationItem(
                id: id,
                type: _NotificationFilter.reminder,
                icon: Icons.notifications_active_rounded,
                color: NaraColors.primary,
                title: title,
                subtitle: subtitle,
                badge: I18n.t(context, 'reminder'),
                detail: detail,
                reminderIndex: reminderIndex >= 0 ? reminderIndex : null,
                sortTime: scheduledAt,
              );
            }),
            if (provider.debtNotificationsEnabled) ...provider.debts.take(8).toList().asMap().entries.map((entry) {
              final itemIndex = entry.key;
              final debt = entry.value;
              final isDebtOwed = (debt['type'] as String?) == 'utang';
              final person = (debt['title'] as String?)?.trim().isNotEmpty == true
                  ? (debt['title'] as String).trim()
                  : '-';
              final dueDate = (debt['dueDate'] as String?)?.trim() ?? '';
              final status = (debt['status'] as String?) ?? 'berjalan';
              final createdAt = debt['createdAt'];
              final subtitle = dueDate.isNotEmpty
                  ? '${I18n.t(context, 'due_date')}: $dueDate'
                  : _formatCreatedAtLabel(context, createdAt);
              final isEnglish = provider.language == 'English';
              final title = isDebtOwed
                  ? (isEnglish ? 'Debt (Mine) to $person' : 'Utang (Saya) kepada $person')
                  : (isEnglish ? 'Receivable (Mine) from $person' : 'Piutang (Saya) dari $person');
              final h1Raw = (debt['debtReminderH1At'] as String?) ?? '';
              final h0Raw = (debt['debtReminderH0At'] as String?) ?? '';
              final h1At = DateTime.tryParse(h1Raw);
              final h0At = DateTime.tryParse(h0Raw);
              final scheduleInfo = _formatDebtScheduleInfo(
                context: context,
                h1At: h1At,
                h0At: h0At,
                isEnglish: isEnglish,
              );
              final statusLabel = status == 'lunas'
                  ? (isEnglish ? 'Paid' : 'Lunas')
                  : (isEnglish ? 'Unpaid' : 'Belum lunas');
              final detail = 'Status: $statusLabel\n$scheduleInfo';
              final id = NotificationFeedIds.debtId(
                debtId: debt['debtId'] as int? ?? itemIndex,
                status: status,
                dueDate: dueDate,
              );
              return _NotificationItem(
                id: id,
                type: _NotificationFilter.debt,
                debtId: debt['debtId'] as int?,
                icon: isDebtOwed ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                color: isDebtOwed ? NaraColors.danger : NaraColors.success,
                title: title,
                subtitle: subtitle,
                badge: isEnglish ? 'Debt/Receivable' : 'Utang/Piutang',
                detail: detail,
                sortTime: _extractDebtSortTime(debt),
              );
            }),
            if (provider.transactionNotificationsEnabled) ...provider.expenses.take(8).toList().asMap().entries.map((entry) {
              final itemIndex = entry.key;
              final e = entry.value;
              final title = e['title'] as String? ?? I18n.t(context, 'transaction');
              final subtitle = I18n.translateRelativeDate(
                context,
                e['time'] as String? ?? I18n.t(context, 'just_now'),
              );
              final detail = '${I18n.t(context, 'expense')} ${formatRupiah((e['amount'] as num?) ?? 0)}';
              final id = NotificationFeedIds.expenseId(
                createdAt: e['createdAt'] ?? itemIndex,
                title: title,
              );
              return _NotificationItem(
                id: id,
                type: _NotificationFilter.transaction,
                icon: Icons.receipt_long_rounded,
                color: NaraColors.accentOrange,
                title: title,
                subtitle: subtitle,
                badge: I18n.t(context, 'message'),
                detail: detail,
              );
            }),
            if (provider.transactionNotificationsEnabled) ...provider.incomes.take(8).toList().asMap().entries.map((entry) {
              final itemIndex = entry.key;
              final i = entry.value;
              final title = i['title'] as String? ?? I18n.t(context, 'income');
              final subtitle = I18n.translateRelativeDate(
                context,
                i['time'] as String? ?? I18n.t(context, 'just_now'),
              );
              final detail = '${I18n.t(context, 'income')} ${formatRupiah((i['amount'] as num?) ?? 0)}';
              final id = NotificationFeedIds.incomeId(
                createdAt: i['createdAt'] ?? itemIndex,
                title: title,
              );
              return _NotificationItem(
                id: id,
                type: _NotificationFilter.transaction,
                icon: Icons.account_balance_wallet_rounded,
                color: NaraColors.success,
                title: title,
                subtitle: subtitle,
                badge: I18n.t(context, 'message'),
                detail: detail,
              );
            }),
          ];

          allItems.sort((a, b) {
            final aTime = a.sortTime ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.sortTime ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime); // newest first
          });

          final notHiddenItems = allItems.where((item) => !_hiddenIds.contains(item.id)).toList();
          final visibleItems = _selectedFilter == _NotificationFilter.all
              ? notHiddenItems
              : notHiddenItems.where((item) => item.type == _selectedFilter).toList();

          final unreadCount = visibleItems.where((item) => !_readIds.contains(item.id)).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(NaraSpacing.lg, NaraSpacing.sm, NaraSpacing.lg, NaraSpacing.lg),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      I18n.t(context, 'notif_unread_count', params: {'count': '$unreadCount'}),
                      style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
                    ),
                  ),
                  TextButton(
                    onPressed: visibleItems.isEmpty ? null : () => _markAllAsRead(visibleItems),
                    child: Text(
                      I18n.t(context, 'notif_mark_all_read'),
                      style: NaraTextStyles.caption.copyWith(color: NaraColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: NaraSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip(I18n.t(context, 'all'), _NotificationFilter.all),
                    const SizedBox(width: NaraSpacing.sm),
                    _filterChip(I18n.t(context, 'reminder'), _NotificationFilter.reminder),
                    const SizedBox(width: NaraSpacing.sm),
                    _filterChip(I18n.t(context, 'debt_receivable'), _NotificationFilter.debt),
                    const SizedBox(width: NaraSpacing.sm),
                    _filterChip(I18n.t(context, 'transaction'), _NotificationFilter.transaction),
                  ],
                ),
              ),
              const SizedBox(height: NaraSpacing.md),
              if (visibleItems.isEmpty)
                NaraEmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: I18n.t(context, 'no_notifications'),
                  message: I18n.t(context, 'notification_empty_msg'),
                  accentColor: NaraColors.primary,
                )
              else
                ..._buildGroupedNotificationList(
                  context: context,
                  provider: provider,
                  items: visibleItems,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterChip(String label, _NotificationFilter filter) {
    return NaraChip(
      label: label,
      selected: _selectedFilter == filter,
      onTap: () => setState(() => _selectedFilter = filter),
    );
  }

  String _formatReminderSubtitle(BuildContext context, DateTime scheduledAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
    final dayDiff = target.difference(today).inDays;
    final dayLabel = switch (dayDiff) {
      0 => I18n.t(context, 'today'),
      1 => I18n.t(context, 'tomorrow'),
      _ => MaterialLocalizations.of(context).formatShortDate(scheduledAt),
    };
    final timeLabel = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: scheduledAt.hour, minute: scheduledAt.minute),
      alwaysUse24HourFormat: true,
    );
    return '$dayLabel • $timeLabel';
  }

  DateTime? _extractDebtSortTime(Map<String, dynamic> debt) {
    final dueDateRaw = (debt['dueDate'] as String?)?.trim() ?? '';
    final dueDate = _parseIndonesianDate(dueDateRaw);
    if (dueDate != null) return dueDate;
    final createdAtRaw = debt['createdAt'];
    if (createdAtRaw is DateTime) return createdAtRaw;
    if (createdAtRaw is String) return DateTime.tryParse(createdAtRaw);
    return null;
  }

  DateTime? _parseIndonesianDate(String raw) {
    if (raw.isEmpty) return null;
    final normalized = raw.replaceAll(',', '').trim();
    final match = RegExp(r'^(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})$').firstMatch(normalized);
    if (match == null) return DateTime.tryParse(raw);
    final day = int.tryParse(match.group(1) ?? '');
    final monthName = (match.group(2) ?? '').toLowerCase();
    final year = int.tryParse(match.group(3) ?? '');
    if (day == null || year == null) return null;
    const months = <String, int>{
      'jan': 1,
      'januari': 1,
      'feb': 2,
      'februari': 2,
      'mar': 3,
      'maret': 3,
      'apr': 4,
      'april': 4,
      'mei': 5,
      'jun': 6,
      'juni': 6,
      'jul': 7,
      'juli': 7,
      'agu': 8,
      'agustus': 8,
      'sep': 9,
      'september': 9,
      'okt': 10,
      'oktober': 10,
      'nov': 11,
      'november': 11,
      'des': 12,
      'desember': 12,
    };
    final month = months[monthName];
    if (month == null) return null;
    return DateTime(year, month, day);
  }

  String _formatCreatedAtLabel(BuildContext context, dynamic rawCreatedAt) {
    DateTime? createdAt;
    if (rawCreatedAt is DateTime) {
      createdAt = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      createdAt = DateTime.tryParse(rawCreatedAt);
    }
    if (createdAt == null) return I18n.t(context, 'just_now');
    final dateLabel = MaterialLocalizations.of(context).formatMediumDate(createdAt);
    final timeLabel = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: createdAt.hour, minute: createdAt.minute),
      alwaysUse24HourFormat: true,
    );
    return '$dateLabel • $timeLabel';
  }

  String _formatDebtScheduleInfo({
    required BuildContext context,
    required DateTime? h1At,
    required DateTime? h0At,
    required bool isEnglish,
  }) {
    String fmt(DateTime dt) {
      final date = MaterialLocalizations.of(context).formatMediumDate(dt);
      final time = MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay(hour: dt.hour, minute: dt.minute),
        alwaysUse24HourFormat: true,
      );
      return '$date • $time';
    }

    final items = <String>[];
    if (h1At != null) items.add('H-1: ${fmt(h1At)}');
    if (h0At != null) items.add('H-0: ${fmt(h0At)}');
    if (items.isEmpty) {
      return isEnglish ? 'Schedule D-1/D-0: not set' : 'Jadwal H-1/H-0: belum diatur';
    }
    return isEnglish ? 'Scheduled ${items.join(' | ')}' : 'Terjadwal ${items.join(' | ')}';
  }

  void _showNotificationDetail(BuildContext context, _NotificationItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(NaraSpacing.lg),
          child: NaraCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: item.color),
                    ),
                    const SizedBox(width: NaraSpacing.md),
                    Expanded(child: Text(item.title, style: NaraTextStyles.h3)),
                  ],
                ),
                const SizedBox(height: NaraSpacing.md),
                Text(item.subtitle, style: NaraTextStyles.body.copyWith(color: NaraColors.textSecondary)),
                const SizedBox(height: NaraSpacing.sm),
                Text(item.detail, style: NaraTextStyles.body),
                const SizedBox(height: NaraSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildGroupedNotificationList({
    required BuildContext context,
    required AppProvider provider,
    required List<_NotificationItem> items,
  }) {
    final groups = <String, List<_NotificationItem>>{
      I18n.t(context, 'notif_group_today'): [],
      I18n.t(context, 'notif_group_yesterday'): [],
      I18n.t(context, 'notif_group_this_week'): [],
      I18n.t(context, 'notif_group_older'): [],
    };

    for (final item in items) {
      final key = _timeGroupLabel(item.sortTime);
      groups[key]!.add(item);
    }

    final widgets = <Widget>[];
    for (final entry in groups.entries) {
      if (entry.value.isEmpty) continue;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: NaraSpacing.sm, top: NaraSpacing.xs),
          child: Text(
            entry.key,
            style: NaraTextStyles.caption.copyWith(
              color: NaraColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
      widgets.addAll(entry.value.map((item) => _notificationTile(context, item)).toList());
    }
    return widgets;
  }

  Widget _notificationTile(BuildContext context, _NotificationItem item) {
    final isRead = _readIds.contains(item.id);
    return Dismissible(
      key: ValueKey(item.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: NaraSpacing.sm),
        decoration: BoxDecoration(
          color: NaraColors.success.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: NaraSpacing.lg),
        child: Row(
          children: [
            const Icon(Icons.mark_email_read_rounded, color: NaraColors.success),
            const SizedBox(width: 8),
            Text(
              I18n.t(context, 'notif_mark_read'),
              style: NaraTextStyles.bodySmall.copyWith(color: NaraColors.success),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: NaraSpacing.sm),
        decoration: BoxDecoration(
          color: NaraColors.danger.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: NaraSpacing.lg),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              I18n.t(context, 'notif_remove'),
              style: NaraTextStyles.bodySmall.copyWith(color: NaraColors.danger),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.delete_outline_rounded, color: NaraColors.danger),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        final markedReadText = I18n.t(context, 'notif_marked_read');
        if (direction == DismissDirection.startToEnd) {
          _markAsRead(item.id);
          if (context.mounted) {
            showAppSnackBar(
              context,
              content: Text(markedReadText),
            );
          }
          return false;
        }
        return true;
      },
      onDismissed: (direction) async {
        final removedText = I18n.t(context, 'notif_removed_from_feed');
        await _hideNotification(item.id);
        if (!context.mounted) return;
        showAppSnackBar(
          context,
          content: Text(removedText),
        );
      },
      child: GestureDetector(
        onTap: () {
          _markAsRead(item.id);
          _showNotificationDetail(context, item);
        },
        child: NaraCard(
          margin: const EdgeInsets.only(bottom: NaraSpacing.sm),
          backgroundColor: isRead
              ? NaraColors.surfaceWhite
              : NaraColors.primary.withValues(alpha: 0.05),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color),
              ),
              const SizedBox(width: NaraSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: NaraTextStyles.label.copyWith(
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                      ),
                    ),
                    Text(item.subtitle, style: NaraTextStyles.bodySmall),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: const BoxDecoration(
                    color: NaraColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              NaraBadge(label: item.badge),
            ],
          ),
        ),
      ),
    );
  }

  String _timeGroupLabel(DateTime? when) {
    if (when == null) return I18n.t(context, 'notif_group_older');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(when.year, when.month, when.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return I18n.t(context, 'notif_group_today');
    if (diff == 1) return I18n.t(context, 'notif_group_yesterday');
    if (diff <= 7) return I18n.t(context, 'notif_group_this_week');
    return I18n.t(context, 'notif_group_older');
  }
}

class _NotificationItem {
  final String id;
  final _NotificationFilter type;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String badge;
  final String detail;
  final DateTime? sortTime;
  final int? reminderIndex;
  final int? debtId;

  const _NotificationItem({
    required this.id,
    required this.type,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.detail,
    this.sortTime,
    this.reminderIndex,
    this.debtId,
  });
}
