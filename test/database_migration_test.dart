import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/database/app_database.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_item_unit.dart';

void main() {
  test('schema 3 debt items migrate to piece units', () async {
    final executor = NativeDatabase.memory(
      setup: (database) {
        database.execute('''
CREATE TABLE debt_items (
  id TEXT NOT NULL PRIMARY KEY,
  debt_id TEXT NOT NULL,
  product_name TEXT NOT NULL,
  quantity REAL NOT NULL,
  unit_price INTEGER NOT NULL,
  subtotal INTEGER NOT NULL,
  deleted_at INTEGER NULL
);
''');
        database.execute('''
INSERT INTO debt_items (
  id, debt_id, product_name, quantity, unit_price, subtotal, deleted_at
) VALUES ('item-1', 'debt-1', 'Rice', 2, 5000, 10000, NULL);
''');
        database.execute('PRAGMA user_version = 3;');
      },
    );
    final database = AppDatabase(executor);
    addTearDown(database.close);

    final item = await database.select(database.debtItems).getSingle();

    expect(item.unit, DebtItemUnits.piece);
    expect(database.schemaVersion, 4);
  });
}
