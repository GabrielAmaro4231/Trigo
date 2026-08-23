const String defaultCurrencySymbol = r'$';
const int maximumSupportedMinorUnits = 99999999999;

String formatCurrencyMinorUnits(
  int minorUnits, {
  String symbol = defaultCurrencySymbol,
}) {
  final sign = minorUnits < 0 ? '-' : '';
  final absoluteMinorUnits = minorUnits.abs();
  final majorUnits = absoluteMinorUnits ~/ 100;
  final cents = absoluteMinorUnits % 100;

  return '$sign$symbol${_formatMajorUnits(majorUnits)}.'
      '${cents.toString().padLeft(2, '0')}';
}

String formatSignedCurrencyMinorUnits(
  int minorUnits, {
  String symbol = defaultCurrencySymbol,
}) {
  final sign = minorUnits >= 0 ? '+' : '-';
  final absoluteMinorUnits = minorUnits.abs();
  final majorUnits = absoluteMinorUnits ~/ 100;
  final cents = absoluteMinorUnits % 100;

  return '$sign$symbol${_formatMajorUnits(majorUnits)}.'
      '${cents.toString().padLeft(2, '0')}';
}

int parseCurrencyInputToMinorUnits(String input) {
  final sanitized =
      input.replaceAll(',', '').replaceAll(RegExp(r'[^0-9.]'), '');

  if (sanitized.isEmpty) {
    return 0;
  }

  final firstDecimal = sanitized.indexOf('.');
  final majorText =
      firstDecimal == -1 ? sanitized : sanitized.substring(0, firstDecimal);
  final minorText = firstDecimal == -1
      ? ''
      : sanitized.substring(firstDecimal + 1).replaceAll('.', '');
  final majorUnits =
      BigInt.tryParse(majorText.isEmpty ? '0' : majorText) ?? BigInt.zero;
  final cents = int.tryParse(minorText.padRight(2, '0').substring(0, 2)) ?? 0;

  final minorUnits = majorUnits * BigInt.from(100) + BigInt.from(cents);
  final maximum = BigInt.from(maximumSupportedMinorUnits);

  return minorUnits > maximum ? maximumSupportedMinorUnits : minorUnits.toInt();
}

String _formatMajorUnits(int majorUnits) {
  final digits = majorUnits.toString();
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index += 1) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write(',');
    }

    buffer.write(digits[index]);
  }

  return buffer.toString();
}
