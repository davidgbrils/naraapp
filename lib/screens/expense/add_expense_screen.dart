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
  String _selectedCategory = 'Makan';
  final Map<String, String> _categoryIconMap = const {
    'Makan': 'restaurant',
    'Transport': 'directions_car',
    'Belanja': 'shopping_bag',
    'Kesehatan': 'local_hospital',
    'Hiburan': 'movie',
    'Lainnya': 'more_horiz',
  };

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Makan', 'icon': Icons.restaurant_rounded, 'color': NaraColors.accentOrange},
    {'name': 'Transport', 'icon': Icons.directions_car_rounded, 'color': NaraColors.primary},
    {'name': 'Belanja', 'icon': Icons.shopping_bag_rounded, 'color': NaraColors.accentPurple},
    {'name': 'Kesehatan', 'icon': Icons.local_hospital_rounded, 'color': NaraColors.danger},
    {'name': 'Hiburan', 'icon': Icons.movie_rounded, 'color': NaraColors.success},
    {'name': 'Lainnya', 'icon': Icons.more_horiz_rounded, 'color': NaraColors.textSecondary},
  ];

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
      'icon': _categoryIconMap[_selectedCategory] ?? 'shopping_bag',
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
            Text(I18n.t(context, 'amount'), style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary)),
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
                fillColor: NaraColors.surfaceCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(NaraRadius.lg), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: NaraSpacing.xl),

            // Title input
            Text(I18n.t(context, 'description'), style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary)),
            const SizedBox(height: NaraSpacing.sm),
            TextField(
              controller: _titleController,
              style: NaraTextStyles.body,
              decoration: InputDecoration(
                hintText: I18n.t(context, 'expense_hint'),
                filled: true,
                fillColor: NaraColors.surfaceCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(NaraRadius.lg), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: NaraSpacing.xl),

            // Category selection
            Text(I18n.t(context, 'category'), style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary)),
            const SizedBox(height: NaraSpacing.md),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: NaraSpacing.md,
              crossAxisSpacing: NaraSpacing.md,
              childAspectRatio: 1.2,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category['name'];
                final color = category['color'] as Color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category['name']),
                  child: NaraCard(
                    borderRadius: NaraRadius.lg,
                    backgroundColor: isSelected ? NaraColors.primaryLight : NaraColors.surfaceWhite,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          category['icon'],
                          color: isSelected ? color : NaraColors.textSecondary,
                          size: 28,
                        ),
                        const SizedBox(height: NaraSpacing.sm),
                        Text(
                          I18n.translateCategory(context, category['name'] as String),
                          style: NaraTextStyles.label.copyWith(
                            color: isSelected ? color : NaraColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
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
}

