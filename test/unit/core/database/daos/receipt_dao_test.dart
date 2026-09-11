// test/unit/core/database/daos/receipt_dao_test.dart
import 'package:drift/native.dart';
import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/features/receipt/domain/models/receipt_input.dart';
import 'package:flutter_test/flutter_test.dart';

import 'receipt_dao_test_fixture.dart';

void main() {
  group('ReceiptDao', () {
    final fixture = ReceiptDaoFixture();

    setUp(fixture.setUp);
    tearDown(fixture.tearDown);

    group('watchAllReceipts', () {
      test('αρχικά κενό', () async {
        expect(await fixture.dao.watchAllReceipts().first, isEmpty);
      });

      test('ordering: receiptDate desc + tiebreak id desc', () async {
        await fixture.createReceipt(date: DateTime(2026, 5, 10));
        await fixture.createReceipt(date: DateTime(2026, 5, 15));
        await fixture.createReceipt(date: DateTime(2026, 5, 10));

        final list = await fixture.dao.watchAllReceipts().first;
        expect(list.length, 3);
        expect(list[0].receiptDate, DateTime(2026, 5, 15));
        // Οι δύο ίδιας ημερομηνίας: μόνο το id desc τις ξεχωρίζει.
        expect(list[1].receiptDate, DateTime(2026, 5, 10));
        expect(list[2].receiptDate, DateTime(2026, 5, 10));
        expect(list[1].id > list[2].id, isTrue);
      });

      test('φίλτρο startDate (αποκλείει προγενέστερες)', () async {
        await fixture.createReceipt(date: DateTime(2026, 4, 30));
        await fixture.createReceipt(date: DateTime(2026, 5, 1));

        final list = await fixture
            .dao
            .watchAllReceipts(startDate: DateTime(2026, 5, 1))
            .first;
        expect(list.length, 1);
        expect(list.first.receiptDate, DateTime(2026, 5, 1));
      });

      test('φίλτρο endDate (αποκλείει μεταγενέστερες)', () async {
        await fixture.createReceipt(date: DateTime(2026, 4, 30));
        await fixture.createReceipt(date: DateTime(2026, 5, 1));

        final list = await fixture
            .dao
            .watchAllReceipts(endDate: DateTime(2026, 4, 30))
            .first;
        expect(list.length, 1);
      });

      test('φίλτρο supplierId', () async {
        final otherSupplier = await fixture.db.into(fixture.db.suppliers).insert(
              SuppliersCompanion.insert(
                name: 'Other Supplier',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
        await fixture.createReceipt(supplier: fixture.supplierId);
        await fixture.createReceipt(supplier: otherSupplier);

        final list = await fixture
            .dao
            .watchAllReceipts(supplierId: fixture.supplierId)
            .first;
        expect(list.length, 1);
      });

      test('φίλτρο paymentStatus', () async {
        // Μερική πληρωμή → 'partial'
        await fixture.createReceipt(payments: [
          PaymentInput(amount: 10, date: DateTime(2026, 5, 15), method: 'cash'),
        ]);
        // Χωρίς πληρωμές → 'pending'
        await fixture.createReceipt();

        final partial = await fixture
            .dao
            .watchAllReceipts(paymentStatus: 'partial')
            .first;
        final pending = await fixture
            .dao
            .watchAllReceipts(paymentStatus: 'pending')
            .first;
        expect(partial.length, 1);
        expect(pending.length, 1);
      });
    });

    group('getReceiptById', () {
      test('βρίσκει την απόδειξη', () async {
        final id = await fixture.createReceipt();
        final r = await fixture.dao.getReceiptById(id);
        expect(r, isNotNull);
        expect(r!.supplierId, fixture.supplierId);
        expect(r.receiptNumber, 1);
      });

      test('ανύπαρκτο id → null', () async {
        expect(await fixture.dao.getReceiptById(99999), isNull);
      });
    });

    group('watchReceiptItems', () {
      test('χωρίς γραμμές → κενό', () async {
        final id = await fixture.createReceipt(items: const []);
        expect(await fixture.dao.watchReceiptItems(id).first, isEmpty);
      });

      test('επιστρέφει γραμμές σε σειρά id asc', () async {
        final id = await fixture.createReceipt(items: [
          ReceiptItemInput(itemId: fixture.itemId, quantity: 2, unitPrice: 10.0),
          ReceiptItemInput(itemId: fixture.itemId, quantity: 3, unitPrice: 5.0),
        ]);
        final items = await fixture.dao.watchReceiptItems(id).first;
        expect(items.length, 2);
        expect(items[0].id < items[1].id, isTrue);
      });
    });

    group('getNextReceiptNumber', () {
      test('αρχική τιμή 1 (seed counter)', () async {
        expect(await fixture.dao.getNextReceiptNumber(), 1);
      });

      test('αυξάνεται μετά από create', () async {
        await fixture.createReceipt();
        expect(await fixture.dao.getNextReceiptNumber(), 2);
        await fixture.createReceipt();
        expect(await fixture.dao.getNextReceiptNumber(), 3);
      });
    });

    group('createReceipt', () {
      test('βασική δημιουργία: πεδία, totals, status pending', () async {
        final id = await fixture.createReceipt();
        final r = (await fixture.dao.getReceiptById(id))!;
        expect(r.supplierId, fixture.supplierId);
        expect(r.paymentMethod, 'cash');
        expect(r.paymentStatus, 'pending');
        // γραμμή: qty2*10 → net 20, vat 24% → 4.80, gross 24.80
        expect(r.totalAmount, closeTo(20.0, 0.001));
        expect(r.vatTotal, closeTo(4.8, 0.001));
        expect(r.discountTotal, closeTo(0.0, 0.001));
        expect(r.paidAmount, closeTo(0.0, 0.001));
        expect(r.remainingAmount, closeTo(24.8, 0.001));
      });

      test('γραμμή: net/vat/gross υπολογισμένα σωστά', () async {
        final id = await fixture.createReceipt();
        final line = (await fixture.dao.watchReceiptItems(id).first).single;
        expect(line.quantity, closeTo(2, 0.001));
        expect(line.unitPrice, closeTo(10, 0.001));
        expect(line.totalPrice, closeTo(20, 0.001));
        expect(line.vatAmount, closeTo(4.8, 0.001));
        expect(line.totalWithVat, closeTo(24.8, 0.001));
      });

      test('discount % μειώνει net/vat και καταγράφεται στο discountTotal',
          () async {
        final id = await fixture.createReceipt(items: [
          ReceiptItemInput(
              itemId: fixture.itemId, quantity: 2, unitPrice: 10.0, discount: 10),
        ]);
        final r = (await fixture.dao.getReceiptById(id))!;
        // net = 20 - 10% = 18, vat 24% = 4.32, gross 22.32
        expect(r.totalAmount, closeTo(18.0, 0.001));
        expect(r.vatTotal, closeTo(4.32, 0.001));
        expect(r.discountTotal, closeTo(2.0, 0.001));
        expect(r.remainingAmount, closeTo(22.32, 0.001));
      });

      test('κενά items: επιτρέπεται (block στο Validators) — totals 0',
          () async {
        final id = await fixture.createReceipt(items: const []);
        final r = (await fixture.dao.getReceiptById(id))!;
        expect(r.totalAmount, closeTo(0, 0.001));
        expect(r.vatTotal, closeTo(0, 0.001));
        // remaining = 0 → 'paid' (συνεπές με §4.3: remaining <= 0 → paid)
        expect(r.paymentStatus, 'paid');
      });

      test('διπλότυπες γραμμές ίδιου item: και οι δύο στον πίνακα', () async {
        final id = await fixture.createReceipt(items: [
          ReceiptItemInput(itemId: fixture.itemId, quantity: 2, unitPrice: 10.0),
          ReceiptItemInput(itemId: fixture.itemId, quantity: 3, unitPrice: 5.0),
        ]);
        final items = await fixture.dao.watchReceiptItems(id).first;
        expect(items.length, 2);
        final r = (await fixture.dao.getReceiptById(id))!;
        // totalAmount = 20 + 15 = 35, vat = 4.8 + 3.6 = 8.4
        expect(r.totalAmount, closeTo(35.0, 0.001));
        expect(r.vatTotal, closeTo(8.4, 0.001));
        // stock: 10 + 2 + 3 = 15
        expect((await fixture.itemDao.getItemById(fixture.itemId))!.currentStock, 15);
      });

      test('ακριβής πληρωμή → paid (ανοχή floating errors)', () async {
        final id = await fixture.createReceipt(payments: [
          PaymentInput(amount: 24.8, date: DateTime(2026, 5, 15), method: 'cash'),
        ]);
        final r = (await fixture.dao.getReceiptById(id))!;
        expect(r.paymentStatus, 'paid');
        expect(r.paidAmount, closeTo(24.8, 0.001));
        expect(r.remainingAmount, closeTo(0, 0.001));
      });

      test('μερική πληρωμή → partial', () async {
        final id = await fixture.createReceipt(payments: [
          PaymentInput(amount: 10, date: DateTime(2026, 5, 15), method: 'cash'),
        ]);
        final r = (await fixture.dao.getReceiptById(id))!;
        expect(r.paymentStatus, 'partial');
        expect(r.paidAmount, closeTo(10, 0.001));
        expect(r.remainingAmount, closeTo(14.8, 0.001));
      });

      test('υπερ-πληρωμή → paid με paidAmount = όσο πληρώθηκε', () async {
        final id = await fixture.createReceipt(payments: [
          PaymentInput(amount: 30, date: DateTime(2026, 5, 15), method: 'cash'),
        ]);
        final r = (await fixture.dao.getReceiptById(id))!;
        expect(r.paymentStatus, 'paid');
        expect(r.paidAmount, closeTo(30, 0.001));
        expect(r.remainingAmount, closeTo(-5.2, 0.001));
      });

      test('stock: αύξηση + lastPrice/lastSupplierId', () async {
        await fixture.createReceipt();
        final item = (await fixture.itemDao.getItemById(fixture.itemId))!;
        expect(item.currentStock, 12);
        expect(item.lastPrice, closeTo(10, 0.001));
        expect(item.lastSupplierId, fixture.supplierId);
      });

      test('price_history: εγγραφή για κάθε γραμμή', () async {
        await fixture.createReceipt();
        final rows = await fixture.db.select(fixture.db.priceHistory).get();
        expect(rows.length, 1);
        expect(rows.single.itemId, fixture.itemId);
        expect(rows.single.price, closeTo(10, 0.001));
        expect(rows.single.supplierId, fixture.supplierId);
        expect(rows.single.quantity, closeTo(2, 0.001));
      });

      test('ανύπαρκτος supplier → SqliteException', () async {
        await expectLater(
          fixture.createReceipt(supplier: 999999),
          throwsA(isA<SqliteException>()),
        );
      });

      test('ανύπαρκτο item → SqliteException', () async {
        await expectLater(
          fixture.createReceipt(items: [
            ReceiptItemInput(itemId: 999999, quantity: 1, unitPrice: 1),
          ]),
          throwsA(isA<SqliteException>()),
        );
      });

      test('μοναδικοί αριθμοί σε διαδοχικές δημιουργίες', () async {
        final a = await fixture.createReceipt();
        final b = await fixture.createReceipt();
        final receiptA = (await fixture.dao.getReceiptById(a))!;
        final receiptB = (await fixture.dao.getReceiptById(b))!;
        expect(receiptA.receiptNumber, 1);
        expect(receiptB.receiptNumber, 2);
      });
    });

    group('updateReceiptItem', () {
      test('επανυπολογισμός totals + stock delta + νέες τιμές γραμμής',
          () async {
        final id = await fixture.createReceipt(); // qty2 price10 → stock 12
        await fixture.dao.updateReceiptItem(
          id,
          fixture.itemId,
          const ReceiptItemUpdate(
            quantity: 3,
            unitPrice: 5,
            vatRate: 24,
            discount: 0,
          ),
        );

        final r = (await fixture.dao.getReceiptById(id))!;
        expect(r.totalAmount, closeTo(15, 0.001));
        expect(r.vatTotal, closeTo(3.6, 0.001));
        expect(r.remainingAmount, closeTo(18.6, 0.001));
        // stock: 12 + (3-2) = 13
        expect((await fixture.itemDao.getItemById(fixture.itemId))!.currentStock, 13);
        final line = (await fixture.dao.watchReceiptItems(id).first).single;
        expect(line.unitPrice, closeTo(5, 0.001));
        expect(line.quantity, closeTo(3, 0.001));
      });

      test('status downgrade paid → partial μετά αύξηση ποσού', () async {
        final id = await fixture.createReceipt(payments: [
          PaymentInput(amount: 24.8, date: DateTime(2026, 5, 15), method: 'cash'),
        ]);
        expect((await fixture.dao.getReceiptById(id))!.paymentStatus, 'paid');

        await fixture.dao.updateReceiptItem(
          id,
          fixture.itemId,
          const ReceiptItemUpdate(
            quantity: 5,
            unitPrice: 10,
            vatRate: 24,
            discount: 0,
          ),
        );

        // νέο gross = 50 + 12 = 62, πληρωμένα 24.8 → remaining 37.2 → partial
        final r = (await fixture.dao.getReceiptById(id))!;
        expect(r.paymentStatus, 'partial');
        expect(r.paidAmount, closeTo(24.8, 0.001));
        expect(r.remainingAmount, closeTo(37.2, 0.001));
      });

      test('ανύπαρκτη γραμμή → no-op χωρίς λάθος', () async {
        final id = await fixture.createReceipt();
        await fixture.dao.updateReceiptItem(
          id,
          999999,
          const ReceiptItemUpdate(
            quantity: 1,
            unitPrice: 1,
            vatRate: 24,
            discount: 0,
          ),
        );
        final r = (await fixture.dao.getReceiptById(id))!;
        expect(r.totalAmount, closeTo(20, 0.001));
      });
    });

    group('deleteReceiptItem', () {
      test('επαναφορά stock + επανυπολογισμός totals', () async {
        final id = await fixture.createReceipt(); // stock 12
        await fixture.dao.deleteReceiptItem(id, fixture.itemId);

        expect(await fixture.dao.watchReceiptItems(id).first, isEmpty);
        expect((await fixture.itemDao.getItemById(fixture.itemId))!.currentStock, 10);
        final r = (await fixture.dao.getReceiptById(id))!;
        expect(r.totalAmount, closeTo(0, 0.001));
        expect(r.vatTotal, closeTo(0, 0.001));
        // κενό υπόλοιπο → 'paid' (consistent semantics με κενή απόδειξη)
        expect(r.paymentStatus, 'paid');
      });

      test('ανύπαρκτη γραμμή → no-op', () async {
        final id = await fixture.createReceipt();
        await fixture.dao.deleteReceiptItem(id, 999999);
        expect((await fixture.dao.watchReceiptItems(id).first).length, 1);
      });
    });

    group('deleteReceipt', () {
      test('cascade: tags + items + payments + receipt', () async {
        final id = await fixture.createReceipt();
        // Προσθήκη tag (μέσω TagDao — SPoT)
        final tag = await fixture.tagDao.createTag('Test Tag');
        await fixture.tagDao.addTagToReceipt(id, tag!.id);

        await fixture.dao.deleteReceipt(id);

        expect(await fixture.dao.getReceiptById(id), isNull);
        expect(await fixture.dao.watchReceiptItems(id).first, isEmpty);
        expect(
          await (fixture.db.select(fixture.db.payments)
                ..where((p) => p.receiptId.equals(id)))
              .get(),
          isEmpty,
        );
        expect(
          await (fixture.db.select(fixture.db.receiptTags)
                ..where((rt) => rt.receiptId.equals(id)))
              .get(),
          isEmpty,
        );
        // Το tag παραμένει (δεν διαγράφεται)
        expect(await fixture.tagDao.getTagById(tag.id), isNotNull);
      });

      test('stock επιστρέφει στην αρχική τιμή', () async {
        await fixture.createReceipt(); // stock 12
        await fixture.createReceipt(); // stock 15
        final list = await fixture.dao.watchAllReceipts().first;

        // Ίδια ημερομηνία → tiebreak id desc: πρώτο = δεύτερη (νεότερη) απόδειξη.
        await fixture.dao.deleteReceipt(list.first.id);
        expect((await fixture.itemDao.getItemById(fixture.itemId))!.currentStock, 12);
        await fixture.dao.deleteReceipt(list.last.id);
        expect((await fixture.itemDao.getItemById(fixture.itemId))!.currentStock, 10);
      });

      test('price_history διατηρείται (ιστορικό)', () async {
        final id = await fixture.createReceipt();
        await fixture.dao.deleteReceipt(id);
        expect(await fixture.db.select(fixture.db.priceHistory).get(), isNotEmpty);
      });
    });
  });
}