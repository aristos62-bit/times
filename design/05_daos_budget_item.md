### 4.3b DAOs — Budget/Item/Category (συνέχεια του §4.3)

> SPLIT (12/09/2026): συνέχεια του `design/05_daos.md`. Η εισαγωγή (§4.3,
> πίνακας DAO, αποκλίσεις, διορθώσεις) και ο οδηγός `ReceiptDao` στο
> `05_daos.md`· `SupplierDao`/`TagDao`/`SettingDao` στο `05_daos_supplier_tag_setting.md`.

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

