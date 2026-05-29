import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/index.dart';
import '../../core/formatters.dart';
import '../../core/i18n.dart';
import '../../core/snackbar_utils.dart';
import '../../core/theme/nara_colors.dart';
import '../../core/theme/nara_radius.dart';
import '../../core/theme/nara_spacing.dart';
import '../../core/theme/nara_text_styles.dart';
import '../../providers/app_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  bool _showValidationHint = false;
  String _selectedCategory = 'Makan';
  static const Color _requiredFieldFill = Color(0xFFF8FBFF);
  static const Color _requiredFieldBorder = Color(0xFFBFD7FF);

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    final title = _titleController.text.trim();
    final amount = parseRupiahInput(_amountController.text);

    if (title.isEmpty || amount <= 0) {
      setState(() => _showValidationHint = true);
      showAppSnackBar(
        context,
        backgroundColor: NaraColors.surfaceWhite,
        content: Text(
          I18n.t(context, 'invalid_amount'),
          style: NaraTextStyles.body.copyWith(color: NaraColors.textPrimary),
        ),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    final isDuplicate = provider.hasPotentialDuplicateExpense(
      title: title,
      amount: amount,
      category: _selectedCategory,
    );
    if (isDuplicate) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Duplikasi terdeteksi', style: NaraTextStyles.h3),
          content: Text(
            'Transaksi mirip baru saja dicatat. Tetap simpan?',
            style: NaraTextStyles.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(I18n.t(context, 'cancel'), style: NaraTextStyles.label),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(I18n.t(context, 'continue'), style: NaraTextStyles.label),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    provider.addExpense({
      'title': title,
      'amount': amount,
      'category': _selectedCategory,
      'time': I18n.t(context, 'today'),
      'icon': _iconNameForCategory(_selectedCategory),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final categories = provider.expenseCategories;
    if (!categories.contains(_selectedCategory) && categories.isNotEmpty) {
      _selectedCategory = categories.first;
    }
    final amountInvalid = _showValidationHint && parseRupiahInput(_amountController.text) <= 0;
    final titleInvalid = _showValidationHint && _titleController.text.trim().isEmpty;
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
            Text(I18n.t(context, 'add_expense'), style: NaraTextStyles.h2),
            const SizedBox(height: 2),
            Text(
              I18n.t(context, 'add_expense_desc'),
              style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: NaraSpacing.md),
            child: IconButton(
              onPressed: _saveExpense,
              icon: const Icon(Icons.check_rounded, color: NaraColors.primary),
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
            // Amount input
            _RequiredLabel(text: I18n.t(context, 'amount')),
            const SizedBox(height: NaraSpacing.sm),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [RupiahInputFormatter()],
              style: NaraTextStyles.amountLarge.copyWith(color: NaraColors.accentOrange),
              decoration: InputDecoration(
                hintText: '0.000',
                hintStyle: NaraTextStyles.amountLarge.copyWith(color: NaraColors.textHint.withValues(alpha: 0.5)),
                prefixText: 'Rp ',
                prefixStyle: NaraTextStyles.amountLarge.copyWith(color: NaraColors.accentOrange),
                filled: true,
                fillColor: _requiredFieldFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(NaraRadius.lg),
                  borderSide: BorderSide(
                    color: amountInvalid ? NaraColors.danger : _requiredFieldBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(NaraRadius.lg),
                  borderSide: BorderSide(
                    color: amountInvalid ? NaraColors.danger : _requiredFieldBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(NaraRadius.lg),
                  borderSide: BorderSide(
                    color: amountInvalid ? NaraColors.danger : NaraColors.primary,
                    width: 1.8,
                  ),
                ),
              ),
            ),
            if (amountInvalid) ...[
              const SizedBox(height: 6),
              Text(
                'Nominal wajib diisi dan lebih dari 0',
                style: NaraTextStyles.caption.copyWith(color: NaraColors.danger),
              ),
            ],
            const SizedBox(height: NaraSpacing.xl),

            // Title input
            _RequiredLabel(text: I18n.t(context, 'description')),
            const SizedBox(height: NaraSpacing.sm),
            TextField(
              controller: _titleController,
              style: NaraTextStyles.body,
              decoration: InputDecoration(
                hintText: I18n.t(context, 'expense_hint'),
                filled: true,
                fillColor: _requiredFieldFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(NaraRadius.lg),
                  borderSide: BorderSide(
                    color: titleInvalid ? NaraColors.danger : _requiredFieldBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(NaraRadius.lg),
                  borderSide: BorderSide(
                    color: titleInvalid ? NaraColors.danger : _requiredFieldBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(NaraRadius.lg),
                  borderSide: BorderSide(
                    color: titleInvalid ? NaraColors.danger : NaraColors.primary,
                    width: 1.8,
                  ),
                ),
              ),
            ),
            if (titleInvalid) ...[
              const SizedBox(height: 6),
              Text(
                'Keterangan wajib diisi',
                style: NaraTextStyles.caption.copyWith(color: NaraColors.danger),
              ),
            ],
            const SizedBox(height: NaraSpacing.xl),

            // Category selection
            Text(I18n.t(context, 'category'), style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary)),
            const SizedBox(height: NaraSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              items: categories
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: category,
                      child: Text(I18n.translateCategory(context, category)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedCategory = value);
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: NaraColors.surfaceWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(NaraRadius.lg),
                ),
              ),
            ),

            const SizedBox(height: NaraSpacing.xxxl),

            // Save button
            NaraPrimaryButton(
              label: I18n.t(context, 'save_expense'),
              onPressed: _saveExpense,
              icon: const Icon(Icons.save_rounded, size: 18, color: NaraColors.textOnPrimary),
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  String _iconNameForCategory(String category) {
    final lower = category.trim().toLowerCase();
    if (lower == 'makan' || lower == 'food') return 'restaurant';
    if (lower == 'transport' || lower == 'trasnport' || lower == 'transportasi') {
      return 'directions_car';
    }
    if (lower == 'belanja' || lower == 'shopping') return 'shopping_bag';
    if (lower == 'kesehatan' || lower == 'health') return 'local_hospital';
    if (lower == 'hiburan' || lower == 'entertainment') return 'movie';
    return 'more_horiz';
  }
}

class _RequiredLabel extends StatelessWidget {
  final String text;

  const _RequiredLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: NaraColors.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(NaraRadius.pill),
          ),
          child: Text(
            '*Wajib',
            style: NaraTextStyles.caption.copyWith(
              color: NaraColors.danger,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

