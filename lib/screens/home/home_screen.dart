import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';
import '../voice_overlay/voice_overlay.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 100,
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
                title: Padding(
                  padding: const EdgeInsets.only(top: 40),
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
                          child: Text('BU', style: AppTheme.h3.copyWith(color: AppTheme.primaryContainer)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Good morning, Nara', style: AppTheme.h3),
                          Text('Halo, Budi', style: AppTheme.label.copyWith(color: AppTheme.outline)),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(top: 40, right: 8),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_rounded, color: AppTheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              
              // Content
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Hero Voice Card
                    _VoiceActivationCard(),
                    const SizedBox(height: 20),
                    
                    // Quick Stats
                    _QuickStatsRow(),
                    const SizedBox(height: 20),
                    
                    // Quick Actions
                    _QuickActionsGrid(),
                    const SizedBox(height: 20),
                    
                    // Recent Activity
                    _RecentActivityList(),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
          
          // Bottom Nav
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _BottomNavBar(),
          ),
          
          // Voice Overlay (appears when listening)
          const VoiceOverlay(),
        ],
      ),
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
                  Text('Siap Mendengar', style: AppTheme.label.copyWith(color: AppTheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  provider.startListening();
                },
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
                  child: Icon(
                    Icons.mic_rounded,
                    size: 40,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Voice Waveform
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
                label: 'Pengeluaran Hari Ini',
                value: 'Rp ${provider.todayExpense.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                color: AppTheme.secondary,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Utang Aktif',
                value: 'Rp ${provider.totalActiveDebt.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
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
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.label.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(value, style: AppTheme.h3),
        ],
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
          childAspectRatio: 2.5,
          children: [
            _ActionButton(
              icon: Icons.add_circle_outline_rounded,
              label: 'Pengeluaran',
              color: AppTheme.secondary,
              onTap: () => Navigator.pushNamed(context, '/add-expense'),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(label, style: AppTheme.label),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aktivitas Terakhir', style: AppTheme.h3),
            const SizedBox(height: 12),
            if (provider.expenses.isEmpty && provider.debts.isEmpty)
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
              ...List.generate(provider.expenses.length + provider.debts.length, (index) {
                if (index < provider.expenses.length) {
                  final expense = provider.expenses[index];
                  return _ActivityItem(
                    icon: Icons.restaurant_rounded,
                    title: expense['title'],
                    time: expense['time'],
                    amount: '-Rp ${expense['amount'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                    amountColor: AppTheme.secondary,
                  );
                } else {
                  final debtIndex = index - provider.expenses.length;
                  if (debtIndex < provider.debts.length) {
                    final debt = provider.debts[debtIndex];
                    return _ActivityItem(
                      icon: Icons.account_balance_wallet_rounded,
                      title: debt['title'],
                      time: debt['date'],
                      amount: 'Rp ${debt['amount'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                      amountColor: AppTheme.primaryContainer,
                    );
                  }
                }
                return const SizedBox.shrink();
              }),
          ],
        );
      },
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  final String amount;
  final Color amountColor;

  const _ActivityItem({
    required this.icon,
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
            child: Icon(icon, color: AppTheme.secondary, size: 22),
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
  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home_rounded, isActive: true, label: 'Home'),
          _NavItem(icon: Icons.bubble_chart_rounded, isActive: false, label: 'Insight'),
          _NavItem(icon: Icons.auto_awesome_rounded, isActive: false, label: 'AI'),
          _NavItem(icon: Icons.person_rounded, isActive: false, label: 'Profil', onTap: () => Navigator.pushNamed(context, '/settings')),
        ],
      ),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryContainer.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppTheme.primaryContainer.withValues(alpha: 0.3),
                  blurRadius: 15,
                ),
              ]
            : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.primary : AppTheme.outline,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.label.copyWith(
                color: isActive ? AppTheme.primary : AppTheme.outline,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}