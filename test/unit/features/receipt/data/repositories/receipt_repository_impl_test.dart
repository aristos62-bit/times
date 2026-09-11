// test/unit/features/receipt/data/repositories/receipt_repository_impl_test.dart
//
// Επαληθεύει ότι το ReceiptRepositoryImpl (pure delegate) προωθεί σωστά όλες
// τις κλήσεις προς τον ReceiptDao — και ότι ΔΕΝ καταπνίγει exceptions ή όρια.
// Δεν επαναλαμβάνονται λεπτομερείς έλεγχοι του DAO (ήδη καλυμμένοι στο
// receipt_dao_test.dart) — εδώ ελέγχεται η σύνδεση contract → impl → DAO
// (σχέδιο: item_repository_impl_test.dart).
import 'package:drift/native.dart';
import 'package:expense_tracker/features/receipt/data/repositories/receipt_repository_impl.dart';
import 'package:expense_tracker/features/receipt/domain/models/receipt_input.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../core/database/daos/receipt_dao_test_fixture.dart';

void main() {
  group('ReceiptRepositoryImpl', () {
    late ReceiptDaoFixture fixture;
    late ReceiptRepositoryImpl repo;

    setUp(() async {
      fixture = ReceiptDaoFixture();
      await fixture.setUp();
      repo = ReceiptRepositoryImpl(fixture.dao);
    });

    tearDown(() async {
      await fixture.tearDown();
    });

    /// Default: 1 γραμμή (itemId, qty 2 @ 10.00, vat 24%, discount 0).
    Future<int> createViaRepo({
      DateTime? date,
      int? supplier,
      List<ReceiptItemInput>? items,
    }) {
      return repo.create(
        ReceiptInput(
          date: date ?? DateTime(2026, 5, 15),
          supplierId: supplier ?? fixture.supplierId,
          paymentMethod: 'cash',
          invoiceNumber: null,
          items: items ?? [ReceiptItemInput(itemId: fixture.itemId, quantity: 2, unitPrice: 10.0)],
          payments: const [],
          notes: null,
        ),
      );
    }

    test('watchAll: αρχικά κενό', () async {
      expect(await repo.watchAll().first, isEmpty);
    });

    test('create + getById + watchAll (δεδομένα γραμμένα μέσω repo)', () async {
      final id = await createViaRepo();
      final receipt = await repo.getById(id);
      expect(receipt, isNotNull);
      expect(receipt!.receiptNumber, 1);
      expect(receipt.totalAmount, 20);
      expect(await repo.watchAll().first, hasLength(1));
    });

    test('watchItemsByReceiptId: γραμμές του receipt', () async {
      final id = await createViaRepo();
      final items = await repo.watchItemsByReceiptId(id).first;
      expect(items, hasLength(1));
      expect(items.single.itemId, fixture.itemId);
      expect(items.single.quantity, 2);
    });

    test('getNextReceiptNumber: 1 (seed) → μετά create → 2', () async {
      expect(await repo.getNextReceiptNumber(), 1);
      await createViaRepo();
      expect(await repo.getNextReceiptNumber(), 2);
    });

    test('updateItem: totals αλλάζουν + stock delta (qty 2 → 5)', () async {
      final id = await createViaRepo();
      await repo.updateItem(
        id,
        fixture.itemId,
        const ReceiptItemUpdate(quantity: 5, unitPrice: 10, vatRate: 24, discount: 0),
      );
      final receipt = await repo.getById(id);
      expect(receipt!.totalAmount, 50);
      expect(receipt.vatTotal, 12);
      final item = await fixture.itemDao.getItemById(fixture.itemId);
      expect(item!.currentStock, 15);
    });

    test('deleteItem: αφαίρεση γραμμής → stock επαναφορά + κενά', () async {
      final id = await createViaRepo();
      await repo.deleteItem(id, fixture.itemId);
      expect(await repo.watchItemsByReceiptId(id).first, isEmpty);
      final item = await fixture.itemDao.getItemById(fixture.itemId);
      expect(item!.currentStock, 10);
      final receipt = await repo.getById(id);
      expect(receipt!.totalAmount, 0);
    });

    test('delete: cascade → receipt εξαφανίζεται + stock επαναφορά', () async {
      final id = await createViaRepo();
      await repo.delete(id);
      expect(await repo.getById(id), isNull);
      expect(await repo.watchAll().first, isEmpty);
      final item = await fixture.itemDao.getItemById(fixture.itemId);
      expect(item!.currentStock, 10);
    });

    test('watchAll: φίλτρα προωθούνται (startDate/endDate/supplier/status)', () async {
      final id = await createViaRepo();
      final inRange = await repo
          .watchAll(startDate: DateTime(2026, 5, 1), endDate: DateTime(2026, 5, 31))
          .first;
      expect(inRange.map((r) => r.id), [id]);
      final outOfRange = await repo
          .watchAll(startDate: DateTime(2026, 6, 1), endDate: DateTime(2026, 6, 30))
          .first;
      expect(outOfRange, isEmpty);
      final wrongSupplier = await repo.watchAll(supplierId: 99999).first;
      expect(wrongSupplier, isEmpty);
      final pending = await repo.watchAll(paymentStatus: 'pending').first;
      expect(pending.map((r) => r.id), [id]);
      final paid = await repo.watchAll(paymentStatus: 'paid').first;
      expect(paid, isEmpty);
    });

    test('watchTotalByDateRange: gross sum (total+vat)', () async {
      await createViaRepo();
      final total = await repo
          .watchTotalByDateRange(DateTime(2026, 5, 1), DateTime(2026, 5, 31))
          .first;
      expect(total, closeTo(24.8, 0.001));
      final outside = await repo
          .watchTotalByDateRange(DateTime(2026, 6, 1), DateTime(2026, 6, 30))
          .first;
      expect(outside, 0);
    });

    test('watchTotalByCategory: grouping by category name (gross, desc)', () async {
      await createViaRepo();
      final totals = await repo
          .watchTotalByCategory(DateTime(2026, 5, 1), DateTime(2026, 5, 31))
          .first;
      final categories = await fixture.db.select(fixture.db.categories).get();
      final name = categories.firstWhere((c) => c.id == fixture.categoryId).name;
      expect(totals, hasLength(1));
      expect(totals[name], closeTo(24.8, 0.001));
    });

    test('create με ανύπαρκτο supplier → SqliteException (καθαρή προώθηση)', () async {
      await expectLater(
        createViaRepo(supplier: 99999),
        throwsA(isA<SqliteException>()),
      );
    });

    test('delete σε ανύπαρκτο id → δεν ρίχνει (no-op passthrough)', () async {
      await repo.delete(99999);
    });
  });
}