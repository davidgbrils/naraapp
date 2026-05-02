import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class CreateReminderScreen extends StatefulWidget {
  const CreateReminderScreen({super.key});

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  final _titleController = TextEditingController();
  String _selectedType = 'Pembayaran';
  String _selectedTime = 'Besok';

  final List<Map<String, dynamic>> _types = [
    {'name': 'Pembayaran', 'icon': Icons.payment_rounded},
    {'name': 'Tagihan', 'icon': Icons.receipt_long_rounded},
    {'name': 'Jadwal', 'icon': Icons.event_rounded},
    {'name': 'Lainnya', 'icon': Icons.more_horiz_rounded},
  ];

  final List<String> _times = [
    'Hari ini',
    'Besok',
    'Minggu ini',
    'Bulan ini',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _saveReminder() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mohon isi judul reminder', style: AppTheme.body)),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    provider.addReminder({
      'title': title,
      'type': _selectedType,
      'date': _selectedTime,
      'status': 'menunggu',
    });

    Navigator.pop(context);
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
        title: Text('Buat Reminder', style: AppTheme.h3),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title input
            Text('Judul Reminder', style: AppTheme.label.copyWith(color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: AppTheme.body,
              decoration: InputDecoration(
                hintText: 'Contoh: Bayar Listrik',
                filled: true,
                fillColor: AppTheme.surfaceContainer,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            // Type selection
            Text('Jenis Reminder', style: AppTheme.label.copyWith(color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _types.map((type) {
                final isSelected = _selectedType == type['name'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = type['name']),
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    borderRadius: 16,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          type['icon'],
                          color: isSelected ? AppTheme.tertiary : AppTheme.outline,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          type['name'],
                          style: AppTheme.label.copyWith(
                            color: isSelected ? AppTheme.tertiary : AppTheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Time selection
            Text('Waktu', style: AppTheme.label.copyWith(color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            Row(
              children: _times.map((time) {
                final isSelected = _selectedTime == time;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTime = time),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.tertiary.withValues(alpha: 0.2) : AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected 
                          ? Border.all(color: AppTheme.tertiary.withValues(alpha: 0.5))
                          : null,
                      ),
                      child: Center(
                        child: Text(
                          time,
                          style: AppTheme.label.copyWith(
                            color: isSelected ? AppTheme.tertiary : AppTheme.outline,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 40),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveReminder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.tertiary.withValues(alpha: 0.2),
                  foregroundColor: AppTheme.tertiary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text('Simpan Reminder', style: AppTheme.label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
