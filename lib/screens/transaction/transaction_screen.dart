// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
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
  DateTime? _expenseCustomDate;
  DateTime? _incomeCustomDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeProvider = context.watch<AppProvider>();
    final isEnglish = activeProvider.language == 'English';
    String tr(String idText, String enText) => isEnglish ? enText : idText;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Tooltip(
          message: tr('Aksi cepat', 'Quick actions'),
          child: IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _openQuickActionSheet();
            },
            icon: const Icon(Icons.menu_rounded, color: AppTheme.onSurface),
            tooltip: tr('Buka menu aksi cepat', 'Open quick actions'),
          ),
        ),
        title: Semantics(
          label: tr('Menu Keuangan', 'Finance menu'),
          child: Text(tr('Keuangan', 'Finance'), style: AppTheme.h2),
        ),
        actions: [
          Tooltip(
            message: tr('Lihat pengingat', 'View reminders'),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppTheme.onSurface),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, '/reminders');
              },
              tooltip: tr('Pengingat transaksi', 'Transaction reminders'),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            height: 44,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.45),
                ),
              ),
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.outline,
              labelStyle: AppTheme.label.copyWith(fontWeight: FontWeight.w700, fontSize: 12),
              unselectedLabelStyle: AppTheme.label.copyWith(fontSize: 12),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.background,
              AppTheme.surfaceContainerLow.withValues(alpha: 0.55),
            ],
          ),
        ),
        child: Consumer<AppProvider>(
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _openQuickActionSheet();
        },
        backgroundColor: AppTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tooltip: tr('Tambah transaksi', 'Add transaction'),
        child: Semantics(
          button: true,
          enabled: true,
          label: tr('Tombol tambah transaksi', 'Add transaction button'),
          child: const Icon(Icons.add_rounded, color: AppTheme.onPrimary, size: 30),
        ),
      ),
    );
  }

  Widget _buildExpenseTab(BuildContext context, AppProvider provider) {
    final isEnglish = provider.language == 'English';
    String tr(String idText, String enText) => isEnglish ? enText : idText;
    final isCompact = MediaQuery.of(context).size.width < 380;
    final filteredExpenses = _filterTransactions(
      provider.expenses,
      _expenseFilter,
      _expenseCustomDate,
    );
    final totalExpense = filteredExpenses.fold<num>(0, (sum, item) => sum + ((item['amount'] as num?) ?? 0));
    const budget = 5000000;
    final progress = totalExpense / budget;

    // Calculate category totals
    final categoryTotals = <String, int>{};
    for (final expense in filteredExpenses) {
      final category = (expense['category'] as String?) ?? tr('Lainnya', 'Others');
      final amount = ((expense['amount'] as num?)?.round() ?? 0);
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
    }

    // Sort categories by amount (descending) and calculate percentages
    final sortedCategories = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    final categoryPercentages = <String, int>{};
    for (final entry in sortedCategories) {
      final percentage = totalExpense == 0 ? 0 : ((entry.value / totalExpense) * 100).round();
      categoryPercentages[entry.key] = percentage;
    }

    // Define colors for categories
    final colors = [
      AppTheme.primary,
      AppTheme.secondary,
      AppTheme.tertiary,
      AppTheme.success,
    ];

    // Calculate gradient stops based on percentages
    final gradientStops = <double>[];
    double accumulated = 0;
    for (int i = 0; i < (sortedCategories.length > 4 ? 4 : sortedCategories.length); i++) {
      accumulated += categoryPercentages[sortedCategories[i].key]! / 100;
      gradientStops.add(accumulated.clamp(0, 1));
    }

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
          GlassContainer(
            padding: EdgeInsets.all(isCompact ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Total Pengeluaran', 'Total Expenses'), style: AppTheme.label.copyWith(color: AppTheme.outline)),
                const SizedBox(height: 8),
                Text(formatRupiah(totalExpense), style: AppTheme.h1),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${tr('Anggaran', 'Budget')}: ${formatRupiah(budget)}', style: AppTheme.label.copyWith(color: AppTheme.outline, fontSize: 12)),
                    Text('${(progress.clamp(0, 1) * 100).toStringAsFixed(0)}%', style: AppTheme.label.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: AppTheme.outlineVariant.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GlassContainer(
            padding: EdgeInsets.all(isCompact ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Kategori', 'Categories'), style: AppTheme.h3),
                const SizedBox(height: 20),
                if (sortedCategories.isEmpty)
                  Center(
                    child: Text(
                      tr('Belum ada pengeluaran', 'No expenses yet'),
                      style: AppTheme.body.copyWith(color: AppTheme.outline),
                    ),
                  )
                else
                  Row(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              for (int i = 0; i < (sortedCategories.length > 4 ? 4 : sortedCategories.length); i++)
                                colors[i % colors.length],
                            ],
                            stops: gradientStops.isEmpty ? [1.0] : gradientStops,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppTheme.background,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.show_chart_rounded, color: AppTheme.outline, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          children: [
                            for (int i = 0; i < (sortedCategories.length > 4 ? 4 : sortedCategories.length); i++)
                              _CategoryLegendItem(
                                label: sortedCategories[i].key,
                                percentage: '${categoryPercentages[sortedCategories[i].key]}%',
                                color: colors[i % colors.length],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr('Riwayat', 'History'), style: AppTheme.h3),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/report'),
                child: Text(tr('Lihat Semua', 'See All'), style: AppTheme.label.copyWith(color: AppTheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _filterDescription(context, _expenseFilter, _expenseCustomDate),
            style: AppTheme.label.copyWith(color: AppTheme.outline),
          ),
          const SizedBox(height: 12),
          if (filteredExpenses.isEmpty)
            GlassContainer(
              padding: EdgeInsets.all(isCompact ? 16 : 20),
              child: Center(
                child: Text(tr('Belum ada pengeluaran pada filter ini', 'No expenses for this filter'), style: AppTheme.body.copyWith(color: AppTheme.outline)),
              ),
            )
          else
            ...filteredExpenses.map(
              (expense) => _TransactionItem(
                icon: _iconFromName(expense['icon'] as String? ?? 'shopping_bag'),
                title: expense['title'] as String? ?? '-',
                subtitle: expense['time'] as String? ?? '-',
                amount: '-${formatRupiah((expense['amount'] as num?) ?? 0)}',
                amountColor: AppTheme.onSurface,
              ),
            ),
          const SizedBox(height: 72),
        ],
      ),
    );
  }

  Widget _buildIncomeTab(BuildContext context, AppProvider provider) {
    final isEnglish = provider.language == 'English';
    String tr(String idText, String enText) => isEnglish ? enText : idText;
    final isCompact = MediaQuery.of(context).size.width < 380;
    final filteredIncomes = _filterTransactions(
      provider.incomes,
      _incomeFilter,
      _incomeCustomDate,
    );
    final totalIncome = filteredIncomes.fold<num>(0, (sum, item) => sum + ((item['amount'] as num?) ?? 0));

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
          GlassContainer(
            padding: EdgeInsets.all(isCompact ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Total Pemasukan', 'Total Income'), style: AppTheme.label.copyWith(color: AppTheme.outline)),
                const SizedBox(height: 8),
                Text(formatRupiah(totalIncome), style: AppTheme.h1.copyWith(color: AppTheme.primary)),
                const SizedBox(height: 8),
                Text(_filterDescription(context, _incomeFilter, _incomeCustomDate), style: AppTheme.label.copyWith(color: AppTheme.outline)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GlassContainer(
            padding: EdgeInsets.all(isCompact ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Sumber Pemasukan', 'Income Sources'), style: AppTheme.h3),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.2), width: 15),
                        gradient: SweepGradient(
                          colors: [
                            AppTheme.primary,
                            AppTheme.success,
                            AppTheme.tertiary,
                            AppTheme.outline,
                          ],
                          stops: const [0.60, 0.85, 0.95, 1.0],
                        ),
                      ),
                      child: Center(
                        child: Icon(Icons.wallet_rounded, color: AppTheme.primary.withValues(alpha: 0.5), size: 30),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _CategoryLegendItem(label: tr('Gaji', 'Salary'), percentage: '60%', color: AppTheme.primary),
                          _CategoryLegendItem(label: 'Freelance', percentage: '25%', color: AppTheme.success),
                          _CategoryLegendItem(label: tr('Investasi', 'Investment'), percentage: '10%', color: AppTheme.tertiary),
                          _CategoryLegendItem(label: tr('Lainnya', 'Others'), percentage: '5%', color: AppTheme.outline),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr('Riwayat Pemasukan', 'Income History'), style: AppTheme.h3),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/report'),
                child: Text(tr('Lihat Semua', 'See All'), style: AppTheme.label.copyWith(color: AppTheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _filterDescription(context, _incomeFilter, _incomeCustomDate),
            style: AppTheme.label.copyWith(color: AppTheme.outline),
          ),
          const SizedBox(height: 12),
          if (filteredIncomes.isEmpty)
            GlassContainer(
              padding: EdgeInsets.all(isCompact ? 16 : 20),
              child: Center(
                child: Text(tr('Belum ada pemasukan pada filter ini', 'No income for this filter'), style: AppTheme.body.copyWith(color: AppTheme.outline)),
              ),
            )
          else
            ...filteredIncomes.map(
              (income) => _TransactionItem(
                icon: _iconFromName(income['icon'] as String? ?? 'account_balance_wallet'),
                title: income['title'] as String? ?? '-',
                subtitle: income['time'] as String? ?? '-',
                amount: '+${formatRupiah((income['amount'] as num?) ?? 0)}',
                amountColor: AppTheme.success,
              ),
            ),
          const SizedBox(height: 72),
        ],
      ),
    );
  }

  Widget _buildDebtTab(BuildContext context, AppProvider provider) {
    final isEnglish = provider.language == 'English';
    String tr(String idText, String enText) => isEnglish ? enText : idText;
    final isCompact = MediaQuery.of(context).size.width < 380;
    final debts = provider.debts;
    final filteredDebts = debts.where((debt) {
      final status = (debt['status'] as String?) ?? 'berjalan';
      switch (_debtFilter) {
        case _DebtFilter.all:
          return true;
        case _DebtFilter.unpaid:
          return status != 'lunas';
        case _DebtFilter.paid:
          return status == 'lunas';
      }
    }).toList();

    final utangSaya = debts.where((debt) => debt['type'] == 'utang').fold<num>(0, (sum, debt) => sum + _remainingDebtAmount(debt));
    final piutangSaya = debts.where((debt) => debt['type'] == 'piutang').fold<num>(0, (sum, debt) => sum + _remainingDebtAmount(debt));
    final overdueDebt = debts.cast<Map<String, dynamic>>().firstWhere(
          (debt) => (debt['status'] as String?) != 'lunas',
          orElse: () => <String, dynamic>{},
        );

    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _DebtSummaryCard(
                  label: tr('Saya Berhutang', 'My Debts'),
                  amount: formatRupiah(utangSaya),
                  color: AppTheme.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DebtSummaryCard(
                  label: tr('Piutang Saya', 'My Receivables'),
                  amount: formatRupiah(piutangSaya),
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _FilterChip(
                label: tr('Semua', 'All'),
                isSelected: _debtFilter == _DebtFilter.all,
                onTap: () => setState(() => _debtFilter = _DebtFilter.all),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: tr('Belum Lunas', 'Unpaid'),
                isSelected: _debtFilter == _DebtFilter.unpaid,
                onTap: () => setState(() => _debtFilter = _DebtFilter.unpaid),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: tr('Lunas', 'Paid'),
                isSelected: _debtFilter == _DebtFilter.paid,
                onTap: () => setState(() => _debtFilter = _DebtFilter.paid),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (overdueDebt.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.tertiary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('Jatuh Tempo Mendekat', 'Due Date Near'), style: AppTheme.label.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          isEnglish
                              ? '${overdueDebt['title'] as String? ?? '-'} is still unpaid.'
                              : '${overdueDebt['title'] as String? ?? '-'} masih belum lunas.',
                          style: AppTheme.body.copyWith(fontSize: 12, color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (overdueDebt.isNotEmpty) SizedBox(height: isCompact ? 16 : 20),
          if (filteredDebts.isEmpty)
            GlassContainer(
              padding: EdgeInsets.all(isCompact ? 16 : 20),
              child: Center(
                child: Text(tr('Belum ada data utang/piutang pada filter ini', 'No debt/receivable data for this filter'), style: AppTheme.body.copyWith(color: AppTheme.outline)),
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
              final accentColor = isDebtOwed ? AppTheme.secondary : AppTheme.success;
              final title = debt['title'] as String? ?? '-';
              final subtitle = debt['note'] as String? ?? debt['date'] as String? ?? '-';
              final h1ScheduledAt = DateTime.tryParse((debt['debtReminderH1At'] as String?) ?? '');
              final h0ScheduledAt = DateTime.tryParse((debt['debtReminderH0At'] as String?) ?? '');
              final hasH1Schedule = h1ScheduledAt != null;
              final hasH0Schedule = h0ScheduledAt != null;

              return GlassContainer(
                padding: EdgeInsets.all(isCompact ? 16 : 20),
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppTheme.surfaceContainer,
                            shape: BoxShape.circle,
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
                              Text(title, style: AppTheme.label.copyWith(fontWeight: FontWeight.bold)),
                              Text(subtitle, style: AppTheme.body.copyWith(fontSize: 12, color: AppTheme.outline)),
                            ],
                          ),
                        ),
                        _StatusBadge(
                          label: isPaid ? tr('Lunas', 'Paid') : tr('Belum Lunas', 'Unpaid'),
                          color: isPaid ? AppTheme.success : AppTheme.outlineVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isDebtOwed ? tr('Sisa Utang', 'Remaining Debt') : tr('Sisa Piutang', 'Remaining Receivable'),
                      style: AppTheme.label.copyWith(color: AppTheme.outline, fontSize: 12),
                    ),
                    Text(formatRupiah(remainingAmount), style: AppTheme.h3.copyWith(color: accentColor)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: totalAmount <= 0 ? 0 : paidAmount / totalAmount,
                        minHeight: 6,
                        backgroundColor: AppTheme.outlineVariant.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        isEnglish ? '${formatRupiah(paidAmount)} paid' : '${formatRupiah(paidAmount)} dibayar',
                        style: AppTheme.label.copyWith(color: AppTheme.outline, fontSize: 10),
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
                                      debtIndex: originalIndex,
                                      remainingAmount: remainingAmount,
                                    ),
                            color: AppTheme.surfaceContainerHigh,
                            textColor: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            label: tr('Tandai Lunas', 'Mark as Paid'),
                            onTap: isPaid
                                ? () {}
                                : () {
                                    provider.markDebtAsPaid(originalIndex);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(tr('Utang sudah ditandai lunas', 'Debt marked as paid'), style: AppTheme.body)),
                                    );
                                  },
                            color: AppTheme.primary.withValues(alpha: 0.8),
                            textColor: AppTheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (!isPaid) ...[
                      const SizedBox(height: 12),
                      _ActionButton(
                        label: tr('Ingatkan lagi', 'Remind again'),
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final ok = await provider.sendDebtReminderById(debtId);
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                ok ? tr('Pengingat dikirim.', 'Reminder sent.') : tr('Gagal kirim pengingat.', 'Failed to send reminder.'),
                                style: AppTheme.body,
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        color: AppTheme.surfaceContainerHigh,
                        textColor: AppTheme.onSurface,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: hasH1Schedule ? tr('Batalkan H-1', 'Cancel D-1') : tr('Ingatkan H-1', 'Remind D-1'),
                              onTap: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final ok = hasH1Schedule
                                    ? await provider.cancelDebtReminderById(debtId, daysBeforeDue: 1)
                                    : await provider.scheduleDebtReminderById(debtId, daysBeforeDue: 1);
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? (hasH1Schedule
                                              ? tr('Pengingat H-1 dibatalkan.', 'D-1 reminder canceled.')
                                              : tr('Pengingat H-1 dijadwalkan.', 'D-1 reminder scheduled.'))
                                          : tr('Gagal memproses H-1.', 'Failed to process D-1.'),
                                      style: AppTheme.body,
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              color: AppTheme.surfaceContainerHigh,
                              textColor: AppTheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ActionButton(
                              label: hasH0Schedule ? tr('Batalkan H-0', 'Cancel D-0') : tr('Ingatkan H-0', 'Remind D-0'),
                              onTap: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final ok = hasH0Schedule
                                    ? await provider.cancelDebtReminderById(debtId, daysBeforeDue: 0)
                                    : await provider.scheduleDebtReminderById(debtId, daysBeforeDue: 0);
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? (hasH0Schedule
                                              ? tr('Pengingat H-0 dibatalkan.', 'D-0 reminder canceled.')
                                              : tr('Pengingat H-0 dijadwalkan.', 'D-0 reminder scheduled.'))
                                          : tr('Gagal memproses H-0.', 'Failed to process D-0.'),
                                      style: AppTheme.body,
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              color: AppTheme.surfaceContainerHigh,
                              textColor: AppTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _debtReminderScheduleLabel(h1ScheduledAt: h1ScheduledAt, h0ScheduledAt: h0ScheduledAt),
                        style: AppTheme.body.copyWith(color: AppTheme.outline, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              );
            }),
          const SizedBox(height: 72),
        ],
      ),
    );
  }

  void _openQuickActionSheet() {
    final isEnglish = context.read<AppProvider>().language == 'English';
    String tr(String idText, String enText) => isEnglish ? enText : idText;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Aksi Cepat', 'Quick Actions'), style: AppTheme.h3),
                const SizedBox(height: 16),
                _QuickActionTile(
                  icon: Icons.add_circle_outline_rounded,
                  title: tr('Tambah Pengeluaran', 'Add Expense'),
                  subtitle: tr('Catat transaksi baru', 'Record a new transaction'),
                  color: AppTheme.secondary,
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
                  color: AppTheme.success,
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
                  color: AppTheme.primaryContainer,
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
                  color: AppTheme.tertiary,
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
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primary,
                  surface: AppTheme.background,
                ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (selectedDate == null || !mounted) return;
    onSelected(DateUtils.dateOnly(selectedDate));
  }

  void _showPartialPaymentDialog({
    required BuildContext context,
    required AppProvider provider,
    required int debtIndex,
    required int remainingAmount,
  }) {
    final isEnglish = provider.language == 'English';
    String tr(String idText, String enText) => isEnglish ? enText : idText;
    final amountController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceContainerLow,
              title: Text(tr('Bayar Sebagian', 'Pay Partially'), style: AppTheme.h3),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Sisa utang yang dapat dibayar:', 'Remaining debt you can pay:'),
                      style: AppTheme.body.copyWith(color: AppTheme.outline),
                    ),
                    const SizedBox(height: 4),
                    Semantics(
                      label: tr('Sisa utang', 'Remaining debt'),
                      child: Text(
                        'Rp ${_formatCurrency(remainingAmount)}',
                        style: AppTheme.h2.copyWith(color: AppTheme.primary),
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
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: tr('Masukkan nominal pembayaran', 'Enter payment amount'),
                          prefixText: 'Rp ',
                          filled: true,
                          fillColor: AppTheme.surfaceContainer,
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
                    child: Text(tr('Batal', 'Cancel'), style: AppTheme.label.copyWith(color: AppTheme.outline)),
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
                            debtIndex: debtIndex,
                            paymentAmount: int.parse(amountController.text),
                            amountController: amountController,
                          );
                        }
                      : null,
                  child: Semantics(
                    button: true,
                    enabled: _isValidPaymentAmount(amountController.text, remainingAmount),
                    label: _isValidPaymentAmount(amountController.text, remainingAmount)
                        ? (isEnglish
                            ? 'Continue payment with amount Rp ${_formatCurrency(int.parse(amountController.text))}'
                            : 'Lanjutkan pembayaran dengan nominal Rp ${_formatCurrency(int.parse(amountController.text))}')
                        : tr('Nominal pembayaran tidak valid', 'Invalid payment amount'),
                    child: Text(tr('Lanjut', 'Continue'), style: AppTheme.label),
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
    final amount = int.tryParse(input) ?? 0;
    return amount > 0 && amount <= remainingAmount;
  }

  Widget _buildPaymentValidationMessage(
    String input,
    int remainingAmount, {
    required bool isEnglish,
  }) {
    final amount = int.tryParse(input) ?? 0;

    if (amount <= 0) {
      return Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isEnglish ? 'Amount must be greater than 0' : 'Nominal harus lebih dari 0',
              style: AppTheme.body.copyWith(color: AppTheme.error),
            ),
          ),
        ],
      );
    }

    if (amount > remainingAmount) {
      return Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isEnglish
                  ? 'Exceeds remaining debt by Rp ${_formatCurrency(amount - remainingAmount)}'
                  : 'Melebihi sisa utang sebesar Rp ${_formatCurrency(amount - remainingAmount)}',
              style: AppTheme.body.copyWith(color: AppTheme.error),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(Icons.check_circle_outline, color: AppTheme.primary, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isEnglish
                ? 'Remaining after payment: Rp ${_formatCurrency(remainingAmount - amount)}'
                : 'Sisa setelah pembayaran: Rp ${_formatCurrency(remainingAmount - amount)}',
            style: AppTheme.body.copyWith(color: AppTheme.primary),
          ),
        ),
      ],
    );
  }

  void _confirmPaymentDialog({
    required BuildContext context,
    required BuildContext dialogContext,
    required AppProvider provider,
    required int debtIndex,
    required int paymentAmount,
    required TextEditingController amountController,
  }) {
    final isEnglish = provider.language == 'English';
    String tr(String idText, String enText) => isEnglish ? enText : idText;
    showDialog<void>(
      context: context,
      builder: (confirmContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLow,
          title: Semantics(
            label: tr('Dialog konfirmasi pembayaran utang', 'Debt payment confirmation dialog'),
            child: Text(tr('Konfirmasi Pembayaran', 'Payment Confirmation'), style: AppTheme.h3),
          ),
          content: Semantics(
            label: tr(
              'Konfirmasi pembayaran sebesar Rp ${_formatCurrency(paymentAmount)}',
              'Confirm payment amount Rp ${_formatCurrency(paymentAmount)}',
            ),
            child: Text(
              'Bayar sebesar Rp ${_formatCurrency(paymentAmount)}?',
              style: AppTheme.body,
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
                child: Text(tr('Batal', 'Cancel'), style: AppTheme.label.copyWith(color: AppTheme.outline)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.heavyImpact();
                provider.updateDebtPayment(debtIndex, paymentAmount);
                Navigator.pop(confirmContext);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Semantics(
                label: tr('Pembayaran berhasil', 'Payment successful'),
                      child: Text(
                        tr(
                          'Pembayaran Rp ${_formatCurrency(paymentAmount)} berhasil tersimpan',
                          'Payment Rp ${_formatCurrency(paymentAmount)} was saved successfully',
                        ),
                        style: AppTheme.body,
                      ),
                    ),
                    backgroundColor: AppTheme.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Semantics(
                button: true,
                enabled: true,
                label: 'Konfirmasi pembayaran sebesar Rp ${_formatCurrency(paymentAmount)}',
                child: Text(tr('Bayar', 'Pay'), style: AppTheme.label),
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
}

enum _TransactionFilterPreset { month, week, year, custom }

enum _DebtFilter { all, unpaid, paid }

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _FilterChip({required this.label, required this.isSelected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.14)
              : AppTheme.surfaceContainerLow.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary.withValues(alpha: 0.7)
                : AppTheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Text(
          label,
          style: AppTheme.label.copyWith(
            color: isSelected ? AppTheme.primary : AppTheme.outline,
            fontSize: 12,
          ),
        ),
      ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer.withValues(alpha: 0.52),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppTheme.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
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
                  Text(title, style: AppTheme.label),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTheme.body.copyWith(fontSize: 12, color: AppTheme.outline)),
                ],
              ),
            ),
          ],
        ),
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
          Expanded(child: Text(label, style: AppTheme.label.copyWith(fontSize: 12, color: AppTheme.onSurfaceVariant))),
          Text(percentage, style: AppTheme.label.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final Color amountColor;

  const _TransactionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 18,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: AppTheme.surfaceContainer, shape: BoxShape.circle),
            child: Icon(icon, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.label),
                Text(subtitle, style: AppTheme.body.copyWith(fontSize: 11, color: AppTheme.outline)),
              ],
            ),
          ),
          Text(amount, style: AppTheme.label.copyWith(color: amountColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DebtSummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _DebtSummaryCard({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.label.copyWith(fontSize: 12, color: AppTheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(amount, style: AppTheme.h3.copyWith(color: color, fontWeight: FontWeight.bold)),
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
      child: Text(label, style: AppTheme.label.copyWith(fontSize: 10, color: color)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;

  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: textColor.withValues(alpha: 0.18),
          ),
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.label.copyWith(color: textColor, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

