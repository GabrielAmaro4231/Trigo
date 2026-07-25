import '../utils/money.dart';

class BudgetPlan {
  const BudgetPlan({
    required this.budgetMinorUnits,
    required this.startDate,
    required this.endDate,
    this.currencySymbol = defaultCurrencySymbol,
  });

  /// Stored as minor currency units, e.g. cents for dollar-based currencies.
  final int budgetMinorUnits;
  final DateTime startDate;
  final DateTime endDate;
  final String currencySymbol;
}
