import 'package:sqflite/sqflite.dart';

import '../../models/budget_plan.dart';
import '../local/app_database.dart';

class BudgetRepository {
  const BudgetRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<BudgetPlan?> findActivePlan() async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      'budget_plans',
      where: 'is_active = ?',
      whereArgs: <Object?>[1],
      orderBy: 'updated_at_millis DESC',
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _budgetPlanFromRow(rows.single);
  }

  Future<void> saveActivePlan(BudgetPlan plan) async {
    final database = await _appDatabase.database;
    final nowMillis = DateTime.now().millisecondsSinceEpoch;

    await database.transaction((transaction) async {
      await transaction.update(
        'budget_plans',
        <String, Object?>{
          'is_active': 0,
          'updated_at_millis': nowMillis,
        },
        where: 'is_active = ?',
        whereArgs: <Object?>[1],
      );

      await transaction.insert(
        'budget_plans',
        _budgetPlanToRow(
          plan,
          nowMillis: nowMillis,
        ),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }
}

BudgetPlan _budgetPlanFromRow(Map<String, Object?> row) {
  return BudgetPlan(
    id: row['id']! as String,
    budgetMinorUnits: row['budget_minor_units']! as int,
    startDate: DateTime.fromMillisecondsSinceEpoch(
      row['start_date_millis']! as int,
    ),
    endDate: DateTime.fromMillisecondsSinceEpoch(
      row['end_date_millis']! as int,
    ),
    currencySymbol: row['currency_symbol']! as String,
  );
}

Map<String, Object?> _budgetPlanToRow(
  BudgetPlan plan, {
  required int nowMillis,
}) {
  return <String, Object?>{
    'id': plan.id,
    'budget_minor_units': plan.budgetMinorUnits,
    'start_date_millis': plan.startDate.millisecondsSinceEpoch,
    'end_date_millis': plan.endDate.millisecondsSinceEpoch,
    'currency_symbol': plan.currencySymbol,
    'is_active': 1,
    'created_at_millis': nowMillis,
    'updated_at_millis': nowMillis,
  };
}
