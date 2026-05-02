import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class CatatPemasukanScreen extends StatefulWidget {
  const CatatPemasukanScreen({super.key});

  @override
  State<CatatPemasukanScreen> createState() => _CatatPemasukanScreenState();
}

class _CatatPemasukanScreenState extends State<CatatPemasukanScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Gaji';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Gaji', 'icon': Icons.work_rounded, 'color': AppTheme.success},
    {'name': 'Freelance', 'icon': Icons.laptop_mac_rounded, 'color': AppTheme.primaryContainer},
    {'name': 'Bisnis', 'icon': Icons.store_rounded, 'color': AppTheme.tertiary},
    {'name': 'Investasi', 'icon': Icons.trending_up_rounded, 'color': AppTheme.secondary},
    {'name': 'Lainnya', 'icon': Icons.more_horiz_rounded, 'color': AppTheme.outline},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _saveIncome() {
    final title = _titleController.text.trim();
    final amount = int.tryParse(_amountController.text) ?? 0;

    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Isi data dengan benar (jumlah harus lebih dari 0)', style: AppTheme.body)),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    provider.addIncome({
      'title': title,
      'amount': amount,
      'category': _selectedCategory,
      'time': 'Hari ini',
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
        title: Text('Catat Pemasukan', style: AppTheme.h3),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount input
            Text('Jumlah', style: AppTheme.label.copyWith(color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTheme.h1.copyWith(color: AppTheme.success),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: AppTheme.h1.copyWith(color: AppTheme.outline.withValues(alpha: 0.5)),
                prefixText: 'Rp ',
                prefixStyle: AppTheme.h1.copyWith(color: AppTheme.success),
                filled: true,
                fillColor: AppTheme.surfaceContainer,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            // Title input
            Text('Keterangan', style: AppTheme.label.copyWith(color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: AppTheme.body,
              decoration: InputDecoration(
                hintText: 'Apa sumber pemasukan?',
                filled: true,
                fillColor: AppTheme.surfaceContainer,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            // Category selection
            Text('Kategori', style: AppTheme.label.copyWith(color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category['name'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category['name']),
                  child: GlassContainer(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          category['icon'],
                          color: isSelected ? category['color'] : AppTheme.outline,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category['name'],
                          style: AppTheme.label.copyWith(
                            color: isSelected ? category['color'] : AppTheme.outline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
                onPressed: _saveIncome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success.withValues(alpha: 0.2),
                  foregroundColor: AppTheme.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text('Simpan Pemasukan', style: AppTheme.label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
