import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _PeriodChip(label: 'Minggu', isSelected: true),
                  const SizedBox(width: 8),
                  _PeriodChip(label: 'Bulan', isSelected: false),
                  const SizedBox(width: 8),
                  _PeriodChip(label: 'Tahun', isSelected: false),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Summary cards
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Pemasukan',
                    amount: 'Rp 0',
                    color: AppTheme.success,
                    icon: Icons.arrow_downward_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Pengeluaran',
                    amount: 'Rp 85.000',
                    color: AppTheme.secondary,
                    icon: Icons.arrow_upward_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SummaryCard(
              title: 'Saldo',
              amount: '-Rp 85.000',
              color: AppTheme.danger,
              icon: Icons.account_balance_wallet_rounded,
              fullWidth: true,
            ),
            const SizedBox(height: 24),

            // Category breakdown
            Text('Berdasarkan Kategori', style: AppTheme.h3),
            const SizedBox(height: 16),
            
            _CategoryItem(
              category: 'Makan',
              amount: 45000,
              percentage: 53,
              color: AppTheme.secondary,
            ),
            const SizedBox(height: 12),
            _CategoryItem(
              category: 'Transport',
              amount: 40000,
              percentage: 47,
              color: AppTheme.primaryContainer,
            ),

            const SizedBox(height: 24),

            // Debt summary
            Text('Ringkasan Utang/Piutang', style: AppTheme.h3),
            const SizedBox(height: 16),
            Consumer<AppProvider>(
              builder: (context, provider, _) {
                final totalUtang = provider.debts.where((d) => d['type'] == 'utang').fold(0, (sum, d) => sum + (d['amount'] as int));
                final totalPiutang = provider.debts.where((d) => d['type'] == 'piutang').fold(0, (sum, d) => sum + (d['amount'] as int));
                
                return Column(
                  children: [
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
                );
              },
            ),

            const SizedBox(height: 24),

            // Export button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_rounded, size: 20),
                label: Text('Export Laporan', style: AppTheme.label),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
                  foregroundColor: AppTheme.primaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _PeriodChip({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTheme.label.copyWith(color: AppTheme.outline)),
              Text(amount, style: AppTheme.h3.copyWith(color: color)),
            ],
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
                'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                style: AppTheme.label.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
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
            'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
            style: AppTheme.h3.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}