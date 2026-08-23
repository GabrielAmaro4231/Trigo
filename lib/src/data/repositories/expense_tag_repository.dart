import 'package:flutter/material.dart';
import '../../models/expense_tag.dart';
import '../local/app_database.dart';

class ExpenseTagRepository {
  const ExpenseTagRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<List<ExpenseTag>> findAllOrdered() async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      'expense_tags',
      orderBy: 'sort_order ASC',
    );

    return rows.map(_expenseTagFromRow).toList(growable: false);
  }

  Future<List<ExpenseTag>> findOrSeedDefaults() async {
    final existingTags = await findAllOrdered();
    if (existingTags.isNotEmpty) {
      return existingTags;
    }

    final tags = defaultExpenseTags();
    await replaceAll(tags);
    return tags;
  }

  Future<void> replaceAll(List<ExpenseTag> tags) async {
    final database = await _appDatabase.database;
    final nowMillis = DateTime.now().millisecondsSinceEpoch;

    await database.transaction((transaction) async {
      if (tags.isEmpty) {
        await transaction.delete('expense_tags');
        return;
      }

      final ids = tags.map((tag) => tag.id).toList(growable: false);
      await transaction.delete(
        'expense_tags',
        where: 'id NOT IN (${List<String>.filled(ids.length, '?').join(', ')})',
        whereArgs: ids,
      );

      for (var index = 0; index < tags.length; index += 1) {
        final row = _expenseTagToRow(
          tags[index],
          sortOrder: index,
          nowMillis: nowMillis,
        );
        final updatedRows = await transaction.update(
          'expense_tags',
          row,
          where: 'id = ?',
          whereArgs: <Object?>[tags[index].id],
        );

        if (updatedRows == 0) {
          await transaction.insert(
            'expense_tags',
            row,
          );
        }
      }
    });
  }
}

ExpenseTag _expenseTagFromRow(Map<String, Object?> row) {
  return ExpenseTag(
    id: row['id']! as String,
    name: row['name']! as String,
    icon: _iconForCodePoint(row['icon_code_point']! as int),
    colorValue: row['color_value']! as int,
  );
}

IconData _iconForCodePoint(int codePoint) {
  for (final option in tagIconOptions()) {
    if (option.icon.codePoint == codePoint) {
      return option.icon;
    }
  }

  return Icons.sell_rounded;
}

Map<String, Object?> _expenseTagToRow(
  ExpenseTag tag, {
  required int sortOrder,
  required int nowMillis,
}) {
  return <String, Object?>{
    'id': tag.id,
    'name': tag.name,
    'icon_code_point': tag.iconCodePoint,
    'color_value': tag.colorValue,
    'sort_order': sortOrder,
    'created_at_millis': nowMillis,
    'updated_at_millis': nowMillis,
  };
}
