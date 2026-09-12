// features/receipt/domain/repositories/receipt_repository.dart
import '../../../../core/database/app_database.dart';
import '../models/receipt_input.dart';

/// SPO: Receipt Repository — abstract contract (Phase 3 Step 4).
///
/// Route A-Συνεπές: καθαρός delegate πάνω στον [ReceiptDao]. Τύποι: τα drift
/// DataClasses (`Receipt`, `ReceiptItem`) + τα input models (`ReceiptInput`,
/// `ReceiptItemUpdate`) από το receipt_input.dart (§5.1.3) ως current SPoT.
/// Καμία αλλαγή λογικής εδώ — οι 10 μέθοδοι αντιστοιχούν ακριβώς στο §5.1.4
/// του DESIGN (όσα χρειάζεται το BLoC/UI στο Βήμα 6· τα aggregates count/avg
/// του DAO §5.1.6 θα εκτεθούν όταν τα ζητήσει το Dashboard, Phase 8).
///
/// Reactive (Stream) για δεδομένα που αλλάζουν συχνά, Future για single-shot.
abstract class ReceiptRepository {
  /// Watch όλες τις αποδείξεις με φίλτρα (reactive, receiptDate desc + id tiebreak).
  Stream<List<Receipt>> watchAll({
    DateTime? startDate,
    DateTime? endDate,
    int? supplierId,
    String? paymentStatus,
  });

  /// Get receipt by id
  Future<Receipt?> getById(int id);

  /// Γραμμές μιας απόδειξης (reactive, id asc)
  Stream<List<ReceiptItem>> watchItemsByReceiptId(int receiptId);

  /// Δημιουργία απόδειξης — return: νέο id.
  /// Η αρίθμηση (counter), τα totals, το stock delta και τα price_history
  /// γίνονται μέσα στο transaction του [ReceiptDao].
  Future<int> create(ReceiptInput input);

  /// Ενημέρωση γραμμής απόδειξης (επανυπολογισμός totals + stock delta).
  Future<void> updateItem(int receiptId, int itemId, ReceiptItemUpdate update);

  /// Διαγραφή γραμμής απόδειξης (επαναφορά stock + refresh totals).
  Future<void> deleteItem(int receiptId, int itemId);

  /// Διαγραφή ολόκληρης απόδειξης (cascade: tags→items→payments→receipt).
  Future<void> delete(int id);

  /// Επόμενος αριθμός απόδειξης (για UI preview πριν την καταχώρηση).
  Future<int> getNextReceiptNumber();

  /// Σύνολο δαπανών εύρους ημερομηνιών (reactive, gross = total+vat).
  Stream<double> watchTotalByDateRange(DateTime start, DateTime end);

  /// Σύνολα ανά κατηγορία εύρους ημερομηνιών (reactive, gross, sorted desc).
  Stream<Map<String, double>> watchTotalByCategory(DateTime start, DateTime end);
}