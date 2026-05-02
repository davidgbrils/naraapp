import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class AddDebtScreen extends StatefulWidget {
  const AddDebtScreen({super.key});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _personController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _debtType = 'utang'; // utang (i owe) or piutang (they owe me)

  @override
  void dispose() {
    _personController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveDebt() {
    final personName = _personController.text.trim();
    final amount = int.tryParse(_amountController.text) ?? 0;

    if (personName.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Isi nama dan jumlah yang valid', style: AppTheme.body)),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    provider.addDebt({
      'title': _debtType == 'utang' ? 'Utang $personName' : 'Piutang $personName',
      'amount': amount,
      'type': _debtType,
      'date': 'Hari ini',
      'note': _noteController.text.trim(),
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
        title: Text('Tambah Utang/Piutang', style: AppTheme.h3),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Debt Type Toggle
            GlassContainer(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _debtType = 'utang'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _debtType == 'utang' ? AppTheme.danger.withValues(alpha: 0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            'Utang (Saya)',
                            style: AppTheme.label.copyWith(
                              color: _debtType == 'utang' ? AppTheme.danger : AppTheme.outline,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _debtType = 'piutang'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _debtType == 'piutang' ? AppTheme.success.withValues(alpha: 0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            'Piutang (Dia)',
                            style: AppTheme.label.copyWith(
                              color: _debtType == 'piutang' ? AppTheme.success : AppTheme.outline,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Person name
            Text('Nama', style: AppTheme.label.copyWith(color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextField(
              controller: _personController,
              style: AppTheme.body,
              decoration: InputDecoration(
                hintText: 'Siapa yang berutang?',
                filled: true,
                fillColor: AppTheme.surfaceContainer,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            // Amount
            Text('Jumlah', style: AppTheme.label.copyWith(color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTheme.h2.copyWith(color: _debtType == 'utang' ? AppTheme.danger : AppTheme.success),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: AppTheme.h2.copyWith(color: AppTheme.outline.withValues(alpha: 0.5)),
                prefixText: 'Rp ',
                filled: true,
                fillColor: AppTheme.surfaceContainer,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            // Note
            Text('Catatan (Opsional)', style: AppTheme.label.copyWith(color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              style: AppTheme.body,
              decoration: InputDecoration(
                hintText: 'Tambahkan catatan...',
                filled: true,
                fillColor: AppTheme.surfaceContainer,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 40),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveDebt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _debtType == 'utang' 
                    ? AppTheme.danger.withValues(alpha: 0.2)
                    : AppTheme.success.withValues(alpha: 0.2),
                  foregroundColor: _debtType == 'utang' ? AppTheme.danger : AppTheme.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text('Simpan', style: AppTheme.label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
