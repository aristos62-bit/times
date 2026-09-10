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

  // ---------- Month boundaries (string-based, consistent with stored ISO) ----------

  ({String start, String end}) _monthBounds(int month, int year) {
    final monthStr = month.toString().padLeft(2, '0');
    final yearStr = year.toString();
    final start = '$yearStr-$monthStr-01';
    final endMonth = month == 12 ? 1 : month + 1;
    final endYear = month == 12 ? year + 1 : year;
    final end =
        '$endYear-${endMonth.toString().padLeft(2, '0')}-01';
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
