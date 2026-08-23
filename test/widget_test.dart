import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trigo/src/app.dart';
import 'package:trigo/src/data/local/app_database.dart';
import 'package:trigo/src/data/repositories/budget_repository.dart';
import 'package:trigo/src/features/setup/budget_setup_screen.dart';
import 'package:trigo/src/features/transactions/transaction_calculator_screen.dart';
import 'package:trigo/src/models/budget_plan.dart';
import 'package:trigo/src/utils/dates.dart';

void main() {
  late AppDatabase appDatabase;
  late Directory temporaryDirectory;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'trigo_widget_test_',
    );
    appDatabase = AppDatabase(
      databaseFactory: createDatabaseFactoryFfi(noIsolate: true),
      databasePath: p.join(temporaryDirectory.path, 'trigo.sqlite3'),
    );
  });

  tearDown(() async {
    await appDatabase.close();
    await temporaryDirectory.delete(recursive: true);
  });

  testWidgets('shows the budget setup screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BudgetSetupScreen(
          database: appDatabase,
          onPlanSaved: (_) {},
        ),
      ),
    );

    expect(find.text('Set budget'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Until'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('opens a persisted active budget without showing setup', (
    tester,
  ) async {
    final today = dateOnly(DateTime.now());
    await tester.runAsync(
      () => BudgetRepository(appDatabase).saveActivePlan(
        BudgetPlan(
          budgetMinorUnits: 10000,
          startDate: today,
          endDate: today,
        ),
      ),
    );
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));

    await tester.pumpWidget(TrigoApp(database: appDatabase));
    for (var attempt = 0; attempt < 100; attempt += 1) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 10));

      if (find.byType(TransactionCalculatorScreen).evaluate().isNotEmpty &&
          find.byType(CircularProgressIndicator).evaluate().isEmpty) {
        break;
      }
    }

    expect(find.byType(TransactionCalculatorScreen), findsOneWidget);
    expect(find.text('Set budget'), findsNothing);
  });
}
