import 'package:drift/drift.dart';

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

  RealColumn get quantity => real()();
  TextColumn get unit => text().withDefault(const Constant('piece'))();

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
