import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:utang_tracker/core/database/app_database.dart';
import 'package:utang_tracker/core/database/mappers.dart';
import 'package:utang_tracker/core/error/app_exception.dart';
import 'package:utang_tracker/core/utils/debt_math.dart';
import 'package:utang_tracker/core/utils/money.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_item.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_status.dart';
import 'package:utang_tracker/features/debts/domain/repositories/debt_repository.dart';

class DebtRepositoryImpl implements DebtRepository {
  DebtRepositoryImpl(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  Expression<bool> get _activeDebt => _db.debts.deletedAt.isNull();
  Expression<bool> get _activeCustomer => _db.customers.deletedAt.isNull();

  @override
  Future<List<Debt>> getAll({DebtStatus? status}) async {
    final query = _db.select(_db.debts).join([
      innerJoin(
        _db.customers,
        _db.customers.id.equalsExp(_db.debts.customerId),
      ),
    ])
      ..where(_activeDebt & _activeCustomer);
    if (status != null) {
      query.where(_db.debts.status.equals(status.value));
    }
    query.orderBy([OrderingTerm.desc(_db.debts.transactionDate)]);

    final rows = await query.get();
    return rows.map((row) {
      final debt = row.readTable(_db.debts);
      final customer = row.readTable(_db.customers);
      return mapDebt(debt, customerName: customer.name);
    }).toList();
  }

  @override
  Future<List<Debt>> getByCustomer(String customerId) async {
    final query = _db.select(_db.debts).join([
      innerJoin(
        _db.customers,
        _db.customers.id.equalsExp(_db.debts.customerId),
      ),
    ])
      ..where(
        _db.debts.customerId.equals(customerId) &
            _activeDebt &
            _activeCustomer,
      )
      ..orderBy([OrderingTerm.desc(_db.debts.transactionDate)]);

    final rows = await query.get();
    return rows.map((row) {
      final debt = row.readTable(_db.debts);
      final customer = row.readTable(_db.customers);
      return mapDebt(debt, customerName: customer.name);
    }).toList();
  }

  @override
  Future<DebtDetail?> getById(String id) async {
    final query = _db.select(_db.debts).join([
      innerJoin(
        _db.customers,
        _db.customers.id.equalsExp(_db.debts.customerId),
      ),
    ])
      ..where(
        _db.debts.id.equals(id) & _activeDebt & _activeCustomer,
      );

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final debtRow = row.readTable(_db.debts);
    final customer = row.readTable(_db.customers);
    final items = await (_db.select(_db.debtItems)
          ..where((t) => t.debtId.equals(id) & t.deletedAt.isNull()))
        .get();

    return DebtDetail(
      debt: mapDebt(debtRow, customerName: customer.name),
      items: items.map(mapDebtItem).toList(),
    );
  }

  @override
  Future<List<Debt>> getRecent({int limit = 5, DebtStatus? status}) async {
    final query = _db.select(_db.debts).join([
      innerJoin(
        _db.customers,
        _db.customers.id.equalsExp(_db.debts.customerId),
      ),
    ])
      ..where(_activeDebt & _activeCustomer);
    if (status != null) {
      query.where(_db.debts.status.equals(status.value));
    }
    query
      ..orderBy([OrderingTerm.desc(_db.debts.createdAt)])
      ..limit(limit);

    final rows = await query.get();
    return rows.map((row) {
      final debt = row.readTable(_db.debts);
      final customer = row.readTable(_db.customers);
      return mapDebt(debt, customerName: customer.name);
    }).toList();
  }

  @override
  Future<Debt> create({
    required String customerId,
    required DateTime transactionDate,
    DateTime? dueDate,
    String? notes,
    required List<DebtItemInput> items,
  }) async {
    _validateItems(items);

    final customer = await (_db.select(_db.customers)
          ..where((t) => t.id.equals(customerId) & t.deletedAt.isNull()))
        .getSingleOrNull();
    if (customer == null) {
      throw const NotFoundException('Customer not found.');
    }

    final prepared = _prepareItems(items);
    final total = DebtMath.computeTotal(prepared.map((e) => e.subtotal));
    final paid = Money.zero();
    final balance = DebtMath.computeBalance(
      totalAmount: total,
      paidAmount: paid,
    );
    final status = DebtMath.deriveStatus(
      totalAmount: total,
      paidAmount: paid,
    );

    final now = DateTime.now().toUtc();
    final debtId = _uuid.v4();

    await _db.transaction(() async {
      await _db.into(_db.debts).insert(
            DebtsCompanion.insert(
              id: debtId,
              customerId: customerId,
              totalAmount: total.centavos,
              paidAmount: paid.centavos,
              balance: balance.centavos,
              status: status.value,
              transactionDate: transactionDate.toUtc(),
              dueDate: Value(dueDate?.toUtc()),
              notes: Value(_emptyToNull(notes)),
              createdAt: now,
              updatedAt: now,
            ),
          );

      for (final item in prepared) {
        await _db.into(_db.debtItems).insert(
              DebtItemsCompanion.insert(
                id: _uuid.v4(),
                debtId: debtId,
                productName: item.productName,
                quantity: item.quantity,
                unitPrice: item.unitPrice.centavos,
                subtotal: item.subtotal.centavos,
              ),
            );
      }
    });

    final detail = await getById(debtId);
    return detail!.debt;
  }

  @override
  Future<Debt> update({
    required String id,
    required DateTime transactionDate,
    DateTime? dueDate,
    String? notes,
    required List<DebtItemInput> items,
  }) async {
    final existing = await getById(id);
    if (existing == null) {
      throw const NotFoundException('Debt not found.');
    }
    if (!existing.debt.isEditable) {
      throw const ConflictException(
        'Cannot edit a debt after payments have been recorded.',
      );
    }

    _validateItems(items);
    final prepared = _prepareItems(items);
    final total = DebtMath.computeTotal(prepared.map((e) => e.subtotal));
    final paid = Money.zero();
    final balance = DebtMath.computeBalance(
      totalAmount: total,
      paidAmount: paid,
    );
    final status = DebtMath.deriveStatus(
      totalAmount: total,
      paidAmount: paid,
    );
    final now = DateTime.now().toUtc();

    await _db.transaction(() async {
      // Soft-delete previous line items so history is retained.
      await (_db.update(_db.debtItems)
            ..where((t) => t.debtId.equals(id) & t.deletedAt.isNull()))
          .write(DebtItemsCompanion(deletedAt: Value(now)));

      final updated = await (_db.update(_db.debts)
            ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
          .write(
        DebtsCompanion(
          totalAmount: Value(total.centavos),
          paidAmount: Value(paid.centavos),
          balance: Value(balance.centavos),
          status: Value(status.value),
          transactionDate: Value(transactionDate.toUtc()),
          dueDate: Value(dueDate?.toUtc()),
          notes: Value(_emptyToNull(notes)),
          updatedAt: Value(now),
        ),
      );
      if (updated == 0) {
        throw const NotFoundException('Debt not found.');
      }

      for (final item in prepared) {
        await _db.into(_db.debtItems).insert(
              DebtItemsCompanion.insert(
                id: _uuid.v4(),
                debtId: id,
                productName: item.productName,
                quantity: item.quantity,
                unitPrice: item.unitPrice.centavos,
                subtotal: item.subtotal.centavos,
              ),
            );
      }
    });

    final detail = await getById(id);
    return detail!.debt;
  }

  @override
  Future<int> countActive() async {
    final count = countAll();
    final query = _db.selectOnly(_db.debts)
      ..addColumns([count])
      ..where(
        _activeDebt &
            _db.debts.status.isIn([
              DebtStatus.unpaid.value,
              DebtStatus.partial.value,
            ]),
      );
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  @override
  Future<int> outstandingBalanceCentavos() async {
    final sum = _db.debts.balance.sum();
    final query = _db.selectOnly(_db.debts)
      ..addColumns([sum])
      ..where(
        _activeDebt &
            _db.debts.status.isIn([
              DebtStatus.unpaid.value,
              DebtStatus.partial.value,
            ]),
      );
    final row = await query.getSingle();
    return row.read(sum) ?? 0;
  }

  void _validateItems(List<DebtItemInput> items) {
    if (items.isEmpty) {
      throw const ValidationException('Add at least one debt item.');
    }
    for (final item in items) {
      if (item.productName.trim().isEmpty) {
        throw const ValidationException('Product name is required.');
      }
      if (item.quantity <= 0) {
        throw const ValidationException('Quantity must be greater than zero.');
      }
      if (!item.unitPrice.isPositive) {
        throw const ValidationException('Price must be greater than zero.');
      }
    }
  }

  List<({String productName, double quantity, Money unitPrice, Money subtotal})>
      _prepareItems(List<DebtItemInput> items) {
    return items.map((item) {
      final subtotal = DebtMath.computeSubtotal(
        quantity: item.quantity,
        unitPrice: item.unitPrice,
      );
      return (
        productName: item.productName.trim(),
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        subtotal: subtotal,
      );
    }).toList();
  }

  String? _emptyToNull(String? value) {
    if (value == null) return null;
    final t = value.trim();
    return t.isEmpty ? null : t;
  }
}
