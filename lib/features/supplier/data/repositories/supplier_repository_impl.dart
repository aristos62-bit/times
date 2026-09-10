import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/daos.dart';
import '../../domain/repositories/supplier_repository.dart';

/// SPO: Supplier Repository implementation (pure delegate).
///
/// Route A-Συνεπές: κάθε μέθοδος προωθεί 1:1 στον [SupplierDao] — χωρίς
/// validation, χωρίς mapping, χωρίς StreamControllers. Ο DAO είναι ο μόνος
/// SPoT του data-access layer. Το [getReceiptCount] χρησιμοποιεί το custom
/// aggregate query του SupplierDao (customSelect) για UI badges.
/// Instantiation: constructor injection (DI έρχεται σε επόμενη φάση).
class SupplierRepositoryImpl implements SupplierRepository {
  /// Ο μόνος dependency του repository — ο supplier DAO.
  final SupplierDao _dao;

  const SupplierRepositoryImpl(this._dao);

  @override
  Stream<List<Supplier>> watchAll() => _dao.watchAllSuppliers();

  @override
  Stream<List<Supplier>> searchByName(String query) =>
      _dao.searchSuppliersByName(query);

  @override
  Future<Supplier?> getById(int id) => _dao.getSupplierById(id);

  @override
  Future<int> create(SuppliersCompanion companion) =>
      _dao.createSupplier(companion);

  @override
  Future<bool> update(SuppliersCompanion companion) =>
      _dao.updateSupplier(companion);

  @override
  Future<void> softDelete(int id) => _dao.softDeleteSupplier(id);

  @override
  Future<int> getReceiptCount(int id) => _dao.getReceiptCount(id);
}