import 'package:flutter_test/flutter_test.dart';
import 'package:trigo/src/models/expense_tag.dart';

void main() {
  group('expense tags', () {
    test('includes common default categories with stable ids', () {
      final tags = defaultExpenseTags();
      final ids = tags.map((tag) => tag.id).toList();
      final names = tags.map((tag) => tag.name).toList();

      expect(ids.toSet().length, tags.length);
      expect(tags.length, lessThanOrEqualTo(maxExpenseTagCount));
      expect(
        names,
        <String>[
          'Home',
          'Bills',
          'Groceries',
          'Fun',
          'Transport',
        ],
      );
      expect(
        ids,
        <String>[
          'home',
          'bills',
          'groceries',
          'fun',
          'transport',
        ],
      );
    });

    test('offers icon choices for editing', () {
      expect(tagIconOptions(), isNotEmpty);
    });
  });
}
