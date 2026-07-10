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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
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
        },
      );
}
