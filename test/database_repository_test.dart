import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trigo/src/data/local/app_database.dart';
import 'package:trigo/src/data/repositories/budget_repository.dart';
import 'package:trigo/src/data/repositories/expense_tag_repository.dart';
import 'package:trigo/src/data/repositories/transaction_repository.dart';
import 'package:trigo/src/models/budget_plan.dart';
import 'package:trigo/src/models/expense_tag.dart';
import 'package:trigo/src/models/transaction_entry.dart';

void main() {
  late AppDatabase appDatabase;
  late Directory temporaryDirectory;
  late String databasePath;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'trigo_database_repository_test_',
    );
    databasePath = p.join(temporaryDirectory.path, 'trigo.sqlite3');
    appDatabase = AppDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: databasePath,
    );
  });

  tearDown(() async {
    await appDatabase.close();
    await temporaryDirectory.delete(recursive: true);
  });

  group('SQLite repositories', () {
    test('persists and loads the active budget plan', () async {
      final repository = BudgetRepository(appDatabase);
      final plan = BudgetPlan(
        budgetMinorUnits: 10034,
        startDate: DateTime(2026, 7, 25),
        endDate: DateTime(2026, 8, 25),
      );

      await repository.saveActivePlan(plan);

      final loadedPlan = await repository.findActivePlan();
      expect(loadedPlan, isNotNull);
      expect(loadedPlan!.id, activeBudgetPlanId);
      expect(loadedPlan.budgetMinorUnits, 10034);
      expect(loadedPlan.startDate, DateTime(2026, 7, 25));
      expect(loadedPlan.endDate, DateTime(2026, 8, 25));
      expect(loadedPlan.currencySymbol, r'$');
    });

    test('keeps a saved plan and transactions after reopening the database',
        () async {
      final plan = BudgetPlan(
        budgetMinorUnits: 7500,
        startDate: DateTime(2026, 8),
        endDate: DateTime(2026, 8, 31),
      );
      await BudgetRepository(appDatabase).saveActivePlan(plan);
      await TransactionRepository(appDatabase).insert(
        TransactionEntry(
          id: 'persisted-transaction',
          amountMinorUnits: -325,
          createdAt: DateTime(2026, 8, 2, 9),
        ),
      );

      await appDatabase.close();
      appDatabase = AppDatabase(
        databaseFactory: databaseFactoryFfi,
        databasePath: databasePath,
      );

      final loadedPlan = await BudgetRepository(appDatabase).findActivePlan();
      final transactions =
          await TransactionRepository(appDatabase).findAllNewestFirst();

      expect(loadedPlan?.budgetMinorUnits, 7500);
      expect(transactions, hasLength(1));
      expect(transactions.single.id, 'persisted-transaction');
    });

    test('deletes a transaction permanently', () async {
      final repository = TransactionRepository(appDatabase);
      await repository.insert(
        TransactionEntry(
          id: 'to-delete',
          amountMinorUnits: -1299,
          createdAt: DateTime(2026, 8, 2, 9),
        ),
      );

      await repository.deleteById('to-delete');
      await appDatabase.close();
      appDatabase = AppDatabase(
        databaseFactory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      final reopenedRepository = TransactionRepository(appDatabase);

      expect(await reopenedRepository.findAllNewestFirst(), isEmpty);
    });

    test('seeds and saves tags in the selected order', () async {
      final repository = ExpenseTagRepository(appDatabase);

      final seededTags = await repository.findOrSeedDefaults();
      expect(
        seededTags.map((tag) => tag.name),
        <String>['Home', 'Bills', 'Groceries', 'Fun', 'Transport'],
      );

      final reorderedTags = <ExpenseTag>[
        seededTags[2],
        seededTags[0].copyWith(
          name: 'Casa',
          icon: Icons.local_cafe_rounded,
          colorValue: 0xFF33691E,
        ),
        seededTags[1],
      ];
      await repository.replaceAll(reorderedTags);

      final loadedTags = await repository.findAllOrdered();
      expect(
        loadedTags.map((tag) => tag.name),
        <String>['Groceries', 'Casa', 'Bills'],
      );
      expect(loadedTags[1].id, 'home');
      expect(loadedTags[1].iconCodePoint, Icons.local_cafe_rounded.codePoint);
      expect(loadedTags[1].colorValue, 0xFF33691E);
    });

    test('persists transactions newest first without losing tag references',
        () async {
      final tagRepository = ExpenseTagRepository(appDatabase);
      final transactionRepository = TransactionRepository(appDatabase);
      final tags = await tagRepository.findOrSeedDefaults();
      final firstTransaction = TransactionEntry(
        id: 'old',
        amountMinorUnits: -1234,
        createdAt: DateTime(2026, 7, 25, 9),
        tagId: tags.first.id,
      );
      final secondTransaction = TransactionEntry(
        id: 'new',
        amountMinorUnits: -2500,
        createdAt: DateTime(2026, 7, 25, 10),
      );

      await transactionRepository.insert(firstTransaction);
      await transactionRepository.insert(secondTransaction);
      await tagRepository.replaceAll(
        <ExpenseTag>[
          tags.first.copyWith(name: 'Casa'),
          ...tags.skip(1),
        ],
      );

      final transactions = await transactionRepository.findAllNewestFirst();
      expect(transactions.map((transaction) => transaction.id), <String>[
        'new',
        'old',
      ]);
      expect(transactions.first.tagId, isNull);
      expect(transactions.last.tagId, 'home');
    });
  });
}
