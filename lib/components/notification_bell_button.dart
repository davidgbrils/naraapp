import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_provider.dart';
import '../screens/notifications/notification_feed_ids.dart';

class NotificationBellButton extends StatefulWidget {
  final Color iconColor;
  final String? tooltip;
  final EdgeInsetsGeometry? padding;

  const NotificationBellButton({
    super.key,
    required this.iconColor,
    this.tooltip,
    this.padding,
  });

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton> {
  static const String _readIdsKey = 'notification_center_read_ids_v1';
  static const String _hiddenIdsKey = 'notification_center_hidden_ids_v1';
  Set<String> _readIds = <String>{};
  Set<String> _hiddenIds = <String>{};
  int _seenFeedVersion = -1;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final read = prefs.getStringList(_readIdsKey) ?? <String>[];
    final hidden = prefs.getStringList(_hiddenIdsKey) ?? <String>[];
    if (!mounted) return;
    setState(() {
      _readIds = read.toSet();
      _hiddenIds = hidden.toSet();
    });
  }

  bool _hasUnread(AppProvider provider) {
    final now = DateTime.now();
    final ids = <String>{};

    if (provider.reminderNotificationsEnabled) {
      final dueReminders = provider.activeRemindersList.where((r) {
        final scheduledAt = DateTime.tryParse(r['scheduledAt'] as String? ?? '');
        if (scheduledAt == null) return true;
        return !scheduledAt.isAfter(now);
      });

      for (final r in dueReminders) {
        final itemIndex = provider.reminders.indexOf(r);
        final title = r['title'] as String? ?? 'Reminder';
        final note = r['note'] as String? ?? r['type'] as String? ?? '-';
        final scheduleKey = (r['scheduledAt'] as String?) ?? (r['date'] as String? ?? '');
        ids.add(
          NotificationFeedIds.reminderId(
            notificationId: r['notificationId'] as int? ?? itemIndex,
            title: title,
            scheduleKey: scheduleKey,
            note: note,
          ),
        );
      }
    }

    if (provider.debtNotificationsEnabled) {
      for (final debt in provider.debts.take(8)) {
        final itemIndex = provider.debts.indexOf(debt);
        final status = (debt['status'] as String?) ?? 'berjalan';
        final dueDate = (debt['dueDate'] as String?)?.trim() ?? '';
        ids.add(
          NotificationFeedIds.debtId(
            debtId: debt['debtId'] as int? ?? itemIndex,
            status: status,
            dueDate: dueDate,
          ),
        );
      }
    }

    if (provider.transactionNotificationsEnabled) {
      for (final e in provider.expenses.take(8)) {
        final itemIndex = provider.expenses.indexOf(e);
        ids.add(
          NotificationFeedIds.expenseId(
            createdAt: e['createdAt'] ?? itemIndex,
            title: e['title'] as String? ?? 'transaction',
          ),
        );
      }
      for (final i in provider.incomes.take(8)) {
        final itemIndex = provider.incomes.indexOf(i);
        ids.add(
          NotificationFeedIds.incomeId(
            createdAt: i['createdAt'] ?? itemIndex,
            title: i['title'] as String? ?? 'income',
          ),
        );
      }
    }

    final visibleIds = ids.where((id) => !_hiddenIds.contains(id));
    return visibleIds.any((id) => !_readIds.contains(id));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    if (_seenFeedVersion != provider.notificationFeedVersion) {
      _seenFeedVersion = provider.notificationFeedVersion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadState();
      });
    }
    final hasUnread = _hasUnread(provider);

    return Tooltip(
      message: widget.tooltip ?? '',
      child: IconButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/notifications');
          await _loadState();
        },
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.notifications_outlined, color: widget.iconColor),
            if (hasUnread)
              Positioned(
                top: -1,
                right: -1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.2),
                  ),
                ),
              ),
          ],
        ),
        padding: widget.padding,
      ),
    );
  }
}
