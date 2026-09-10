import '../../../../core/database/app_database.dart';

/// SPO: Item Repository — abstract contract (Phase 2 Step 4).
///
/// Route A-Συνεπές: οι Repositories είναι καθαροί delegates πάνω στους DAOs.
/// Τύποι: τα drift DataClasses (`Item`) + `ItemsCompanion` είναι τα current
/// SPoT entities — δεν δημιουργούνται domain entities/models τώρα (κανένας
/// consumer/BLoC/screen δεν υπάρχει ακόμα). Η πλήρης Clean-Architecture δομή
/// (entities/models/usecases) ανά feature έρχεται μαζί με το εκάστοτε feature.
///
/// Reactive (Stream) για δεδομένα που αλλάζουν συχνά, Future για single-shot.
abstract class ItemRepository {
  /// Watch όλα τα ενεργά είδη (reactive, sorted by name)
  Stream<List<Item>> watchAll();

  /// Watch ενεργά είδη μιας κατηγορίας (reactive)
  Stream<List<Item>> watchByCategory(int categoryId);

  /// Watch είδη με συγκεκριμένο barcode (reactive, exact match)
  Stream<List<Item>> watchByBarcode(String barcode);

  /// Αναζήτηση ειδών με LIKE στο name (reactive)
  Stream<List<Item>> searchByName(String query);

  /// Watch low-stock είδη (reorderLevel>0 AND currentStock<=reorderLevel)
  Stream<List<Item>> watchLowStock();

  /// Get item by id
  Future<Item?> getById(int id);

  /// Δημιουργία είδους — return: νέο id
  Future<int> create(ItemsCompanion companion);

  /// Ενημέρωση είδους (full replace — ο caller δίνει πλήρες companion με id)
  Future<bool> update(ItemsCompanion companion);

  /// Soft delete (isActive = false)
  Future<void> softDelete(int id);

  /// Αύξηση stock (atomic): currentStock = currentStock + quantity
  Future<void> increaseStock(
    int itemId,
    double quantity, {
    double? unitPrice,
    int? supplierId,
  });
}