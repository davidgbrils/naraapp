import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';

enum _ReportPeriod { week, month, year }

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  _ReportPeriod _selectedPeriod = _ReportPeriod.week;

  bool _isInSelectedPeriod(DateTime date) {
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case _ReportPeriod.week:
        return date.isAfter(now.subtract(const Duration(days: 7)));
      case _ReportPeriod.month:
        return date.year == now.year && date.month == now.month;
      case _ReportPeriod.year:
        return date.year == now.year;
    }
  }

  DateTime _extractDate(Map<String, dynamic> item) {
    final createdAt = item['createdAt'];
    if (createdAt is DateTime) return createdAt;
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Laporan Keuangan', style: AppTheme.h3),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppTheme.primaryContainer),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final filteredExpenses = provider.expenses.where((e) => _isInSelectedPeriod(_extractDate(e))).toList();
          final filteredIncomes = provider.incomes.where((i) => _isInSelectedPeriod(_extractDate(i))).toList();
          final filteredDebts = provider.debts.where((d) => _isInSelectedPeriod(_extractDate(d))).toList();

          final totalExpense = filteredExpenses.fold<int>(0, (sum, e) => sum + ((e['amount'] as num?)?.round() ?? 0));
          final totalIncome = filteredIncomes.fold<int>(0, (sum, i) => sum + ((i['amount'] as num?)?.round() ?? 0));
          final balance = totalIncome - totalExpense;

          final categoryTotals = <String, int>{};
          for (final expense in filteredExpenses) {
            final category = (expense['category'] as String?) ?? 'Lainnya';
            final amount = ((expense['amount'] as num?)?.round() ?? 0);
            categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
          }

          final categoryEntries = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final totalUtang = filteredDebts
              .where((d) => d['type'] == 'utang')
              .fold<int>(0, (sum, d) => sum + ((d['amount'] as num?)?.round() ?? 0));
          final totalPiutang = filteredDebts
              .where((d) => d['type'] == 'piutang')
              .fold<int>(0, (sum, d) => sum + ((d['amount'] as num?)?.round() ?? 0));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _PeriodChip(
                        label: 'Minggu',
                        isSelected: _selectedPeriod == _ReportPeriod.week,
                        onTap: () => setState(() => _selectedPeriod = _ReportPeriod.week),
                      ),
                      const SizedBox(width: 8),
                      _PeriodChip(
                        label: 'Bulan',
                        isSelected: _selectedPeriod == _ReportPeriod.month,
                        onTap: () => setState(() => _selectedPeriod = _ReportPeriod.month),
                      ),
                      const SizedBox(width: 8),
                      _PeriodChip(
                        label: 'Tahun',
                        isSelected: _selectedPeriod == _ReportPeriod.year,
                        onTap: () => setState(() => _selectedPeriod = _ReportPeriod.year),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Pemasukan',
                        amount: formatRupiah(totalIncome),
                        color: AppTheme.success,
                        icon: Icons.arrow_downward_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Pengeluaran',
                        amount: formatRupiah(totalExpense),
                        color: AppTheme.secondary,
                        icon: Icons.arrow_upward_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SummaryCard(
                  title: 'Saldo',
                  amount: formatRupiah(balance),
                  color: balance < 0 ? AppTheme.danger : AppTheme.success,
                  icon: Icons.account_balance_wallet_rounded,
                  fullWidth: true,
                ),
                const SizedBox(height: 24),
                Text('Berdasarkan Kategori', style: AppTheme.h3),
                const SizedBox(height: 16),
                if (categoryEntries.isEmpty)
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Belum ada pengeluaran pada periode ini',
                        style: AppTheme.body.copyWith(color: AppTheme.outline),
                      ),
                    ),
                  )
                else
                  ...categoryEntries.map((entry) {
                    final percentage = totalExpense == 0 ? 0 : ((entry.value / totalExpense) * 100).round();
                    final colors = [
                      AppTheme.secondary,
                      AppTheme.primaryContainer,
                      AppTheme.tertiary,
                      AppTheme.success,
                      AppTheme.warning,
                    ];
                    final color = colors[categoryEntries.indexOf(entry) % colors.length];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CategoryItem(
                        category: entry.key,
                        amount: entry.value,
                        percentage: percentage,
                        color: color,
                      ),
                    );
                  }),
                const SizedBox(height: 24),
                Text('Ringkasan Utang/Piutang', style: AppTheme.h3),
                const SizedBox(height: 16),
                _DebtSummaryItem(
                  title: 'Total Utang',
                  amount: totalUtang,
                  color: AppTheme.danger,
                ),
                const SizedBox(height: 12),
                _DebtSummaryItem(
                  title: 'Total Piutang',
                  amount: totalPiutang,
                  color: AppTheme.success,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTheme.label.copyWith(
                color: isSelected ? AppTheme.onPrimaryContainer : AppTheme.outline,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  final IconData icon;
  final bool fullWidth;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      width: fullWidth ? double.infinity : null,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.label.copyWith(color: AppTheme.outline)),
                Text(amount, style: AppTheme.h3.copyWith(color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String category;
  final int amount;
  final int percentage;
  final Color color;

  const _CategoryItem({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category, style: AppTheme.label),
              Text(
                formatRupiah(amount),
                style: AppTheme.label.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              backgroundColor: AppTheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtSummaryItem extends StatelessWidget {
  final String title;
  final int amount;
  final Color color;

  const _DebtSummaryItem({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTheme.label),
          Text(
            formatRupiah(amount),
            style: AppTheme.h3.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
