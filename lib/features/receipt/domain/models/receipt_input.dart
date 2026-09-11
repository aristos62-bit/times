// features/receipt/domain/models/receipt_input.dart
import '../../../../core/constants/app_constants.dart';

/// SPoT: Input models του Receipt Feature (DESIGN §5.1.3).
///
/// Ορίζονται ΜΟΝΟ εδώ τα `ReceiptInput`, `ReceiptItemInput`, `PaymentInput`,
/// `ReceiptItemUpdate`. Τα εισάγουν: ReceiptDao (§4.3), abstract Repository
/// (§5.1.4) και impl (§5.1.5). ΔΕΝ επιτρέπεται δεύτερος ορισμός αλλού — το
/// placeholder `ReceiptItemInput` (validators.dart:165) αντικαθίσταται στο
/// Βήμα 5 (edit validators + test, με ξεχωριστή έγκριση). Ως τότε, κανένα
/// αρχείο δεν πρέπει να importάρει και τα δύο μαζί.
///
/// Route A-Συνεπές: immutable data carriers (BLoC → DAO → DB), χωρίς I/O,
/// logging (DebugConfig/AppLogger ζουν σε DAOs/BLoC) ή επικύρωση (Validators).
///
/// Στοίχιση με Drift tables (cross-check 11/09): τα πεδία αντιστοιχούν 1:1
/// στα receipts/receipt_items/payments. Υπολογιζόμενες στήλες (totals,
/// paymentStatus, receiptNumber, uuid, isSynced, createdAt/updatedAt) τις
/// θέτει Ο DAO. Οι στήλες `receipt_items.notes` & `payments.notes` ΔΕΝ
/// εκτίθενται εδώ (καμία καταναλωτής — μελλοντική επέκταση χωρίς schema
/// change). `paymentMethod` required στο input (ο πίνακας τη δέχεται nullable
/// — legacy).
///
/// Ημερομηνίες: LOCAL. Το UtcDateTimeConverter (§4.2) μετατρέπει σε UTC στη
/// βάση — κανένα .toUtc() εδώ.
class ReceiptInput {
  final DateTime date;
  final int supplierId;
  final String? invoiceNumber;
  final String? invoiceSeries;
  final String paymentMethod;
  final List<ReceiptItemInput> items;
  final List<PaymentInput> payments;
  final String? notes;

  const ReceiptInput({
    required this.date,
    required this.supplierId,
    this.invoiceNumber,
    this.invoiceSeries,
    required this.paymentMethod,
    required this.items,
    this.payments = const [],
    this.notes,
  });
}

/// Input για μία γραμμή (receipt item) της απόδειξης.
///
/// `vatRate` default = AppConstants.defaultVatRate (SPoT — όχι magic 24.0·
/// ταυτίζεται με το table default του receipt_items.vat_rate).
/// `discount` είναι ΠΟΣΟΣΤΟ (0-100): στο DAO υπολογίζεται
/// `discountAmount = (quantity * unitPrice) * (discount / 100)`.
/// Επιτρέπονται NaN/αρνητικά (pure carrier) — ο έλεγχος ανήκει στους
/// Validators (receiptItemInvalidQuantity / receiptItemNegativePrice).
class ReceiptItemInput {
  final int itemId;
  final double quantity;
  final double unitPrice;
  final double vatRate;
  final double discount;

  const ReceiptItemInput({
    required this.itemId,
    required this.quantity,
    required this.unitPrice,
    this.vatRate = AppConstants.defaultVatRate,
    this.discount = 0,
  });
}

/// Input για πληρωμή απόδειξης (μερική ή ολική → πολλές PaymentInput).
class PaymentInput {
  final double amount;
  final DateTime date;
  final String method;
  final String? reference;

  const PaymentInput({
    required this.amount,
    required this.date,
    required this.method,
    this.reference,
  });
}

/// Update για γραμμή απόδειξης — πλήρης αντικατάσταση τιμών (ο DAO
/// ξαναϋπολογίζει totals + stock). Όλα required — σκόπιμα (πλήρες restore,
/// χωρίς μερικά updates).
class ReceiptItemUpdate {
  final double quantity;
  final double unitPrice;
  final double vatRate;
  final double discount;

  const ReceiptItemUpdate({
    required this.quantity,
    required this.unitPrice,
    required this.vatRate,
    required this.discount,
  });
}