import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';
import '../reminder/reminder_list_screen.dart';
import '../voice_overlay/voice_overlay.dart';
import '../transaction/transaction_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          bottomNavigationBar: const SafeArea(
            minimum: EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _BottomNavBar(),
          ),
          body: IndexedStack(
            index: provider.selectedNavIndex,
            children: [
              const _HomeContent(),
              const TransactionScreen(),
              const ReminderListScreen(),
              const Center(child: Text('Profile Screen')),  // Placeholder for Profile
            ],
          ),
        );
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              toolbarHeight: 92,
              floating: true,
              pinned: true,
              backgroundColor: AppTheme.surfaceContainerLowest.withValues(alpha: 0.8),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.surfaceContainerLowest.withValues(alpha: 0.9),
                        AppTheme.background,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              title: Consumer<AppProvider>(
                builder: (context, provider, _) {
                  final userName = provider.userName.trim().isEmpty ? 'Pengguna' : provider.userName.trim();
                  final initials = userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'U';

                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerHigh,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Center(
                            child: Text(initials, style: AppTheme.h3.copyWith(color: AppTheme.primaryContainer)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Good morning, Nara', style: AppTheme.h3),
                            Text('Halo, $userName', style: AppTheme.label.copyWith(color: AppTheme.outline)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, right: 8),
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_rounded, color: AppTheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),
                  _VoiceActivationCard(),
                  const SizedBox(height: 20),
                  _QuickStatsRow(),
                  const SizedBox(height: 20),
                  _QuickActionsGrid(),
                  const SizedBox(height: 20),
                  _RecentActivityList(),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
        const VoiceOverlay(),
      ],
    );
  }
}

class _VoiceActivationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.success.withValues(alpha: 0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    label: 'Status: Siap mendengar input suara',
                    child: Text('Siap Mendengar', style: AppTheme.label.copyWith(color: AppTheme.onSurfaceVariant)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Semantics(
                button: true,
                enabled: true,
                label: 'Tombol aktivasi mikrofon untuk input suara',
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    provider.startListening();
                  },
                  child: Tooltip(
                    message: 'Tekan untuk mulai berbicara',
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainer,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryContainer, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryContainer.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        size: 40,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              VoiceWaveform(isAnimating: provider.isListening),
            ],
          ),
        );
      },
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _StatCard(
                label: 'Pengeluaran',
                value: formatRupiah(provider.todayExpense),
                color: AppTheme.secondary,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Utang Aktif',
                value: formatRupiah(provider.totalActiveDebt),
                color: AppTheme.primaryContainer,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Reminder Aktif',
                value: '${provider.activeReminders} aktif',
                color: AppTheme.success,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      width: 160,
      child: Semantics(
        label: '$label: $value',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTheme.label.copyWith(color: color)),
            const SizedBox(height: 4),
            Text(value, style: AppTheme.h3),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aksi Cepat', style: AppTheme.h3),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: [
            _ActionButton(
              icon: Icons.add_circle_outline_rounded,
              label: 'Pengeluaran',
              color: AppTheme.secondary,
              onTap: () => Navigator.pushNamed(context, '/add-expense'),
            ),
            _ActionButton(
              icon: Icons.arrow_downward_rounded,
              label: 'Pemasukan',
              color: AppTheme.success,
              onTap: () => Navigator.pushNamed(context, '/add-income'),
            ),
            _ActionButton(
              icon: Icons.currency_exchange_rounded,
              label: 'Utang/Piutang',
              color: AppTheme.primaryContainer,
              onTap: () => Navigator.pushNamed(context, '/add-debt'),
            ),
            _ActionButton(
              icon: Icons.notifications_active_rounded,
              label: 'Reminder',
              color: AppTheme.tertiary,
              onTap: () => Navigator.pushNamed(context, '/reminders'),
            ),
            _ActionButton(
              icon: Icons.bar_chart_rounded,
              label: 'Lihat Rekap',
              color: AppTheme.success,
              onTap: () => Navigator.pushNamed(context, '/report'),
            ),
            _ActionButton(
              icon: Icons.settings_rounded,
              label: 'Pengaturan',
              color: AppTheme.outline,
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Semantics(
            button: true,
            enabled: true,
            label: label,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: AppTheme.label,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentActivityItemData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String time;
  final String amount;
  final Color amountColor;

  const _RecentActivityItemData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.time,
    required this.amount,
    required this.amountColor,
  });
}

class _RecentActivityList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final activities = <_RecentActivityItemData>[
          ...provider.expenses.map(
            (expense) => _RecentActivityItemData(
              icon: Icons.shopping_bag_rounded,
              iconColor: AppTheme.secondary,
              title: expense['title'] as String? ?? '-',
              time: expense['time'] as String? ?? 'Hari ini',
              amount: '-${formatRupiah((expense['amount'] as num?) ?? 0)}',
              amountColor: AppTheme.secondary,
            ),
          ),
          ...provider.incomes.map(
            (income) => _RecentActivityItemData(
              icon: Icons.account_balance_wallet_rounded,
              iconColor: AppTheme.success,
              title: income['title'] as String? ?? '-',
              time: income['time'] as String? ?? 'Hari ini',
              amount: '+${formatRupiah((income['amount'] as num?) ?? 0)}',
              amountColor: AppTheme.success,
            ),
          ),
          ...provider.debts.map(
            (debt) => _RecentActivityItemData(
              icon: Icons.currency_exchange_rounded,
              iconColor: AppTheme.primaryContainer,
              title: debt['title'] as String? ?? '-',
              time: debt['date'] as String? ?? 'Hari ini',
              amount: formatRupiah((debt['amount'] as num?) ?? 0),
              amountColor: AppTheme.primaryContainer,
            ),
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aktivitas Terakhir', style: AppTheme.h3),
            const SizedBox(height: 12),
            if (activities.isEmpty)
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Belum ada aktivitas',
                    style: AppTheme.body.copyWith(color: AppTheme.outline),
                  ),
                ),
              )
            else
              ...activities.take(10).map(
                    (activity) => _ActivityItem(
                      icon: activity.icon,
                      iconColor: activity.iconColor,
                      title: activity.title,
                      time: activity.time,
                      amount: activity.amount,
                      amountColor: activity.amountColor,
                    ),
                  ),
          ],
        );
      },
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String time;
  final String amount;
  final Color amountColor;

  const _ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.time,
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
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.label),
                Text(time, style: AppTheme.body.copyWith(color: AppTheme.outlineVariant, fontSize: 12)),
              ],
            ),
          ),
          Text(amount, style: AppTheme.label.copyWith(color: amountColor)),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return GlassContainer(
          borderRadius: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined, 
                isActive: provider.selectedNavIndex == 0, 
                label: 'Home',
                onTap: () => provider.setNavIndex(0),
              ),
              _NavItem(
                icon: Icons.receipt_long_outlined, 
                isActive: provider.selectedNavIndex == 1, 
                label: 'Transaksi',
                onTap: () => provider.setNavIndex(1),
              ),
              _NavItem(
                icon: Icons.calendar_month_outlined, 
                isActive: provider.selectedNavIndex == 2, 
                label: 'Planning',
                onTap: () => provider.setNavIndex(2),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded, 
                isActive: provider.selectedNavIndex == 3, 
                label: 'Profile', 
                onTap: () {
                  provider.setNavIndex(3);
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final String label;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.primary : AppTheme.outline.withValues(alpha: 0.7),
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTheme.label.copyWith(
                color: isActive ? AppTheme.primary : AppTheme.outline.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
