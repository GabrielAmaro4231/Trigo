import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase({
    DatabaseFactory? databaseFactory,
    String? databasePath,
  })  : _databaseFactory = databaseFactory,
        _databasePath = databasePath;

  static final AppDatabase instance = AppDatabase();

  static const int schemaVersion = 1;
  static const String databaseFileName = 'trigo.sqlite3';

  final DatabaseFactory? _databaseFactory;
  final String? _databasePath;

  Database? _database;

  Future<Database> get database async {
    final currentDatabase = _database;
    if (currentDatabase != null) {
      return currentDatabase;
    }

    final path = _databasePath ??
        p.join(
          await getDatabasesPath(),
          databaseFileName,
        );
    final options = OpenDatabaseOptions(
      version: schemaVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    final openedDatabase = _databaseFactory == null
        ? await openDatabase(
            path,
            version: schemaVersion,
            onConfigure: _onConfigure,
            onCreate: _onCreate,
            onUpgrade: _onUpgrade,
          )
        : await _databaseFactory.openDatabase(path, options: options);

    _database = openedDatabase;
    return openedDatabase;
  }

  Future<void> close() async {
    final currentDatabase = _database;
    if (currentDatabase == null) {
      return;
    }

    await currentDatabase.close();
    _database = null;
  }

  Future<void> _onConfigure(Database database) async {
    await database.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database database, int version) async {
    await database.execute('''
CREATE TABLE budget_plans (
  id TEXT PRIMARY KEY,
  budget_minor_units INTEGER NOT NULL,
  start_date_millis INTEGER NOT NULL,
  end_date_millis INTEGER NOT NULL,
  currency_symbol TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 0,
  created_at_millis INTEGER NOT NULL,
  updated_at_millis INTEGER NOT NULL
)
''');

    await database.execute('''
CREATE TABLE expense_tags (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  icon_code_point INTEGER NOT NULL,
  color_value INTEGER NOT NULL,
  sort_order INTEGER NOT NULL,
  created_at_millis INTEGER NOT NULL,
  updated_at_millis INTEGER NOT NULL
)
''');

    await database.execute('''
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  amount_minor_units INTEGER NOT NULL,
  created_at_millis INTEGER NOT NULL,
  tag_id TEXT NULL,
  FOREIGN KEY (tag_id) REFERENCES expense_tags(id) ON DELETE SET NULL
)
''');

    await database.execute(
      'CREATE INDEX idx_transactions_created_at '
      'ON transactions(created_at_millis DESC)',
    );
    await database.execute(
      'CREATE INDEX idx_expense_tags_sort_order '
      'ON expense_tags(sort_order ASC)',
    );
    await database.execute(
      'CREATE INDEX idx_budget_plans_active '
      'ON budget_plans(is_active)',
    );
  }

  Future<void> _onUpgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    // Future migrations will be added here as the schema evolves.
  }
}
