// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/i18n.dart';
import '../../core/formatters.dart';
import '../../core/snackbar_utils.dart';
import '../../core/theme.dart';
import '../../components/index.dart';
import '../../providers/app_provider.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  _TransactionFilterPreset _expenseFilter = _TransactionFilterPreset.month;
  _TransactionFilterPreset _incomeFilter = _TransactionFilterPreset.month;
  _DebtFilter _debtFilter = _DebtFilter.all;
  _DebtTypeFilter _debtTypeFilter = _DebtTypeFilter.all;
  _DebtDueFilter _debtDueFilter = _DebtDueFilter.all;
  bool _debtFilterExpanded = false;
  DateTime? _expenseCustomDate;
  DateTime? _incomeCustomDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      final provider = context.read<AppProvider>();
      provider.setTransactionTabIndex(_tabController.index, notify: false);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeProvider = context.watch<AppProvider>();
    final desiredTabIndex = activeProvider.transactionTabIndex.clamp(0, 2);
    if (_tabController.index != desiredTabIndex && !_tabController.indexIsChanging) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _tabController.animateTo(desiredTabIndex);
      });
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    String tr(String idText, String enText) => _tr(context, activeProvider, idText, enText);
    final languageCode = activeProvider.language == 'English' ? 'en' : 'id';
    final tabIndex = _tabController.index;
    final addRoute = switch (tabIndex) {
      1 => '/add-income',
      2 => '/add-debt',
      _ => '/add-expense',
    };
    final addLabel = switch (tabIndex) {
      1 => I18n.tByCode(languageCode, 'add_income'),
      2 => I18n.tByCode(languageCode, 'add_debt'),
      _ => I18n.tByCode(languageCode, 'add_expense'),
    };

    return Scaffold(
      backgroundColor: NaraColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const SizedBox.shrink(),
        leadingWidth: 0,
        title: Semantics(
          label: tr('Menu Keuangan', 'Finance menu'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tr('Keuangan', 'Finance'), style: NaraTextStyles.h3),
              const SizedBox(height: 2),
              Text(
                tr('Ringkasan transaksi harian', 'Your daily transaction summary'),
                style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: I18n.t(context, 'history'),
            onPressed: () => Navigator.pushNamed(
              context,
              '/history',
              arguments: {'tab': 'expense'},
            ),
          ),
          NotificationBellButton(
            iconColor: scheme.onSurface,
            tooltip: tr('Lihat notifikasi', 'View notifications'),
          ),
          const SizedBox(width: 8),
        ],
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
              labelStyle: NaraTextStyles.label.copyWith(fontWeight: FontWeight.w700, fontSize: 12),
              unselectedLabelStyle: NaraTextStyles.label.copyWith(fontSize: 12),
              tabs: [
                Tab(text: tr('Pengeluaran', 'Expenses')),
                Tab(text: tr('Pemasukan', 'Income')),
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      tr('Utang/Piutang', 'Debt/Receivable'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildExpenseTab(context, provider),
              _buildIncomeTab(context, provider),
              _buildDebtTab(context, provider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.pushNamed(context, addRoute);
        },
        backgroundColor: scheme.primary,
        shape: const CircleBorder(),
        tooltip: addLabel,
        child: Semantics(
          button: true,
          enabled: true,
          label: addLabel,
          child: Icon(Icons.add_rounded, color: scheme.onPrimary, size: 30),
        ),
      ),
    );
  }

  Widget _buildExpenseTab(BuildContext context, AppProvider provider) {
    String tr(String idText, String enText) => _tr(context, provider, idText, enText);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bodyStyle = NaraTextStyles.body;
    final titleStyle = NaraTextStyles.h3;
    final displayStyle = NaraTextStyles.h1;
    final isCompact = MediaQuery.of(context).size.width < 380;
    final filteredExpenses = _filterTransactions(
      provider.expenses,
      _expenseFilter,
      _expenseCustomDate,
    );
    final totalExpense = filteredExpenses.fold<num>(0, (sum, item) => sum + ((item['amount'] as num?) ?? 0));
    final budget = provider.monthlyBudget;
    final progress = budget > 0 ? (totalExpense / budget) : 0.0;

    final expenseCategoryTotals = _buildCategoryTotals(filteredExpenses, tr);
    final sortedExpenseCategories = _sortCategoryTotals(expenseCategoryTotals);
    final expenseCategoryPercentages =
        _buildCategoryPercentages(sortedExpenseCategories, totalExpense);
    final categoryColors = [
      NaraColors.primary,
      NaraColors.accentOrange,
      NaraColors.accentPurple,
      NaraColors.success,
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: tr('Bulan Ini', 'This Month'),
                  isSelected: _expenseFilter == _TransactionFilterPreset.month,
                  onTap: () => setState(() => _expenseFilter = _TransactionFilterPreset.month),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: tr('Minggu Ini', 'This Week'),
                  isSelected: _expenseFilter == _TransactionFilterPreset.week,
                  onTap: () => setState(() => _expenseFilter = _TransactionFilterPreset.week),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: tr('Tahun Ini', 'This Year'),
                  isSelected: _expenseFilter == _TransactionFilterPreset.year,
                  onTap: () => setState(() => _expenseFilter = _TransactionFilterPreset.year),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: _expenseCustomDate == null ? tr('Pilih Tanggal', 'Pick Date') : _formatDateLabel(context, _expenseCustomDate!),
                  isSelected: _expenseFilter == _TransactionFilterPreset.custom,
                  onTap: () => _pickCustomDate(
                    context: context,
                    currentDate: _expenseCustomDate,
                    onSelected: (date) {
                      setState(() {
                        _expenseFilter = _TransactionFilterPreset.custom;
                        _expenseCustomDate = date;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          NaraCard(
            padding: EdgeInsets.all(isCompact ? 16 : 20),
            borderRadius: NaraRadius.lg,
            backgroundColor: NaraColors.surfaceWhite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Total Pengeluaran', 'Total Expenses'),
                  style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(formatRupiah(totalExpense), style: displayStyle),
                const SizedBox(height: 20),
                if (budget > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${I18n.t(context, 'monthly_budget')}: ${formatRupiah(budget)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${tr('Terpakai', 'Used')} ${(progress.clamp(0, 1) * 100).toStringAsFixed(0)}%',
                        style: NaraTextStyles.label.copyWith(color: NaraColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0, 1),
                      minHeight: 8,
                      backgroundColor: NaraColors.textHint.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(NaraColors.primary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr('Dihitung dari total pengeluaran pada periode aktif.', 'Calculated from total expenses in current period.'),
                    style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _showBudgetDialog(context, provider),
                      child: Text(
                        I18n.t(context, 'edit_budget'),
                        style: NaraTextStyles.label.copyWith(color: NaraColors.primary),
                      ),
                    ),
                  ),
                ] else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: NaraColors.surfaceCard,
                      borderRadius: BorderRadius.circular(NaraRadius.md),
                      border: Border.all(color: NaraColors.textHint.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      I18n.t(context, 'no_budget_set'),
                      style: NaraTextStyles.bodySmall.copyWith(
                        color: NaraColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (budget <= 0)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _showBudgetDialog(context, provider),
                      child: Text(
                        I18n.t(context, 'set_budget'),
                        style: NaraTextStyles.label.copyWith(color: NaraColors.primary),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          NaraCard(
            padding: EdgeInsets.all(isCompact ? 16 : 20),
            borderRadius: NaraRadius.lg,
            backgroundColor: NaraColors.surfaceWhite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Kategori', 'Categories'), style: titleStyle),
                const SizedBox(height: 20),
                _buildCategoryChartRow(
                  sortedCategories: sortedExpenseCategories,
                  categoryPercentages: expenseCategoryPercentages,
                  colors: categoryColors,
                  scheme: scheme,
                  bodyStyle: bodyStyle,
                  emptyText: tr('Belum ada pengeluaran', 'No expenses yet'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  tr('Riwayat', 'History'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NaraTextStyles.h3,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/history',
                  arguments: {'tab': 'expense'},
                ),
                child: Text(tr('Lihat Semua', 'See All'),
                    style: NaraTextStyles.label.copyWith(color: NaraColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _filterDescription(context, _expenseFilter, _expenseCustomDate),
            style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary),
          ),
          const SizedBox(height: 8),
          if (provider.transactionSwipeEnabled)
            Row(
              children: [
                Icon(Icons.swipe_rounded, size: 14, color: NaraColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    I18n.t(context, 'transaction_swipe_actions_subtitle'),
                    style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          if (filteredExpenses.isEmpty)
            NaraCard(
              padding: EdgeInsets.all(isCompact ? 16 : 20),
              borderRadius: NaraRadius.lg,
              backgroundColor: NaraColors.surfaceWhite,
              child: Center(
                child: Text(
                  tr('Belum ada pengeluaran pada filter ini', 'No expenses for this filter'),
                  style: NaraTextStyles.body.copyWith(color: NaraColors.textSecondary),
                ),
              ),
            )
          else
            ...filteredExpenses.map(
              (expense) {
                final originalIndex = provider.expenses.indexOf(expense);
                return _TransactionItem(
                  itemKey: ValueKey('expense-$originalIndex-${expense['title'] ?? ''}'),
                  swipeEnabled: provider.transactionSwipeEnabled,
                  icon: _iconFromName(expense['icon'] as String? ?? 'shopping_bag'),
                  title: expense['title'] as String? ?? '-',
                  subtitle: expense['time'] as String? ?? '-',
                  amount: '-${formatRupiah((expense['amount'] as num?) ?? 0)}',
                  amountColor: NaraColors.textPrimary,
                  onSwipeStartToEnd: originalIndex >= 0
                      ? () => _showEditExpenseDialog(
                            context: context,
                            provider: provider,
                            index: originalIndex,
                          )
                      : null,
                  onSwipeEndToStart: originalIndex >= 0
                      ? () => _confirmDeleteHistoryItem(
                            context: context,
                            provider: provider,
                            type: _HistoryDeleteType.expense,
                            index: originalIndex,
                          )
                      : null,
                  onDelete: originalIndex >= 0
                      ? () => _confirmDeleteHistoryItem(
                            context: context,
                            provider: provider,
                            type: _HistoryDeleteType.expense,
                            index: originalIndex,
                          )
                      : null,
                  onTap: originalIndex >= 0
                      ? () => _showEditExpenseDialog(
                            context: context,
                            provider: provider,
                            index: originalIndex,
                          )
                      : null,
                );
              },
            ),
          const SizedBox(height: 72),
        ],
      ),
    );
  }

  Widget _buildIncomeTab(BuildContext context, AppProvider provider) {
    String tr(String idText, String enText) => _tr(context, provider, idText, enText);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bodyStyle = NaraTextStyles.body;
    final titleStyle = NaraTextStyles.h3;
    final displayStyle = NaraTextStyles.h1;
    final isCompact = MediaQuery.of(context).size.width < 380;
    final filteredIncomes = _filterTransactions(
      provider.incomes,
      _incomeFilter,
      _incomeCustomDate,
    );
    final totalIncome = filteredIncomes.fold<num>(0, (sum, item) => sum + ((item['amount'] as num?) ?? 0));
    final incomeCategoryTotals = _buildCategoryTotals(filteredIncomes, tr);
    final sortedIncomeCategories = _sortCategoryTotals(incomeCategoryTotals);
    final incomeCategoryPercentages =
        _buildCategoryPercentages(sortedIncomeCategories, totalIncome);
    final categoryColors = [
      NaraColors.primary,
      NaraColors.accentOrange,
      NaraColors.accentPurple,
      NaraColors.success,
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: tr('Minggu Ini', 'This Week'),
                  isSelected: _incomeFilter == _TransactionFilterPreset.week,
                  onTap: () => setState(() => _incomeFilter = _TransactionFilterPreset.week),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: tr('Bulan Ini', 'This Month'),
                  isSelected: _incomeFilter == _TransactionFilterPreset.month,
                  onTap: () => setState(() => _incomeFilter = _TransactionFilterPreset.month),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: tr('Tahun Ini', 'This Year'),
                  isSelected: _incomeFilter == _TransactionFilterPreset.year,
                  onTap: () => setState(() => _incomeFilter = _TransactionFilterPreset.year),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: _incomeCustomDate == null ? tr('Custom', 'Custom') : _formatDateLabel(context, _incomeCustomDate!),
                  isSelected: _incomeFilter == _TransactionFilterPreset.custom,
                  onTap: () => _pickCustomDate(
                    context: context,
                    currentDate: _incomeCustomDate,
                    onSelected: (date) {
                      setState(() {
                        _incomeFilter = _TransactionFilterPreset.custom;
                        _incomeCustomDate = date;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          NaraCard(
            padding: EdgeInsets.all(isCompact ? 16 : 20),
            borderRadius: NaraRadius.lg,
            backgroundColor: NaraColors.surfaceWhite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Total Pemasukan', 'Total Income'),
                  style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(formatRupiah(totalIncome), style: displayStyle.copyWith(color: NaraColors.primary)),
                const SizedBox(height: 8),
                Text(
                  _filterDescription(context, _incomeFilter, _incomeCustomDate),
                  style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          NaraCard(
            padding: EdgeInsets.all(isCompact ? 16 : 20),
            borderRadius: NaraRadius.lg,
            backgroundColor: NaraColors.surfaceWhite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Sumber Pemasukan', 'Income Sources'), style: titleStyle),
                const SizedBox(height: 20),
                _buildCategoryChartRow(
                  sortedCategories: sortedIncomeCategories,
                  categoryPercentages: incomeCategoryPercentages,
                  colors: categoryColors,
                  scheme: scheme,
                  bodyStyle: bodyStyle,
                  emptyText: tr('Belum ada pemasukan', 'No income yet'),
                  icon: Icons.wallet_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  tr('Riwayat Pemasukan', 'Income History'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NaraTextStyles.h3,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/history',
                  arguments: {'tab': 'income'},
                ),
                child: Text(
                  tr('Lihat Semua', 'See All'),
                  style: NaraTextStyles.label.copyWith(color: NaraColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _filterDescription(context, _incomeFilter, _incomeCustomDate),
            style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary),
          ),
          const SizedBox(height: 8),
          if (provider.transactionSwipeEnabled)
            Row(
              children: [
                Icon(Icons.swipe_rounded, size: 14, color: NaraColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    I18n.t(context, 'transaction_swipe_actions_subtitle'),
                    style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          if (filteredIncomes.isEmpty)
            NaraCard(
              padding: EdgeInsets.all(isCompact ? 16 : 20),
              borderRadius: NaraRadius.lg,
              backgroundColor: NaraColors.surfaceWhite,
              child: Center(
                child: Text(
                  tr('Belum ada pemasukan pada filter ini', 'No income for this filter'),
                  style: NaraTextStyles.body.copyWith(color: NaraColors.textSecondary),
                ),
              ),
            )
          else
            ...filteredIncomes.map(
              (income) {
                final originalIndex = provider.incomes.indexOf(income);
                return _TransactionItem(
                  itemKey: ValueKey('income-$originalIndex-${income['title'] ?? ''}'),
                  swipeEnabled: provider.transactionSwipeEnabled,
                  icon: _iconFromName(income['icon'] as String? ?? 'account_balance_wallet'),
                  title: income['title'] as String? ?? '-',
                  subtitle: income['time'] as String? ?? '-',
                  amount: '+${formatRupiah((income['amount'] as num?) ?? 0)}',
                  amountColor: NaraColors.success,
                  onSwipeStartToEnd: originalIndex >= 0
                      ? () => _showEditIncomeDialog(
                            context: context,
                            provider: provider,
                            index: originalIndex,
                          )
                      : null,
                  onSwipeEndToStart: originalIndex >= 0
                      ? () => _confirmDeleteHistoryItem(
                            context: context,
                            provider: provider,
                            type: _HistoryDeleteType.income,
                            index: originalIndex,
                          )
                      : null,
                  onDelete: originalIndex >= 0
                      ? () => _confirmDeleteHistoryItem(
                            context: context,
                            provider: provider,
                            type: _HistoryDeleteType.income,
                            index: originalIndex,
                          )
                      : null,
                  onTap: originalIndex >= 0
                      ? () => _showEditIncomeDialog(
                            context: context,
                            provider: provider,
                            index: originalIndex,
                          )
                      : null,
                );
              },
            ),
          const SizedBox(height: 72),
        ],
      ),
    );
  }

  Widget _buildDebtTab(BuildContext context, AppProvider provider) {
    final isEnglish = provider.language == 'English';
    String tr(String idText, String enText) => _tr(context, provider, idText, enText);
    final softRed = NaraColors.danger;
    final softGreen = NaraColors.success;
    final isCompact = MediaQuery.of(context).size.width < 380;
    final debts = provider.debts;
    final typeFilteredDebts = debts.where((debt) {
      final type = (debt['type'] as String?) ?? 'utang';
      switch (_debtTypeFilter) {
        case _DebtTypeFilter.all:
          return true;
        case _DebtTypeFilter.debt:
          return type == 'utang';
        case _DebtTypeFilter.receivable:
          return type == 'piutang';
      }
    }).toList();
    final statusFilteredDebts = typeFilteredDebts.where((debt) {
      final status = (debt['status'] as String?) ?? 'berjalan';
      switch (_debtFilter) {
        case _DebtFilter.all:
          return true;
        case _DebtFilter.unpaid:
          return status != 'lunas';
        case _DebtFilter.paid:
          return status == 'lunas';
        case _DebtFilter.overdue:
          return _isDebtOverdue(debt);
      }
    }).toList();
    final filteredDebts = statusFilteredDebts.where((debt) {
      switch (_debtDueFilter) {
        case _DebtDueFilter.all:
          return true;
        case _DebtDueFilter.today:
          final dueDate = _parseDebtDueDate((debt['dueDate'] as String?) ?? '');
          if (dueDate == null) return false;
          return DateUtils.isSameDay(DateUtils.dateOnly(dueDate), DateUtils.dateOnly(DateTime.now()));
        case _DebtDueFilter.next7Days:
          final dueDate = _parseDebtDueDate((debt['dueDate'] as String?) ?? '');
          if (dueDate == null) return false;
          final today = DateUtils.dateOnly(DateTime.now());
          final end = today.add(const Duration(days: 7));
          final due = DateUtils.dateOnly(dueDate);
          return (due.isAtSameMomentAs(today) || due.isAfter(today)) &&
              (due.isAtSameMomentAs(end) || due.isBefore(end));
        case _DebtDueFilter.overdue:
          return _isDebtOverdue(debt);
      }
    }).toList()
      ..sort(_compareDebtItemsForDefaultOrder);
    final statusAllCount = typeFilteredDebts.length;
    final statusUnpaidCount = typeFilteredDebts.where((debt) {
      final status = (debt['status'] as String?) ?? 'berjalan';
      return status != 'lunas';
    }).length;
    final statusPaidCount = typeFilteredDebts.where((debt) {
      final status = (debt['status'] as String?) ?? 'berjalan';
      return status == 'lunas';
    }).length;
    final statusOverdueCount = typeFilteredDebts.where(_isDebtOverdue).length;

    final utangSaya = typeFilteredDebts.where((debt) => debt['type'] == 'utang').fold<num>(0, (sum, debt) => sum + _remainingDebtAmount(debt));
    final piutangSaya = typeFilteredDebts.where((debt) => debt['type'] == 'piutang').fold<num>(0, (sum, debt) => sum + _remainingDebtAmount(debt));
    final overdueDebt = debts.cast<Map<String, dynamic>>().firstWhere(
          (debt) => (debt['status'] as String?) != 'lunas',
          orElse: () => <String, dynamic>{},
        );

    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_debtTypeFilter == _DebtTypeFilter.debt)
            _DebtSummaryCard(
              label: tr('Saya Berhutang', 'My Debts'),
              amount: formatRupiah(utangSaya),
              color: softRed,
            )
          else if (_debtTypeFilter == _DebtTypeFilter.receivable)
            _DebtSummaryCard(
              label: tr('Piutang Saya', 'My Receivables'),
              amount: formatRupiah(piutangSaya),
              color: softGreen,
            )
          else
            Row(
              children: [
                Expanded(
                  child: _DebtSummaryCard(
                    label: tr('Saya Berhutang', 'My Debts'),
                    amount: formatRupiah(utangSaya),
                    color: softRed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DebtSummaryCard(
                    label: tr('Piutang Saya', 'My Receivables'),
                    amount: formatRupiah(piutangSaya),
                    color: softGreen,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
          NaraCard(
            padding: const EdgeInsets.all(12),
            borderRadius: NaraRadius.lg,
            backgroundColor: NaraColors.surfaceWhite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr('Filter Utang/Piutang', 'Debt/Receivable Filter'),
                        style: NaraTextStyles.label.copyWith(
                          color: NaraColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _debtFilterExpanded = !_debtFilterExpanded),
                      child: Text(_debtFilterExpanded ? tr('Sembunyikan', 'Hide') : tr('Tampilkan', 'Show')),
                    ),
                  ],
                ),
                if (_debtFilterExpanded) ...[
                  Text(
                    tr('Tipe', 'Type'),
                    style: NaraTextStyles.caption.copyWith(
                      color: NaraColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: tr('Semua', 'All'),
                        isSelected: _debtTypeFilter == _DebtTypeFilter.all,
                        onTap: () => setState(() => _debtTypeFilter = _DebtTypeFilter.all),
                      ),
                      _FilterChip(
                        label: tr('Saya Berhutang', 'My Debts'),
                        isSelected: _debtTypeFilter == _DebtTypeFilter.debt,
                        onTap: () => setState(() => _debtTypeFilter = _DebtTypeFilter.debt),
                      ),
                      _FilterChip(
                        label: tr('Piutang Saya', 'My Receivables'),
                        isSelected: _debtTypeFilter == _DebtTypeFilter.receivable,
                        onTap: () => setState(() => _debtTypeFilter = _DebtTypeFilter.receivable),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr('Status', 'Status'),
                    style: NaraTextStyles.caption.copyWith(
                      color: NaraColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: '${tr('Semua', 'All')} ($statusAllCount)',
                        isSelected: _debtFilter == _DebtFilter.all,
                        onTap: () => setState(() => _debtFilter = _DebtFilter.all),
                      ),
                      _FilterChip(
                        label: '${tr('Belum Lunas', 'Unpaid')} ($statusUnpaidCount)',
                        isSelected: _debtFilter == _DebtFilter.unpaid,
                        onTap: () => setState(() => _debtFilter = _DebtFilter.unpaid),
                      ),
                      _FilterChip(
                        label: '${tr('Lunas', 'Paid')} ($statusPaidCount)',
                        isSelected: _debtFilter == _DebtFilter.paid,
                        onTap: () => setState(() => _debtFilter = _DebtFilter.paid),
                      ),
                      _FilterChip(
                        label: '${tr('Overdue', 'Overdue')} ($statusOverdueCount)',
                        isSelected: _debtFilter == _DebtFilter.overdue,
                        onTap: () => setState(() => _debtFilter = _DebtFilter.overdue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr('Jatuh Tempo', 'Due Date'),
                    style: NaraTextStyles.caption.copyWith(
                      color: NaraColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: tr('Semua', 'All'),
                        isSelected: _debtDueFilter == _DebtDueFilter.all,
                        onTap: () => setState(() => _debtDueFilter = _DebtDueFilter.all),
                      ),
                      _FilterChip(
                        label: tr('Hari ini', 'Today'),
                        isSelected: _debtDueFilter == _DebtDueFilter.today,
                        onTap: () => setState(() => _debtDueFilter = _DebtDueFilter.today),
                      ),
                      _FilterChip(
                        label: tr('7 hari', '7 days'),
                        isSelected: _debtDueFilter == _DebtDueFilter.next7Days,
                        onTap: () => setState(() => _debtDueFilter = _DebtDueFilter.next7Days),
                      ),
                      _FilterChip(
                        label: tr('Overdue', 'Overdue'),
                        isSelected: _debtDueFilter == _DebtDueFilter.overdue,
                        onTap: () => setState(() => _debtDueFilter = _DebtDueFilter.overdue),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (overdueDebt.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3D6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFE1A6)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFD6A43B), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('Jatuh Tempo Mendekat', 'Due Date Near'),
                          style: NaraTextStyles.label.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8A5B00),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEnglish
                              ? '${overdueDebt['title'] as String? ?? '-'} is still unpaid.'
                              : '${overdueDebt['title'] as String? ?? '-'} masih belum lunas.',
                          style: NaraTextStyles.bodySmall.copyWith(fontSize: 12, color: const Color(0xFF8A5B00)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (overdueDebt.isNotEmpty) SizedBox(height: isCompact ? 16 : 20),
          if (provider.transactionSwipeEnabled) ...[
            Row(
              children: [
                Icon(Icons.swipe_rounded, size: 14, color: NaraColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    I18n.t(context, 'transaction_swipe_actions_subtitle'),
                    style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (filteredDebts.isEmpty)
            NaraCard(
              padding: EdgeInsets.all(isCompact ? 16 : 20),
              borderRadius: NaraRadius.lg,
              backgroundColor: NaraColors.surfaceWhite,
              child: Center(
                child: Text(
                  tr('Belum ada data utang/piutang pada filter ini', 'No debt/receivable data for this filter'),
                  style: NaraTextStyles.body.copyWith(color: NaraColors.textSecondary),
                ),
              ),
            )
          else
            ...filteredDebts.map((debt) {
              final originalIndex = debts.indexOf(debt);
              final debtId = (debt['debtId'] as int?) ?? originalIndex;
              final totalAmount = (debt['amount'] as num?)?.toInt() ?? 0;
              final paidAmount = (debt['paidAmount'] as num?)?.toInt() ?? 0;
              final remainingAmount = totalAmount - paidAmount;
              final isPaid = (debt['status'] as String?) == 'lunas' || remainingAmount <= 0;
              final isDebtOwed = (debt['type'] as String?) == 'utang';
              final accentColor = isDebtOwed ? softRed : softGreen;
              final title = debt['title'] as String? ?? '-';
              final subtitle = debt['note'] as String? ?? debt['date'] as String? ?? '-';
              final h1ScheduledAt = DateTime.tryParse((debt['debtReminderH1At'] as String?) ?? '');
              final h0ScheduledAt = DateTime.tryParse((debt['debtReminderH0At'] as String?) ?? '');
              final hasH1Schedule = h1ScheduledAt != null;
              final hasH0Schedule = h0ScheduledAt != null;

              final debtCard = NaraCard(
                padding: EdgeInsets.all(isCompact ? 16 : 20),
                margin: const EdgeInsets.only(bottom: 16),
                borderRadius: NaraRadius.lg,
                backgroundColor: NaraColors.surfaceWhite,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: NaraColors.surfaceCard,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: NaraColors.textHint.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Icon(
                            isDebtOwed ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            color: accentColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: NaraTextStyles.label.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(subtitle, style: NaraTextStyles.bodySmall.copyWith(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        _StatusBadge(
                          label: isPaid ? tr('Lunas', 'Paid') : tr('Belum Lunas', 'Unpaid'),
                          color: isPaid ? NaraColors.success : NaraColors.textHint,
                        ),
                        PopupMenuButton<String>(
                          tooltip: tr('Aksi lainnya', 'More actions'),
                          onSelected: (value) async {
                            final currentIndex = _findDebtIndexById(provider, debtId);
                            if (currentIndex < 0) return;
                            if (value == 'edit') {
                              await _showEditDebtDialog(context: context, provider: provider, index: currentIndex);
                              return;
                            }
                            if (value == 'delete') {
                              await _confirmDeleteHistoryItem(
                                context: context,
                                provider: provider,
                                type: _HistoryDeleteType.debt,
                                index: currentIndex,
                              );
                              return;
                            }
                            if (value == 'remind_now') {
                              final ok = await provider.sendDebtReminderById(debtId);
                              if (!context.mounted) return;
                              showAppSnackBar(
                                context,
                                content: Text(
                                  ok ? tr('Pengingat dikirim.', 'Reminder sent.') : tr('Gagal kirim pengingat.', 'Failed to send reminder.'),
                                  style: NaraTextStyles.body,
                                ),
                              );
                              return;
                            }
                            if (value == 'toggle_h1') {
                              final ok = hasH1Schedule
                                  ? await provider.cancelDebtReminderById(debtId, daysBeforeDue: 1)
                                  : await provider.scheduleDebtReminderById(debtId, daysBeforeDue: 1);
                              if (!context.mounted) return;
                              showAppSnackBar(
                                context,
                                content: Text(
                                  ok
                                      ? (hasH1Schedule
                                          ? tr('Pengingat H-1 dibatalkan.', 'D-1 reminder canceled.')
                                          : tr('Pengingat H-1 dijadwalkan.', 'D-1 reminder scheduled.'))
                                      : tr('Gagal memproses H-1.', 'Failed to process D-1.'),
                                  style: NaraTextStyles.body,
                                ),
                              );
                              return;
                            }
                            if (value == 'toggle_h0') {
                              final ok = hasH0Schedule
                                  ? await provider.cancelDebtReminderById(debtId, daysBeforeDue: 0)
                                  : await provider.scheduleDebtReminderById(debtId, daysBeforeDue: 0);
                              if (!context.mounted) return;
                              showAppSnackBar(
                                context,
                                content: Text(
                                  ok
                                      ? (hasH0Schedule
                                          ? tr('Pengingat H-0 dibatalkan.', 'D-0 reminder canceled.')
                                          : tr('Pengingat H-0 dijadwalkan.', 'D-0 reminder scheduled.'))
                                      : tr('Gagal memproses H-0.', 'Failed to process D-0.'),
                                  style: NaraTextStyles.body,
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'edit', child: Text(tr('Edit Data', 'Edit Data'))),
                            PopupMenuItem(value: 'delete', child: Text(tr('Hapus', 'Delete'))),
                            if (!isPaid) ...[
                              PopupMenuItem(value: 'remind_now', child: Text(tr('Ingatkan lagi', 'Remind again'))),
                              PopupMenuItem(
                                value: 'toggle_h1',
                                child: Text(hasH1Schedule ? tr('Batalkan H-1', 'Cancel D-1') : tr('Ingatkan H-1', 'Remind D-1')),
                              ),
                              PopupMenuItem(
                                value: 'toggle_h0',
                                child: Text(hasH0Schedule ? tr('Batalkan H-0', 'Cancel D-0') : tr('Ingatkan H-0', 'Remind D-0')),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isDebtOwed ? tr('Sisa Utang', 'Remaining Debt') : tr('Sisa Piutang', 'Remaining Receivable'),
                      style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary, fontSize: 12),
                    ),
                    Text(formatRupiah(remainingAmount), style: NaraTextStyles.h3.copyWith(color: accentColor)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: totalAmount <= 0 ? 0 : paidAmount / totalAmount,
                        minHeight: 6,
                        backgroundColor: NaraColors.textHint.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        isEnglish ? '${formatRupiah(paidAmount)} paid' : '${formatRupiah(paidAmount)} dibayar',
                        style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary, fontSize: 10),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: tr('Bayar Sebagian', 'Pay Partially'),
                            onTap: isPaid
                                ? () {}
                                : () => _showPartialPaymentDialog(
                                      context: context,
                                      provider: provider,
                                      debtId: debtId,
                                      remainingAmount: remainingAmount,
                                    ),
                            color: NaraColors.surfaceCard,
                            textColor: NaraColors.primary,
                            borderColor: NaraColors.primary.withValues(alpha: 0.35),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            label: tr('Tandai Lunas', 'Mark as Paid'),
                            onTap: isPaid
                                ? () {}
                                : () {
                                    provider.markDebtAsPaidById(debtId);
                                    showAppSnackBar(
                                      context,
                                      content: Text(
                                        tr('Utang sudah ditandai lunas', 'Debt marked as paid'),
                                        style: NaraTextStyles.body,
                                      ),
                                    );
                                  },
                            color: NaraColors.primary,
                            textColor: NaraColors.textOnPrimary,
                            borderColor: NaraColors.primary.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    if (!isPaid) ...[
                      const SizedBox(height: 6),
                      Text(
                        _debtReminderScheduleLabel(h1ScheduledAt: h1ScheduledAt, h0ScheduledAt: h0ScheduledAt),
                        style: NaraTextStyles.bodySmall.copyWith(color: NaraColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              );

              if (!provider.transactionSwipeEnabled) {
                return debtCard;
              }

              return Dismissible(
                key: ValueKey('debt-$debtId-${debt['title'] ?? ''}'),
                direction: DismissDirection.horizontal,
                background: _SwipeActionBackground(
                  icon: Icons.edit_rounded,
                  label: tr('Edit Data', 'Edit Data'),
                  color: NaraColors.primary,
                  alignment: Alignment.centerLeft,
                ),
                secondaryBackground: _SwipeActionBackground(
                  icon: Icons.delete_outline_rounded,
                  label: tr('Hapus', 'Delete'),
                  color: NaraColors.danger,
                  alignment: Alignment.centerRight,
                ),
                confirmDismiss: (direction) async {
                  final currentIndex = _findDebtIndexById(provider, debtId);
                  if (currentIndex < 0) return false;
                  if (direction == DismissDirection.startToEnd) {
                    await _showEditDebtDialog(
                      context: context,
                      provider: provider,
                      index: currentIndex,
                    );
                  } else if (direction == DismissDirection.endToStart) {
                    await _confirmDeleteHistoryItem(
                      context: context,
                      provider: provider,
                      type: _HistoryDeleteType.debt,
                      index: currentIndex,
                    );
                  }
                  return false;
                },
                child: debtCard,
              );
            }),
          const SizedBox(height: 72),
        ],
      ),
    );
  }

  void _openQuickActionSheet() {
    final activeProvider = context.read<AppProvider>();
    String tr(String idText, String enText) =>
        _tr(context, activeProvider, idText, enText);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: NaraCard(
            padding: const EdgeInsets.all(20),
            borderRadius: NaraRadius.lg,
            backgroundColor: NaraColors.surfaceWhite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Aksi Cepat', 'Quick Actions'), style: NaraTextStyles.h3),
                const SizedBox(height: 16),
                _QuickActionTile(
                  icon: Icons.add_circle_outline_rounded,
                  title: tr('Tambah Pengeluaran', 'Add Expense'),
                  subtitle: tr('Catat transaksi baru', 'Record a new transaction'),
                  color: NaraColors.accentOrange,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushNamed(context, '/add-expense');
                  },
                ),
                const SizedBox(height: 12),
                _QuickActionTile(
                  icon: Icons.arrow_downward_rounded,
                  title: tr('Tambah Pemasukan', 'Add Income'),
                  subtitle: tr('Simpan pemasukan baru', 'Save a new income record'),
                  color: NaraColors.success,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushNamed(context, '/add-income');
                  },
                ),
                const SizedBox(height: 12),
                _QuickActionTile(
                  icon: Icons.currency_exchange_rounded,
                  title: tr('Tambah Utang / Piutang', 'Add Debt / Receivable'),
                  subtitle: tr('Kelola saldo utang', 'Manage debt balances'),
                  color: NaraColors.primary,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushNamed(context, '/add-debt');
                  },
                ),
                const SizedBox(height: 12),
                _QuickActionTile(
                  icon: Icons.notifications_active_rounded,
                  title: tr('Buka Reminder', 'Open Reminders'),
                  subtitle: tr('Lihat daftar pengingat', 'View reminder list'),
                  color: NaraColors.accentPurple,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushNamed(context, '/reminders');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickCustomDate({
    required BuildContext context,
    required DateTime? currentDate,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        final scheme = Theme.of(context).colorScheme;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: scheme.primary,
                  surface: scheme.surface,
                ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (selectedDate == null || !mounted) return;
    onSelected(DateUtils.dateOnly(selectedDate));
  }

  Future<void> _confirmDeleteHistoryItem({
    required BuildContext context,
    required AppProvider provider,
    required _HistoryDeleteType type,
    required int index,
  }) async {
    final isEnglish = provider.language == 'English';
    String title() => switch (type) {
          _HistoryDeleteType.expense => isEnglish ? 'Delete expense?' : 'Hapus pengeluaran?',
          _HistoryDeleteType.income => isEnglish ? 'Delete income?' : 'Hapus pemasukan?',
          _HistoryDeleteType.debt => isEnglish ? 'Delete debt/receivable?' : 'Hapus utang/piutang?',
        };

    late final Map<String, dynamic> payload;
    if (type == _HistoryDeleteType.expense) {
      if (index < 0 || index >= provider.expenses.length) return;
      payload = Map<String, dynamic>.from(provider.expenses[index]);
    } else if (type == _HistoryDeleteType.income) {
      if (index < 0 || index >= provider.incomes.length) return;
      payload = Map<String, dynamic>.from(provider.incomes[index]);
    } else {
      if (index < 0 || index >= provider.debts.length) return;
      payload = Map<String, dynamic>.from(provider.debts[index]);
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title(), style: NaraTextStyles.h3),
        content: Text(
          isEnglish
              ? 'Deleting this data will affect summaries, charts, and related reports.'
              : 'Data yang dihapus akan mengubah ringkasan, grafik, dan laporan periode terkait.',
          style: NaraTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(I18n.t(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isEnglish ? 'Delete' : 'Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    if (type == _HistoryDeleteType.expense) {
      provider.removeExpenseAt(index);
    } else if (type == _HistoryDeleteType.income) {
      provider.removeIncomeAt(index);
    } else {
      provider.removeDebtAt(index);
    }

    showAppSnackBar(
      context,
      duration: const Duration(seconds: 5),
      content: Text(
        isEnglish ? 'Data deleted.' : 'Data berhasil dihapus.',
        style: NaraTextStyles.body,
      ),
      action: SnackBarAction(
        label: isEnglish ? 'Undo' : 'Urungkan',
        onPressed: () {
          if (type == _HistoryDeleteType.expense) {
            provider.restoreExpenseAt(index, payload);
          } else if (type == _HistoryDeleteType.income) {
            provider.restoreIncomeAt(index, payload);
          } else {
            provider.restoreDebtAt(index, payload);
          }
        },
      ),
    );
  }

  Future<void> _showBudgetDialog(BuildContext context, AppProvider provider) async {
    final controller = TextEditingController(
      text: provider.monthlyBudget > 0 ? provider.monthlyBudget.toString() : '',
    );
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(I18n.t(context, 'monthly_budget'), style: NaraTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              I18n.t(context, 'monthly_budget_hint'),
              style: NaraTextStyles.body.copyWith(color: NaraColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [RupiahInputFormatter()],
              decoration: InputDecoration(
                prefixText: 'Rp ',
                hintText: I18n.t(context, 'budget_input_hint'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(I18n.t(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = parseRupiahInput(controller.text);
              await provider.setMonthlyBudget(value);
              if (!context.mounted) return;
              showAppSnackBar(
                context,
                content: Text(
                  value > 0
                      ? I18n.t(context, 'budget_saved')
                      : (isEnglish ? 'Monthly budget cleared' : 'Anggaran bulanan dihapus'),
                ),
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: Text(I18n.t(context, 'save')),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditExpenseDialog({
    required BuildContext context,
    required AppProvider provider,
    required int index,
  }) async {
    if (index < 0 || index >= provider.expenses.length) return;
    final expense = provider.expenses[index];
    final titleController = TextEditingController(text: (expense['title'] as String?) ?? '');
    final amountController = TextEditingController(
      text: _formatCurrency(((expense['amount'] as num?)?.toInt() ?? 0)),
    );
    final isEnglish = provider.language == 'English';

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: NaraColors.surfaceWhite,
        title: Text(isEnglish ? 'Edit Expense' : 'Edit Pengeluaran', style: NaraTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: isEnglish ? 'Description' : 'Deskripsi'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [RupiahInputFormatter()],
              decoration: const InputDecoration(labelText: 'Nominal', prefixText: 'Rp '),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(I18n.t(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(I18n.t(context, 'save')),
          ),
        ],
      ),
    );
    if (!context.mounted) {
      titleController.dispose();
      amountController.dispose();
      return;
    }
    if (ok != true) {
      titleController.dispose();
      amountController.dispose();
      return;
    }

    final title = titleController.text.trim();
    final amount = parseRupiahInput(amountController.text);
    titleController.dispose();
    amountController.dispose();

    if (title.isEmpty || amount <= 0) {
      showAppSnackBar(context, content: Text(isEnglish ? 'Invalid input.' : 'Input tidak valid.'));
      return;
    }

    final updatedExpense = Map<String, dynamic>.from(expense)
      ..['title'] = title
      ..['amount'] = amount;
    provider.updateExpenseAt(index, updatedExpense);
    showAppSnackBar(context, content: Text(isEnglish ? 'Expense updated.' : 'Pengeluaran diperbarui.'));
  }

  Future<void> _showEditIncomeDialog({
    required BuildContext context,
    required AppProvider provider,
    required int index,
  }) async {
    if (index < 0 || index >= provider.incomes.length) return;
    final income = provider.incomes[index];
    final titleController = TextEditingController(text: (income['title'] as String?) ?? '');
    final amountController = TextEditingController(
      text: _formatCurrency(((income['amount'] as num?)?.toInt() ?? 0)),
    );
    final isEnglish = provider.language == 'English';

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: NaraColors.surfaceWhite,
        title: Text(isEnglish ? 'Edit Income' : 'Edit Pemasukan', style: NaraTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: isEnglish ? 'Description' : 'Deskripsi'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [RupiahInputFormatter()],
              decoration: const InputDecoration(labelText: 'Nominal', prefixText: 'Rp '),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(I18n.t(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(I18n.t(context, 'save')),
          ),
        ],
      ),
    );
    if (!context.mounted) {
      titleController.dispose();
      amountController.dispose();
      return;
    }
    if (ok != true) {
      titleController.dispose();
      amountController.dispose();
      return;
    }

    final title = titleController.text.trim();
    final amount = parseRupiahInput(amountController.text);
    titleController.dispose();
    amountController.dispose();

    if (title.isEmpty || amount <= 0) {
      showAppSnackBar(context, content: Text(isEnglish ? 'Invalid input.' : 'Input tidak valid.'));
      return;
    }

    final updatedIncome = Map<String, dynamic>.from(income)
      ..['title'] = title
      ..['amount'] = amount;
    provider.updateIncomeAt(index, updatedIncome);
    showAppSnackBar(context, content: Text(isEnglish ? 'Income updated.' : 'Pemasukan diperbarui.'));
  }

  Future<void> _showEditDebtDialog({
    required BuildContext context,
    required AppProvider provider,
    required int index,
  }) async {
    if (index < 0 || index >= provider.debts.length) return;
    final debt = provider.debts[index];
    final isEnglish = provider.language == 'English';

    final titleController = TextEditingController(text: (debt['title'] as String?) ?? '');
    final amountController = TextEditingController(
      text: _formatCurrency(((debt['amount'] as num?)?.toInt() ?? 0)),
    );
    final noteController = TextEditingController(text: (debt['note'] as String?) ?? '');
    final typeNotifier = ValueNotifier<String>((debt['type'] as String?) == 'piutang' ? 'piutang' : 'utang');
    DateTime? dueDate = _parseDebtDueDate((debt['dueDate'] as String?) ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          backgroundColor: NaraColors.surfaceWhite,
          title: Text(isEnglish ? 'Edit Debt / Receivable' : 'Edit Utang / Piutang', style: NaraTextStyles.h3),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: typeNotifier,
                  builder: (context, debtType, _) => DropdownButtonFormField<String>(
                    initialValue: debtType,
                    items: [
                      DropdownMenuItem(value: 'utang', child: Text(isEnglish ? 'My Debt' : 'Saya Berhutang')),
                      DropdownMenuItem(value: 'piutang', child: Text(isEnglish ? 'My Receivable' : 'Piutang Saya')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      typeNotifier.value = value;
                    },
                    decoration: InputDecoration(labelText: isEnglish ? 'Type' : 'Jenis'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: isEnglish ? 'Name' : 'Nama'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [RupiahInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Nominal', prefixText: 'Rp '),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(labelText: isEnglish ? 'Note' : 'Catatan'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: dueDate ?? now,
                            firstDate: DateTime(now.year - 2),
                            lastDate: DateTime(now.year + 20),
                          );
                          if (picked == null) return;
                          setLocalState(() => dueDate = DateUtils.dateOnly(picked));
                        },
                        icon: const Icon(Icons.event_rounded, size: 16),
                        label: Text(
                          dueDate == null
                              ? (isEnglish ? 'Set due date' : 'Atur jatuh tempo')
                              : _formatDateLabel(context, dueDate!),
                        ),
                      ),
                    ),
                    if (dueDate != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: isEnglish ? 'Clear due date' : 'Hapus jatuh tempo',
                        onPressed: () => setLocalState(() => dueDate = null),
                        icon: const Icon(Icons.clear_rounded),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(I18n.t(context, 'cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(I18n.t(context, 'save')),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted) {
      titleController.dispose();
      amountController.dispose();
      noteController.dispose();
      typeNotifier.dispose();
      return;
    }
    if (ok != true) {
      titleController.dispose();
      amountController.dispose();
      noteController.dispose();
      typeNotifier.dispose();
      return;
    }

    final title = titleController.text.trim();
    final amount = parseRupiahInput(amountController.text);
    final note = noteController.text.trim();
    final debtType = typeNotifier.value;
    titleController.dispose();
    amountController.dispose();
    noteController.dispose();
    typeNotifier.dispose();

    if (title.isEmpty || amount <= 0) {
      showAppSnackBar(context, content: Text(isEnglish ? 'Invalid input.' : 'Input tidak valid.'));
      return;
    }

    final updatedDebt = Map<String, dynamic>.from(debt)
      ..['title'] = title
      ..['amount'] = amount
      ..['type'] = debtType
      ..['note'] = note
      ..['dueDate'] = dueDate == null
          ? ''
          : '${dueDate!.day.toString().padLeft(2, '0')} ${_monthShortId(dueDate!.month)} ${dueDate!.year}';

    provider.updateDebtAt(index, updatedDebt);
    showAppSnackBar(
      context,
      content: Text(isEnglish ? 'Debt/receivable updated.' : 'Utang/piutang diperbarui.'),
    );
  }

  String _monthShortId(int month) {
    const months = <String>['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    if (month < 1 || month > 12) return 'Jan';
    return months[month - 1];
  }

  int _findDebtIndexById(AppProvider provider, int debtId) {
    return provider.debts.indexWhere((debt) => (debt['debtId'] as int?) == debtId);
  }

  void _showPartialPaymentDialog({
    required BuildContext context,
    required AppProvider provider,
    required int debtId,
    required int remainingAmount,
  }) {
    final isEnglish = provider.language == 'English';
    String tr(String idText, String enText) => _tr(context, provider, idText, enText);
    final amountController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: NaraColors.surfaceWhite,
              title: Text(tr('Bayar Sebagian', 'Pay Partially'), style: NaraTextStyles.h3),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Sisa utang yang dapat dibayar:', 'Remaining debt you can pay:'),
                      style: NaraTextStyles.body.copyWith(color: NaraColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Semantics(
                      label: tr('Sisa utang', 'Remaining debt'),
                      child: Text(
                        'Rp ${_formatCurrency(remainingAmount)}',
                        style: NaraTextStyles.h2.copyWith(color: NaraColors.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      textField: true,
                      label: tr('Masukkan nominal pembayaran dalam rupiah', 'Enter payment amount in rupiah'),
                      child: TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          _ThousandsSeparatorInputFormatter(),
                        ],
                        decoration: InputDecoration(
                          hintText: tr('Masukkan nominal pembayaran', 'Enter payment amount'),
                          prefixText: 'Rp ',
                          filled: true,
                          fillColor: NaraColors.surfaceCard,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    if (amountController.text.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildPaymentValidationMessage(
                        amountController.text,
                        remainingAmount,
                        isEnglish: isEnglish,
                      ),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(dialogContext);
                  },
                  child: Semantics(
                    button: true,
                    enabled: true,
                    label: tr('Batalkan pembayaran', 'Cancel payment'),
                    child: Text(
                      tr('Batal', 'Cancel'),
                      style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isValidPaymentAmount(amountController.text, remainingAmount)
                      ? () {
                          HapticFeedback.mediumImpact();
                          _confirmPaymentDialog(
                            context: context,
                            dialogContext: dialogContext,
                            provider: provider,
                            debtId: debtId,
                            paymentAmount: _parseAmountInput(amountController.text),
                            amountController: amountController,
                          );
                        }
                      : null,
                  child: Semantics(
                    button: true,
                    enabled: _isValidPaymentAmount(amountController.text, remainingAmount),
                    label: _isValidPaymentAmount(amountController.text, remainingAmount)
                        ? (isEnglish
                            ? 'Continue payment with amount Rp ${_formatCurrency(_parseAmountInput(amountController.text))}'
                            : 'Lanjutkan pembayaran dengan nominal Rp ${_formatCurrency(_parseAmountInput(amountController.text))}')
                        : tr('Nominal pembayaran tidak valid', 'Invalid payment amount'),
                    child: Text(tr('Lanjut', 'Continue'), style: NaraTextStyles.label),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(amountController.dispose);
  }

  bool _isValidPaymentAmount(String input, int remainingAmount) {
    final amount = _parseAmountInput(input);
    return amount > 0 && amount <= remainingAmount;
  }

  Widget _buildPaymentValidationMessage(
    String input,
    int remainingAmount, {
    required bool isEnglish,
  }) {
    final bodyStyle = NaraTextStyles.body;
    final amount = _parseAmountInput(input);

    if (amount <= 0) {
      return Row(
        children: [
          Icon(Icons.error_outline, color: NaraColors.danger, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isEnglish ? 'Amount must be greater than 0' : 'Nominal harus lebih dari 0',
              style: bodyStyle.copyWith(color: NaraColors.danger),
            ),
          ),
        ],
      );
    }

    if (amount > remainingAmount) {
      return Row(
        children: [
          Icon(Icons.error_outline, color: NaraColors.danger, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isEnglish
                  ? 'Exceeds remaining debt by Rp ${_formatCurrency(amount - remainingAmount)}'
                  : 'Melebihi sisa utang sebesar Rp ${_formatCurrency(amount - remainingAmount)}',
              style: bodyStyle.copyWith(color: NaraColors.danger),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(Icons.check_circle_outline, color: NaraColors.primary, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isEnglish
                ? 'Remaining after payment: Rp ${_formatCurrency(remainingAmount - amount)}'
                : 'Sisa setelah pembayaran: Rp ${_formatCurrency(remainingAmount - amount)}',
            style: bodyStyle.copyWith(color: NaraColors.primary),
          ),
        ),
      ],
    );
  }

  void _confirmPaymentDialog({
    required BuildContext context,
    required BuildContext dialogContext,
    required AppProvider provider,
    required int debtId,
    required int paymentAmount,
    required TextEditingController amountController,
  }) {
    String tr(String idText, String enText) => _tr(context, provider, idText, enText);
    showDialog<void>(
      context: context,
      builder: (confirmContext) {
        return AlertDialog(
          backgroundColor: NaraColors.surfaceWhite,
          title: Semantics(
            label: tr('Dialog konfirmasi pembayaran utang', 'Debt payment confirmation dialog'),
            child: Text(tr('Konfirmasi Pembayaran', 'Payment Confirmation'), style: NaraTextStyles.h3),
          ),
          content: Semantics(
            label: tr(
              'Konfirmasi pembayaran sebesar Rp ${_formatCurrency(paymentAmount)}',
              'Confirm payment amount Rp ${_formatCurrency(paymentAmount)}',
            ),
            child: Text(
              tr(
                'Bayar sebesar Rp ${_formatCurrency(paymentAmount)}?',
                'Pay Rp ${_formatCurrency(paymentAmount)}?',
              ),
              style: NaraTextStyles.body,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(confirmContext);
              },
              child: Semantics(
                button: true,
                enabled: true,
                label: tr('Batalkan pembayaran', 'Cancel payment'),
                child: Text(
                  tr('Batal', 'Cancel'),
                  style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.heavyImpact();
                Navigator.of(confirmContext).pop();
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop();
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  provider.updateDebtPaymentById(debtId, paymentAmount);
                  showAppSnackBar(
                    context,
                    backgroundColor: NaraColors.primary,
                    content: Semantics(
                      label: tr('Pembayaran berhasil', 'Payment successful'),
                      child: Text(
                        tr(
                          'Pembayaran Rp ${_formatCurrency(paymentAmount)} berhasil tersimpan',
                          'Payment Rp ${_formatCurrency(paymentAmount)} was saved successfully',
                        ),
                        style: NaraTextStyles.body,
                      ),
                    ),
                  );
                });
              },
              child: Semantics(
                button: true,
                enabled: true,
                label: tr(
                  'Konfirmasi pembayaran sebesar Rp ${_formatCurrency(paymentAmount)}',
                  'Confirm payment amount Rp ${_formatCurrency(paymentAmount)}',
                ),
                child: Text(tr('Bayar', 'Pay'), style: NaraTextStyles.label),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match.group(1)}.',
        );
  }

  int _parseAmountInput(String input) {
    final normalized = input.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(normalized) ?? 0;
  }

  String _debtReminderScheduleLabel({
    DateTime? h1ScheduledAt,
    DateTime? h0ScheduledAt,
  }) {
    String fmt(DateTime dt) {
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year.toString();
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$d/$m/$y $h:$min';
    }

    final items = <String>[];
    if (h1ScheduledAt != null) items.add('H-1: ${fmt(h1ScheduledAt)}');
    if (h0ScheduledAt != null) items.add('H-0: ${fmt(h0ScheduledAt)}');
    final isEnglish = context.read<AppProvider>().language == 'English';
    if (items.isEmpty) return isEnglish ? 'No D-1/D-0 schedule yet.' : 'Belum ada jadwal H-1/H-0.';
    return isEnglish ? 'Scheduled ${items.join(' | ')}' : 'Terjadwal ${items.join(' | ')}';
  }

  List<Map<String, dynamic>> _filterTransactions(
    List<Map<String, dynamic>> items,
    _TransactionFilterPreset preset,
    DateTime? customDate,
  ) {
    final now = DateUtils.dateOnly(DateTime.now());
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfNextWeek = startOfWeek.add(const Duration(days: 7));

    return items.where((item) {
      final createdAt = DateUtils.dateOnly((item['createdAt'] as DateTime?) ?? DateTime.now());
      switch (preset) {
        case _TransactionFilterPreset.week:
          return !createdAt.isBefore(startOfWeek) && createdAt.isBefore(startOfNextWeek);
        case _TransactionFilterPreset.month:
          return createdAt.year == now.year && createdAt.month == now.month;
        case _TransactionFilterPreset.year:
          return createdAt.year == now.year;
        case _TransactionFilterPreset.custom:
          return customDate != null && DateUtils.isSameDay(createdAt, customDate);
      }
    }).toList();
  }

  double _remainingDebtAmount(Map<String, dynamic> debt) {
    final amount = (debt['amount'] as num?)?.toDouble() ?? 0;
    final paidAmount = (debt['paidAmount'] as num?)?.toDouble() ?? 0;
    final remaining = amount - paidAmount;
    return remaining < 0 ? 0 : remaining;
  }

  bool _isDebtOverdue(Map<String, dynamic> debt) {
    final status = (debt['status'] as String?) ?? 'berjalan';
    if (status == 'lunas') return false;
    final dueDateRaw = (debt['dueDate'] as String?)?.trim() ?? '';
    if (dueDateRaw.isEmpty) return false;
    final dueDate = _parseDebtDueDate(dueDateRaw);
    if (dueDate == null) return false;
    final today = DateUtils.dateOnly(DateTime.now());
    return DateUtils.dateOnly(dueDate).isBefore(today);
  }

  int _compareDebtItemsForDefaultOrder(Map<String, dynamic> a, Map<String, dynamic> b) {
    final aPaid = ((a['status'] as String?) ?? 'berjalan') == 'lunas';
    final bPaid = ((b['status'] as String?) ?? 'berjalan') == 'lunas';
    if (aPaid != bPaid) {
      return aPaid ? 1 : -1;
    }

    final aDue = _parseDebtDueDate((a['dueDate'] as String?) ?? '');
    final bDue = _parseDebtDueDate((b['dueDate'] as String?) ?? '');
    if (aDue == null && bDue != null) return 1;
    if (aDue != null && bDue == null) return -1;
    if (aDue != null && bDue != null) {
      return DateUtils.dateOnly(aDue).compareTo(DateUtils.dateOnly(bDue));
    }

    final aCreated = DateTime.tryParse((a['createdAt'] as String?) ?? '');
    final bCreated = DateTime.tryParse((b['createdAt'] as String?) ?? '');
    if (aCreated != null && bCreated != null) {
      return bCreated.compareTo(aCreated);
    }
    return 0;
  }

  DateTime? _parseDebtDueDate(String raw) {
    final direct = DateTime.tryParse(raw);
    if (direct != null) return direct;
    final normalized = raw.replaceAll(',', '').trim();
    final match = RegExp(r'^(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})$').firstMatch(normalized);
    if (match == null) return null;
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

  String _filterDescription(BuildContext context, _TransactionFilterPreset preset, DateTime? customDate) {
    final isEnglish = context.read<AppProvider>().language == 'English';
    switch (preset) {
      case _TransactionFilterPreset.week:
        return isEnglish ? 'Filter: This week' : 'Filter: Minggu ini';
      case _TransactionFilterPreset.month:
        return isEnglish ? 'Filter: This month' : 'Filter: Bulan ini';
      case _TransactionFilterPreset.year:
        return isEnglish ? 'Filter: This year' : 'Filter: Tahun ini';
      case _TransactionFilterPreset.custom:
        return customDate == null
            ? (isEnglish ? 'Filter: Custom date' : 'Filter: Tanggal khusus')
            : 'Filter: ${_formatDateLabel(context, customDate)}';
    }
  }

  String _formatDateLabel(BuildContext context, DateTime date) {
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  Map<String, int> _buildCategoryTotals(
    List<Map<String, dynamic>> items,
    String Function(String, String) tr,
  ) {
    final totals = <String, int>{};
    for (final item in items) {
      final rawCategory = (item['category'] as String?)?.trim();
      final category = (rawCategory == null || rawCategory.isEmpty)
          ? tr('Lainnya', 'Others')
          : rawCategory;
      final amount = ((item['amount'] as num?)?.round() ?? 0);
      totals[category] = (totals[category] ?? 0) + amount;
    }
    return totals;
  }

  List<MapEntry<String, int>> _sortCategoryTotals(Map<String, int> totals) {
    final entries = totals.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  Map<String, int> _buildCategoryPercentages(
    List<MapEntry<String, int>> entries,
    num totalAmount,
  ) {
    final total = totalAmount <= 0 ? 0.0 : totalAmount.toDouble();
    final percents = <String, int>{};
    for (final entry in entries) {
      final pct = total == 0 ? 0 : ((entry.value / total) * 100).round();
      percents[entry.key] = pct;
    }
    return percents;
  }

  List<double> _buildGradientStops(
    List<MapEntry<String, int>> entries,
    Map<String, int> percents,
    int maxItems,
  ) {
    final stops = <double>[];
    double accumulated = 0;
    for (int i = 0; i < maxItems; i++) {
      final key = entries[i].key;
      accumulated += (percents[key] ?? 0) / 100;
      stops.add(accumulated.clamp(0, 1));
    }
    if (stops.isEmpty) return [1.0];
    return stops;
  }

  Widget _buildCategoryChartRow({
    required List<MapEntry<String, int>> sortedCategories,
    required Map<String, int> categoryPercentages,
    required List<Color> colors,
    required ColorScheme scheme,
    required TextStyle bodyStyle,
    required String emptyText,
    IconData icon = Icons.show_chart_rounded,
  }) {
    final maxItems = sortedCategories.length > 4 ? 4 : sortedCategories.length;
    final hasData = maxItems > 0;
    final chartColors = hasData
        ? List<Color>.generate(maxItems, (i) => colors[i % colors.length])
        : [
            scheme.outlineVariant.withValues(alpha: 0.4),
            NaraColors.textHint.withValues(alpha: 0.4),
          ];
    final stops = hasData
        ? _buildGradientStops(sortedCategories, categoryPercentages, maxItems)
        : const [0.5, 1.0];

    return Row(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: chartColors,
              stops: stops,
            ),
          ),
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(icon, color: scheme.onSurfaceVariant, size: 20),
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: hasData
              ? Column(
                  children: [
                    for (int i = 0; i < maxItems; i++)
                      _CategoryLegendItem(
                        label: sortedCategories[i].key,
                        percentage: '${categoryPercentages[sortedCategories[i].key] ?? 0}%',
                        color: chartColors[i % chartColors.length],
                      ),
                  ],
                )
              : Text(
                  emptyText,
                  style: bodyStyle.copyWith(color: scheme.onSurfaceVariant),
                ),
        ),
      ],
    );
  }

  IconData _iconFromName(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'work':
        return Icons.work_rounded;
      case 'laptop_mac':
        return Icons.laptop_mac_rounded;
      case 'store':
        return Icons.store_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet_rounded;
      case 'currency_exchange':
        return Icons.currency_exchange_rounded;
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  String _tr(
    BuildContext context,
    AppProvider provider,
    String idText,
    String enText,
  ) {
    final key = _transactionI18nKey(idText);
    if (key == null) {
      return provider.language == 'English' ? enText : idText;
    }
    final code = provider.language == 'English' ? 'en' : 'id';
    return I18n.tByCode(code, key);
  }

  String? _transactionI18nKey(String idText) {
    switch (idText) {
      case 'Aksi cepat':
      case 'Aksi Cepat':
        return 'quick_action';
      case 'Keuangan':
        return 'finance';
      case 'Lihat pengingat':
      case 'Buka Reminder':
        return 'see_notifications';
      case 'Pengeluaran':
        return 'expenses';
      case 'Pemasukan':
        return 'income';
      case 'Utang/Piutang':
        return 'debt_receivable_tab';
      case 'Tambah transaksi':
        return 'add_transaction';
      case 'Lainnya':
        return 'cat_others';
      case 'Bulan Ini':
        return 'this_month';
      case 'Minggu Ini':
        return 'this_week';
      case 'Tahun Ini':
        return 'this_year';
      case 'Pilih Tanggal':
      case 'Custom':
        return 'filter_custom_date';
      case 'Total Pengeluaran':
        return 'total_expense';
      case 'Anggaran':
        return 'budget';
      case 'Kategori':
        return 'expense_categories';
      case 'Belum ada pengeluaran':
        return 'no_expense';
      case 'Riwayat':
        return 'history';
      case 'Lihat Semua':
        return 'view_all';
      case 'Total Pemasukan':
        return 'total_income';
      case 'Sumber Pemasukan':
        return 'source_income';
      case 'Gaji':
        return 'cat_salary';
      case 'Freelance':
        return 'cat_freelance';
      case 'Investasi':
        return 'cat_investment';
      case 'Riwayat Pemasukan':
        return 'income_history';
      case 'Saya Berhutang':
        return 'debt_mine';
      case 'Piutang Saya':
        return 'receivable_mine';
      case 'Belum Lunas':
        return 'debt_unpaid';
      case 'Lunas':
        return 'debt_paid';
      case 'Belum ada data utang/piutang pada filter ini':
        return 'no_debt_filter';
      case 'Bayar Sebagian':
        return 'pay_partial';
      case 'Tandai Lunas':
        return 'mark_paid';
      case 'Utang sudah ditandai lunas':
        return 'debt_marked_paid';
      case 'Batal':
        return 'cancel';
      case 'Lanjut':
        return 'continue';
      case 'Pembayaran berhasil':
        return 'payment_success';
      case 'Bayar':
        return 'pay';
      default:
        return null;
    }
  }
}

enum _TransactionFilterPreset { month, week, year, custom }

enum _DebtFilter { all, unpaid, paid, overdue }
enum _DebtTypeFilter { all, debt, receivable }
enum _DebtDueFilter { all, today, next7Days, overdue }
enum _HistoryDeleteType { expense, income, debt }

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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _FilterChip({required this.label, required this.isSelected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return NaraChip(
      label: label,
      selected: isSelected,
      onTap: onTap,
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NaraCard(
      onTap: onTap,
      borderRadius: NaraRadius.md,
      padding: const EdgeInsets.all(14),
      backgroundColor: NaraColors.surfaceWhite,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: NaraTextStyles.label),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NaraTextStyles.bodySmall.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryLegendItem extends StatelessWidget {
  final String label;
  final String percentage;
  final Color color;

  const _CategoryLegendItem({required this.label, required this.percentage, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: NaraTextStyles.label.copyWith(fontSize: 12, color: NaraColors.textSecondary),
            ),
          ),
          Text(
            percentage,
            style: NaraTextStyles.label.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Key itemKey;
  final bool swipeEnabled;
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final Color amountColor;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onSwipeStartToEnd;
  final VoidCallback? onSwipeEndToStart;

  const _TransactionItem({
    required this.itemKey,
    required this.swipeEnabled,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
    this.onTap,
    this.onDelete,
    this.onSwipeStartToEnd,
    this.onSwipeEndToStart,
  });

  @override
  Widget build(BuildContext context) {
    final card = NaraCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: NaraRadius.md,
      backgroundColor: NaraColors.surfaceWhite,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: NaraColors.surfaceCard, shape: BoxShape.circle),
            child: Icon(icon, color: NaraColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: NaraTextStyles.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NaraTextStyles.bodySmall.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: NaraTextStyles.label.copyWith(color: amountColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );

    if (!swipeEnabled) {
      return card;
    }

    return Dismissible(
      key: itemKey,
      direction: DismissDirection.horizontal,
      background: const _SwipeActionBackground(
        icon: Icons.edit_rounded,
        label: 'Edit',
        color: NaraColors.primary,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: const _SwipeActionBackground(
        icon: Icons.delete_outline_rounded,
        label: 'Hapus',
        color: NaraColors.danger,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onSwipeStartToEnd?.call();
        } else if (direction == DismissDirection.endToStart) {
          onSwipeEndToStart?.call();
        }
        return false;
      },
      child: card,
    );
  }
}

class _SwipeActionBackground extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Alignment alignment;

  const _SwipeActionBackground({
    required this.icon,
    required this.label,
    required this.color,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(horizontal: isLeft ? 16 : 20),
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
            Text(label, style: NaraTextStyles.label.copyWith(color: color, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
          ],
          Icon(icon, color: color, size: 20),
          if (isLeft) ...[
            const SizedBox(width: 8),
            Text(label, style: NaraTextStyles.label.copyWith(color: color, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}

class _DebtSummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _DebtSummaryCard({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return NaraCard(
      padding: const EdgeInsets.all(16),
      borderRadius: NaraRadius.lg,
      backgroundColor: NaraColors.surfaceWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: NaraTextStyles.label.copyWith(fontSize: 12, color: NaraColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: NaraTextStyles.h3.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label, style: NaraTextStyles.label.copyWith(fontSize: 10, color: color)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;
  final Color? borderColor;

  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.color,
    required this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (borderColor ?? scheme.outlineVariant).withValues(alpha: 0.4),
          ),
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: NaraTextStyles.label.copyWith(color: textColor, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

