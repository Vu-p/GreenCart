String formatCurrency(double value) {
  final intValue = value.round();
  final buffer = StringBuffer();
  final str = intValue.abs().toString();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(str[i]);
  }
  final sign = intValue < 0 ? '-' : '';
  return '$sign${buffer.toString()} đ';
}
