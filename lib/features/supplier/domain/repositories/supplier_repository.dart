import '../../../../core/database/app_database.dart';

/// SPO: Supplier Repository — abstract contract (Phase 2 Step 4).
///
/// Route A-Συνεπές: καθαρός delegate πάνω στον SupplierDao. Τύποι: τα drift
/// DataClasses (`Supplier`/`SuppliersCompanion`) ως current SPoT entities.
///
/// Reactive (Stream) για δεδομένα που αλλάζουν συχνά, Future για single-shot.
abstract class SupplierRepository {
  /// Watch όλους τους ενεργούς προμηθευτές (reactive, sorted by name)
  Stream<List<Supplier>> watchAll();

  /// Αναζήτηση προμηθευτών με LIKE στο name (reactive)
  Stream<List<Supplier>> searchByName(String query);

  /// Get supplier by id
  Future<Supplier?> getById(int id);

  /// Δημιουργία προμηθευτή — return: νέο id
  Future<int> create(SuppliersCompanion companion);

  /// Ενημέρωση προμηθευτή (full replace — πλήρες companion με id)
  Future<bool> update(SuppliersCompanion companion);

  /// Soft delete (isActive = false)
  Future<void> softDelete(int id);

  /// Πλήθος αποδείξεων ενός προμηθευτή (για UI badges)
  Future<int> getReceiptCount(int id);
}