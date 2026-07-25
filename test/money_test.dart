import 'package:buckwheat/src/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('money formatting', () {
    test('formats minor units as dollars and cents', () {
      expect(formatCurrencyMinorUnits(0), r'$0.00');
      expect(formatCurrencyMinorUnits(1), r'$0.01');
      expect(formatCurrencyMinorUnits(1234), r'$12.34');
      expect(formatCurrencyMinorUnits(123456789), r'$1,234,567.89');
    });

    test('formats signed minor units', () {
      expect(formatSignedCurrencyMinorUnits(1), r'+$0.01');
      expect(formatSignedCurrencyMinorUnits(-1234), r'-$12.34');
    });

    test('parses currency input into minor units', () {
      expect(parseCurrencyInputToMinorUnits('100.34'), 10034);
      expect(parseCurrencyInputToMinorUnits('12.34'), 1234);
      expect(parseCurrencyInputToMinorUnits(r'$1,234.56'), 123456);
      expect(parseCurrencyInputToMinorUnits('99'), 9900);
    });
  });
}
