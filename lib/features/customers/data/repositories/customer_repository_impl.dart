import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:utang_tracker/core/database/app_database.dart';
import 'package:utang_tracker/core/database/mappers.dart';
import 'package:utang_tracker/core/error/app_exception.dart';
import 'package:utang_tracker/features/customers/domain/entities/customer.dart';
import 'package:utang_tracker/features/customers/domain/repositories/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  CustomerRepositoryImpl(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  Expression<bool> get _active => _db.customers.deletedAt.isNull();

  @override
  Future<List<Customer>> getAll() async {
    final rows =
        await (_db.select(_db.customers)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.asc(t.name)]))
            .get();
    return rows.map(mapCustomer).toList();
  }

  @override
  Future<List<Customer>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();

    final rows =
        await (_db.select(_db.customers)
              ..where((t) => t.deletedAt.isNull() & t.name.lower().like('%$q%'))
              ..orderBy([(t) => OrderingTerm.asc(t.name)]))
            .get();
    return rows.map(mapCustomer).toList();
  }

  @override
  Future<Customer?> getById(String id) async {
    final row = await (_db.select(
      _db.customers,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
    return row == null ? null : mapCustomer(row);
  }

  @override
  Future<Customer> create({
    required String name,
    String? phone,
    String? notes,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const ValidationException('Customer name is required.');
    }
    await _ensureUniqueName(trimmed);

    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    await _db
        .into(_db.customers)
        .insert(
          CustomersCompanion.insert(
            id: id,
            name: trimmed,
            phone: Value(_emptyToNull(phone)),
            notes: Value(_emptyToNull(notes)),
            createdAt: now,
            updatedAt: now,
          ),
        );
    final created = await getById(id);
    return created!;
  }

  @override
  Future<Customer> update(Customer customer) async {
    final trimmed = customer.name.trim();
    if (trimmed.isEmpty) {
      throw const ValidationException('Customer name is required.');
    }
    await _ensureUniqueName(trimmed, excludeId: customer.id);

    final now = DateTime.now().toUtc();
    final updated =
        await (_db.update(
          _db.customers,
        )..where((t) => t.id.equals(customer.id) & t.deletedAt.isNull())).write(
          CustomersCompanion(
            name: Value(trimmed),
            phone: Value(_emptyToNull(customer.phone)),
            notes: Value(_emptyToNull(customer.notes)),
            updatedAt: Value(now),
          ),
        );
    if (updated == 0) {
      throw const NotFoundException('Customer not found.');
    }
    final result = await getById(customer.id);
    return result!;
  }

  @override
  Future<void> delete(String id) async {
    final existing = await getById(id);
    if (existing == null) {
      throw const NotFoundException('Customer not found.');
    }
    if (await hasDebts(id)) {
      throw const ConflictException(
        'Cannot delete a customer who still has debts.',
      );
    }

    final now = DateTime.now().toUtc();
    final updated =
        await (_db.update(
          _db.customers,
        )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).write(
          CustomersCompanion(deletedAt: Value(now), updatedAt: Value(now)),
        );
    if (updated == 0) {
      throw const NotFoundException('Customer not found.');
    }
  }

  @override
  Future<int> count() async {
    final count = countAll();
    final query = _db.selectOnly(_db.customers)
      ..addColumns([count])
      ..where(_active);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  @override
  Future<bool> hasDebts(String customerId) async {
    final row =
        await (_db.select(_db.debts)
              ..where(
                (t) => t.customerId.equals(customerId) & t.deletedAt.isNull(),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  /// Active customers must have unique names (case-insensitive).
  /// Soft-deleted customers are ignored so a name can be reused after delete.
  Future<void> _ensureUniqueName(String name, {String? excludeId}) async {
    final existing =
        await (_db.select(_db.customers)
              ..where((t) {
                var expr =
                    t.deletedAt.isNull() &
                    t.name.lower().equals(name.toLowerCase());
                if (excludeId != null) {
                  expr = expr & t.id.equals(excludeId).not();
                }
                return expr;
              })
              ..limit(1))
            .getSingleOrNull();

    if (existing != null) {
      throw const ConflictException(
        'A customer with this name already exists.',
      );
    }
  }

  String? _emptyToNull(String? value) {
    if (value == null) return null;
    final t = value.trim();
    return t.isEmpty ? null : t;
  }
}
