import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/database/app_database.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_item_unit.dart';

void main() {
  test('schema 3 debt items migrate to piece units and final prices', () async {
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
    expect(item.price, 10000);
    expect(database.schemaVersion, 5);
  });

  test('schema 4 custom units and subtotals migrate without changes', () async {
    final executor = NativeDatabase.memory(
      setup: (database) {
        database.execute('''
CREATE TABLE debt_items (
  id TEXT NOT NULL PRIMARY KEY,
  debt_id TEXT NOT NULL,
  product_name TEXT NOT NULL,
  quantity REAL NOT NULL,
  unit TEXT NOT NULL DEFAULT 'piece',
  unit_price INTEGER NOT NULL,
  subtotal INTEGER NOT NULL,
  deleted_at INTEGER NULL
);
''');
        database.execute('''
INSERT INTO debt_items (
  id, debt_id, product_name, quantity, unit, unit_price, subtotal, deleted_at
) VALUES ('item-1', 'debt-1', 'Rice', 2, 'kg', 5000, 10000, NULL);
''');
        database.execute('PRAGMA user_version = 4;');
      },
    );
    final database = AppDatabase(executor);
    addTearDown(database.close);

    final item = await database.select(database.debtItems).getSingle();

    expect(item.unit, DebtItemUnits.kilogram);
    expect(item.price, 10000);
  });
}
