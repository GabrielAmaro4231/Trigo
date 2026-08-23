import '../utils/money.dart';

const String activeBudgetPlanId = 'active';

class BudgetPlan {
  const BudgetPlan({
    required this.budgetMinorUnits,
    required this.startDate,
    required this.endDate,
    this.id = activeBudgetPlanId,
    this.currencySymbol = defaultCurrencySymbol,
  });

  final String id;

  /// Stored as minor currency units, e.g. cents for dollar-based currencies.
  final int budgetMinorUnits;
  final DateTime startDate;
  final DateTime endDate;
  final String currencySymbol;
}
