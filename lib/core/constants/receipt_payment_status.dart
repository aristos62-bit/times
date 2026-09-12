// core/constants/receipt_payment_status.dart
//
// SPoT Status Pattern — κατάσταση πληρωμής απόδειξης (type-safe layer πάνω
// στα AppConstants.paymentStatus*).
//
// Τα members "καταναλώνουν" τα υπάρχοντα `const String` του AppConstants
// (SPoT των αποθηκευμένων DB τιμών) — ΚΑΝΕΝΑ magic string εδώ. Ο λόγος που
// τα literals μένουν στο AppConstants: το `.g.dart` (γραμμή 3166) θέλει
// `const Constant(AppConstants.paymentStatusPending)` με compile-time const —
// δεν γίνεται delegate σε instance accessor (`enum.dbValue`) ούτε regen.
//
// Η χρήση: DAO φίλτρο/`_paymentStatus`, repository params, event filters,
// UI chip (ReceiptCard). Το drift DataClass `Receipt.paymentStatus` παραμένει
// String (schema) — η μετατροπή γίνεται στα boundaries με `fromDbValue`.
import '../debug/app_logger.dart';
import '../debug/debug_config.dart';
import 'app_constants.dart';

/// Κατάσταση πληρωμής απόδειξης — η μοναδική πηγή αλήθειας (SPoT Status).
enum ReceiptPaymentStatus {
  pending(AppConstants.paymentStatusPending),
  partial(AppConstants.paymentStatusPartial),
  paid(AppConstants.paymentStatusPaid);

  const ReceiptPaymentStatus(this.dbValue);

  /// Αποθηκευμένη τιμή DB ('pending' | 'partial' | 'paid').
  final String dbValue;

  /// Μετατροπή αποθηκευμένης DB τιμής → enum. ΑΥΣΤΗΡΟ (fail-fast):
  /// άγνωστη τιμή ρίχνει [ArgumentError] (+ debug log) — δεν υπάρχει
  /// σιωπηλό fallback (θα έκρυβε επιχειρηματικά λάθη).
  /// Οι τιμές γράφονται ΜΟΝΟ από `ReceiptDao._paymentStatus` (single-writer),
  /// άρα άγνωστη τιμή = bug ή χειροκίνητη αλλαγή στη βάση.
  static ReceiptPaymentStatus fromDbValue(String value) {
    for (final status in values) {
      if (status.dbValue == value) return status;
    }
    if (DebugConfig.isDebug) {
      AppLogger.error('ReceiptPaymentStatus: άγνωστη τιμή "$value"');
    }
    throw ArgumentError.value(
        value, 'dbValue', 'Άγνωστο ReceiptPaymentStatus (pending/partial/paid)');
  }
}