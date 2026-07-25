import '../models/budget_plan.dart';
import '../models/transaction_entry.dart';
import 'dates.dart';

int dailyBudgetMinorUnitsForDate(BudgetPlan plan, DateTime date) {
  final currentDate = dateOnly(date);
  final startDate = dateOnly(plan.startDate);
  final endDate = dateOnly(plan.endDate);

  if (currentDate.isBefore(startDate) || currentDate.isAfter(endDate)) {
    return 0;
  }

  final totalDays = inclusiveDaysBetween(startDate, endDate);
  final dayIndex = currentDate.difference(startDate).inDays;
  final baseDailyAmount = plan.budgetMinorUnits ~/ totalDays;
  final remainder = plan.budgetMinorUnits % totalDays;

  return baseDailyAmount + (dayIndex < remainder ? 1 : 0);
}

int cumulativeBudgetMinorUnitsThroughDate(BudgetPlan plan, DateTime date) {
  final currentDate = dateOnly(date);
  final startDate = dateOnly(plan.startDate);
  final endDate = dateOnly(plan.endDate);

  if (currentDate.isBefore(startDate)) {
    return 0;
  }

  if (currentDate.isAfter(endDate)) {
    return plan.budgetMinorUnits;
  }

  final totalDays = inclusiveDaysBetween(startDate, endDate);
  final elapsedDays = inclusiveDaysBetween(startDate, currentDate);
  final baseDailyAmount = plan.budgetMinorUnits ~/ totalDays;
  final remainder = plan.budgetMinorUnits % totalDays;

  return baseDailyAmount * elapsedDays +
      (elapsedDays < remainder ? elapsedDays : remainder);
}

int expenseMinorUnitsThroughDate(
  Iterable<TransactionEntry> transactions,
  DateTime date,
) {
  final currentDate = dateOnly(date);

  return transactions.fold<int>(
    0,
    (total, transaction) {
      if (dateOnly(transaction.createdAt).isAfter(currentDate)) {
        return total;
      }

      return total + transaction.amountMinorUnits.abs();
    },
  );
}

int availableBudgetMinorUnitsThroughDate(
  BudgetPlan plan,
  DateTime date,
  Iterable<TransactionEntry> transactions,
) {
  return cumulativeBudgetMinorUnitsThroughDate(plan, date) -
      expenseMinorUnitsThroughDate(transactions, date);
}
