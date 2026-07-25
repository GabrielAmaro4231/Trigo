import 'package:flutter_test/flutter_test.dart';
import 'package:trigo/src/utils/dates.dart';

void main() {
  group('date utilities', () {
    test('adds one calendar month and clamps month-end dates', () {
      expect(
        oneCalendarMonthFrom(DateTime(2026, 1, 31)),
        DateTime(2026, 2, 28),
      );
      expect(
        oneCalendarMonthFrom(DateTime(2028, 1, 31)),
        DateTime(2028, 2, 29),
      );
      expect(
        oneCalendarMonthFrom(DateTime(2026, 12, 31)),
        DateTime(2027, 1, 31),
      );
    });

    test('counts inclusive date spans', () {
      expect(
        inclusiveDaysBetween(DateTime(2026, 7, 25), DateTime(2026, 7, 25)),
        1,
      );
      expect(
        inclusiveDaysBetween(DateTime(2026, 7, 25), DateTime(2026, 7, 27)),
        3,
      );
    });
  });
}
