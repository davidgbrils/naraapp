import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Makan';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Makan', 'icon': Icons.restaurant_rounded, 'color': AppTheme.secondary},
    {'name': 'Transport', 'icon': Icons.directions_car_rounded, 'color': AppTheme.primaryContainer},
    {'name': 'Belanja', 'icon': Icons.shopping_bag_rounded, 'color': AppTheme.tertiary},
    {'name': 'Kesehatan', 'icon': Icons.local_hospital_rounded, 'color': AppTheme.danger},
    {'name': 'Hiburan', 'icon': Icons.movie_rounded, 'color': AppTheme.success},
    {'name': 'Lainnya', 'icon': Icons.more_horiz_rounded, 'color': AppTheme.outline},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _saveExpense() {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mohon isi semua data', style: AppTheme.body)),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    provider.addExpense({
      'title': _titleController.text,
      'amount': int.tryParse(_amountController.text) ?? 0,
      'category': _selectedCategory,
      'time': 'Hari ini',
      'icon': _categories.firstWhere((c) => c['name'] == _selectedCategory)['icon'].toString().split('.').last,
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
        title: Text('Tambah Pengeluaran', style: AppTheme.h3),
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
              style: AppTheme.h1.copyWith(color: AppTheme.secondary),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: AppTheme.h1.copyWith(color: AppTheme.outline.withValues(alpha: 0.5)),
                prefixText: 'Rp ',
                prefixStyle: AppTheme.h1.copyWith(color: AppTheme.secondary),
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
                hintText: 'Apa yang kamu belikan?',
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
                onPressed: _saveExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryContainer,
                  foregroundColor: AppTheme.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text('Simpan Pengeluaran', style: AppTheme.label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}