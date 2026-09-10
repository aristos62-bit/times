import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/database/daos/daos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgetDao', () {
    late AppDatabase db;
    late BudgetDao dao;
    late int categoryId;
    late DateTime now;

    setUp(() async {
      db = AppDatabase.test();
      dao = BudgetDao(db);
      final categories = await db.select(db.categories).get();
      categoryId = categories.first.id;
      now = DateTime.now();
    });

    tearDown(() async {
      await db.close();
    });

    /// Creates: supplier + item (υπό categoryId) + receipt + receipt_item
    /// με total_with_vat = amount στις receiptDate.
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
      await dao.upsertBudget(
        categoryId: categoryId,
        month: 5,
        year: 2026,
        amount: 100,
      );
      await dao.upsertBudget(
        categoryId: categoryId,
        month: 5,
        year: 2026,
        amount: 250,
      );

      final rows = await db.select(db.budgets).get();
      expect(rows.length, 1);
      expect(rows.single.amount, 250);
      expect(rows.single.month, 5);
      expect(rows.single.year, 2026);
    });

    test('watchBudget: χωρίς budget → budget=null, spent=0', () async {
      final result = await dao.watchBudget(categoryId, 5, 2026).first;
      expect(result, isNotNull);
      expect(result!.budget, isNull);
      expect(result.spent, 0);
      expect(result.hasBudget, isFalse);
    });

    test('watchBudget: υπολογίζει spent από receipts του μήνα', () async {
      await dao.upsertBudget(
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

      final result = await dao.watchBudget(categoryId, 5, 2026).first;
      expect(result!.hasBudget, isTrue);
      expect(result.spent, 150);
      expect(result.amount, 500);
      expect(result.remaining, 350);
      expect(result.percentage, 30);
      expect(result.isOverBudget, isFalse);
    });

    test('watchBudget: αποκλείει receipts εκτός μήνα (πριν/μετά)', () async {
      await dao.upsertBudget(
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

      final result = await dao.watchBudget(categoryId, 5, 2026).first;
      expect(result!.spent, 0);
    });

    test('watchBudget: spent > amount → isOverBudget', () async {
      await dao.upsertBudget(
        categoryId: categoryId,
        month: 5,
        year: 2026,
        amount: 100,
      );
      await seedSpend(
        receiptDate: DateTime(2026, 5, 10),
        totalWithVat: 200,
      );

      final result = await dao.watchBudget(categoryId, 5, 2026).first;
      expect(result!.isOverBudget, isTrue);
      expect(result.remaining, -100);
      expect(result.percentage, 200);
    });

    test('watchBudget: Δεκέμβριος → όριο εντός επόμενου έτους', () async {
      await dao.upsertBudget(
        categoryId: categoryId,
        month: 12,
        year: 2025,
        amount: 500,
      );
      await seedSpend(
        receiptDate: DateTime(2025, 12, 31),
        totalWithVat: 80,
      );
      // 15 Ιανουαρίου 2026 → ΔΕΝ ανήκει στο Δεκ 2025
      await seedSpend(
        receiptDate: DateTime(2026, 1, 15),
        totalWithVat: 1000,
      );

      final result = await dao.watchBudget(categoryId, 12, 2025).first;
      expect(result!.spent, 80);
    });

    test('watchBudgetsForMonth: μόνο budgets του μήνα με spent', () async {
      await dao.upsertBudget(
        categoryId: categoryId,
        month: 5,
        year: 2026,
        amount: 500,
      );
      final other = (await db.select(db.categories).get())[1];
      await dao.upsertBudget(
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

      final list = await dao.watchBudgetsForMonth(5, 2026).first;
      expect(list.length, 1);
      expect(list.single.spent, 40);
      expect(list.single.categoryId, categoryId);
    });

    test('watchDashboardSpending: top κατηγορίες με spent (LIMIT 8)', () async {
      final cats = await db.select(db.categories).get();

      // Δαπάνες σε 2 κατηγορίες (10 > 2 στην ταξινόμηση)
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

      final list = await dao.watchDashboardSpending(5, 2026).first;

      // Μόνο κατηγορίες με spent > 0 περιλαμβάνονται
      final withSpend = list.where((c) => c.spent > 0).toList();
      expect(withSpend.length, 2);
      expect(withSpend.first.categoryId, cats[0].id);
      expect(withSpend.first.spent, 300);
      expect(withSpend.first.categoryName, cats[0].name);
      expect(withSpend.length, lessThanOrEqualTo(8));
    });
  });
}