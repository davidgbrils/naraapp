import 'package:flutter/services.dart';

String formatRupiah(num value) {
  final isNegative = value < 0;
  final absolute = value.abs().round();
  final formatted = absolute.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]}.',
  );

  return '${isNegative ? '-' : ''}Rp $formatted';
}

int parseRupiahInput(String input) {
  final digitsOnly = input.replaceAll('.', '').trim();
  return int.tryParse(digitsOnly) ?? 0;
}

class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final formatted = raw.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)}.',
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
