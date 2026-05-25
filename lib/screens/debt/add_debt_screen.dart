import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/index.dart';
import '../../core/formatters.dart';
import '../../core/i18n.dart';
import '../../core/theme/nara_colors.dart';
import '../../core/theme/nara_radius.dart';
import '../../core/theme/nara_spacing.dart';
import '../../core/theme/nara_text_styles.dart';
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
  DateTime? _dueDate;

  @override
  void dispose() {
    _personController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveDebt() {
    final personName = _personController.text.trim();
    final amount = parseRupiahInput(_amountController.text);

    if (personName.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: NaraColors.surfaceWhite,
          content: Text(
            I18n.t(context, 'invalid_name_amount'),
            style: NaraTextStyles.body.copyWith(color: NaraColors.textPrimary),
          ),
        ),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    provider.addDebt({
      'title': personName,
      'amount': amount,
      'type': _debtType,
      'date': I18n.t(context, 'today'),
      'dueDate': _dueDate == null ? '' : _formatDate(_dueDate!),
      'note': _noteController.text.trim(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NaraColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(I18n.t(context, 'add_debt'), style: NaraTextStyles.h2),
            const SizedBox(height: 2),
            Text(
              I18n.t(context, 'add_debt_desc'),
              style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: NaraSpacing.md),
            child: IconButton(
              onPressed: _saveDebt,
              icon: Icon(Icons.check_rounded, color: _debtType == 'utang' ? NaraColors.danger : NaraColors.success),
              tooltip: I18n.t(context, 'save'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(NaraSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Debt Type Toggle
            NaraCard(
              padding: const EdgeInsets.all(NaraSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _debtType = 'utang'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: NaraSpacing.md),
                        decoration: BoxDecoration(
                          color: _debtType == 'utang' ? NaraColors.dangerLight : Colors.transparent,
                          borderRadius: BorderRadius.circular(NaraRadius.md),
                        ),
                        child: Center(
                          child: Text(
                            I18n.t(context, 'debt_me'),
                            style: NaraTextStyles.label.copyWith(
                              color: _debtType == 'utang' ? NaraColors.danger : NaraColors.textSecondary,
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
                        padding: const EdgeInsets.symmetric(vertical: NaraSpacing.md),
                        decoration: BoxDecoration(
                          color: _debtType == 'piutang' ? NaraColors.successLight : Colors.transparent,
                          borderRadius: BorderRadius.circular(NaraRadius.md),
                        ),
                        child: Center(
                          child: Text(
                            I18n.t(context, 'receivable_them'),
                            style: NaraTextStyles.label.copyWith(
                              color: _debtType == 'piutang' ? NaraColors.success : NaraColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: NaraSpacing.xl),

            Text(
              'Tanggal jatuh tempo (opsional)',
              style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary),
            ),
            const SizedBox(height: NaraSpacing.sm),
            InkWell(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? now,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 10),
                );
                if (picked != null && mounted) {
                  setState(() => _dueDate = DateUtils.dateOnly(picked));
                }
              },
              borderRadius: BorderRadius.circular(NaraRadius.lg),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: NaraSpacing.md, vertical: NaraSpacing.md),
                decoration: BoxDecoration(
                  color: NaraColors.surfaceCard,
                  borderRadius: BorderRadius.circular(NaraRadius.lg),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_rounded, color: NaraColors.primary),
                    const SizedBox(width: NaraSpacing.md),
                    Expanded(
                      child: Text(
                        _dueDate == null ? 'Pilih tanggal jatuh tempo' : _formatDate(_dueDate!),
                        style: NaraTextStyles.body.copyWith(
                          color: _dueDate == null ? NaraColors.textSecondary : NaraColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: NaraSpacing.sm),
            Text(
              _debtType == 'utang'
                  ? 'Anda berutang ke orang ini'
                  : 'Orang ini berutang ke Anda',
              style: NaraTextStyles.bodySmall.copyWith(color: NaraColors.textSecondary),
            ),
            const SizedBox(height: NaraSpacing.xl),

            // Person name
            Text(
              _debtType == 'utang' ? 'Nama pemberi pinjaman' : 'Nama peminjam',
              style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary),
            ),
            const SizedBox(height: NaraSpacing.sm),
            TextField(
              controller: _personController,
              style: NaraTextStyles.body,
              decoration: InputDecoration(
                hintText: _debtType == 'utang'
                    ? 'Contoh: Andi, Sari, Toko A'
                    : 'Contoh: Budi, Rina, Klien X',
                filled: true,
                fillColor: NaraColors.surfaceCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(NaraRadius.lg), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: NaraSpacing.xl),

            // Amount
            Text(
              _debtType == 'utang' ? 'Jumlah yang saya pinjam' : 'Jumlah yang dipinjam dari saya',
              style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary),
            ),
            const SizedBox(height: NaraSpacing.sm),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [RupiahInputFormatter()],
              style: NaraTextStyles.amountMedium.copyWith(color: _debtType == 'utang' ? NaraColors.danger : NaraColors.success),
              decoration: InputDecoration(
                hintText: '0.000',
                hintStyle: NaraTextStyles.amountMedium.copyWith(color: NaraColors.textHint.withValues(alpha: 0.5)),
                prefixText: 'Rp ',
                filled: true,
                fillColor: NaraColors.surfaceCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(NaraRadius.lg), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: NaraSpacing.xl),

            // Note
            Text(
              _debtType == 'utang'
                  ? 'Catatan (opsional) - misal alasan pinjaman'
                  : 'Catatan (opsional) - misal kebutuhan peminjam',
              style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary),
            ),
            const SizedBox(height: NaraSpacing.sm),
            TextField(
              controller: _noteController,
              maxLines: 3,
              style: NaraTextStyles.body,
              decoration: InputDecoration(
                hintText: I18n.t(context, 'note_hint'),
                filled: true,
                fillColor: NaraColors.surfaceCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(NaraRadius.lg), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: NaraSpacing.xxxl),

            // Save button
            NaraReveal(
              delay: const Duration(milliseconds: 120),
              child: NaraPrimaryButton(
                label: I18n.t(context, 'save'),
                onPressed: _saveDebt,
                icon: const Icon(Icons.save_rounded, size: 18, color: NaraColors.textOnPrimary),
                fullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const bulan = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${bulan[date.month - 1]} ${date.year}';
  }
}

