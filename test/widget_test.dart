import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trigo/src/data/local/app_database.dart';
import 'package:trigo/src/features/setup/budget_setup_screen.dart';

void main() {
  late AppDatabase appDatabase;
  late Directory temporaryDirectory;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'trigo_widget_test_',
    );
    appDatabase = AppDatabase(
      databaseFactory: databaseFactoryFfi,
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
}
