// core/database/daos/receipt_dao.dart
import 'package:drift/drift.dart';

import '../../../features/receipt/domain/models/receipt_input.dart';
import '../../constants/app_constants.dart';
import '../../debug/app_logger.dart';
import '../../debug/debug_config.dart';
import '../../utils/extensions.dart';
import '../app_database.dart';
import '../tables/tables.dart';
import 'item_dao.dart';
import 'setting_dao.dart';
import 'tag_dao.dart';

part 'receipt_dao.g.dart';

/// SPO: Receipt Data Access Object — Phase 3 Step 2.
///
/// Αποκλίσεις από §4.3 (τεκμηριωμένες στο DESIGN):
///  - Αρίθμηση: counter μέσω `SettingDao.getSetting/setSetting` (SPoT —
///    χρησιμοποιεί το seeded setting `receipt_number_counter`), αντί
///    MAX(receiptNumber)+1 (μη επανάληψη αριθμών μετά από delete).
///  - Stock: reuse `ItemDao.increaseStock` (delta) αντί rebuild SUM —
///    αποφεύγει διπλότυπη λογική, διατηρεί το Fix #2 (UTC).
///  - Cascade tags: reuse `TagDao.removeAllTagsFromReceipt` (SPoT).
///  - Totals + paymentStatus: ενιαίο write `_refreshFinancials` (αντί των
///    δύο βημάτων `_updateReceiptTotals` + `_updatePaymentStatus` του §4.3).
///  - Line math: Dart record αντί της κλάσης `ReceiptItemData` (§4.3).
///  - Status literals: `AppConstants.paymentStatus*` (SPoT — συνεπή με το
///    table default, χωρίς magic strings).
///  - Paid-status: `DoubleExtensions.approximates` (ε=0.001) — ανοχή floating
///    errors αντί strict `remaining <= 0`.
///  - Κενά items: επιτρέπονται (block μόνο στο `Validators.validateReceipt`).
///  - Accessor tables: Items/Categories απαραίτητα για `readsFrom` των
///    aggregates (§5.1.6). Τα item/tag operations παραμένουν στους ειδικούς
///    DAOs (ItemDao/TagDao) — κανένα CRUD item εδώ.
@DriftAccessor(tables: [
  Receipts,
  ReceiptItems,
  Payments,
  PriceHistory,
  Items,
  Categories,
])
class ReceiptDao extends DatabaseAccessor<AppDatabase> with _$ReceiptDaoMixin {
  final SettingDao settingDao;
  final ItemDao itemDao;
  final TagDao tagDao;

  ReceiptDao(
    super.db, {
    required this.settingDao,
    required this.itemDao,
    required this.tagDao,
  });

  // Αρχική τιμή μετρητή — αντιστοιχεί στο seed της βάσης 'receipt_number_counter'.
  // Single SPoT: αν αλλάξει το seed, αλλάζει κι εδώ.
  static const int _initialCounterValue = 1;
  static const String _counterKey = 'receipt_number_counter';

  // -----------------------------------------------------------------------
  //  Watches / reads
  // -----------------------------------------------------------------------

  /// Παρακολούθηση αποδείξεων (reactive) με προαιρετικά φίλτρα.
  /// Δ5: ισοδύναμες ημερομηνίες ταξινομούνται με tiebreak `id desc`.
  Stream<List<Receipt>> watchAllReceipts({
    DateTime? startDate,
    DateTime? endDate,
    int? supplierId,
    String? paymentStatus,
  }) {
    return (select(receipts)
          ..where((r) {
            final filters = <Expression<bool>>[];
            if (startDate != null) {
              filters.add(
                  r.receiptDate.isBiggerOrEqualValue(startDate.toUtc()));
            }
            if (endDate != null) {
              filters.add(r.receiptDate.isSmallerOrEqualValue(endDate.toUtc()));
            }
            if (supplierId != null) {
              filters.add(r.supplierId.equals(supplierId));
            }
            if (paymentStatus != null) {
              filters.add(r.paymentStatus.equals(paymentStatus));
            }
            if (filters.isEmpty) return const Constant<bool>(true);
            return filters.reduce((a, b) => a & b);
          })
          ..orderBy([
            (r) => OrderingTerm.desc(r.receiptDate),
            (r) => OrderingTerm.desc(r.id),
          ]))
        .watch();
  }

  Future<Receipt?> getReceiptById(int id) =>
      (select(receipts)..where((r) => r.id.equals(id))).getSingleOrNull();

  /// Γραμμές απόδειξης (reactive). Ταξινόμηση: `id asc` (χρονολογική σειρά).
  Stream<List<ReceiptItem>> watchReceiptItems(int receiptId) {
    return (select(receiptItems)
          ..where((ri) => ri.receiptId.equals(receiptId))
          ..orderBy([(ri) => OrderingTerm.asc(ri.id)]))
        .watch();
  }

  // -----------------------------------------------------------------------
  //  Numbering
  // -----------------------------------------------------------------------

  /// Επόμενος αριθμός απόδειξης (μέσω SettingDao counter — SPoT).
  Future<int> getNextReceiptNumber() async {
    final value = await settingDao.getSetting(_counterKey);
    return int.tryParse(value ?? '$_initialCounterValue') ?? _initialCounterValue;
  }

  // -----------------------------------------------------------------------
  //  Mutations
  // -----------------------------------------------------------------------

  /// Δημιουργία απόδειξης (ατομική συναλλαγή). Επιστρέφει το νέο receiptId.
  ///
  /// Ο μετρητής αριθμοδότησης διαβάζεται και γράφεται από το ίδιο
  /// transaction → ατομικότητα μεταξύ settings και receipts.
  Future<int> createReceipt(ReceiptInput input) async {
    final receiptId = await transaction(() async {
      // 1. Αρίθμηση (counter)
      final nextNumber = await getNextReceiptNumber();
      final now = DateTime.now();

      // 2. Insert receipt
      final id = await into(receipts).insert(ReceiptsCompanion.insert(
        receiptNumber: nextNumber,
        receiptDate: input.date,
        supplierId: input.supplierId,
        invoiceNumber: Value(input.invoiceNumber),
        invoiceSeries: Value(input.invoiceSeries),
        paymentMethod: Value(input.paymentMethod),
        notes: Value(input.notes),
        createdAt: now,
        updatedAt: now,
      ));

      // 3. Γραμμές + stock + price_history
      for (final item in input.items) {
        final math = _lineMath(
            item.quantity, item.unitPrice, item.vatRate, item.discount);
        await into(receiptItems).insert(ReceiptItemsCompanion.insert(
          receiptId: id,
          itemId: item.itemId,
          quantity: Value(item.quantity),
          unitPrice: item.unitPrice,
          vatRate: Value(item.vatRate),
          vatAmount: Value(math.vatAmount),
          discount: Value(item.discount),
          totalPrice: math.totalPrice,
          totalWithVat: math.totalWithVat,
          createdAt: now,
        ));
        await itemDao.increaseStock(
          item.itemId,
          item.quantity,
          unitPrice: item.unitPrice,
          supplierId: input.supplierId,
        );
        await into(priceHistory).insert(PriceHistoryCompanion.insert(
          itemId: item.itemId,
          price: item.unitPrice,
          vatRate: Value(item.vatRate),
          receiptDate: input.date,
          supplierId: input.supplierId,
          quantity: Value(item.quantity),
          createdAt: now,
        ));
      }

      // 4. Πληρωμές
      for (final payment in input.payments) {
        await into(payments).insert(PaymentsCompanion.insert(
          receiptId: id,
          amount: payment.amount,
          paymentDate: payment.date,
          paymentMethod: payment.method,
          reference: Value(payment.reference),
          createdAt: now,
        ));
      }

      // 5. Σύνολα + κατάσταση πληρωμής
      await _refreshFinancials(id);

      // 6. Αύξηση μετρητή (στο ίδιο transaction)
      await settingDao.setSetting(_counterKey, '${nextNumber + 1}',
          type: 'int');

      return id;
    });
    return receiptId;
  }

  /// Ενημέρωση γραμμής απόδειξης (επανυπολογισμός totals + stock delta).
  /// Δ6: αν υπάρχουν πολλές γραμμές για το ίδιο itemId, ενημερώνονται ΟΛΕΣ.
  Future<void> updateReceiptItem(
    int receiptId,
    int itemId,
    ReceiptItemUpdate itemUpdate,
  ) async {
    await transaction(() async {
      final oldRows = await (select(receiptItems)
            ..where((ri) =>
                ri.receiptId.equals(receiptId) & ri.itemId.equals(itemId)))
            .get();
      if (oldRows.isEmpty) return;

      final totalOldQty =
          oldRows.fold<double>(0, (sum, r) => sum + r.quantity);
      final math = _lineMath(itemUpdate.quantity, itemUpdate.unitPrice,
          itemUpdate.vatRate, itemUpdate.discount);

      await (update(receiptItems)
            ..where((ri) =>
                ri.receiptId.equals(receiptId) & ri.itemId.equals(itemId)))
          .write(ReceiptItemsCompanion(
        quantity: Value(itemUpdate.quantity),
        unitPrice: Value(itemUpdate.unitPrice),
        vatRate: Value(itemUpdate.vatRate),
        discount: Value(itemUpdate.discount),
        totalPrice: Value(math.totalPrice),
        totalWithVat: Value(math.totalWithVat),
        vatAmount: Value(math.vatAmount),
      ));

      await _refreshFinancials(receiptId);
      // Stock delta: νέο συνολικό - παλιό συνολικό (Δ6: αφορά όλες τις γραμμές).
      await itemDao.increaseStock(itemId, itemUpdate.quantity - totalOldQty);
    });
  }

  /// Διαγραφή γραμμής απόδειξης (επαναφορά stock + επανυπολογισμός totals).
  Future<void> deleteReceiptItem(int receiptId, int itemId) async {
    await transaction(() async {
      final rows = await (select(receiptItems)
            ..where((ri) =>
                ri.receiptId.equals(receiptId) & ri.itemId.equals(itemId)))
            .get();
      if (rows.isEmpty) return;

      final totalQty = rows.fold<double>(0, (sum, r) => sum + r.quantity);
      await (delete(receiptItems)
            ..where((ri) =>
                ri.receiptId.equals(receiptId) & ri.itemId.equals(itemId)))
          .go();
      await _refreshFinancials(receiptId);
      await itemDao.increaseStock(itemId, -totalQty);
    });
  }

  /// Διαγραφή ολόκληρης απόδειξης (cascade: tags→items→payments→receipt).
  /// Price history διατηρείται (ιστορικό τιμών — §4.3), χωρίς FK violation.
  Future<void> deleteReceipt(int id) async {
    await transaction(() async {
      final items = await (select(receiptItems)
            ..where((ri) => ri.receiptId.equals(id)))
          .get();
      await tagDao.removeAllTagsFromReceipt(id);
      await (delete(receiptItems)..where((ri) => ri.receiptId.equals(id))).go();
      await (delete(payments)..where((p) => p.receiptId.equals(id))).go();
      await (delete(receipts)..where((r) => r.id.equals(id))).go();
      for (final item in items) {
        await itemDao.increaseStock(item.itemId, -item.quantity);
      }
    });
  }

  // -----------------------------------------------------------------------
  //  Private — line math
  // -----------------------------------------------------------------------

  /// Υπολογισμός γραμμής (net total, VAT, gross). Dart record αντί κλάσης
  /// `ReceiptItemData` (§4.3). `discount` είναι ΠΟΣΟΣΤΟ (0-100) — το δέχεται
  /// ως έχει (ακόμα και NaN/αρνητικά: pure carrier, έλεγχος στους Validators).
  ({double totalPrice, double vatAmount, double totalWithVat}) _lineMath(
    double quantity,
    double unitPrice,
    double vatRate,
    double discount,
  ) {
    final subtotal = quantity * unitPrice;
    final discountAmount = subtotal * (discount / 100.0);
    final taxable = subtotal - discountAmount;
    final vatAmount = taxable * (vatRate / 100.0);
    return (
      totalPrice: taxable,
      vatAmount: vatAmount,
      totalWithVat: taxable + vatAmount,
    );
  }

  // -----------------------------------------------------------------------
  //  Private — financial state refresh
  // -----------------------------------------------------------------------

  /// Ενημέρωση totals + paidAmount + remainingAmount + paymentStatus σε ΜΙΑ
  /// write (αντί των δύο βημάτων του §4.3 — λογικά ισοδύναμο, λιγότερες writes).
  Future<void> _refreshFinancials(int receiptId) async {
    final totals = await _sumTotals(receiptId);
    final paid = await _sumPaid(receiptId);
    final remaining = totals.total + totals.vat - paid;
    final status = _paymentStatus(remaining, paid);
    await (update(receipts)..where((r) => r.id.equals(receiptId))).write(
      ReceiptsCompanion(
        totalAmount: Value(totals.total),
        vatTotal: Value(totals.vat),
        discountTotal: Value(totals.discount),
        paidAmount: Value(paid),
        remainingAmount: Value(remaining),
        paymentStatus: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<({double total, double vat, double discount})> _sumTotals(
      int receiptId) async {
    final sw = Stopwatch()..start();
    try {
      final result = await customSelect(
        'SELECT COALESCE(SUM(total_price), 0) as total, '
        'COALESCE(SUM(vat_amount), 0) as vat, '
        'COALESCE(SUM((quantity * unit_price) * (discount / 100.0)), 0) '
        'as discount '
        'FROM receipt_items WHERE receipt_id = ?',
        variables: [Variable.withInt(receiptId)],
        readsFrom: {receiptItems},
      ).getSingleOrNull();
      return (
        total: result?.read<double>('total') ?? 0,
        vat: result?.read<double>('vat') ?? 0,
        discount: result?.read<double>('discount') ?? 0,
      );
    } finally {
      sw.stop();
      if (sw.elapsed > DebugConfig.slowQueryThreshold) {
        AppLogger.performance(
            'ReceiptDao._sumTotals(id=$receiptId): ${sw.elapsed.inMilliseconds}ms');
      }
    }
  }

  Future<double> _sumPaid(int receiptId) async {
    final sw = Stopwatch()..start();
    try {
      final result = await customSelect(
        'SELECT COALESCE(SUM(amount), 0) as paid '
        'FROM payments WHERE receipt_id = ?',
        variables: [Variable.withInt(receiptId)],
        readsFrom: {payments},
      ).getSingleOrNull();
      return result?.read<double>('paid') ?? 0;
    } finally {
      sw.stop();
      if (sw.elapsed > DebugConfig.slowQueryThreshold) {
        AppLogger.performance(
            'ReceiptDao._sumPaid(id=$receiptId): ${sw.elapsed.inMilliseconds}ms');
      }
    }
  }

  /// Κατάσταση πληρωμής από τρέχον υπόλοιπο + πληρωμένο ποσό.
  /// Δ4: approximates (ε=0.001) + ρητό <0 για overpaid → πάντα 'paid'.
  /// Οι τιμές έρχονται από `AppConstants.paymentStatus*` (SPoT).
  String _paymentStatus(double remaining, double paid) {
    if (remaining < 0 || remaining.approximates(0)) {
      return AppConstants.paymentStatusPaid;
    }
    if (paid > 0) return AppConstants.paymentStatusPartial;
    return AppConstants.paymentStatusPending;
  }
}

// -----------------------------------------------------------------------
//  §5.1.6 Live Aggregate Queries — χωρίς stored columns, πάντα fresh.
//  Σημ: τα όρια start/end μετατρέπονται σε UTC πριν τη σύγκριση (η βάση
//  αποθηκεύει UTC μέσω UtcDateTimeConverter).
// -----------------------------------------------------------------------

/// SPO: Live aggregates πάνω στον [ReceiptDao] (DESIGN §5.1.6).
extension ReceiptDaoAggregates on ReceiptDao {
  /// Σύνολο δαπανών για εύρος ημερομηνιών (reactive, gross = total+vat).
  Stream<double> watchTotalByDateRange(DateTime start, DateTime end) {
    final sw = Stopwatch()..start();
    final query = customSelect(
      'SELECT COALESCE(SUM(total_amount + vat_total), 0) as total '
      'FROM receipts '
      'WHERE receipt_date >= ? AND receipt_date <= ?',
      variables: [
        Variable.withDateTime(start.toUtc()),
        Variable.withDateTime(end.toUtc()),
      ],
      readsFrom: {receipts},
    );
    return query.watch().map((rows) {
      sw.stop();
      if (sw.elapsed > DebugConfig.slowQueryThreshold) {
        AppLogger.performance(
            'ReceiptDao.watchTotalByDateRange: ${sw.elapsed.inMilliseconds}ms');
      }
      return rows.first.read<double>('total');
    });
  }

  /// Σύνολα ανά κατηγορία για εύρος ημερομηνιών (reactive, gross), sorted desc.
  Stream<Map<String, double>> watchTotalByCategory(
      DateTime start, DateTime end) {
    final sw = Stopwatch()..start();
    final query = customSelect(
      'SELECT c.name as category_name, '
      'COALESCE(SUM(ri.total_with_vat), 0) as total '
      'FROM receipt_items ri '
      'JOIN items i ON ri.item_id = i.id '
      'JOIN categories c ON i.category_id = c.id '
      'JOIN receipts r ON ri.receipt_id = r.id '
      'WHERE r.receipt_date >= ? AND r.receipt_date <= ? '
      'GROUP BY c.id '
      'ORDER BY total DESC',
      variables: [
        Variable.withDateTime(start.toUtc()),
        Variable.withDateTime(end.toUtc()),
      ],
      readsFrom: {receiptItems, items, categories, receipts},
    );
    return query.watch().map((rows) {
      sw.stop();
      if (sw.elapsed > DebugConfig.slowQueryThreshold) {
        AppLogger.performance(
            'ReceiptDao.watchTotalByCategory: ${sw.elapsed.inMilliseconds}ms');
      }
      return {
        for (final row in rows)
          row.read<String>('category_name'): row.read<double>('total'),
      };
    });
  }

  /// Πλήθος αποδείξεων (reactive).
  Stream<int> watchReceiptCount() {
    final sw = Stopwatch()..start();
    final query = customSelect(
      'SELECT COUNT(*) as count FROM receipts',
      readsFrom: {receipts},
    );
    return query.watch().map((rows) {
      sw.stop();
      if (sw.elapsed > DebugConfig.slowQueryThreshold) {
        AppLogger.performance(
            'ReceiptDao.watchReceiptCount: ${sw.elapsed.inMilliseconds}ms');
      }
      return rows.first.read<int>('count');
    });
  }

  /// Μέσο ποσό (total_amount) για όλες τις αποδείξεις (reactive).
  Stream<double> watchAverageAmount() {
    final sw = Stopwatch()..start();
    final query = customSelect(
      'SELECT COALESCE(AVG(total_amount), 0) as average FROM receipts',
      readsFrom: {receipts},
    );
    return query.watch().map((rows) {
      sw.stop();
      if (sw.elapsed > DebugConfig.slowQueryThreshold) {
        AppLogger.performance(
            'ReceiptDao.watchAverageAmount: ${sw.elapsed.inMilliseconds}ms');
      }
      return rows.first.read<double>('average');
    });
  }
}