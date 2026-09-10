import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'supplier_dao.g.dart';

/// SPO: Supplier Data Access Object
@DriftAccessor(tables: [Suppliers, Receipts])
class SupplierDao extends DatabaseAccessor<AppDatabase>
    with _$SupplierDaoMixin {
  SupplierDao(super.db);

  /// Watch all active suppliers (reactive)
  Stream<List<Supplier>> watchAllSuppliers() {
    return (select(suppliers)
          ..where((s) => s.isActive.equals(true))
          ..orderBy([(s) => OrderingTerm.asc(s.name)]))
        .watch();
  }

  /// Search suppliers by name (LIKE, reactive)
  Stream<List<Supplier>> searchSuppliersByName(String query) {
    final pattern = '%${query.toLowerCase()}%';
    return (select(suppliers)
          ..where(
              (s) => s.isActive.equals(true) & s.name.lower().like(pattern))
          ..orderBy([(s) => OrderingTerm.asc(s.name)]))
        .watch();
  }

  /// Get supplier by id
  Future<Supplier?> getSupplierById(int id) =>
      (select(suppliers)..where((s) => s.id.equals(id))).getSingleOrNull();

  /// Δημιουργία προμηθευτή
  Future<int> createSupplier(SuppliersCompanion companion) =>
      into(suppliers).insert(companion);

  /// Ενημέρωση προμηθευτή
  Future<bool> updateSupplier(SuppliersCompanion companion) =>
      update(suppliers).replace(companion);

  /// Soft delete (isActive = false)
  Future<void> softDeleteSupplier(int id) async {
    await (update(suppliers)..where((s) => s.id.equals(id))).write(
      SuppliersCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Πλήθος αποδείξεων ενός προμηθευτή (για UI badges / στοιχεία ασφαλείας)
  Future<int> getReceiptCount(int id) async {
    final row = await (customSelect(
      'SELECT COUNT(*) as count FROM receipts WHERE supplier_id = ?',
      variables: [Variable.withInt(id)],
      readsFrom: {receipts},
    ))
        .getSingle();
    return row.read<int>('count');
  }
}
