import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trigo/src/data/local/app_database.dart';
import 'package:trigo/src/data/repositories/transaction_repository.dart';
import 'package:trigo/src/features/transactions/transaction_calculator_screen.dart';
import 'package:trigo/src/models/budget_plan.dart';
import 'package:trigo/src/models/transaction_entry.dart';
import 'package:trigo/src/theme/trigo_theme.dart';
import 'package:trigo/src/utils/dates.dart';
import 'package:trigo/src/widgets/budget_pill.dart';

void main() {
  late AppDatabase appDatabase;
  late Directory temporaryDirectory;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'trigo_transaction_screen_test_',
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

  testWidgets('saves one tagged expense and resets the selected tag', (
    tester,
  ) async {
    await _pumpCalculator(tester, appDatabase);
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));

    await tester.tap(find.text('Tag'));
    await _pumpAnimation(tester);
    await tester.tap(find.text('Bills'));
    await _pumpAnimation(tester);
    expect(find.text('Bills'), findsWidgets);

    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.tap(find.byIcon(Icons.check_rounded));
    await _pumpUntil(
      tester,
      () => find.text(r'$0.00').evaluate().isNotEmpty,
    );

    final transactions = await tester.runAsync(
      () => TransactionRepository(appDatabase).findAllNewestFirst(),
    );
    expect(transactions, isNotNull);
    final savedTransactions = transactions!;
    expect(savedTransactions, hasLength(1));
    expect(savedTransactions.single.amountMinorUnits, -1);
    expect(savedTransactions.single.tagId, 'bills');
    expect(find.text('Tag'), findsOneWidget);
  });

  testWidgets('deletes an expense after confirmation and refunds the budget', (
    tester,
  ) async {
    final now = DateTime.now();
    await tester.runAsync(
      () => TransactionRepository(appDatabase).insert(
        TransactionEntry(
          id: 'expense-to-delete',
          amountMinorUnits: -1234,
          createdAt: now,
        ),
      ),
    );
    await _pumpCalculator(tester, appDatabase);
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));

    await tester.tap(find.byType(BudgetPill));
    await _pumpAnimation(tester);
    await tester.tap(find.text(r'-$12.34'));
    await _pumpAnimation(tester);
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await _pumpAnimation(tester);

    final cancelButton = find.widgetWithText(FilledButton, 'Cancel');
    final deleteButton = find.widgetWithText(FilledButton, 'Delete');
    expect(cancelButton, findsOneWidget);
    expect(deleteButton, findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(cancelButton)
          .style
          ?.shape
          ?.resolve(<WidgetState>{}),
      tester
          .widget<FilledButton>(deleteButton)
          .style
          ?.shape
          ?.resolve(<WidgetState>{}),
    );

    await tester.tap(cancelButton);
    await _pumpAnimation(tester);
    final transactionsAfterCancel = await tester.runAsync(
      () => TransactionRepository(appDatabase).findAllNewestFirst(),
    );
    expect(transactionsAfterCancel, hasLength(1));

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await _pumpAnimation(tester);
    await tester.tap(deleteButton);
    await _pumpUntil(
      tester,
      () => find.text('No transactions yet').evaluate().isNotEmpty,
    );

    final transactionsAfterDeletion = await tester.runAsync(
      () => TransactionRepository(appDatabase).findAllNewestFirst(),
    );
    expect(transactionsAfterDeletion, isEmpty);
    expect(find.text('No transactions yet'), findsOneWidget);
    expect(find.text(r'Today $100.00'), findsOneWidget);
  });
}

Future<void> _pumpCalculator(
  WidgetTester tester,
  AppDatabase database,
) async {
  final today = dateOnly(DateTime.now());

  await tester.pumpWidget(
    MaterialApp(
      theme: TrigoTheme.light(),
      home: TransactionCalculatorScreen(
        plan: BudgetPlan(
          budgetMinorUnits: 10000,
          startDate: today,
          endDate: today,
        ),
        database: database,
      ),
    ),
  );
  await _pumpUntil(
    tester,
    () => find.byType(CircularProgressIndicator).evaluate().isEmpty,
  );
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition,
) async {
  for (var attempt = 0; attempt < 100; attempt += 1) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 10));

    if (condition()) {
      await tester.pump(const Duration(milliseconds: 400));
      return;
    }
  }

  fail('Timed out while waiting for asynchronous UI work.');
}

Future<void> _pumpAnimation(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
