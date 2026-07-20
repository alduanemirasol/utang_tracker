import 'package:drift/drift.dart';

/// Tables mirror `rules/database_rules.md`.
/// DECIMAL(10,2) → integer centavos; UUID → TEXT; DATETIME → DateTime.
/// Soft delete: `deleted_at` null = active; non-null = deleted (kept for history).

@DataClassName('CustomerRow')
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DebtRow')
class Debts extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text().references(Customers, #id)();

  IntColumn get totalAmount => integer()();
  IntColumn get paidAmount => integer()();
  IntColumn get balance => integer()();
  TextColumn get status => text()();
  DateTimeColumn get transactionDate => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DebtItemRow')
class DebtItems extends Table {
  TextColumn get id => text()();
  TextColumn get debtId => text().references(Debts, #id)();
  TextColumn get productName => text()();

  /// Quantity supports fractions (e.g. 0.5); stored as REAL.
  RealColumn get quantity => real()();
  TextColumn get unit => text().withDefault(const Constant('piece'))();

  /// Final custom line amount in centavos; quantity does not multiply it.
  IntColumn get price => integer()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PaymentRow')
class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get debtId => text().references(Debts, #id)();
  IntColumn get amount => integer()();
  DateTimeColumn get paymentDate => dateTime()();
  TextColumn get paymentMethod => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
