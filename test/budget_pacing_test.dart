import 'package:flutter_test/flutter_test.dart';
import 'package:trigo/src/models/budget_plan.dart';
import 'package:trigo/src/models/transaction_entry.dart';
import 'package:trigo/src/utils/budget_pacing.dart';

void main() {
  group('budget pacing', () {
    test('spreads a budget across the selected dates', () {
      final plan = BudgetPlan(
        budgetMinorUnits: 30000,
        startDate: DateTime(2026, 7, 25),
        endDate: DateTime(2026, 8, 23),
      );

      expect(
        dailyBudgetMinorUnitsForDate(plan, DateTime(2026, 7, 25)),
        1000,
      );
      expect(
        dailyBudgetMinorUnitsForDate(plan, DateTime(2026, 8, 23)),
        1000,
      );
    });

    test('distributes remainder cents across the first days', () {
      final plan = BudgetPlan(
        budgetMinorUnits: 10000,
        startDate: DateTime(2026, 7, 25),
        endDate: DateTime(2026, 7, 27),
      );

      expect(
        dailyBudgetMinorUnitsForDate(plan, DateTime(2026, 7, 25)),
        3334,
      );
      expect(
        dailyBudgetMinorUnitsForDate(plan, DateTime(2026, 7, 26)),
        3333,
      );
      expect(
        dailyBudgetMinorUnitsForDate(plan, DateTime(2026, 7, 27)),
        3333,
      );
    });

    test('rolls unused previous-day money into the current day', () {
      final plan = BudgetPlan(
        budgetMinorUnits: 30000,
        startDate: DateTime(2026, 7, 25),
        endDate: DateTime(2026, 7, 27),
      );
      final transactions = <TransactionEntry>[
        TransactionEntry(
          id: 'one',
          amountMinorUnits: -4000,
          createdAt: DateTime(2026, 7, 25, 12),
        ),
      ];

      expect(
        availableBudgetMinorUnitsThroughDate(
          plan,
          DateTime(2026, 7, 26),
          transactions,
        ),
        16000,
      );
    });

    test('subtracts current-day expenses from rolled available money', () {
      final plan = BudgetPlan(
        budgetMinorUnits: 30000,
        startDate: DateTime(2026, 7, 25),
        endDate: DateTime(2026, 7, 27),
      );
      final transactions = <TransactionEntry>[
        TransactionEntry(
          id: 'one',
          amountMinorUnits: -4000,
          createdAt: DateTime(2026, 7, 25, 12),
        ),
        TransactionEntry(
          id: 'two',
          amountMinorUnits: -2500,
          createdAt: DateTime(2026, 7, 26, 9),
        ),
      ];

      expect(
        availableBudgetMinorUnitsThroughDate(
          plan,
          DateTime(2026, 7, 26),
          transactions,
        ),
        13500,
      );
    });
  });
}
