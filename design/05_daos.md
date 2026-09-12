### 4.3 Drift DAOs (`core/database/daos/`)

Εξελίχθηκαν και υλοποιήθηκαν 6 DAOs (Phase 2 Step 3), καθένα δικό του
αρχείο `<name>_dao.dart` + `part '<name>_dao.g.dart'`:

| DAO | Αρχείο | Βασικές λειτουργίες |
|---|---|---|
| SettingDao | `setting_dao.dart` | `getSetting/setSetting/watchSetting`, `getThemeMode/setThemeMode/watchThemeMode` |
| CategoryDao | `category_dao.dart` | `watchAllCategories`, `getCategoryById`, `watchCategoryTree`, `watchCategoryWithChildrenRecursively` (recursive CTE), `createCategory`, `updateCategory`, `softDeleteCategory → Future<bool>` |
| SupplierDao | `supplier_dao.dart` | `watchAllSuppliers`, `searchSuppliersByName`, `getSupplierById`, `create/update/softDelete`, `getReceiptCount` |
| ItemDao | `item_dao.dart` | `watchAllItems/ByCategory/ByBarcode`, `searchItemsByName`, `watchLowStock`, `getItemById`, `create/update/softDelete`, `increaseStock` (atomic `currentStock = currentStock + qty`) |
| TagDao | `tag_dao.dart` | `watchAllTags`, `searchTagsByName`, `getTagById`, `createTag → Future<Tag?>`, `updateTag`, `deleteTag`, `watchTagsByReceiptId`, `addTagToReceipt`, `removeTagFromReceipt`, `removeAllTagsFromReceipt` |
| BudgetDao | `budget_dao.dart` | `watchBudget`, `watchBudgetsForMonth`, `upsertBudget`, `watchDashboardSpending` (top-8), μοντέλα `BudgetWithSpent` + `CategorySpending` |

Barrel export: `daos/daos.dart` (`export 'setting_dao.dart';` κ.ο.κ.).

Υλοποίηση & codegen: `@DriftAccessor` + `part 'x.g.dart'` + `with _$XMixin`
(κανονική drift codegen, `dart run build_runner build`). Ο constructor είναι
`XDao(super.db);` (για `use_super_parameters`). Το `app_database.g.dart`
παραμένει ΑΜΕΤΑΒΛΗΤΟ — τα DAOs κάνουν export τα tables, δεν τα αλλάζουν.

Αποκλίσεις από τις ENTIRE §4.3 λεπτομέρειες που κρίθηκαν AGENTS-safe:
- Σημεία όπου το snippet χρησιμοποιούσε `Expression.constant()` → όπου
  χρειαζόταν expression, χρησιμοποιείται `Variable<T>(...)`.
- `insertOnConflictUpdate` στο budgets δεν αρκεί (ΠΚ ≠ UNIQUE (category_id,
  month, year)) → `onConflict: DoUpdate(..., target: [...])`.
- Στα aggregates, το φίλτρο ημερομηνίας μπαίνει ΜΟΝΟ στο LEFT JOIN receipts;
  για να μην αθροίζονται receipt_items εκτός μήνα, το SUM γίνεται
  `SUM(CASE WHEN r.id IS NOT NULL THEN ri.total_with_vat ELSE 0 END)`.
- Όλα τα `row.read<DateTime>()` από customSelect καλούν `.toLocal()`.
- Το BudgetDao (και τα customSelect της εφαρμογής) κάνουν
  `Stopwatch` + `AppLogger.performance` όταν ξεπερνιέται `DebugConfig.slowQueryThreshold`
  (ίδιο μοτίβο με το §4.1).

Διορθώσεις Phase 2 Step 3.1 (review 2026-09-10) — παλιά bug/ασυνέπειες:
- **`BudgetDao._monthBounds`** (όριο μήνα): ο υπολογισμός γινόταν με γυμνά
  strings ημερομηνίας (`'2026-03-01'`). Επειδή η βάση αποθηκεύει `receipt_date`
  ως πλήρες UTC ISO (UtcDateTimeConverter), μια απόδειξη της 1ης το πρωί
  (π.χ. `DateTime(2026,5,1)` → αποθηκευμένο `2026-04-30T21:00:00.000Z`)
  ήταν λεξικογραφικά ΜΙΚΡΟΤΕΡΟ του `'2026-05-01'` → έπεφτε στον προηγούμενο
  μήνα. Διόρθωση: τα bounds υπολογίζονται από το ΤΟΠΙΚΟ μεσονύχτι και
  μετατρέπονται σε UTC:
  `DateTime(year, month, 1).toUtc().toIso8601String()` (ο Dart constructor
  κάνει μόνος roll-over για month=13 → αφαιρέθηκε το ειδικό case για Δεκέμβριο).
  Μία αλλαγή στο `_monthBounds` καλύπτει `watchBudget`, `watchBudgetsForMonth`,
  `watchDashboardSpending`.
- **`ItemDao.increaseStock`**: το `ItemsCompanion.custom` με
  `Variable<DateTime>(DateTime.now())` παρακάμπτει τον UtcDateTimeConverter →
  αποθήκευση τοπικής ώρας αντί UTC. Διόρθωση: `Variable<DateTime>(DateTime.now().toUtc())`.
  (Σημ.: στο custom, `lastPrice: null` σημαίνει «αμετάβλητο», όχι «μηδένισε».)
- **`SettingDao.setSetting`**: `InsertMode.insertOrReplace` στη σύγκρουση UNIQUE
  κάνει DELETE+INSERT → νέο `id` κάθε φορά. Διόρθωση: ίδιο pattern με το
  budget — `onConflict: DoUpdate(..., target: [userSettings.key])` ώστε το id
  να μένει ίδιο.
- **`CategoryDao.createCategory`**: το SQLite `UNIQUE (name, parentId)` δεν
  μπλοκάρει δύο ρίζες (parentId = NULL) με ίδιο name (τα NULL θεωρούνται
  διακεκριμένα). Διόρθωση: app-level έλεγχος πριν το insert — αν υπάρχει ήδη
  ίδιο name με ίδιο parentId (ή τόσο ρίζα όσο και ρίζα) πετιέται
  `CategoryDuplicateNameException`.

> **⚠️ STALE (Phase 3 Step 2):** Το snippet παρακάτω του `ReceiptDao` είναι η
> ΚΑΝΟΝΙΚΗ σχεδίαση (§5.1.2). Η υλοποίηση (478 γραμμές) αποκλίνει:
> constructor `ReceiptDao(db, {required settingDao, itemDao, tagDao})` (όχι
> `ReceiptDao(AppDatabase db)`), accessor
> `[Receipts, ReceiptItems, Payments, PriceHistory, Items, Categories]` (όχι
> ReceiptTags — τα tags πάνε μέσω TagDao), χωρίς `Expression.constant()`,
> counter μέσω SettingDao αντί `MAX(receipt_number)` (Δ1(α)), `_refreshFinancials`
> ως μοναδικό write totals/status (Δ3). Η ακριβής υπογραφή του contract
> (10 μέθοδοι) είναι στο §5.1.4 — η υλοποίηση είναι ο SPoT.

```dart
// core/database/daos/receipt_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'receipt_dao.g.dart';

/// SPO: Receipt Data Access Object
@DriftAccessor(tables: [Receipts, ReceiptItems, Payments, Items, Suppliers, Categories, ReceiptTags])
class ReceiptDao extends DatabaseAccessor<AppDatabase> with _$ReceiptDaoMixin {
  ReceiptDao(AppDatabase db) : super(db);

  /// Watch all receipts (reactive)
  /// Οι ημερομηνίες εισόδου μετατρέπονται σε UTC πριν τη σύγκριση
  /// (η βάση αποθηκεύει UTC μέσω UtcDateTimeConverter).
  Stream<List<Receipt>> watchAllReceipts({
    DateTime? startDate,
    DateTime? endDate,
    int? supplierId,
    ReceiptPaymentStatus? paymentStatus,
  }) {
    var query = select(receipts);
    
    if (startDate != null) {
      query = query..where((r) => r.receiptDate.isBiggerOrEqualValue(startDate.toUtc()));
    }
    if (endDate != null) {
      query = query..where((r) => r.receiptDate.isSmallerOrEqualValue(endDate.toUtc()));
    }
    if (supplierId != null) {
      query = query..where((r) => r.supplierId.equals(supplierId));
    }
    if (paymentStatus != null) {
      query = query..where((r) => r.paymentStatus.equals(paymentStatus.dbValue));
    }
    
    query = query..orderBy([(r) => OrderingTerm.desc(r.receiptDate)]);
    
    return query.watch();
  }
  
  /// Get receipt by ID
  Future<Receipt?> getReceiptById(int id) async {
    return (select(receipts)..where((r) => r.id.equals(id))).getSingleOrNull();
  }
  
  /// Get receipt items by receipt ID
  Stream<List<ReceiptItem>> watchReceiptItems(int receiptId) {
    return (select(receiptItems)
      ..where((ri) => ri.receiptId.equals(receiptId))
    ).watch();
  }
  
  /// Get next receipt number (για προεπισκόπηση σε UI form, π.χ. "Απόδειξη #1234")
  Future<int> getNextReceiptNumber() async {
    final lastReceipt = await (select(receipts)
      ..limit(1)
      ..orderBy([(r) => OrderingTerm.desc(r.receiptNumber)])
    ).getSingleOrNull();
    return (lastReceipt?.receiptNumber ?? 0) + 1;
  }
  
  /// Create receipt with items (atomic transaction)
  Future<int> createReceipt(ReceiptInput input) async {
    return await transaction(() async {
      // 1. Get next receipt number (atomic)
      final lastReceipt = await (select(receipts)
        ..limit(1)
        ..orderBy([(r) => OrderingTerm.desc(r.receiptNumber)])
      ).getSingleOrNull();
      
      final nextNumber = (lastReceipt?.receiptNumber ?? 0) + 1;
      
      // 2. Insert receipt
      final receiptId = await into(receipts).insert(ReceiptsCompanion.insert(
        receiptNumber: nextNumber,
        receiptDate: input.date,
        supplierId: input.supplierId,
        invoiceNumber: Value(input.invoiceNumber),
        invoiceSeries: Value(input.invoiceSeries),
        paymentMethod: Value(input.paymentMethod),
        notes: Value(input.notes),
      ));
      
      // 3. Insert receipt items
      for (var itemInput in input.items) {
        final item = _calculateReceiptItem(
          receiptId: receiptId,
          itemId: itemInput.itemId,
          quantity: itemInput.quantity,
          unitPrice: itemInput.unitPrice,
          vatRate: itemInput.vatRate,
          discount: itemInput.discount,
        );
        
        await into(receiptItems).insert(ReceiptItemsCompanion.insert(
          receiptId: receiptId,
          itemId: itemInput.itemId,
          quantity: Value(item.quantity),
          unitPrice: item.unitPrice,
          vatRate: Value(item.vatRate),
          vatAmount: Value(item.vatAmount),
          discount: Value(item.discount),
          totalPrice: item.totalPrice,
          totalWithVat: item.totalWithVat,
        ));
        
        // Update item stock
        await _updateItemStock(
          itemId: itemInput.itemId,
          quantity: itemInput.quantity,
          unitPrice: itemInput.unitPrice,
          supplierId: input.supplierId,
        );
        
        // Insert price history
        await into(priceHistory).insert(PriceHistoryCompanion.insert(
          itemId: itemInput.itemId,
          price: itemInput.unitPrice,
          vatRate: Value(itemInput.vatRate),
          receiptDate: input.date,
          supplierId: input.supplierId,
          quantity: Value(itemInput.quantity),
        ));
      }
      
      // 4. Update receipt totals
      await _updateReceiptTotals(receiptId);
      
      // 5. Insert payments
      for (var paymentInput in input.payments) {
        await into(payments).insert(PaymentsCompanion.insert(
          receiptId: receiptId,
          amount: paymentInput.amount,
          paymentDate: paymentInput.date,
          paymentMethod: paymentInput.method,
          reference: Value(paymentInput.reference),
        ));
      }
      
      // 6. Update payment status
      await _updatePaymentStatus(receiptId);
      
      return receiptId;
    });
  }
  
  /// Update receipt item (with recalculation)
  Future<void> updateReceiptItem(int receiptId, int itemId, ReceiptItemUpdate update) async {
    await transaction(() async {
      // 1. Update the item
      await (update(receiptItems)
        ..where((ri) => ri.receiptId.equals(receiptId) & ri.itemId.equals(itemId)))
        .write(ReceiptItemsCompanion(
          quantity: Value(update.quantity),
          unitPrice: Value(update.unitPrice),
          vatRate: Value(update.vatRate),
          discount: Value(update.discount),
          // Recalculate totals
          totalPrice: Value(_calculateTotal(update.quantity, update.unitPrice, update.discount)),
          totalWithVat: Value(_calculateTotalWithVat(update.quantity, update.unitPrice, update.vatRate, update.discount)),
          vatAmount: Value(_calculateVat(update.quantity, update.unitPrice, update.vatRate, update.discount)),
        ));
      
      // 2. Recalculate receipt totals
      await _updateReceiptTotals(receiptId);
      
      // 3. Update item stock
      await _recalculateItemStock(itemId);
    });
  }
  
  /// Delete receipt item (with recalculation)
  Future<void> deleteReceiptItem(int receiptId, int itemId) async {
    await transaction(() async {
      // 1. Delete the item
      await (delete(receiptItems)
        ..where((ri) => ri.receiptId.equals(receiptId) & ri.itemId.equals(itemId)))
        .go();
      
      // 2. Recalculate receipt totals
      await _updateReceiptTotals(receiptId);
      
      // 3. Recalculate item stock
      await _recalculateItemStock(itemId);
    });
  }
  
  /// Delete receipt
  Future<void> deleteReceipt(int id) async {
    await transaction(() async {
      // Get all items for stock recalculation
      final items = await (select(receiptItems)
        ..where((ri) => ri.receiptId.equals(id))
      ).get();
      
      // Delete receipt tags (αποφυγή orphan records / FK violation)
      await (delete(receiptTags)..where((rt) => rt.receiptId.equals(id))).go();
      
      // Delete receipt items
      await (delete(receiptItems)..where((ri) => ri.receiptId.equals(id))).go();
      
      // Delete payments
      await (delete(payments)..where((p) => p.receiptId.equals(id))).go();
      
      // Delete receipt
      await (delete(receipts)..where((r) => r.id.equals(id))).go();
      
      // Recalculate stock for affected items
      for (var item in items) {
        await _recalculateItemStock(item.itemId);
      }
    });
  }
  
  // Private helpers
  
  ReceiptItemData _calculateReceiptItem({
    required int receiptId,
    required int itemId,
    required double quantity,
    required double unitPrice,
    required double vatRate,
    required double discount,
  }) {
    final subtotal = quantity * unitPrice;
    final discountAmount = subtotal * (discount / 100);
    final taxableAmount = subtotal - discountAmount;
    final vatAmount = taxableAmount * (vatRate / 100);
    final totalWithVat = taxableAmount + vatAmount;
    
    return ReceiptItemData(
      receiptId: receiptId,
      itemId: itemId,
      quantity: quantity,
      unitPrice: unitPrice,
      vatRate: vatRate,
      vatAmount: vatAmount,
      discount: discount,
      totalPrice: taxableAmount,
      totalWithVat: totalWithVat,
      createdAt: DateTime.now(),
    );
  }
  
  Future<void> _updateItemStock({
    required int itemId,
    required double quantity,
    required double unitPrice,
    required int supplierId,
  }) async {
    await (update(items)..where((i) => i.id.equals(itemId)))
        .write(ItemsCompanion(
          // Parameterized expression - NO raw string interpolation
          currentStock: items.currentStock + constant(quantity),
          lastPrice: Value(unitPrice),
          lastSupplierId: Value(supplierId),
          updatedAt: Value(DateTime.now()),
        ));
  }
  
  Future<void> _recalculateItemStock(int itemId) async {
    // Calculate total stock from all receipt items
    final result = await customSelect(
      'SELECT COALESCE(SUM(quantity), 0) as total_stock '
      'FROM receipt_items '
      'WHERE item_id = ?',
      variables: [Variable.withInt(itemId)],
    ).getSingleOrNull();
    
    final totalStock = result?.read<double>('total_stock') ?? 0;
    
    await (update(items)..where((i) => i.id.equals(itemId)))
        .write(ItemsCompanion(
          currentStock: Value(totalStock),
          updatedAt: Value(DateTime.now()),
        ));
  }
  
  Future<void> _updateReceiptTotals(int receiptId) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(total_price), 0) as total, '
      'COALESCE(SUM(vat_amount), 0) as vat, '
      'COALESCE(SUM((quantity * unit_price) * (discount / 100.0)), 0) as discount '
      'FROM receipt_items '
      'WHERE receipt_id = ?',
      variables: [Variable.withInt(receiptId)],
    ).getSingleOrNull();
    
    // total_amount = Σ total_price (μετά από line discount, πριν ΦΠΑ)
    final total = result?.read<double>('total') ?? 0;
    final vat = result?.read<double>('vat') ?? 0;
    final totalDiscount = result?.read<double>('discount') ?? 0;
    
    await (update(receipts)..where((r) => r.id.equals(receiptId)))
        .write(ReceiptsCompanion(
          totalAmount: Value(total),
          vatTotal: Value(vat),
          discountTotal: Value(totalDiscount),
          remainingAmount: Value(total + vat - await _getPaidAmount(receiptId)),
          updatedAt: Value(DateTime.now()),
        ));
  }
  
  Future<double> _getPaidAmount(int receiptId) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(amount), 0) as paid '
      'FROM payments '
      'WHERE receipt_id = ?',
      variables: [Variable.withInt(receiptId)],
    ).getSingleOrNull();
    
    return result?.read<double>('paid') ?? 0;
  }
  
  Future<void> _updatePaymentStatus(int receiptId) async {
    final receipt = await getReceiptById(receiptId);
    if (receipt == null) return;
    
    final paidAmount = await _getPaidAmount(receiptId);
    // remaining = (total χωρίς ΦΠΑ + ΦΠΑ) - πληρωμένα = μεικτό υπόλοιπο
    final remaining = receipt.totalAmount + receipt.vatTotal - paidAmount;
    
    final status = _paymentStatus(remaining, paidAmount);

    await (update(receipts)..where((r) => r.id.equals(receiptId)))
        .write(ReceiptsCompanion(
          paidAmount: Value(paidAmount),
          remainingAmount: Value(remaining),
          paymentStatus: Value(status.dbValue),
          updatedAt: Value(DateTime.now()),
        ));
  }
  
  double _calculateTotal(double quantity, double unitPrice, double discount) {
    final subtotal = quantity * unitPrice;
    final discountAmount = subtotal * (discount / 100);
    return subtotal - discountAmount;
  }
  
  double _calculateVat(double quantity, double unitPrice, double vatRate, double discount) {
    final taxable = _calculateTotal(quantity, unitPrice, discount);
    return taxable * (vatRate / 100);
  }
  
  double _calculateTotalWithVat(double quantity, double unitPrice, double vatRate, double discount) {
    final taxable = _calculateTotal(quantity, unitPrice, discount);
    final vat = _calculateVat(quantity, unitPrice, vatRate, discount);
    return taxable + vat;
  }
}

/// SPoΤ: Τα input types βρίσκονται στο DOMAIN layer (§5.1.3):
///   - ReceiptInput
///   - ReceiptItemInput
///   - PaymentInput
///   - ReceiptItemUpdate
/// Ο ReceiptDao τα εισάγει με import από
/// `features/receipt/domain/models/receipt_input.dart` — ΔΕΝ ορίζονται ξανά εδώ
/// (αποφυγή name collision αν βρεθούν στο ίδιο scope).

class ReceiptItemData {
  final int receiptId;
  final int itemId;
  final double quantity;
  final double unitPrice;
  final double vatRate;
  final double vatAmount;
  final double discount;
  final double totalPrice;
  final double totalWithVat;
  final DateTime createdAt;
  
  const ReceiptItemData({
    required this.receiptId,
    required this.itemId,
    required this.quantity,
    required this.unitPrice,
    required this.vatRate,
    required this.vatAmount,
    required this.discount,
    required this.totalPrice,
    required this.totalWithVat,
    required this.createdAt,
  });
}
```

---

> SPLIT (12/09/2026): Το §4.3 συνεχίζεται στα
> `design/05_daos_budget_item.md` (§4.3b — BudgetDao, ItemDao, CategoryDao) και
> `design/05_daos_supplier_tag_setting.md` (§4.3c — SupplierDao, TagDao,
> SettingDao) λόγω κανόνα ≤500 γρ.

