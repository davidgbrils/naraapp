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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Tooltip(
          message: 'Aksi cepat',
          child: IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _openQuickActionSheet();
            },
            icon: const Icon(Icons.menu_rounded, color: AppTheme.onSurface),
            tooltip: 'Buka menu aksi cepat',
          ),
        ),
        title: Semantics(
          label: 'Menu Keuangan',
          child: Text('Keuangan', style: AppTheme.h2),
        ),
        actions: [
          Tooltip(
            message: 'Lihat pengingat',
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppTheme.onSurface),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, '/reminders');
              },
              tooltip: 'Pengingat transaksi',
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          indicatorColor: AppTheme.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.outline,
          labelStyle: AppTheme.label.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTheme.label,
          tabs: const [
            Tab(text: 'Pengeluaran'),
            Tab(text: 'Pemasukan'),
            Tab(text: 'Utang & Piutang'),
          ],
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
          _openQuickActionSheet();
        },
        backgroundColor: AppTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tooltip: 'Tambah transaksi',
        child: Semantics(
          button: true,
          enabled: true,
          label: 'Tombol tambah transaksi',
          child: const Icon(Icons.add_rounded, color: AppTheme.onPrimary, size: 30),
        ),
      ),
    );
  }

  Widget _buildExpenseTab(BuildContext context, AppProvider provider) {
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
      final category = (expense['category'] as String?) ?? 'Lainnya';
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Bulan Ini',
                  isSelected: _expenseFilter == _TransactionFilterPreset.month,
                  onTap: () => setState(() => _expenseFilter = _TransactionFilterPreset.month),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Minggu Ini',
                  isSelected: _expenseFilter == _TransactionFilterPreset.week,
                  onTap: () => setState(() => _expenseFilter = _TransactionFilterPreset.week),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Tahun Ini',
                  isSelected: _expenseFilter == _TransactionFilterPreset.year,
                  onTap: () => setState(() => _expenseFilter = _TransactionFilterPreset.year),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: _expenseCustomDate == null ? 'Pilih Tanggal' : _formatDateLabel(context, _expenseCustomDate!),
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Pengeluaran', style: AppTheme.label.copyWith(color: AppTheme.outline)),
                const SizedBox(height: 8),
                Text(formatRupiah(totalExpense), style: AppTheme.h1),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Anggaran: ${formatRupiah(budget)}', style: AppTheme.label.copyWith(color: AppTheme.outline, fontSize: 12)),
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kategori', style: AppTheme.h3),
                const SizedBox(height: 20),
                if (sortedCategories.isEmpty)
                  Center(
                    child: Text(
                      'Belum ada pengeluaran',
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
              Text('Riwayat', style: AppTheme.h3),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/report'),
                child: Text('Lihat Semua', style: AppTheme.label.copyWith(color: AppTheme.primary)),
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
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text('Belum ada pengeluaran pada filter ini', style: AppTheme.body.copyWith(color: AppTheme.outline)),
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
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildIncomeTab(BuildContext context, AppProvider provider) {
    final filteredIncomes = _filterTransactions(
      provider.incomes,
      _incomeFilter,
      _incomeCustomDate,
    );
    final totalIncome = filteredIncomes.fold<num>(0, (sum, item) => sum + ((item['amount'] as num?) ?? 0));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Minggu Ini',
                  isSelected: _incomeFilter == _TransactionFilterPreset.week,
                  onTap: () => setState(() => _incomeFilter = _TransactionFilterPreset.week),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Bulan Ini',
                  isSelected: _incomeFilter == _TransactionFilterPreset.month,
                  onTap: () => setState(() => _incomeFilter = _TransactionFilterPreset.month),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Tahun Ini',
                  isSelected: _incomeFilter == _TransactionFilterPreset.year,
                  onTap: () => setState(() => _incomeFilter = _TransactionFilterPreset.year),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: _incomeCustomDate == null ? 'Custom' : _formatDateLabel(context, _incomeCustomDate!),
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Pemasukan', style: AppTheme.label.copyWith(color: AppTheme.outline)),
                const SizedBox(height: 8),
                Text(formatRupiah(totalIncome), style: AppTheme.h1.copyWith(color: AppTheme.primary)),
                const SizedBox(height: 8),
                Text(_filterDescription(context, _incomeFilter, _incomeCustomDate), style: AppTheme.label.copyWith(color: AppTheme.outline)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sumber Pemasukan', style: AppTheme.h3),
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
                          _CategoryLegendItem(label: 'Gaji', percentage: '60%', color: AppTheme.primary),
                          _CategoryLegendItem(label: 'Freelance', percentage: '25%', color: AppTheme.success),
                          _CategoryLegendItem(label: 'Investasi', percentage: '10%', color: AppTheme.tertiary),
                          _CategoryLegendItem(label: 'Lainnya', percentage: '5%', color: AppTheme.outline),
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
              Text('Riwayat Pemasukan', style: AppTheme.h3),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/report'),
                child: Text('Lihat Semua', style: AppTheme.label.copyWith(color: AppTheme.primary)),
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
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text('Belum ada pemasukan pada filter ini', style: AppTheme.body.copyWith(color: AppTheme.outline)),
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
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDebtTab(BuildContext context, AppProvider provider) {
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _DebtSummaryCard(
                  label: 'Saya Berhutang',
                  amount: formatRupiah(utangSaya),
                  color: AppTheme.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DebtSummaryCard(
                  label: 'Piutang Saya',
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
                label: 'Semua',
                isSelected: _debtFilter == _DebtFilter.all,
                onTap: () => setState(() => _debtFilter = _DebtFilter.all),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Belum Lunas',
                isSelected: _debtFilter == _DebtFilter.unpaid,
                onTap: () => setState(() => _debtFilter = _DebtFilter.unpaid),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Lunas',
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
                        Text('Jatuh Tempo Mendekat', style: AppTheme.label.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          '${overdueDebt['title'] as String? ?? '-'} masih belum lunas.',
                          style: AppTheme.body.copyWith(fontSize: 12, color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (overdueDebt.isNotEmpty) const SizedBox(height: 20),
          if (filteredDebts.isEmpty)
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text('Belum ada data utang/piutang pada filter ini', style: AppTheme.body.copyWith(color: AppTheme.outline)),
              ),
            )
          else
            ...filteredDebts.map((debt) {
              final originalIndex = debts.indexOf(debt);
              final totalAmount = (debt['amount'] as num?)?.toInt() ?? 0;
              final paidAmount = (debt['paidAmount'] as num?)?.toInt() ?? 0;
              final remainingAmount = totalAmount - paidAmount;
              final isPaid = (debt['status'] as String?) == 'lunas' || remainingAmount <= 0;
              final isDebtOwed = (debt['type'] as String?) == 'utang';
              final accentColor = isDebtOwed ? AppTheme.secondary : AppTheme.success;
              final title = debt['title'] as String? ?? '-';
              final subtitle = debt['note'] as String? ?? debt['date'] as String? ?? '-';

              return GlassContainer(
                padding: const EdgeInsets.all(20),
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
                          label: isPaid ? 'Lunas' : 'Belum Lunas',
                          color: isPaid ? AppTheme.success : AppTheme.outlineVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Sisa ${isDebtOwed ? 'Utang' : 'Piutang'}', style: AppTheme.label.copyWith(color: AppTheme.outline, fontSize: 12)),
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
                      child: Text('${formatRupiah(paidAmount)} dibayar', style: AppTheme.label.copyWith(color: AppTheme.outline, fontSize: 10)),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: 'Bayar Sebagian',
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
                            label: 'Tandai Lunas',
                            onTap: isPaid
                                ? () {}
                                : () {
                                    provider.markDebtAsPaid(originalIndex);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Utang sudah ditandai lunas', style: AppTheme.body)),
                                    );
                                  },
                            color: AppTheme.primary.withValues(alpha: 0.8),
                            textColor: AppTheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _openQuickActionSheet() {
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
                Text('Aksi Cepat', style: AppTheme.h3),
                const SizedBox(height: 16),
                _QuickActionTile(
                  icon: Icons.add_circle_outline_rounded,
                  title: 'Tambah Pengeluaran',
                  subtitle: 'Catat transaksi baru',
                  color: AppTheme.secondary,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushNamed(context, '/add-expense');
                  },
                ),
                const SizedBox(height: 12),
                _QuickActionTile(
                  icon: Icons.arrow_downward_rounded,
                  title: 'Tambah Pemasukan',
                  subtitle: 'Simpan pemasukan baru',
                  color: AppTheme.success,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushNamed(context, '/add-income');
                  },
                ),
                const SizedBox(height: 12),
                _QuickActionTile(
                  icon: Icons.currency_exchange_rounded,
                  title: 'Tambah Utang / Piutang',
                  subtitle: 'Kelola saldo utang',
                  color: AppTheme.primaryContainer,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushNamed(context, '/add-debt');
                  },
                ),
                const SizedBox(height: 12),
                _QuickActionTile(
                  icon: Icons.notifications_active_rounded,
                  title: 'Buka Reminder',
                  subtitle: 'Lihat daftar pengingat',
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
    final amountController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceContainerLow,
              title: Text('Bayar Sebagian', style: AppTheme.h3),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sisa utang yang dapat dibayar:',
                      style: AppTheme.body.copyWith(color: AppTheme.outline),
                    ),
                    const SizedBox(height: 4),
                    Semantics(
                      label: 'Sisa utang',
                      child: Text(
                        'Rp ${_formatCurrency(remainingAmount)}',
                        style: AppTheme.h2.copyWith(color: AppTheme.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      textField: true,
                      label: 'Masukkan nominal pembayaran dalam rupiah',
                      child: TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: 'Masukkan nominal pembayaran',
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
                      _buildPaymentValidationMessage(amountController.text, remainingAmount),
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
                    label: 'Batalkan pembayaran',
                    child: Text('Batal', style: AppTheme.label.copyWith(color: AppTheme.outline)),
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
                        ? 'Lanjutkan pembayaran dengan nominal Rp ${_formatCurrency(int.parse(amountController.text))}'
                        : 'Nominal pembayaran tidak valid',
                    child: Text('Lanjut', style: AppTheme.label),
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

  Widget _buildPaymentValidationMessage(String input, int remainingAmount) {
    final amount = int.tryParse(input) ?? 0;

    if (amount <= 0) {
      return Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Nominal harus lebih dari 0',
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
              'Melebihi sisa utang sebesar Rp ${_formatCurrency(amount - remainingAmount)}',
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
            'Sisa setelah pembayaran: Rp ${_formatCurrency(remainingAmount - amount)}',
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
    showDialog<void>(
      context: context,
      builder: (confirmContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLow,
          title: Semantics(
            label: 'Dialog konfirmasi pembayaran utang',
            child: Text('Konfirmasi Pembayaran', style: AppTheme.h3),
          ),
          content: Semantics(
            label: 'Konfirmasi pembayaran sebesar Rp ${_formatCurrency(paymentAmount)}',
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
                label: 'Batalkan pembayaran',
                child: Text('Batal', style: AppTheme.label.copyWith(color: AppTheme.outline)),
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
                      label: 'Pembayaran berhasil',
                      child: Text(
                        'Pembayaran Rp ${_formatCurrency(paymentAmount)} berhasil tersimpan',
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
                child: Text('Bayar', style: AppTheme.label),
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
    switch (preset) {
      case _TransactionFilterPreset.week:
        return 'Filter: Minggu ini';
      case _TransactionFilterPreset.month:
        return 'Filter: Bulan ini';
      case _TransactionFilterPreset.year:
        return 'Filter: Tahun ini';
      case _TransactionFilterPreset.custom:
        return customDate == null ? 'Filter: Tanggal khusus' : 'Filter: ${_formatDateLabel(context, customDate)}';
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.outlineVariant.withValues(alpha: 0.5),
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
          color: AppTheme.surfaceContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(18),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.05),
          ],
        ),
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
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTheme.label.copyWith(color: textColor, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
