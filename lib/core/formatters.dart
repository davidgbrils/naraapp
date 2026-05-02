String formatRupiah(num value) {
  final isNegative = value < 0;
  final absolute = value.abs().round();
  final formatted = absolute.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]}.',
  );

  return '${isNegative ? '-' : ''}Rp $formatted';
}
