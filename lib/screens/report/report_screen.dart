import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/formatters.dart';
import '../../core/i18n.dart';
import '../../core/snackbar_utils.dart';
import '../../components/index.dart';
import '../../core/theme/nara_colors.dart';
import '../../core/theme/nara_radius.dart';
import '../../core/theme/nara_spacing.dart';
import '../../core/theme/nara_text_styles.dart';
import '../../providers/app_provider.dart';
import '../../services/notification_service.dart';

enum _ReportPeriod { week, month, year, custom }

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  _ReportPeriod _selectedPeriod = _ReportPeriod.week;
  String? _selectedCategoryFilter;
  DateTimeRange? _customRange;
  final NotificationService _notificationService = NotificationService();
  List<_DownloadHistoryItem> _downloadHistory = const [];
  static const String _downloadHistoryKey = 'report_download_history_v1';

  @override
  void initState() {
    super.initState();
    _loadDownloadHistory();
  }

  String _periodLabel() {
    switch (_selectedPeriod) {
      case _ReportPeriod.week:
        return I18n.t(context, 'this_week');
      case _ReportPeriod.month:
        return I18n.t(context, 'this_month');
      case _ReportPeriod.year:
        return I18n.t(context, 'this_year');
      case _ReportPeriod.custom:
        return _customRangeLabel();
    }
  }

  String _customRangeLabel() {
    final range = _customRange;
    if (range == null) return 'Rentang Kustom';
    final start = MaterialLocalizations.of(context).formatShortDate(range.start);
    final end = MaterialLocalizations.of(context).formatShortDate(range.end);
    return '$start - $end';
    }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initial = _customRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, now.day - 6),
          end: DateTime(now.year, now.month, now.day),
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
      initialDateRange: initial,
      saveText: 'Terapkan',
      helpText: 'Pilih rentang laporan',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _customRange = DateTimeRange(
        start: DateTime(picked.start.year, picked.start.month, picked.start.day),
        end: DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
      );
      _selectedPeriod = _ReportPeriod.custom;
    });
  }

  Future<void> _downloadSummary(
    AppProvider provider, {
    bool shareAfterDownload = false,
  }) async {
    final langCode = Localizations.localeOf(context).languageCode;
    final filteredExpenses = provider.expenses.where((e) => _isInSelectedPeriod(_extractDate(e))).toList();
    final filteredIncomes = provider.incomes.where((i) => _isInSelectedPeriod(_extractDate(i))).toList();
    final filteredDebts = provider.debts.where((d) => _isInSelectedPeriod(_extractDate(d))).toList();
    final totalExpense = filteredExpenses.fold<int>(0, (sum, e) => sum + ((e['amount'] as num?)?.round() ?? 0));
    final totalIncome = filteredIncomes.fold<int>(0, (sum, i) => sum + ((i['amount'] as num?)?.round() ?? 0));
    final totalUtang = filteredDebts
        .where((d) => d['type'] == 'utang')
        .fold<int>(0, (sum, d) => sum + ((d['amount'] as num?)?.round() ?? 0));
    final totalPiutang = filteredDebts
        .where((d) => d['type'] == 'piutang')
        .fold<int>(0, (sum, d) => sum + ((d['amount'] as num?)?.round() ?? 0));
    final balance = totalIncome - totalExpense;
    final categoryTotals = <String, int>{};
    for (final expense in filteredExpenses) {
      final category = (expense['category'] as String?) ?? 'Lainnya';
      final amount = ((expense['amount'] as num?)?.round() ?? 0);
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
    }
    final sortedCategories = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top3PdfCategories = sortedCategories.take(3).toList();

    final dir = await _resolveDownloadDirectory();
    late final String filePath;
    final pdf = pw.Document();
      const brandPrimary = PdfColor.fromInt(0xFF4B8CFF);
      const brandAccent = PdfColor.fromInt(0xFF22C55E);
      const brandWarm = PdfColor.fromInt(0xFFF59E0B);
      const brandText = PdfColor.fromInt(0xFF111827);
      const brandMuted = PdfColor.fromInt(0xFF6B7280);
      const brandBg = PdfColor.fromInt(0xFFF8FAFC);

      pw.Widget metricCard({
        required String title,
        required String value,
        required PdfColor stripe,
      }) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(10),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 4,
                height: 34,
                decoration: pw.BoxDecoration(
                  color: stripe,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(title, style: const pw.TextStyle(fontSize: 9, color: brandMuted)),
                    pw.SizedBox(height: 3),
                    pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brandText)),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      final topCategoryPdf = sortedCategories.isEmpty ? null : sortedCategories.first;
      final savingsRatePdf = totalIncome <= 0 ? 0.0 : ((totalIncome - totalExpense) / totalIncome) * 100;
      final generatedAt = DateTime.now();
      final generatedAtLabel =
          '${generatedAt.year}-${generatedAt.month.toString().padLeft(2, '0')}-${generatedAt.day.toString().padLeft(2, '0')} '
          '${generatedAt.hour.toString().padLeft(2, '0')}:${generatedAt.minute.toString().padLeft(2, '0')}';

      pdf.addPage(
        pw.MultiPage(
          pageTheme: const pw.PageTheme(
            margin: pw.EdgeInsets.fromLTRB(24, 28, 24, 28),
          ),
          footer: (context) => pw.Container(
            margin: const pw.EdgeInsets.only(top: 10),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated at $generatedAtLabel',
                  style: const pw.TextStyle(fontSize: 8, color: brandMuted),
                ),
                pw.Text(
                  'Page ${context.pageNumber} / ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: brandMuted),
                ),
              ],
            ),
          ),
          build: (context) {
            final maxCategory = sortedCategories.isEmpty ? 1 : sortedCategories.first.value;
            return [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: brandPrimary,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 38,
                      height: 38,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(20),
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'N',
                        style: pw.TextStyle(
                          color: brandPrimary,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            I18n.tByCode(langCode, 'report_title_upper'),
                            style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            '${I18n.tByCode(langCode, 'period')}: ${_periodLabel()}',
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
                          ),
                          pw.Text(
                            '${I18n.tByCode(langCode, 'date')}: ${generatedAt.toString().substring(0, 10)}',
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: brandBg,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  'NARA Finance Intelligence',
                  style: pw.TextStyle(fontSize: 9, color: brandMuted, fontStyle: pw.FontStyle.italic),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: metricCard(
                      title: I18n.tByCode(langCode, 'income'),
                      value: formatRupiah(totalIncome),
                      stripe: brandAccent,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: metricCard(
                      title: I18n.tByCode(langCode, 'expense'),
                      value: formatRupiah(totalExpense),
                      stripe: brandWarm,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: metricCard(
                      title: I18n.tByCode(langCode, 'balance'),
                      value: formatRupiah(balance),
                      stripe: brandPrimary,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: metricCard(
                      title: I18n.tByCode(langCode, 'debt_summary'),
                      value: '${formatRupiah(totalUtang)} / ${formatRupiah(totalPiutang)}',
                      stripe: PdfColors.red400,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Insight Otomatis',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brandText),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Cashflow: ${balance >= 0 ? 'Positif' : 'Negatif'} (${formatRupiah(balance)})',
                      style: const pw.TextStyle(fontSize: 10, color: brandMuted),
                    ),
                    pw.Text(
                      'Rasio tabungan: ${savingsRatePdf.toStringAsFixed(1)}%',
                      style: const pw.TextStyle(fontSize: 10, color: brandMuted),
                    ),
                    pw.Text(
                      topCategoryPdf == null
                          ? 'Kategori terbesar: belum ada data'
                          : 'Kategori terbesar: ${I18n.tByCode(langCode, _categoryKeyFromRaw(topCategoryPdf.key))} (${formatRupiah(topCategoryPdf.value)})',
                      style: const pw.TextStyle(fontSize: 10, color: brandMuted),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Top 3 Kategori Pengeluaran',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: brandText),
              ),
              pw.SizedBox(height: 8),
              if (top3PdfCategories.isEmpty)
                pw.Text('Belum ada data kategori pada periode ini', style: const pw.TextStyle(color: brandMuted))
              else
                ...top3PdfCategories.asMap().entries.map((entry) {
                  final rank = entry.key + 1;
                  final cat = entry.value;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(
                      '$rank. ${I18n.tByCode(langCode, _categoryKeyFromRaw(cat.key))} - ${formatRupiah(cat.value)}',
                      style: const pw.TextStyle(fontSize: 10, color: brandText),
                    ),
                  );
                }),
              pw.SizedBox(height: 12),
              pw.Text(
                I18n.tByCode(langCode, 'expense_categories'),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: brandText),
              ),
              pw.SizedBox(height: 8),
              if (sortedCategories.isEmpty)
                pw.Text(I18n.tByCode(langCode, 'no_category_data'), style: const pw.TextStyle(color: brandMuted))
              else
                ...sortedCategories.take(6).map((entry) {
                  final barWidth = (entry.value / maxCategory) * 180;
                  final percent = totalExpense == 0 ? 0 : ((entry.value / totalExpense) * 100).round();
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Row(
                      children: [
                        pw.SizedBox(
                          width: 84,
                          child: pw.Text(
                            I18n.tByCode(langCode, _categoryKeyFromRaw(entry.key)),
                            style: const pw.TextStyle(fontSize: 10, color: brandText),
                          ),
                        ),
                        pw.Container(
                          width: barWidth.toDouble(),
                          height: 10,
                          decoration: pw.BoxDecoration(
                            color: brandPrimary,
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                        ),
                        pw.SizedBox(width: 6),
                        pw.Text('$percent%', style: const pw.TextStyle(fontSize: 10, color: brandMuted)),
                      ],
                    ),
                  );
                }),
            ];
          },
        ),
      );
    final dateBounds = _selectedDateBounds();
    final start = _formatDateKey(dateBounds.start);
    final end = _formatDateKey(dateBounds.end);
    final defaultName = 'nara_laporan_${start}_sampai_$end';
    final customName = await _askReportFileName(defaultName);
    if (customName == null || customName.trim().isEmpty) return;
    final fileName = '${_sanitizeFileName(customName)}.pdf';
    filePath = await _resolveUniqueReportPath(dir, fileName);
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    if (!mounted) return;
    showAppSnackBar(
      context,
      backgroundColor: NaraColors.surfaceWhite,
      content: Text(
        '${I18n.t(context, 'download_success')} $filePath',
        style: NaraTextStyles.body.copyWith(color: NaraColors.textPrimary),
      ),
      action: SnackBarAction(
        label: 'Bagikan',
        onPressed: () => _shareReportFile(file),
        textColor: NaraColors.primary,
      ),
    );
    if (shareAfterDownload) {
      await _shareReportFile(file);
    }
    if (provider.notificationsEnabled && provider.transactionNotificationsEnabled) {
      await _notificationService.showDownloadSuccessNow(
        id: DateTime.now().millisecondsSinceEpoch.remainder(2147480000),
        title: 'Download berhasil',
        body: fileName,
        filePath: file.path,
      );
    }
    await _appendDownloadHistory(
      _DownloadHistoryItem(
        fileName: fileName,
        filePath: file.path,
        periodLabel: _periodLabel(),
        downloadedAt: DateTime.now(),
      ),
    );
  }

  Future<String?> _askReportFileName(String defaultName) async {
    final controller = TextEditingController(text: defaultName);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nama file laporan'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Masukkan nama file',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  String _sanitizeFileName(String value) {
    final sanitized = value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    if (sanitized.isEmpty) {
      return 'nara_laporan';
    }
    return sanitized;
  }

  Future<void> _loadDownloadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_downloadHistoryKey);
    if (raw == null || raw.isEmpty) {
      if (!mounted) return;
      setState(() => _downloadHistory = const []);
      return;
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final items = decoded
          .whereType<Map>()
          .map((e) => _DownloadHistoryItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final cleaned = await _filterExistingHistory(items);
      if (!mounted) return;
      setState(() => _downloadHistory = cleaned);
      await _persistDownloadHistory(cleaned);
    } catch (_) {
      if (!mounted) return;
      setState(() => _downloadHistory = const []);
    }
  }

  Future<void> _appendDownloadHistory(_DownloadHistoryItem item) async {
    final next = <_DownloadHistoryItem>[item, ..._downloadHistory]
        .where((e) => e.filePath.trim().isNotEmpty)
        .toList();
    final deduped = <String, _DownloadHistoryItem>{};
    for (final entry in next) {
      deduped[entry.filePath] = entry;
    }
    final limited = deduped.values.toList()
      ..sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
    final result = limited.take(30).toList();
    if (!mounted) return;
    setState(() => _downloadHistory = result);
    await _persistDownloadHistory(result);
  }

  Future<void> _persistDownloadHistory(List<_DownloadHistoryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_downloadHistoryKey, encoded);
  }

  Future<List<_DownloadHistoryItem>> _filterExistingHistory(
    List<_DownloadHistoryItem> items,
  ) async {
    final result = <_DownloadHistoryItem>[];
    for (final item in items) {
      if (await File(item.filePath).exists()) {
        result.add(item);
      }
    }
    return result;
  }

  Future<void> _openHistoryFile(_DownloadHistoryItem item) async {
    final file = File(item.filePath);
    if (!await file.exists()) {
      await _removeHistoryByPath(item.filePath);
      if (!mounted) return;
      showAppSnackBar(
        context,
        content: const Text('File tidak ditemukan. Riwayat sudah dibersihkan.'),
      );
      return;
    }
    await OpenFilex.open(item.filePath);
  }

  Future<void> _shareHistoryFile(_DownloadHistoryItem item) async {
    final file = File(item.filePath);
    if (!await file.exists()) {
      await _removeHistoryByPath(item.filePath);
      if (!mounted) return;
      showAppSnackBar(
        context,
        content: const Text('File tidak ditemukan. Riwayat sudah dibersihkan.'),
      );
      return;
    }
    await Share.shareXFiles([XFile(item.filePath)], text: 'Laporan keuangan NARA');
  }

  Future<void> _removeHistoryByPath(String path) async {
    final next = _downloadHistory.where((e) => e.filePath != path).toList();
    if (!mounted) return;
    setState(() => _downloadHistory = next);
    await _persistDownloadHistory(next);
  }

  void _showAllDownloadHistory() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(NaraSpacing.lg),
          child: NaraCard(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Semua Riwayat Unduhan', style: NaraTextStyles.h3),
                  const SizedBox(height: NaraSpacing.md),
                  if (_downloadHistory.isEmpty)
                    Text(
                      'Belum ada riwayat unduhan.',
                      style: NaraTextStyles.bodySmall.copyWith(color: NaraColors.textSecondary),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: _downloadHistory.length,
                        separatorBuilder: (context, index) => const SizedBox(height: NaraSpacing.sm),
                        itemBuilder: (context, index) {
                          final item = _downloadHistory[index];
                          final when =
                              '${MaterialLocalizations.of(context).formatShortDate(item.downloadedAt)} '
                              '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: item.downloadedAt.hour, minute: item.downloadedAt.minute), alwaysUse24HourFormat: true)}';
                          return Container(
                            padding: const EdgeInsets.all(NaraSpacing.sm),
                            decoration: BoxDecoration(
                              color: NaraColors.surfaceCard,
                              borderRadius: BorderRadius.circular(NaraRadius.md),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.fileName, style: NaraTextStyles.label),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.periodLabel} • $when',
                                  style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
                                ),
                                const SizedBox(height: NaraSpacing.xs),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    TextButton(
                                      onPressed: () => _openHistoryFile(item),
                                      child: const Text('Buka'),
                                    ),
                                    TextButton(
                                      onPressed: () => _shareHistoryFile(item),
                                      child: const Text('Bagikan'),
                                    ),
                                    TextButton(
                                      onPressed: () => _removeHistoryByPath(item.filePath),
                                      child: const Text('Hapus'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<String> _resolveUniqueReportPath(Directory dir, String fileName) async {
    final dotIndex = fileName.lastIndexOf('.');
    final base = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
    final ext = dotIndex > 0 ? fileName.substring(dotIndex) : '';

    var candidate = '${dir.path}${Platform.pathSeparator}$fileName';
    var counter = 1;
    while (await File(candidate).exists()) {
      candidate = '${dir.path}${Platform.pathSeparator}$base-$counter$ext';
      counter++;
    }
    return candidate;
  }

  Future<void> _shareReportFile(File file) async {
    if (!await file.exists()) return;
    final shareText = 'Laporan keuangan NARA (${_periodLabel()})';
    await Share.shareXFiles(
      [XFile(file.path)],
      text: shareText,
      subject: 'Laporan Keuangan NARA',
    );
  }

  ({DateTime start, DateTime end}) _selectedDateBounds() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case _ReportPeriod.week:
        return (
          start: DateTime(now.year, now.month, now.day - 6),
          end: DateTime(now.year, now.month, now.day),
        );
      case _ReportPeriod.month:
        return (
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
      case _ReportPeriod.year:
        return (
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31),
        );
      case _ReportPeriod.custom:
        final range = _customRange;
        if (range != null) {
          return (
            start: DateTime(range.start.year, range.start.month, range.start.day),
            end: DateTime(range.end.year, range.end.month, range.end.day),
          );
        }
        return (
          start: DateTime(now.year, now.month, now.day - 6),
          end: DateTime(now.year, now.month, now.day),
        );
    }
  }

  String _formatDateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _categoryKeyFromRaw(String raw) {
    switch (raw) {
      case 'Makan':
        return 'cat_food';
      case 'Transport':
        return 'cat_transport';
      case 'Belanja':
        return 'cat_shopping';
      case 'Kesehatan':
        return 'cat_health';
      case 'Hiburan':
        return 'cat_entertainment';
      case 'Gaji':
        return 'cat_salary';
      case 'Freelance':
        return 'cat_freelance';
      case 'Bisnis':
        return 'cat_business';
      case 'Investasi':
        return 'cat_investment';
      default:
        return 'cat_others';
    }
  }

  Future<Directory> _resolveDownloadDirectory() async {
    if (Platform.isAndroid) {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        return downloadDir;
      }
    }

    final platformDir = await getDownloadsDirectory();
    if (platformDir != null) {
      return platformDir;
    }

    return getApplicationDocumentsDirectory();
  }

  bool _isInSelectedPeriod(DateTime date) {
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case _ReportPeriod.week:
        return date.isAfter(now.subtract(const Duration(days: 7)));
      case _ReportPeriod.month:
        return date.year == now.year && date.month == now.month;
      case _ReportPeriod.year:
        return date.year == now.year;
      case _ReportPeriod.custom:
        final range = _customRange;
        if (range == null) return false;
        return !date.isBefore(range.start) && !date.isAfter(range.end);
    }
  }

  bool _isInPreviousSelectedPeriod(DateTime date) {
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case _ReportPeriod.week:
        final currentStart = now.subtract(const Duration(days: 7));
        final previousStart = now.subtract(const Duration(days: 14));
        return date.isAfter(previousStart) && !date.isAfter(currentStart);
      case _ReportPeriod.month:
        final currentMonthStart = DateTime(now.year, now.month, 1);
        final previousMonthStart = DateTime(now.year, now.month - 1, 1);
        return date.isAfter(previousMonthStart.subtract(const Duration(seconds: 1))) &&
            date.isBefore(currentMonthStart);
      case _ReportPeriod.year:
        return date.year == (now.year - 1);
      case _ReportPeriod.custom:
        final range = _customRange;
        if (range == null) return false;
        final spanDays = range.end.difference(range.start).inDays + 1;
        final previousEnd = range.start.subtract(const Duration(seconds: 1));
        final previousStart = previousEnd.subtract(Duration(days: spanDays - 1));
        return !date.isBefore(previousStart) && !date.isAfter(previousEnd);
    }
  }

  _TrendSummary _buildTrendSummary({
    required int current,
    required int previous,
    required bool preferLower,
  }) {
    if (previous <= 0 && current <= 0) {
      return const _TrendSummary(
        label: 'Belum ada data pembanding',
        color: NaraColors.textSecondary,
      );
    }
    if (previous <= 0 && current > 0) {
      return _TrendSummary(
        label: 'Naik 100.0% dari periode sebelumnya',
        color: preferLower ? NaraColors.danger : NaraColors.success,
      );
    }

    final diff = ((current - previous) / previous) * 100;
    final isUp = diff >= 0;
    final trendWord = isUp ? 'Naik' : 'Turun';
    final absDiff = diff.abs().toStringAsFixed(1);
    final isPositive = preferLower ? !isUp : isUp;
    return _TrendSummary(
      label: '$trendWord $absDiff% dari periode sebelumnya',
      color: isPositive ? NaraColors.success : NaraColors.danger,
    );
  }

  List<_TrendPoint> _buildTrendPoints(AppProvider provider) {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case _ReportPeriod.week:
        return List.generate(7, (offset) {
          final day = DateTime(now.year, now.month, now.day - (6 - offset));
          final income = provider.incomes
              .where((i) {
                final date = _extractDate(i);
                return date.year == day.year && date.month == day.month && date.day == day.day;
              })
              .fold<int>(0, (sum, i) => sum + ((i['amount'] as num?)?.round() ?? 0));
          final expense = provider.expenses
              .where((e) {
                final date = _extractDate(e);
                return date.year == day.year && date.month == day.month && date.day == day.day;
              })
              .fold<int>(0, (sum, e) => sum + ((e['amount'] as num?)?.round() ?? 0));
          const names = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
          return _TrendPoint(
            label: names[day.weekday % 7],
            income: income,
            expense: expense,
          );
        });
      case _ReportPeriod.month:
        return List.generate(4, (index) {
          final weekStart = now.subtract(Duration(days: (3 - index) * 7));
          final weekEnd = weekStart.add(const Duration(days: 6));
          final income = provider.incomes.where((i) {
            final date = _extractDate(i);
            return !date.isBefore(DateTime(weekStart.year, weekStart.month, weekStart.day)) &&
                !date.isAfter(DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59));
          }).fold<int>(0, (sum, i) => sum + ((i['amount'] as num?)?.round() ?? 0));
          final expense = provider.expenses.where((e) {
            final date = _extractDate(e);
            return !date.isBefore(DateTime(weekStart.year, weekStart.month, weekStart.day)) &&
                !date.isAfter(DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59));
          }).fold<int>(0, (sum, e) => sum + ((e['amount'] as num?)?.round() ?? 0));
          return _TrendPoint(label: 'W${index + 1}', income: income, expense: expense);
        });
      case _ReportPeriod.year:
        return List.generate(6, (index) {
          final monthDate = DateTime(now.year, now.month - (5 - index), 1);
          final income = provider.incomes.where((i) {
            final date = _extractDate(i);
            return date.year == monthDate.year && date.month == monthDate.month;
          }).fold<int>(0, (sum, i) => sum + ((i['amount'] as num?)?.round() ?? 0));
          final expense = provider.expenses.where((e) {
            final date = _extractDate(e);
            return date.year == monthDate.year && date.month == monthDate.month;
          }).fold<int>(0, (sum, e) => sum + ((e['amount'] as num?)?.round() ?? 0));
          const monthShort = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
          return _TrendPoint(label: monthShort[monthDate.month - 1], income: income, expense: expense);
        });
      case _ReportPeriod.custom:
        final range = _customRange;
        if (range == null) return const <_TrendPoint>[];
        final totalDays = range.end.difference(range.start).inDays + 1;
        final bucketCount = totalDays < 6 ? totalDays : 6;
        if (bucketCount <= 0) return const <_TrendPoint>[];
        final bucketSize = (totalDays / bucketCount).ceil();
        return List.generate(bucketCount, (index) {
          final start = range.start.add(Duration(days: index * bucketSize));
          var end = start.add(Duration(days: bucketSize - 1));
          if (end.isAfter(range.end)) end = range.end;
          final income = provider.incomes.where((i) {
            final date = _extractDate(i);
            return !date.isBefore(start) && !date.isAfter(DateTime(end.year, end.month, end.day, 23, 59, 59));
          }).fold<int>(0, (sum, i) => sum + ((i['amount'] as num?)?.round() ?? 0));
          final expense = provider.expenses.where((e) {
            final date = _extractDate(e);
            return !date.isBefore(start) && !date.isAfter(DateTime(end.year, end.month, end.day, 23, 59, 59));
          }).fold<int>(0, (sum, e) => sum + ((e['amount'] as num?)?.round() ?? 0));
          final label = '${start.day}/${start.month}';
          return _TrendPoint(label: label, income: income, expense: expense);
        });
    }
  }

  DateTime _extractDate(Map<String, dynamic> item) {
    final createdAt = item['createdAt'];
    if (createdAt is DateTime) return createdAt;
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompactWidth = screenWidth < 420;

    return Scaffold(
      backgroundColor: NaraColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 86,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              I18n.t(context, 'financial_report'),
              style: NaraTextStyles.h2,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            LayoutBuilder(
              builder: (context, constraints) => SizedBox(
                width: constraints.maxWidth,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    I18n.t(context, 'report_desc'),
                    style: NaraTextStyles.caption.copyWith(
                      color: NaraColors.textSecondary,
                      fontSize: isCompactWidth ? 10 : 11,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: isCompactWidth
            ? [
                Consumer<AppProvider>(
                  builder: (context, provider, _) => Padding(
                    padding: const EdgeInsets.only(right: NaraSpacing.sm),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: NaraColors.primary),
                      onSelected: (value) {
                        if (value == 'download') {
                          _downloadSummary(provider);
                        } else if (value == 'share') {
                          _downloadSummary(provider, shareAfterDownload: true);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'download',
                          child: Text(I18n.t(context, 'download_report')),
                        ),
                        const PopupMenuItem<String>(
                          value: 'share',
                          child: Text('Bagikan laporan'),
                        ),
                      ],
                    ),
                  ),
                ),
              ]
            : [
                Consumer<AppProvider>(
                  builder: (context, provider, _) => Padding(
                    padding: const EdgeInsets.only(right: NaraSpacing.md),
                    child: IconButton(
                      icon: const Icon(Icons.download_rounded, color: NaraColors.primary),
                      onPressed: () => _downloadSummary(provider),
                      tooltip: I18n.t(context, 'download_report'),
                    ),
                  ),
                ),
                Consumer<AppProvider>(
                  builder: (context, provider, _) => Padding(
                    padding: const EdgeInsets.only(right: NaraSpacing.md),
                    child: IconButton(
                      icon: const Icon(Icons.share_rounded, color: NaraColors.primary),
                      onPressed: () => _downloadSummary(provider, shareAfterDownload: true),
                      tooltip: 'Bagikan laporan',
                    ),
                  ),
                ),
              ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final filteredExpenses = provider.expenses.where((e) => _isInSelectedPeriod(_extractDate(e))).toList();
          final filteredIncomes = provider.incomes.where((i) => _isInSelectedPeriod(_extractDate(i))).toList();
          final filteredDebts = provider.debts.where((d) => _isInSelectedPeriod(_extractDate(d))).toList();

          final totalExpense = filteredExpenses.fold<int>(0, (sum, e) => sum + ((e['amount'] as num?)?.round() ?? 0));
          final totalIncome = filteredIncomes.fold<int>(0, (sum, i) => sum + ((i['amount'] as num?)?.round() ?? 0));
          final balance = totalIncome - totalExpense;
          final previousExpense = provider.expenses
              .where((e) => _isInPreviousSelectedPeriod(_extractDate(e)))
              .fold<int>(0, (sum, e) => sum + ((e['amount'] as num?)?.round() ?? 0));
          final previousIncome = provider.incomes
              .where((i) => _isInPreviousSelectedPeriod(_extractDate(i)))
              .fold<int>(0, (sum, i) => sum + ((i['amount'] as num?)?.round() ?? 0));
          final incomeTrend = _buildTrendSummary(
            current: totalIncome,
            previous: previousIncome,
            preferLower: false,
          );
          final expenseTrend = _buildTrendSummary(
            current: totalExpense,
            previous: previousExpense,
            preferLower: true,
          );
          final trendPoints = _buildTrendPoints(provider);

          final categoryTotals = <String, int>{};
          for (final expense in filteredExpenses) {
            final category = (expense['category'] as String?) ?? 'Lainnya';
            final amount = ((expense['amount'] as num?)?.round() ?? 0);
            categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
          }

          final categoryEntries = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final visibleCategoryEntries = _selectedCategoryFilter == null
              ? categoryEntries
              : categoryEntries.where((entry) => entry.key == _selectedCategoryFilter).toList();

          final totalUtang = filteredDebts
              .where((d) => d['type'] == 'utang')
              .fold<int>(0, (sum, d) => sum + ((d['amount'] as num?)?.round() ?? 0));
          final totalPiutang = filteredDebts
              .where((d) => d['type'] == 'piutang')
              .fold<int>(0, (sum, d) => sum + ((d['amount'] as num?)?.round() ?? 0));
          final topCategory = categoryEntries.isEmpty ? null : categoryEntries.first;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(NaraSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NaraCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: NaraChip(
                              label: I18n.t(context, 'week'),
                              selected: _selectedPeriod == _ReportPeriod.week,
                              onTap: () => setState(() => _selectedPeriod = _ReportPeriod.week),
                            ),
                          ),
                          const SizedBox(width: NaraSpacing.sm),
                          Expanded(
                            child: NaraChip(
                              label: I18n.t(context, 'month'),
                              selected: _selectedPeriod == _ReportPeriod.month,
                              onTap: () => setState(() => _selectedPeriod = _ReportPeriod.month),
                            ),
                          ),
                          const SizedBox(width: NaraSpacing.sm),
                          Expanded(
                            child: NaraChip(
                              label: I18n.t(context, 'year'),
                              selected: _selectedPeriod == _ReportPeriod.year,
                              onTap: () => setState(() => _selectedPeriod = _ReportPeriod.year),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: NaraSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: NaraChip(
                              label: _selectedPeriod == _ReportPeriod.custom
                                  ? _customRangeLabel()
                                  : 'Rentang Kustom',
                              selected: _selectedPeriod == _ReportPeriod.custom,
                              onTap: _pickCustomRange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: NaraSpacing.xxl),
                NaraCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Riwayat Unduhan', style: NaraTextStyles.h3),
                          if (_downloadHistory.length > 5)
                            TextButton(
                              onPressed: _showAllDownloadHistory,
                              child: Text(
                                'Lihat semua',
                                style: NaraTextStyles.caption.copyWith(
                                  color: NaraColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: NaraSpacing.sm),
                      if (_downloadHistory.isEmpty)
                        Text(
                          'Belum ada riwayat unduhan.',
                          style: NaraTextStyles.bodySmall.copyWith(color: NaraColors.textSecondary),
                        )
                      else
                        ..._downloadHistory.take(5).map((item) {
                          final when = '${MaterialLocalizations.of(context).formatShortDate(item.downloadedAt)} '
                              '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: item.downloadedAt.hour, minute: item.downloadedAt.minute), alwaysUse24HourFormat: true)}';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: NaraSpacing.sm),
                            child: Container(
                              padding: const EdgeInsets.all(NaraSpacing.sm),
                              decoration: BoxDecoration(
                                color: NaraColors.surfaceCard,
                                borderRadius: BorderRadius.circular(NaraRadius.md),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.fileName, style: NaraTextStyles.label),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.periodLabel} • $when',
                                    style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
                                  ),
                                  const SizedBox(height: NaraSpacing.xs),
                                  Row(
                                    children: [
                                      TextButton(
                                        onPressed: () => _openHistoryFile(item),
                                        child: const Text('Buka'),
                                      ),
                                      TextButton(
                                        onPressed: () => _shareHistoryFile(item),
                                        child: const Text('Bagikan'),
                                      ),
                                      TextButton(
                                        onPressed: () => _removeHistoryByPath(item.filePath),
                                        child: const Text('Hapus'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: NaraSpacing.xxl),
                if (isCompactWidth)
                  Column(
                    children: [
                      _SummaryCard(
                        title: I18n.t(context, 'income'),
                        amount: formatRupiah(totalIncome),
                        color: NaraColors.success,
                        icon: Icons.arrow_downward_rounded,
                        fullWidth: true,
                      ),
                      const SizedBox(height: NaraSpacing.md),
                      _SummaryCard(
                        title: I18n.t(context, 'expense'),
                        amount: formatRupiah(totalExpense),
                        color: NaraColors.accentOrange,
                        icon: Icons.arrow_upward_rounded,
                        fullWidth: true,
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: I18n.t(context, 'income'),
                          amount: formatRupiah(totalIncome),
                          color: NaraColors.success,
                          icon: Icons.arrow_downward_rounded,
                        ),
                      ),
                      const SizedBox(width: NaraSpacing.md),
                      Expanded(
                        child: _SummaryCard(
                          title: I18n.t(context, 'expense'),
                          amount: formatRupiah(totalExpense),
                          color: NaraColors.accentOrange,
                          icon: Icons.arrow_upward_rounded,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: NaraSpacing.md),
                _SummaryCard(
                  title: I18n.t(context, 'net_balance'),
                  amount: formatRupiah(balance),
                  color: balance < 0 ? NaraColors.danger : NaraColors.success,
                  icon: Icons.account_balance_wallet_rounded,
                  subtitle: I18n.t(context, 'balance_formula_hint'),
                  fullWidth: true,
                ),
                const SizedBox(height: NaraSpacing.md),
                NaraCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pemasukan: ${incomeTrend.label}',
                        style: NaraTextStyles.caption.copyWith(color: incomeTrend.color),
                      ),
                      const SizedBox(height: NaraSpacing.xs),
                      Text(
                        'Pengeluaran: ${expenseTrend.label}',
                        style: NaraTextStyles.caption.copyWith(color: expenseTrend.color),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: NaraSpacing.lg),
                _TrendChartCard(points: trendPoints),
                const SizedBox(height: NaraSpacing.xxl),
                NaraCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Top 3 Kategori Pengeluaran', style: NaraTextStyles.h3),
                      const SizedBox(height: NaraSpacing.sm),
                      if (categoryEntries.isEmpty)
                        Text(
                          'Belum ada data pengeluaran di periode ini',
                          style: NaraTextStyles.bodySmall.copyWith(color: NaraColors.textSecondary),
                        )
                      else
                        ...categoryEntries.take(3).toList().asMap().entries.map((entry) {
                          final rank = entry.key + 1;
                          final item = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: NaraSpacing.xs),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedCategoryFilter =
                                      _selectedCategoryFilter == item.key ? null : item.key;
                                });
                              },
                              borderRadius: BorderRadius.circular(NaraRadius.sm),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$rank. ${I18n.translateCategory(context, item.key)} • ${formatRupiah(item.value)}',
                                        style: NaraTextStyles.bodySmall.copyWith(color: NaraColors.textSecondary),
                                      ),
                                    ),
                                    if (_selectedCategoryFilter == item.key)
                                      Text(
                                        'Aktif',
                                        style: NaraTextStyles.caption.copyWith(
                                          color: NaraColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: NaraSpacing.lg),
                _InsightCard(
                  balance: balance,
                  totalIncome: totalIncome,
                  totalExpense: totalExpense,
                  topCategoryLabel: topCategory == null
                      ? null
                      : I18n.translateCategory(context, topCategory.key),
                  topCategoryAmount: topCategory?.value,
                ),
                const SizedBox(height: NaraSpacing.xxl),
                Text(I18n.t(context, 'by_category'), style: NaraTextStyles.h3),
                const SizedBox(height: NaraSpacing.lg),
                if (_selectedCategoryFilter != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Filter aktif: ${I18n.translateCategory(context, _selectedCategoryFilter!)}',
                          style: NaraTextStyles.caption.copyWith(color: NaraColors.primary),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _selectedCategoryFilter = null),
                        child: Text(
                          'Reset',
                          style: NaraTextStyles.caption.copyWith(color: NaraColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: NaraSpacing.sm),
                ],
                if (visibleCategoryEntries.isEmpty)
                  NaraEmptyState(
                    icon: Icons.insights_rounded,
                    title: I18n.t(context, 'no_period_data'),
                    message: I18n.t(context, 'no_period_data_message'),
                    accentColor: NaraColors.accentPurple,
                  )
                else
                  ...visibleCategoryEntries.map((entry) {
                    final percentage = totalExpense == 0 ? 0 : ((entry.value / totalExpense) * 100).round();
                    final colors = [
                      NaraColors.accentOrange,
                      NaraColors.primary,
                      NaraColors.accentPurple,
                      NaraColors.success,
                      NaraColors.warning,
                    ];
                    final color = colors[categoryEntries.indexOf(entry) % colors.length];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: NaraSpacing.md),
                      child: _CategoryItem(
                        category: I18n.translateCategory(context, entry.key),
                        amount: entry.value,
                        percentage: percentage,
                        color: color,
                      ),
                    );
                  }),
                const SizedBox(height: NaraSpacing.xxl),
                Text(I18n.t(context, 'debt_receivable_summary'), style: NaraTextStyles.h3),
                const SizedBox(height: NaraSpacing.lg),
                _DebtSummaryItem(
                  title: I18n.t(context, 'total_debt'),
                  amount: totalUtang,
                  color: NaraColors.danger,
                ),
                const SizedBox(height: NaraSpacing.md),
                _DebtSummaryItem(
                  title: I18n.t(context, 'total_receivable'),
                  amount: totalPiutang,
                  color: NaraColors.success,
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: null,
    );
  }

}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  final IconData icon;
  final bool fullWidth;
  final String? subtitle;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    this.fullWidth = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final content = NaraCard(
      borderRadius: NaraRadius.lg,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(NaraRadius.sm),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: NaraSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: NaraTextStyles.label.copyWith(color: NaraColors.textSecondary),
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.fade,
                ),
                const SizedBox(height: 2),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      amount,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      style: NaraTextStyles.h3.copyWith(color: color),
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: NaraTextStyles.caption.copyWith(
                      color: NaraColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: content);
    }

    return content;
  }
}

class _CategoryItem extends StatelessWidget {
  final String category;
  final int amount;
  final int percentage;
  final Color color;

  const _CategoryItem({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return NaraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category, style: NaraTextStyles.label),
              Text(
                formatRupiah(amount),
                style: NaraTextStyles.label.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: NaraSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(NaraRadius.xs),
            child: LinearProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              backgroundColor: NaraColors.textHint.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtSummaryItem extends StatelessWidget {
  final String title;
  final int amount;
  final Color color;

  const _DebtSummaryItem({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return NaraCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: NaraTextStyles.label),
          Text(
            formatRupiah(amount),
            style: NaraTextStyles.h3.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _TrendSummary {
  final String label;
  final Color color;

  const _TrendSummary({
    required this.label,
    required this.color,
  });
}

class _TrendPoint {
  final String label;
  final int income;
  final int expense;

  const _TrendPoint({
    required this.label,
    required this.income,
    required this.expense,
  });
}

class _TrendChartCard extends StatelessWidget {
  final List<_TrendPoint> points;

  const _TrendChartCard({
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold<int>(
      1,
      (max, p) => [max, p.income, p.expense].reduce((a, b) => a > b ? a : b),
    );

    return NaraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tren Pemasukan vs Pengeluaran', style: NaraTextStyles.h3),
          const SizedBox(height: NaraSpacing.sm),
          Row(
            children: [
              _LegendDot(color: NaraColors.success, label: 'Pemasukan'),
              const SizedBox(width: NaraSpacing.md),
              _LegendDot(color: NaraColors.accentOrange, label: 'Pengeluaran'),
            ],
          ),
          const SizedBox(height: NaraSpacing.lg),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: points.map((point) {
                final incomeHeight = (point.income / maxValue) * 110;
                final expenseHeight = (point.expense / maxValue) * 110;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () {
                        showAppSnackBar(
                          context,
                          content: Text(
                            '${point.label} • Pemasukan ${formatRupiah(point.income)} • Pengeluaran ${formatRupiah(point.expense)}',
                          ),
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                width: 8,
                                height: incomeHeight.clamp(4, 110).toDouble(),
                                decoration: BoxDecoration(
                                  color: NaraColors.success,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 8,
                                height: expenseHeight.clamp(4, 110).toDouble(),
                                decoration: BoxDecoration(
                                  color: NaraColors.accentOrange,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            point.label,
                            style: NaraTextStyles.caption.copyWith(
                              color: NaraColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: NaraTextStyles.caption.copyWith(color: NaraColors.textSecondary),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final int balance;
  final int totalIncome;
  final int totalExpense;
  final String? topCategoryLabel;
  final int? topCategoryAmount;

  const _InsightCard({
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
    required this.topCategoryLabel,
    required this.topCategoryAmount,
  });

  @override
  Widget build(BuildContext context) {
    final cashflowLabel = balance >= 0 ? 'Cashflow positif' : 'Cashflow negatif';
    final cashflowColor = balance >= 0 ? NaraColors.success : NaraColors.danger;
    final savingsRate = totalIncome <= 0
        ? 0.0
        : ((totalIncome - totalExpense) / totalIncome) * 100;

    return NaraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Insight Otomatis', style: NaraTextStyles.h3),
          const SizedBox(height: NaraSpacing.sm),
          Text(
            '$cashflowLabel • Saldo ${formatRupiah(balance)}',
            style: NaraTextStyles.bodySmall.copyWith(
              color: cashflowColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: NaraSpacing.xs),
          Text(
            'Rasio tabungan: ${savingsRate.toStringAsFixed(1)}%',
            style: NaraTextStyles.bodySmall.copyWith(color: NaraColors.textSecondary),
          ),
          const SizedBox(height: NaraSpacing.xs),
          Text(
            topCategoryLabel == null
                ? 'Belum ada kategori dominan di periode ini'
                : 'Kategori terbesar: $topCategoryLabel (${formatRupiah(topCategoryAmount ?? 0)})',
            style: NaraTextStyles.bodySmall.copyWith(color: NaraColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DownloadHistoryItem {
  final String fileName;
  final String filePath;
  final String periodLabel;
  final DateTime downloadedAt;

  const _DownloadHistoryItem({
    required this.fileName,
    required this.filePath,
    required this.periodLabel,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'filePath': filePath,
      'periodLabel': periodLabel,
      'downloadedAt': downloadedAt.toIso8601String(),
    };
  }

  factory _DownloadHistoryItem.fromJson(Map<String, dynamic> json) {
    return _DownloadHistoryItem(
      fileName: (json['fileName'] as String?) ?? 'laporan.pdf',
      filePath: (json['filePath'] as String?) ?? '',
      periodLabel: (json['periodLabel'] as String?) ?? '-',
      downloadedAt: DateTime.tryParse((json['downloadedAt'] as String?) ?? '') ?? DateTime.now(),
    );
  }
}


