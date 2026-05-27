import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../components/index.dart';
import '../../core/formatters.dart';
import '../../core/i18n.dart';
import '../../core/snackbar_utils.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';

enum _HistoryPeriod { all, week, month, year }

class HistoryScreen extends StatefulWidget {
  final int initialTab;

  const HistoryScreen({super.key, this.initialTab = 0});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  _HistoryPeriod _period = _HistoryPeriod.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: Text(I18n.t(context, 'history'), style: NaraTextStyles.h3),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            height: 44,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            decoration: BoxDecoration(
              color: NaraColors.surfaceCard,
              borderRadius: BorderRadius.circular(NaraRadius.md),
              border: Border.all(
                color: NaraColors.textHint.withValues(alpha: 0.35),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: NaraColors.primaryLight,
                borderRadius: BorderRadius.circular(NaraRadius.sm),
                border: Border.all(
                  color: NaraColors.primary.withValues(alpha: 0.55),
                ),
              ),
              labelColor: NaraColors.primary,
              unselectedLabelColor: NaraColors.textSecondary,
              labelStyle: NaraTextStyles.label.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              unselectedLabelStyle: NaraTextStyles.label.copyWith(fontSize: 12),
              tabs: [
                Tab(text: I18n.t(context, 'expense')),
                Tab(text: I18n.t(context, 'income')),
                Tab(text: I18n.t(context, 'debt_receivable_tab')),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _PeriodChip(
                      label: I18n.t(context, 'all'),
                      selected: _period == _HistoryPeriod.all,
                      onTap: () => setState(() => _period = _HistoryPeriod.all),
                    ),
                    const SizedBox(width: 8),
                    _PeriodChip(
                      label: I18n.t(context, 'this_week'),
                      selected: _period == _HistoryPeriod.week,
                      onTap: () => setState(() => _period = _HistoryPeriod.week),
                    ),
                    const SizedBox(width: 8),
                    _PeriodChip(
                      label: I18n.t(context, 'this_month'),
                      selected: _period == _HistoryPeriod.month,
                      onTap: () => setState(() => _period = _HistoryPeriod.month),
                    ),
                    const SizedBox(width: 8),
                    _PeriodChip(
                      label: I18n.t(context, 'this_year'),
                      selected: _period == _HistoryPeriod.year,
                      onTap: () => setState(() => _period = _HistoryPeriod.year),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _HistoryList(
                    provider: provider,
                    items: provider.expenses,
                    emptyText: I18n.t(context, 'no_expense'),
                    amountPrefix: '-',
                    amountColor: NaraColors.danger,
                    period: _period,
                    mode: _HistoryType.expense,
                    swipeEnabled: provider.transactionSwipeEnabled,
                  ),
                  _HistoryList(
                    provider: provider,
                    items: provider.incomes,
                    emptyText: I18n.t(context, 'no_income'),
                    amountPrefix: '+',
                    amountColor: NaraColors.success,
                    period: _period,
                    mode: _HistoryType.income,
                    swipeEnabled: provider.transactionSwipeEnabled,
                  ),
                  _HistoryList(
                    provider: provider,
                    items: provider.debts,
                    emptyText: I18n.t(context, 'no_debt_filter'),
                    amountPrefix: '',
                    amountColor: NaraColors.primary,
                    period: _period,
                    mode: _HistoryType.debt,
                    swipeEnabled: provider.transactionSwipeEnabled,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _HistoryType { expense, income, debt }

class _HistoryList extends StatelessWidget {
  final AppProvider provider;
  final List<Map<String, dynamic>> items;
  final String emptyText;
  final String amountPrefix;
  final Color amountColor;
  final _HistoryPeriod period;
  final _HistoryType mode;
  final bool swipeEnabled;

  const _HistoryList({
    required this.provider,
    required this.items,
    required this.emptyText,
    required this.amountPrefix,
    required this.amountColor,
    required this.period,
    required this.mode,
    required this.swipeEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = items.where((item) => _isInPeriod(_createdAt(item), period)).toList()
      ..sort((a, b) => _createdAt(b).compareTo(_createdAt(a)));

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: NaraTextStyles.body.copyWith(color: NaraColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final sourceIndex = items.indexOf(item);
        if (sourceIndex < 0) return const SizedBox.shrink();

        final title = (item['title'] as String?) ?? '-';
        final subtitle = (item['time'] as String?) ??
            (item['date'] as String?) ??
            (item['dueDate'] as String?) ??
            '-';

        final isDebt = mode == _HistoryType.debt;
        final amount = isDebt
            ? ((item['amount'] as num?)?.toInt() ?? 0) -
                ((item['paidAmount'] as num?)?.toInt() ?? 0)
            : (item['amount'] as num?) ?? 0;

        final card = NaraCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          backgroundColor: NaraColors.surfaceWhite,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: NaraColors.surfaceCard,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDebt ? Icons.handshake_rounded : Icons.work_outline_rounded,
                  size: 20,
                  color: NaraColors.primary,
                ),
              ),
              const SizedBox(width: 12),
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
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NaraTextStyles.bodySmall.copyWith(
                        color: NaraColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$amountPrefix${formatRupiah(amount)}',
                style: NaraTextStyles.label.copyWith(
                  fontWeight: FontWeight.w700,
                  color: amountColor,
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    await _showEditDialog(
                      context: context,
                      provider: provider,
                      mode: mode,
                      sourceIndex: sourceIndex,
                      item: item,
                    );
                  } else if (value == 'delete') {
                    if (!context.mounted) return;
                    _deleteWithUndo(
                      context: context,
                      provider: provider,
                      mode: mode,
                      index: sourceIndex,
                      payload: item,
                    );
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Text(I18n.t(context, 'edit'))),
                  PopupMenuItem(value: 'delete', child: Text(I18n.t(context, 'delete'))),
                ],
              ),
            ],
          ),
        );

        if (!swipeEnabled) {
          return card;
        }

        return Dismissible(
          key: ValueKey('history-${mode.name}-$sourceIndex-$title'),
          direction: DismissDirection.horizontal,
          background: const _SwipeBg(
            icon: Icons.edit_rounded,
            label: 'Edit',
            alignment: Alignment.centerLeft,
            color: NaraColors.primary,
          ),
          secondaryBackground: const _SwipeBg(
            icon: Icons.delete_outline_rounded,
            label: 'Hapus',
            alignment: Alignment.centerRight,
            color: NaraColors.danger,
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              await _showEditDialog(
                context: context,
                provider: provider,
                mode: mode,
                sourceIndex: sourceIndex,
                item: item,
              );
            } else {
              if (!context.mounted) return false;
              _deleteWithUndo(
                context: context,
                provider: provider,
                mode: mode,
                index: sourceIndex,
                payload: item,
              );
            }
            return false;
          },
          child: card,
        );
      },
    );
  }

  void _deleteWithUndo({
    required BuildContext context,
    required AppProvider provider,
    required _HistoryType mode,
    required int index,
    required Map<String, dynamic> payload,
  }) {
    final snapshot = Map<String, dynamic>.from(payload);
    _deleteItem(provider, mode, index);
    final isEnglish = provider.language == 'English';
    showDeleteSnackBarWithDelayedUndo(
      context,
      deletedContent: Text(
        isEnglish ? 'Data deleted.' : 'Data dihapus.',
      ),
      undoContent: Text(
        isEnglish ? 'Undo delete?' : 'Urungkan penghapusan?',
      ),
      undoLabel: isEnglish ? 'Undo' : 'Urungkan',
      undoTextColor: NaraColors.primary,
      undoDuration: const Duration(seconds: 5),
      onUndo: () {
        if (mode == _HistoryType.expense) {
          provider.restoreExpenseAt(index, snapshot);
        } else if (mode == _HistoryType.income) {
          provider.restoreIncomeAt(index, snapshot);
        } else {
          provider.restoreDebtAt(index, snapshot);
        }
      },
    );
  }

  void _deleteItem(AppProvider provider, _HistoryType mode, int index) {
    if (mode == _HistoryType.expense) {
      provider.removeExpenseAt(index);
    } else if (mode == _HistoryType.income) {
      provider.removeIncomeAt(index);
    } else {
      provider.removeDebtAt(index);
    }
  }

  Future<void> _showEditDialog({
    required BuildContext context,
    required AppProvider provider,
    required _HistoryType mode,
    required int sourceIndex,
    required Map<String, dynamic> item,
  }) async {
    final title = TextEditingController(text: (item['title'] as String?) ?? '');
    final amount = TextEditingController(
      text: _formatCurrency(((item['amount'] as num?)?.toInt() ?? 0)),
    );
    final note = TextEditingController(text: (item['note'] as String?) ?? '');
    final isDebt = mode == _HistoryType.debt;
    final isEnglish = provider.language == 'English';
    final typeNotifier = ValueNotifier<String>(
      (item['type'] as String?) == 'piutang' ? 'piutang' : 'utang',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEnglish ? 'Edit Data' : 'Edit Data'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isDebt) ...[
                ValueListenableBuilder<String>(
                  valueListenable: typeNotifier,
                  builder: (context, debtType, _) => DropdownButtonFormField<String>(
                    initialValue: debtType,
                    items: [
                      DropdownMenuItem(value: 'utang', child: Text(isEnglish ? 'My Debt' : 'Saya Berhutang')),
                      DropdownMenuItem(value: 'piutang', child: Text(isEnglish ? 'My Receivable' : 'Piutang Saya')),
                    ],
                    onChanged: (value) {
                      if (value != null) typeNotifier.value = value;
                    },
                    decoration: InputDecoration(labelText: isEnglish ? 'Type' : 'Jenis'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: title,
                decoration: InputDecoration(labelText: isEnglish ? 'Name' : 'Nama'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                inputFormatters: [_ThousandsSeparatorInputFormatter()],
                decoration: const InputDecoration(labelText: 'Nominal', prefixText: 'Rp '),
              ),
              if (isDebt) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: note,
                  decoration: InputDecoration(labelText: isEnglish ? 'Note' : 'Catatan'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(I18n.t(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(I18n.t(context, 'save')),
          ),
        ],
      ),
    );

    if (ok != true) {
      title.dispose();
      amount.dispose();
      note.dispose();
      typeNotifier.dispose();
      return;
    }

    final parsedAmount = parseRupiahInput(amount.text);
    if (title.text.trim().isEmpty || parsedAmount <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEnglish ? 'Invalid input.' : 'Input tidak valid.')),
        );
      }
      title.dispose();
      amount.dispose();
      note.dispose();
      typeNotifier.dispose();
      return;
    }

    final updated = Map<String, dynamic>.from(item)
      ..['title'] = title.text.trim()
      ..['amount'] = parsedAmount;
    if (isDebt) {
      updated['type'] = typeNotifier.value;
      updated['note'] = note.text.trim();
    }

    if (mode == _HistoryType.expense) {
      provider.updateExpenseAt(sourceIndex, updated);
    } else if (mode == _HistoryType.income) {
      provider.updateIncomeAt(sourceIndex, updated);
    } else {
      provider.updateDebtAt(sourceIndex, updated);
    }

    title.dispose();
    amount.dispose();
    note.dispose();
    typeNotifier.dispose();
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NaraChip(
      label: label,
      selected: selected,
      onTap: onTap,
    );
  }
}

class _SwipeBg extends StatelessWidget {
  final IconData icon;
  final String label;
  final Alignment alignment;
  final Color color;

  const _SwipeBg({
    required this.icon,
    required this.label,
    required this.alignment,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(NaraRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isLeft) ...[
            Text(label, style: NaraTextStyles.label.copyWith(color: color)),
            const SizedBox(width: 8),
          ],
          Icon(icon, color: color, size: 20),
          if (isLeft) ...[
            const SizedBox(width: 8),
            Text(label, style: NaraTextStyles.label.copyWith(color: color)),
          ],
        ],
      ),
    );
  }
}

DateTime _createdAt(Map<String, dynamic> item) {
  final value = item['createdAt'];
  if (value is DateTime) return value;
  return DateTime.fromMillisecondsSinceEpoch(0);
}

bool _isInPeriod(DateTime date, _HistoryPeriod period) {
  if (period == _HistoryPeriod.all) return true;
  final now = DateTime.now();
  if (period == _HistoryPeriod.year) {
    return date.year == now.year;
  }
  if (period == _HistoryPeriod.month) {
    return date.year == now.year && date.month == now.month;
  }
  final startOfWeek = DateTime(now.year, now.month, now.day).subtract(
    Duration(days: now.weekday - 1),
  );
  final endOfWeek = startOfWeek.add(const Duration(days: 7));
  return !date.isBefore(startOfWeek) && date.isBefore(endOfWeek);
}

String _formatCurrency(int amount) {
  return amount.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match.group(1)}.',
      );
}

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final formatted = digitsOnly.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)}.',
    );
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
