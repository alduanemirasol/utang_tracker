import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/database/app_database.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_item_unit.dart';

void main() {
  test('schema 3 debt items migrate to piece units and final prices', () async {
    final executor = NativeDatabase.memory(
      setup: (database) {
        _createIndexedTables(database);
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
        _createIndexedTables(database);
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

    final indexes = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_%'",
        )
        .get();
    expect(
      indexes.map((row) => row.read<String>('name')),
      containsAll([
        'idx_debts_customer_id',
        'idx_debts_status',
        'idx_debts_transaction_date',
        'idx_debt_items_debt_id',
        'idx_payments_debt_id',
        'idx_payments_payment_date',
      ]),
    );
  });

  test('schema 1 adds deleted_at columns and preserves data', () async {
    final executor = NativeDatabase.memory(
      setup: (database) {
        database.execute('''
CREATE TABLE customers (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT NULL,
  notes TEXT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
''');
        database.execute('''
CREATE TABLE debts (
  id TEXT NOT NULL PRIMARY KEY,
  customer_id TEXT NOT NULL,
  total_amount INTEGER NOT NULL,
  paid_amount INTEGER NOT NULL,
  balance INTEGER NOT NULL,
  status TEXT NOT NULL,
  transaction_date INTEGER NOT NULL,
  due_date INTEGER NULL,
  notes TEXT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
''');
        database.execute('''
CREATE TABLE debt_items (
  id TEXT NOT NULL PRIMARY KEY,
  debt_id TEXT NOT NULL,
  product_name TEXT NOT NULL,
  quantity REAL NOT NULL,
  unit_price INTEGER NOT NULL,
  subtotal INTEGER NOT NULL
);
''');
        database.execute('''
CREATE TABLE payments (
  id TEXT NOT NULL PRIMARY KEY,
  debt_id TEXT NOT NULL,
  amount INTEGER NOT NULL,
  payment_date INTEGER NOT NULL,
  payment_method TEXT NOT NULL,
  notes TEXT NULL,
  created_at INTEGER NOT NULL
);
''');
        database.execute('''
INSERT INTO customers (id, name, phone, created_at, updated_at)
VALUES ('cust-1', 'Legacy', NULL, 1, 1);
''');
        database.execute('''
INSERT INTO debts (
  id, customer_id, total_amount, paid_amount, balance, status,
  transaction_date, created_at, updated_at
) VALUES ('debt-1', 'cust-1', 10000, 0, 10000, 'unpaid', 1, 1, 1);
''');
        database.execute('''
INSERT INTO debt_items (
  id, debt_id, product_name, quantity, unit_price, subtotal
) VALUES ('item-1', 'debt-1', 'Rice', 2, 5000, 10000);
''');
        database.execute('''
INSERT INTO payments (
  id, debt_id, amount, payment_date, payment_method, notes, created_at
) VALUES ('payment-1', 'debt-1', 1000, 1, 'Cash', NULL, 1);
''');
        database.execute('PRAGMA user_version = 1;');
      },
    );
    final database = AppDatabase(executor);
    addTearDown(database.close);

    final customer = await database.select(database.customers).getSingle();
    expect(customer.name, 'Legacy');
    expect(customer.deletedAt, isNull);

    final debt = await database.select(database.debts).getSingle();
    expect(debt.status, 'unpaid');
    expect(debt.deletedAt, isNull);

    final item = await database.select(database.debtItems).getSingle();
    expect(item.productName, 'Rice');
    expect(item.price, 10000);

    final payment = await database.select(database.payments).getSingle();
    expect(payment.amount, 1000);
    expect(payment.deletedAt, isNull);

    expect(database.schemaVersion, 5);
  });

  test('fresh onCreate creates all tables and indexes', () async {
    final database = AppDatabase.forTesting();
    addTearDown(database.close);

    final indexes = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_%'",
        )
        .get();
    expect(
      indexes.map((row) => row.read<String>('name')),
      containsAll([
        'idx_debts_customer_id',
        'idx_debts_status',
        'idx_debts_transaction_date',
        'idx_debt_items_debt_id',
        'idx_payments_debt_id',
        'idx_payments_payment_date',
      ]),
    );

    final tables = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
        )
        .get();
    expect(
      tables.map((row) => row.read<String>('name')),
      containsAll(['customers', 'debts', 'debt_items', 'payments']),
    );
  });
}

void _createIndexedTables(dynamic database) {
  database.execute('''
CREATE TABLE debts (
  id TEXT NOT NULL PRIMARY KEY,
  customer_id TEXT NOT NULL,
  status TEXT NOT NULL,
  transaction_date INTEGER NOT NULL
);
''');
  database.execute('''
CREATE TABLE payments (
  id TEXT NOT NULL PRIMARY KEY,
  debt_id TEXT NOT NULL,
  payment_date INTEGER NOT NULL
);
''');
}
