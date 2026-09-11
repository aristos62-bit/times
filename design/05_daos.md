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
    String? paymentStatus,
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
      query = query..where((r) => r.paymentStatus.equals(paymentStatus));
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
    
    String status;
    if (remaining <= 0) {
      status = 'paid';
    } else if (paidAmount > 0) {
      status = 'partial';
    } else {
      status = 'pending';
    }
    
    await (update(receipts)..where((r) => r.id.equals(receiptId)))
        .write(ReceiptsCompanion(
          paidAmount: Value(paidAmount),
          remainingAmount: Value(remaining),
          paymentStatus: Value(status),
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

```dart
// core/database/daos/budget_dao.dart
import 'package:drift/drift.dart';
import '../../debug/app_logger.dart';
import '../../debug/debug_config.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'budget_dao.g.dart';

/// SPO: Budget Data Access Object
@DriftAccessor(tables: [Budgets, Categories, ReceiptItems, Receipts, Items])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(super.db);

  // ---------- Month boundaries (UTC ISO, consistent with stored ISO) ----------
  // DIOORTH 2026-09-10: τα όρια υπολογίζονται από το ΤΟΠΙΚΟ μεσονύχτι και
  // μετατρέπονται σε UTC. Γυμνά strings ημερομηνίας ('2026-05-01') ήταν
  // λεξικογραφικά ΜΕΓΑΛΥΤΕΡΑ από το πλήρες ISO '2026-04-30T21:00:00.000Z'
  // (απόδειξη 1ης το πρωί → έπεφτε στον προηγούμενο μήνα).
  ({String start, String end}) _monthBounds(int month, int year) {
    final start = DateTime(year, month, 1).toUtc().toIso8601String();
    final end = DateTime(year, month + 1, 1).toUtc().toIso8601String();
    return (start: start, end: end);
  }

  // ---------- Row mappers ----------

  BudgetWithSpent _mapBudgetRow(QueryRow row, int month, int year) {
    return BudgetWithSpent(
      budget: Budget(
        id: row.read<int>('id'),
        uuid: row.read<String>('uuid'),
        categoryId: row.read<int>('category_id'),
        month: row.read<int>('month'),
        year: row.read<int>('year'),
        amount: row.read<double>('amount'),
        notes: row.readNullable<String>('notes'),
        createdAt: row.read<DateTime>('created_at').toLocal(),
        updatedAt: row.read<DateTime>('updated_at').toLocal(),
      ),
      spent: row.read<double>('spent'),
      amount: row.read<double>('amount'),
      categoryId: row.read<int>('category_id'),
      month: month,
      year: year,
    );
  }

  // ---------- Core queries ----------

  /// Watch budget with live spent calculation (reactive)
  Stream<BudgetWithSpent?> watchBudget(
      int categoryId, int month, int year) {
    final bounds = _monthBounds(month, year);
    final query = customSelect(
      'SELECT '
      'b.id as id, '
      'b.uuid as uuid, '
      'b.category_id as category_id, '
      'b.month as month, '
      'b.year as year, '
      'b.amount as amount, '
      'b.notes as notes, '
      'b.created_at as created_at, '
      'b.updated_at as updated_at, '
      'COALESCE(SUM(CASE WHEN r.id IS NOT NULL '
      'THEN ri.total_with_vat ELSE 0 END), 0) as spent '
      'FROM budgets b '
      'LEFT JOIN items i ON i.category_id = b.category_id '
      'LEFT JOIN receipt_items ri ON ri.item_id = i.id '
      'LEFT JOIN receipts r ON r.id = ri.receipt_id '
      '  AND r.receipt_date >= ? AND r.receipt_date < ? '
      'WHERE b.category_id = ? AND b.month = ? AND b.year = ? '
      'GROUP BY b.id',
      variables: [
        Variable.withString(bounds.start),
        Variable.withString(bounds.end),
        Variable.withInt(categoryId),
        Variable.withInt(month),
        Variable.withInt(year),
      ],
      readsFrom: {budgets, receiptItems, items, receipts},
    );

    return query.watchSingleOrNull().map((row) {
      final sw = Stopwatch()..start();
      try {
        if (row == null) {
          return BudgetWithSpent(
            budget: null,
            spent: 0,
            amount: 0,
            categoryId: categoryId,
            month: month,
            year: year,
          );
        }
        return _mapBudgetRow(row, month, year);
      } finally {
        sw.stop();
        if (sw.elapsed > DebugConfig.slowQueryThreshold) {
          AppLogger.performance(
              'BudgetDao.watchBudget(cat=$categoryId): ${sw.elapsed.inMilliseconds}ms');
        }
      }
    });
  }

  /// Watch all budgets for a month with live spent (reactive)
  Stream<List<BudgetWithSpent>> watchBudgetsForMonth(int month, int year) {
    final bounds = _monthBounds(month, year);
    final query = customSelect(
      'SELECT '
      'b.id as id, '
      'b.uuid as uuid, '
      'b.category_id as category_id, '
      'b.month as month, '
      'b.year as year, '
      'b.amount as amount, '
      'b.notes as notes, '
      'b.created_at as created_at, '
      'b.updated_at as updated_at, '
      'COALESCE(SUM(CASE WHEN r.id IS NOT NULL '
      'THEN ri.total_with_vat ELSE 0 END), 0) as spent '
      'FROM budgets b '
      'LEFT JOIN items i ON i.category_id = b.category_id '
      'LEFT JOIN receipt_items ri ON ri.item_id = i.id '
      'LEFT JOIN receipts r ON r.id = ri.receipt_id '
      '  AND r.receipt_date >= ? AND r.receipt_date < ? '
      'WHERE b.month = ? AND b.year = ? '
      'GROUP BY b.id',
      variables: [
        Variable.withString(bounds.start),
        Variable.withString(bounds.end),
        Variable.withInt(month),
        Variable.withInt(year),
      ],
      readsFrom: {budgets, receiptItems, items, receipts},
    );

    return query.watch().map((rows) {
      final sw = Stopwatch()..start();
      try {
        return rows.map((r) => _mapBudgetRow(r, month, year)).toList();
      } finally {
        sw.stop();
        if (sw.elapsed > DebugConfig.slowQueryThreshold) {
          AppLogger.performance(
              'BudgetDao.watchBudgetsForMonth($month/$year): ${sw.elapsed.inMilliseconds}ms');
        }
      }
    });
  }

  /// Create or update budget
  Future<void> upsertBudget({
    required int categoryId,
    required int month,
    required int year,
    required double amount,
    String? notes,
  }) async {
    final now = DateTime.now();
    // ΣΗΜΕΙΩΣΗ: insertOnConflictUpdate στοχεύει ΜΟΝΟ το PK (id).
    // Το budgets έχει UNIQUE (category_id, month, year) άρα χρειάζεται
    // explicit onConflict: DoUpdate με target αυτό το UNIQUE.
    await into(budgets).insert(
      BudgetsCompanion.insert(
        categoryId: categoryId,
        month: month,
        year: year,
        amount: amount,
        notes: Value(notes),
        createdAt: now,
        updatedAt: now,
      ),
      onConflict: DoUpdate(
        (old) => BudgetsCompanion(
          amount: Value(amount),
          notes: Value(notes),
          // Το createdAt μένει ως έχει (πρώτη δημιουργία), μόνο updatedAt αλλάζει.
          updatedAt: Value(now),
        ),
        target: [budgets.categoryId, budgets.month, budgets.year],
      ),
    );
  }

  /// Top κατηγορίες με spending για τον μήνα (για Dashboard / HomeScreen).
  Stream<List<CategorySpending>> watchDashboardSpending(
      int month, int year) {
    final bounds = _monthBounds(month, year);
    final query = customSelect(
      'SELECT '
      'c.id as category_id, '
      'c.name as category_name, '
      'c.color as color, '
      'c.icon as icon, '
      'COALESCE(SUM(CASE WHEN r.id IS NOT NULL '
      'THEN ri.total_with_vat ELSE 0 END), 0) as spent '
      'FROM categories c '
      'LEFT JOIN items i ON i.category_id = c.id '
      'LEFT JOIN receipt_items ri ON ri.item_id = i.id '
      'LEFT JOIN receipts r ON r.id = ri.receipt_id '
      '  AND r.receipt_date >= ? AND r.receipt_date < ? '
      'WHERE c.is_active = 1 '
      'GROUP BY c.id '
      'ORDER BY spent DESC '
      'LIMIT 8',
      variables: [
        Variable.withString(bounds.start),
        Variable.withString(bounds.end),
      ],
      readsFrom: {categories, items, receiptItems, receipts},
    );

    return query.watch().map(
      (rows) => rows
          .map(
            (r) => CategorySpending(
              categoryId: r.read<int>('category_id'),
              categoryName: r.read<String>('category_name'),
              color: r.readNullable<String>('color'),
              icon: r.readNullable<String>('icon'),
              spent: r.read<double>('spent'),
            ),
          )
          .toList(),
    );
  }
}

// ---------- Models ----------

/// SPO: Budget with live spent amount
class BudgetWithSpent {
  final Budget? budget;
  final double spent;
  final double amount;
  final int categoryId;
  final int month;
  final int year;

  const BudgetWithSpent({
    required this.budget,
    required this.spent,
    required this.amount,
    required this.categoryId,
    required this.month,
    required this.year,
  });

  bool get hasBudget => budget != null;
  double get percentage => amount > 0 ? (spent / amount) * 100 : 0;
  bool get isOverBudget => spent > amount;
  double get remaining => amount - spent;
}

/// SPO: Category spending summary for Dashboard
class CategorySpending {
  final int categoryId;
  final String categoryName;
  final String? color;
  final String? icon;
  final double spent;

  const CategorySpending({
    required this.categoryId,
    required this.categoryName,
    required this.color,
    required this.icon,
    required this.spent,
  });
}
```
```dart
// core/database/daos/item_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'item_dao.g.dart';

/// SPO: Item Data Access Object
@DriftAccessor(tables: [Items, Categories, Suppliers, ReceiptItems, PriceHistory])
class ItemDao extends DatabaseAccessor<AppDatabase> with _$ItemDaoMixin {
  ItemDao(super.db);

  /// Watch all active items (reactive)
  Stream<List<Item>> watchAllItems() {
    return (select(items)
      ..where((i) => i.isActive.equals(true))
      ..orderBy([(i) => OrderingTerm.asc(i.name)])
    ).watch();
  }

  /// Watch items by category (reactive)
  Stream<List<Item>> watchItemsByCategory(int categoryId) {
    return (select(items)
      ..where((i) => i.isActive.equals(true) & i.categoryId.equals(categoryId))
      ..orderBy([(i) => OrderingTerm.asc(i.name)])
    ).watch();
  }

  /// Watch items by barcode (reactive, exact match)
  Stream<List<Item>> watchItemsByBarcode(String barcode) {
    return (select(items)
      ..where((i) => i.barcode.equals(barcode))
    ).watch();
  }

  /// Search items by name (LIKE query, reactive)
  Stream<List<Item>> searchItemsByName(String query) {
    final pattern = '%${query.toLowerCase()}%';
    return (select(items)
      ..where((i) => i.isActive.equals(true) & i.name.lower().like(pattern))
      ..orderBy([(i) => OrderingTerm.asc(i.name)])
    ).watch();
  }

  /// Watch low-stock items (reorderLevel > 0 AND currentStock <= reorderLevel, reactive)
  Stream<List<Item>> watchLowStock() {
    return (select(items)
      ..where((i) =>
          i.isActive.equals(true) &
          i.reorderLevel.isBiggerThanValue(0) &
          i.currentStock.isSmallerOrEqual(i.reorderLevel))
      ..orderBy([(i) => OrderingTerm.asc(i.currentStock)])
    ).watch();
  }

  /// Get item by id
  Future<Item?> getItemById(int id) =>
      (select(items)..where((i) => i.id.equals(id))).getSingleOrNull();

  /// Create item
  Future<int> createItem(ItemsCompanion companion) =>
      into(items).insert(companion);

  /// Update item (full recalc handled by caller where needed)
  Future<bool> updateItem(ItemsCompanion companion) =>
      update(items).replace(companion);

  /// Soft delete (isActive = false)
  Future<void> softDeleteItem(int id) async {
    await (update(items)..where((i) => i.id.equals(id)))
        .write(ItemsCompanion(
          isActive: const Value(false),
          updatedAt: Value(DateTime.now()),
        ));
  }

  /// Αύξηση stock (π.χ. κατά καταχώρηση απόδειξης).
  /// Atomic: `currentStock = currentStock + quantity`.
  /// ΣΗΜΕΙΩΣΗ: χρησιμοποιεί ItemsCompanion.custom — το `update().write()`
  /// δέχεται RawValuesInsertable (το fail σωστά ως UPDATE με expressions).
  /// DIOORTH 2026-09-10: στο custom ο UtcDateTimeConverter παρακάμπτεται →
  /// το updatedAt πρέπει ρητά `.toUtc()` για ομοιόμορφη αποθήκευση UTC.
  Future<void> increaseStock(
    int itemId,
    double quantity, {
    double? unitPrice,
    int? supplierId,
  }) async {
    await (update(items)..where((i) => i.id.equals(itemId))).write(
      ItemsCompanion.custom(
        currentStock: items.currentStock + Variable<double>(quantity),
        lastPrice: unitPrice == null ? null : Variable<double>(unitPrice),
        lastSupplierId:
            supplierId == null ? null : Variable<int>(supplierId),
        updatedAt: Variable<DateTime>(DateTime.now().toUtc()),
      ),
    );
  }
}

// core/database/daos/category_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'category_dao.g.dart';

/// SPO: Category Data Access Object
@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(super.db);

  /// Watch all active categories (reactive)
  Stream<List<Category>> watchAllCategories() {
    return (select(categories)
      ..where((c) => c.isActive.equals(true))
      ..orderBy([
        (c) => OrderingTerm.asc(c.level),
        (c) => OrderingTerm.asc(c.sortOrder),
      ])
    ).watch();
  }

  /// Get category by id
  Future<Category?> getCategoryById(int id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  /// Watch category tree (parent/child groups, reactive)
  Stream<List<Category>> watchCategoryTree() {
    return (select(categories)
      ..orderBy([
        (c) => OrderingTerm.asc(c.level),
        (c) => OrderingTerm.asc(c.parentId),
        (c) => OrderingTerm.asc(c.sortOrder),
      ])
    ).watch();
  }

  /// Watch μία κατηγορία μαζί με όλα τα έμμεσα παιδιά της (recursive CTE).
  /// Χρησιμεύει π.χ. στο Budget: το spent της γονικής αθροίζει και τα παιδιά τους.
  Stream<List<Category>> watchCategoryWithChildrenRecursively(int rootId) {
    final query = customSelect(
      'WITH RECURSIVE tree AS ('
      'SELECT * FROM categories WHERE id = ? '
      'UNION ALL '
      'SELECT c.* FROM categories c '
      'JOIN tree t ON c.parent_id = t.id'
      ') SELECT * FROM tree ORDER BY level, sort_order, name',
      variables: [Variable.withInt(rootId)],
      readsFrom: {categories},
    );
    return query.watch().map((rows) => rows
        .map((r) => Category(
              id: r.read<int>('id'),
              uuid: r.read<String>('uuid'),
              name: r.read<String>('name'),
              description: r.readNullable<String>('description'),
              icon: r.readNullable<String>('icon'),
              color: r.readNullable<String>('color'),
              parentId: r.readNullable<int>('parent_id'),
              level: r.read<int>('level'),
              sortOrder: r.read<int>('sort_order'),
              isActive: r.read<bool>('is_active'),
              createdBy: r.readNullable<String>('created_by'),
              createdAt: r.read<DateTime>('created_at').toLocal(),
              updatedAt: r.read<DateTime>('updated_at').toLocal(),
            ))
        .toList());
  }

  /// Create category.
  /// DIOORTH 2026-09-10: app-level έλεγχος duplicate — το SQLite UNIQUE
  /// (name, parentId) δεν μπλοκάρει δύο ρίζες (parentId=NULL) με ίδιο name
  /// (τα NULL θεωρούνται διακεκριμένα). Ίδιο name + ίδιο parentId (ή ρίζα-ρίζα)
  /// → CategoryDuplicateNameException.
  Future<int> createCategory(CategoriesCompanion companion) async {
    final name = companion.name.value;
    final parentId =
        companion.parentId.present ? companion.parentId.value : null;

    final existing = await (select(categories)
          ..where((c) =>
              c.name.equals(name) &
              (parentId == null
                  ? c.parentId.isNull()
                  : c.parentId.equals(parentId))))
        .get();

    if (existing.isNotEmpty) {
      throw CategoryDuplicateNameException(name);
    }

    return into(categories).insert(companion);
  }

  /// Update category
  Future<bool> updateCategory(CategoriesCompanion companion) =>
      update(categories).replace(companion);

  /// Soft delete (isActive = false).
  /// Επιστρέφει false αν υπάρχουν ενεργά παιδιά (αποτροπή ορφανών στο δέντρο).
  Future<bool> softDeleteCategory(int id) async {
    final activeChildren = await (select(categories)
          ..where((c) => c.parentId.equals(id) & c.isActive.equals(true)))
        .get();
    if (activeChildren.isNotEmpty) {
      return false;
    }
    await (update(categories)..where((c) => c.id.equals(id)))
        .write(CategoriesCompanion(
          isActive: const Value(false),
          updatedAt: Value(DateTime.now()),
        ));
    return true;
  }
}

// core/database/daos/supplier_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'supplier_dao.g.dart';

/// SPO: Supplier Data Access Object
@DriftAccessor(tables: [Suppliers, Receipts])
class SupplierDao extends DatabaseAccessor<AppDatabase> with _$SupplierDaoMixin {
  SupplierDao(super.db);

  /// Watch all active suppliers (reactive)
  Stream<List<Supplier>> watchAllSuppliers() {
    return (select(suppliers)
      ..where((s) => s.isActive.equals(true))
      ..orderBy([(s) => OrderingTerm.asc(s.name)])
    ).watch();
  }

  /// Search suppliers by name (LIKE query, reactive)
  Stream<List<Supplier>> searchSuppliersByName(String query) {
    final pattern = '%${query.toLowerCase()}%';
    return (select(suppliers)
      ..where((s) => s.isActive.equals(true) & s.name.lower().like(pattern))
      ..orderBy([(s) => OrderingTerm.asc(s.name)])
    ).watch();
  }

  /// Get supplier by id
  Future<Supplier?> getSupplierById(int id) =>
      (select(suppliers)..where((s) => s.id.equals(id))).getSingleOrNull();

  /// Create supplier
  Future<int> createSupplier(SuppliersCompanion companion) =>
      into(suppliers).insert(companion);

  /// Update supplier
  Future<bool> updateSupplier(SuppliersCompanion companion) =>
      update(suppliers).replace(companion);

  /// Soft delete (isActive = false)
  Future<void> softDeleteSupplier(int id) async {
    await (update(suppliers)..where((s) => s.id.equals(id)))
        .write(SuppliersCompanion(
          isActive: const Value(false),
          updatedAt: Value(DateTime.now()),
        ));
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
```
```dart
// core/database/daos/tag_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'tag_dao.g.dart';

/// SPO: Tag Data Access Object (tags + receipt_tags)
@DriftAccessor(tables: [Tags, ReceiptTags])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(super.db);

  /// Watch all tags (reactive)
  Stream<List<Tag>> watchAllTags() {
    return (select(tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  /// Search tags by name (LIKE, reactive)
  Stream<List<Tag>> searchTagsByName(String query) {
    final pattern = '%${query.toLowerCase()}%';
    return (select(tags)
      ..where((t) => t.name.lower().like(pattern))
      ..orderBy([(t) => OrderingTerm.asc(t.name)])
    ).watch();
  }

  /// Get tag by id
  Future<Tag?> getTagById(int id) =>
      (select(tags)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Create tag (αν υπάρχει ήδη με το ίδιο name → null / UNIQUE constraint)
  /// ΣΗΜΕΙΩΣΗ: insertReturningOrNull + insertOrIgnore = upsert με εισαγωγή
  /// timestamp δημιουργίας. Δεν χρησιμοποιείται insertOnConflictUpdate γιατί
  /// δεν θες mirror-update σε duplicate.
  Future<Tag?> createTag(String name, {String? color}) =>
      into(tags).insertReturningOrNull(
        TagsCompanion.insert(
          name: name,
          color: Value(color),
          createdAt: DateTime.now(),
        ),
        mode: InsertMode.insertOrIgnore,
      );

  /// Update tag
  Future<bool> updateTag(TagsCompanion companion) =>
      update(tags).replace(companion);

  /// Delete tag (αφαιρεί και τις ενώσεις receipt_tags)
  Future<void> deleteTag(int id) async {
    await transaction(() async {
      await (delete(receiptTags)..where((rt) => rt.tagId.equals(id))).go();
      await (delete(tags)..where((t) => t.id.equals(id))).go();
    });
  }

  /// Tags ενός receipt (reactive)
  Stream<List<Tag>> watchTagsByReceiptId(int receiptId) {
    final query = select(receiptTags).join([
      innerJoin(tags, tags.id.equalsExp(receiptTags.tagId)),
    ])
      ..where(receiptTags.receiptId.equals(receiptId))
      ..orderBy([OrderingTerm.asc(tags.name)]);
    return query.watch().map((rows) => rows.map((r) => r.readTable(tags)).toList());
  }

  /// Προσθήκη tag σε receipt (idempotent)
  Future<void> addTagToReceipt(int receiptId, int tagId) async {
    await into(receiptTags).insert(
      ReceiptTagsCompanion.insert(receiptId: receiptId, tagId: tagId),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// Αφαίρεση tag από receipt
  Future<void> removeTagFromReceipt(int receiptId, int tagId) async {
    await (delete(receiptTags)
      ..where((rt) => rt.receiptId.equals(receiptId) & rt.tagId.equals(tagId))
    ).go();
  }

  /// Αφαίρεση όλων των tags ενός receipt
  Future<void> removeAllTagsFromReceipt(int receiptId) async {
    await (delete(receiptTags)
      ..where((rt) => rt.receiptId.equals(receiptId))
    ).go();
  }
}
```
```dart
// core/database/daos/setting_dao.dart
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'setting_dao.g.dart';

/// SPO: User settings Data Access Object
/// SPoT αποθήκευσης ρυθμίσεων (π.χ. theme). Η UserSettings table είναι
/// η ΜΟΝΗ πηγή αλήθειας — κανένα SharedPreferences για theme.
@DriftAccessor(tables: [UserSettings])
class SettingDao extends DatabaseAccessor<AppDatabase> with _$SettingDaoMixin {
  SettingDao(super.db);

  static const themeKey = 'theme_mode';

  /// Read a setting by key (as string, nullable)
  Future<String?> getSetting(String key) async {
    final row = await (select(userSettings)
      ..where((s) => s.key.equals(key))
    ).getSingleOrNull();
    return row?.value;
  }

  /// Write a setting by key (upsert)
  /// DIOORTH 2026-09-10: DoUpdate (όχι insertOrReplace) — σε αντίθετη
  /// περίπτωση το UNIQUE conflict έκανε DELETE+INSERT (νέο id κάθε φορά).
  Future<void> setSetting(String key, String value, {String type = 'string'}) async {
    final now = DateTime.now();
    await into(userSettings).insert(
      UserSettingsCompanion.insert(
        key: key,
        value: Value(value),
        type: Value(type),
        updatedAt: now,
      ),
      onConflict: DoUpdate(
        (old) => UserSettingsCompanion(
          value: Value(value),
          type: Value(type),
          updatedAt: Value(now),
        ),
        target: [userSettings.key],
      ),
    );
  }

  /// Watch a setting by key (reactive stream)
  Stream<String?> watchSetting(String key) {
    return (select(userSettings)
      ..where((s) => s.key.equals(key))
    ).watchSingleOrNull().map((row) => row?.value);
  }

  // --- Theme helpers ---

  /// Watch theme mode (reactive) — null/άκυρο → system
  Stream<ThemeMode?> watchThemeMode() => watchSetting(themeKey).map(_parseThemeMode);

  /// Φόρτωση theme mode (single-shot για το startup)
  Future<ThemeMode> getThemeMode() async {
    final value = await getSetting(themeKey);
    return _parseThemeMode(value) ?? ThemeMode.system;
  }

  /// Αποθήκευση theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    await setSetting(themeKey, '${mode.index}', type: 'int');
  }

  /// '0'=system, '1'=light, '2'=dark (ή null όταν δεν υπάρχει/άκυρο)
  ThemeMode? _parseThemeMode(String? value) {
    if (value == null) return null;
    final index = int.tryParse(value);
    if (index == null || index < 0 || index >= ThemeMode.values.length) {
      return null;
    }
    return ThemeMode.values[index];
  }
}
```
---

