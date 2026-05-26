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
    {'name': 'Gaji', 'icon': Icons.work_rounded, 'color': NaraColors.success},
    {'name': 'Freelance', 'icon': Icons.laptop_mac_rounded, 'color': NaraColors.primary},
    {'name': 'Bisnis', 'icon': Icons.store_rounded, 'color': NaraColors.warning},
    {'name': 'Investasi', 'icon': Icons.trending_up_rounded, 'color': NaraColors.accentPurple},
    {'name': 'Lainnya', 'icon': Icons.more_horiz_rounded, 'color': NaraColors.textSecondary},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveIncome() async {
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
    final isDuplicate = provider.hasPotentialDuplicateIncome(
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
            'Pemasukan mirip baru saja dicatat. Tetap simpan?',
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

    provider.addIncome({
      'title': title,
      'amount': amount,
      'category': _selectedCategory,
      'time': I18n.t(context, 'today'),
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
            Text(I18n.t(context, 'add_income'), style: NaraTextStyles.h2),
            const SizedBox(height: 2),
            Text(
              I18n.t(context, 'add_income_desc'),
              style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: NaraSpacing.md),
            child: IconButton(
              onPressed: _saveIncome,
              icon: const Icon(Icons.check_rounded, color: NaraColors.success),
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
              style: NaraTextStyles.amountLarge.copyWith(color: NaraColors.success),
              decoration: InputDecoration(
                hintText: '0.000',
                hintStyle: NaraTextStyles.amountLarge.copyWith(color: NaraColors.textHint.withValues(alpha: 0.5)),
                prefixText: 'Rp ',
                prefixStyle: NaraTextStyles.amountLarge.copyWith(color: NaraColors.success),
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
                hintText: I18n.t(context, 'income_hint'),
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
            NaraReveal(
              delay: const Duration(milliseconds: 120),
              child: NaraPrimaryButton(
                label: I18n.t(context, 'save_income'),
                onPressed: _saveIncome,
                icon: const Icon(Icons.save_rounded, size: 18, color: NaraColors.textOnPrimary),
                fullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

