import 'package:sqflite/sqflite.dart';

import '../../models/transaction_entry.dart';
import '../local/app_database.dart';

class TransactionRepository {
  const TransactionRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<List<TransactionEntry>> findAllNewestFirst() async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      'transactions',
      orderBy: 'created_at_millis DESC',
    );

    return rows.map(_transactionFromRow).toList(growable: false);
  }

  Future<void> insert(TransactionEntry transaction) async {
    final database = await _appDatabase.database;

    await database.insert(
      'transactions',
      _transactionToRow(transaction),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteById(String id) async {
    final database = await _appDatabase.database;

    await database.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }
}

TransactionEntry _transactionFromRow(Map<String, Object?> row) {
  return TransactionEntry(
    id: row['id']! as String,
    amountMinorUnits: row['amount_minor_units']! as int,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      row['created_at_millis']! as int,
    ),
    tagId: row['tag_id'] as String?,
  );
}

Map<String, Object?> _transactionToRow(TransactionEntry transaction) {
  return <String, Object?>{
    'id': transaction.id,
    'amount_minor_units': transaction.amountMinorUnits,
    'created_at_millis': transaction.createdAt.millisecondsSinceEpoch,
    'tag_id': transaction.tagId,
  };
}
