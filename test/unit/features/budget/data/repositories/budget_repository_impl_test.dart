// test/unit/features/budget/data/repositories/budget_repository_impl_test.dart
//
// Επαληθεύει ότι το BudgetRepositoryImpl (pure delegate) προωθεί σωστά τις
// κλήσεις στον BudgetDao — upsert, reactive aggregates με spent boundaries
// (Fix #1 _monthBounds: UTC ISO bounds) και dashboard top categories.
// Τα μοντέλα BudgetWithSpent/CategorySpending ορίζονται στο budget_dao.dart
// (reuse — όχι αντίγραφα), οπότε η σύγκριση γίνεται στα νούμερα.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/database/daos/daos.dart';
import 'package:expense_tracker/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgetRepositoryImpl', () {
    late AppDatabase db;
    late BudgetRepositoryImpl repo;
    late int categoryId;
    late DateTime now;

    setUp(() async {
      db = AppDatabase.test();
      repo = BudgetRepositoryImpl(BudgetDao(db));
      final categories = await db.select(db.categories).get();
      categoryId = categories.first.id;
      now = DateTime.now();
    });

    tearDown(() async {
      await db.close();
    });

    /// Creates: supplier + item + receipt + receipt_item with total_with_vat.
    int receiptCounter = 0;
    Future<void> seedSpend({
      required DateTime receiptDate,
      required double totalWithVat,
      int? category,
    }) async {
      final cat = category ?? categoryId;
      receiptCounter += 1;
      final supplierId = await db.into(db.suppliers).insert(
            SuppliersCompanion.insert(
              name: 'Supplier $receiptDate',
              createdAt: now,
              updatedAt: now,
            ),
          );
      final itemId = await db.into(db.items).insert(
            ItemsCompanion.insert(
              name: 'Item $receiptDate $totalWithVat',
              categoryId: cat,
              createdAt: now,
              updatedAt: now,
            ),
          );
      final receiptId = await db.into(db.receipts).insert(
            ReceiptsCompanion.insert(
              receiptNumber: receiptCounter,
              receiptDate: receiptDate,
              supplierId: supplierId,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db.into(db.receiptItems).insert(
            ReceiptItemsCompanion.insert(
              receiptId: receiptId,
              itemId: itemId,
              quantity: const Value(1),
              unitPrice: totalWithVat,
              vatRate: Value(0),
              totalPrice: totalWithVat,
              totalWithVat: totalWithVat,
              createdAt: now,
            ),
          );
    }

    test('upsertBudget: δημιουργεί + ενημερώνει την ίδια εγγραφή', () async {
      await repo.upsertBudget(
        categoryId: categoryId,
        month: 5,
        year: 2026,
        amount: 100,
      );
      await repo.upsertBudget(
        categoryId: categoryId,
        month: 5,
        year: 2026,
        amount: 250,
      );

      final rows = await db.select(db.budgets).get();
      expect(rows.length, 1);
      expect(rows.single.amount, 250);
    });

    test('watchBudget: χωρίς budget → budget=null, spent=0', () async {
      final result = await repo.watchBudget(categoryId, 5, 2026).first;
      expect(result!.budget, isNull);
      expect(result.spent, 0);
      expect(result.hasBudget, isFalse);
    });

    test('watchBudget: υπολογίζει spent από receipts του μήνα', () async {
      await repo.upsertBudget(
        categoryId: categoryId,
        month: 5,
        year: 2026,
        amount: 500,
      );
      await seedSpend(
        receiptDate: DateTime(2026, 5, 10),
        totalWithVat: 120,
      );
      await seedSpend(
        receiptDate: DateTime(2026, 5, 20),
        totalWithVat: 30,
      );

      final result = await repo.watchBudget(categoryId, 5, 2026).first;
      expect(result!.hasBudget, isTrue);
      expect(result.spent, 150);
      expect(result.remaining, 350);
    });

    test('watchBudget: αποκλείει receipts εκτός μήνα (bounds Fix #1)', () async {
      await repo.upsertBudget(
        categoryId: categoryId,
        month: 5,
        year: 2026,
        amount: 500,
      );
      await seedSpend(
        receiptDate: DateTime(2026, 4, 25),
        totalWithVat: 1000,
      );
      await seedSpend(
        receiptDate: DateTime(2026, 6, 15),
        totalWithVat: 1000,
      );

      final result = await repo.watchBudget(categoryId, 5, 2026).first;
      expect(result!.spent, 0);
    });

    test('watchBudget: Δεκ 31 23:59:59.999 → Δεκέμβριος, 1 Ιαν → Ιανουάριος', () async {
      await repo.upsertBudget(
        categoryId: categoryId,
        month: 12,
        year: 2025,
        amount: 500,
      );
      await repo.upsertBudget(
        categoryId: categoryId,
        month: 1,
        year: 2026,
        amount: 500,
      );
      await seedSpend(
        receiptDate: DateTime(2025, 12, 31, 23, 59, 59, 999),
        totalWithVat: 70,
      );
      await seedSpend(
        receiptDate: DateTime(2026, 1, 1),
        totalWithVat: 120,
      );

      final dec = await repo.watchBudget(categoryId, 12, 2025).first;
      final jan = await repo.watchBudget(categoryId, 1, 2026).first;
      expect(dec!.spent, 70);
      expect(jan!.spent, 120);
    });

    test('watchBudgetsForMonth: μόνο budgets του μήνα με spent', () async {
      await repo.upsertBudget(
        categoryId: categoryId,
        month: 5,
        year: 2026,
        amount: 500,
      );
      final other = (await db.select(db.categories).get())[1];
      await repo.upsertBudget(
        categoryId: other.id,
        month: 6,
        year: 2026,
        amount: 300,
      );
      await seedSpend(
        receiptDate: DateTime(2026, 5, 10),
        totalWithVat: 40,
        category: categoryId,
      );

      final list = await repo.watchBudgetsForMonth(5, 2026).first;
      expect(list.length, 1);
      expect(list.single.spent, 40);
      expect(list.single.categoryId, categoryId);
    });

    test('watchDashboardSpending: top κατηγορίες με spent', () async {
      final cats = await db.select(db.categories).get();
      await seedSpend(
        receiptDate: DateTime(2026, 5, 10),
        totalWithVat: 300,
        category: cats[0].id,
      );
      await seedSpend(
        receiptDate: DateTime(2026, 5, 12),
        totalWithVat: 100,
        category: cats[1].id,
      );

      final list = await repo.watchDashboardSpending(5, 2026).first;
      final withSpend = list.where((c) => c.spent > 0).toList();
      expect(withSpend.length, 2);
      expect(withSpend.first.categoryId, cats[0].id);
      expect(withSpend.first.spent, 300);
      expect(withSpend.length, lessThanOrEqualTo(8));
    });
  });
}