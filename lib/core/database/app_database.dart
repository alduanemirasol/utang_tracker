import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:utang_tracker/core/database/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Customers, Debts, DebtItems, Payments])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// In-memory DB for tests.
  AppDatabase.forTesting() : super(NativeDatabase.memory());

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'utang_tracker');
  }

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createIndexes();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(customers, customers.deletedAt);
            await m.addColumn(debts, debts.deletedAt);
            await m.addColumn(debtItems, debtItems.deletedAt);
            await m.addColumn(payments, payments.deletedAt);
          }
          if (from < 3) {
            // Drop debt_items.unit (SQLite: recreate table).
            await customStatement('''
CREATE TABLE debt_items_new (
  id TEXT NOT NULL PRIMARY KEY,
  debt_id TEXT NOT NULL REFERENCES debts (id),
  product_name TEXT NOT NULL,
  quantity REAL NOT NULL,
  unit_price INTEGER NOT NULL,
  subtotal INTEGER NOT NULL,
  deleted_at INTEGER NULL
);
''');
            await customStatement('''
INSERT INTO debt_items_new (
  id, debt_id, product_name, quantity, unit_price, subtotal, deleted_at
)
SELECT id, debt_id, product_name, quantity, unit_price, subtotal, deleted_at
FROM debt_items;
''');
            await customStatement('DROP TABLE debt_items;');
            await customStatement(
              'ALTER TABLE debt_items_new RENAME TO debt_items;',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_debt_items_debt_id ON debt_items (debt_id)',
            );
          }
        },
      );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_debts_customer_id ON debts (customer_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_debts_status ON debts (status)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_debts_transaction_date ON debts (transaction_date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_debt_items_debt_id ON debt_items (debt_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_payments_debt_id ON payments (debt_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_payments_payment_date ON payments (payment_date)',
    );
  }
}
