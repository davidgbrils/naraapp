import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _showEditNameDialog(BuildContext context, AppProvider provider) async {
    final controller = TextEditingController(text: provider.userName);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceContainer,
          title: Text('Ubah nama', style: AppTheme.h3),
          content: TextField(
            controller: controller,
            style: AppTheme.body,
            decoration: const InputDecoration(
              hintText: 'Masukkan nama',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Batal', style: AppTheme.label.copyWith(color: AppTheme.outline)),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  provider.setUserName(newName);
                }
                Navigator.pop(dialogContext);
              },
              child: Text('Simpan', style: AppTheme.label),
            ),
          ],
        );
      },
    );
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
        title: Text('Pengaturan', style: AppTheme.h3),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile section
            Consumer<AppProvider>(
              builder: (context, provider, _) {
                final userName = provider.userName.trim().isEmpty ? 'Pengguna' : provider.userName.trim();
                return InkWell(
                  onTap: () => _showEditNameDialog(context, provider),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              userName.substring(0, 1).toUpperCase(),
                              style: AppTheme.h2.copyWith(color: AppTheme.onPrimaryContainer),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userName, style: AppTheme.h3),
                              Text('Ketuk untuk ubah nama', style: AppTheme.body.copyWith(color: AppTheme.outline)),
                            ],
                          ),
                        ),
                        Icon(Icons.edit_rounded, color: AppTheme.outline),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Settings list
            Text('Preferensi', style: AppTheme.h3),
            const SizedBox(height: 16),
            
            _SettingsItem(
              icon: Icons.dark_mode_rounded,
              title: 'Mode Gelap',
              subtitle: 'Aktif',
              trailing: Switch(
                value: true,
                onChanged: (_) {},
                activeThumbColor: AppTheme.primaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            _SettingsItem(
              icon: Icons.notifications_rounded,
              title: 'Notifikasi',
              subtitle: 'Atur pengingat',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _SettingsItem(
              icon: Icons.language_rounded,
              title: 'Bahasa',
              subtitle: 'Indonesia',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _SettingsItem(
              icon: Icons.mic_rounded,
              title: 'Pengaturan Voice',
              subtitle: 'Suara, bahasa',
              onTap: () {},
            ),

            const SizedBox(height: 24),

            Text('Data & Privasi', style: AppTheme.h3),
            const SizedBox(height: 16),
            
            _SettingsItem(
              icon: Icons.backup_rounded,
              title: 'Backup Data',
              subtitle: 'Simpan data ke cloud',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _SettingsItem(
              icon: Icons.delete_outline_rounded,
              title: 'Hapus Data',
              subtitle: 'Hapus semua data lokal',
              onTap: () {},
              isDanger: true,
            ),

            const SizedBox(height: 24),

            Text('Tentang', style: AppTheme.h3),
            const SizedBox(height: 16),
            
            _SettingsItem(
              icon: Icons.info_outline_rounded,
              title: 'Tentang NARA',
              subtitle: 'Versi 1.0.0',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _SettingsItem(
              icon: Icons.help_outline_rounded,
              title: 'Bantuan',
              subtitle: 'FAQ, kontak support',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _SettingsItem(
              icon: Icons.privacy_tip_outlined,
              title: 'Kebijakan Privasi',
              subtitle: 'Baca kebijakan privasi',
              onTap: () {},
            ),

            const SizedBox(height: 32),

            // Sign out button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: BorderSide(color: AppTheme.danger.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text('Keluar', style: AppTheme.label.copyWith(color: AppTheme.danger)),
              ),
            ),

            const SizedBox(height: 40),

            Center(
              child: Text(
                'NARA v1.0.0\nMade with ❤️',
                style: AppTheme.label.copyWith(color: AppTheme.outline),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDanger;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDanger 
                  ? AppTheme.danger.withValues(alpha: 0.2)
                  : AppTheme.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDanger ? AppTheme.danger : AppTheme.primaryContainer,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.label.copyWith(
                      color: isDanger ? AppTheme.danger : AppTheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTheme.body.copyWith(
                      color: AppTheme.outline,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right_rounded, color: AppTheme.outline),
          ],
        ),
      ),
    );
  }
}
