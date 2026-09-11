// test/unit/core/database/daos/receipt_dao_test.dart
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/database/daos/daos.dart';
import 'package:expense_tracker/features/receipt/domain/models/receipt_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReceiptDao', () {
    late AppDatabase db;
    late ReceiptDao dao;
    late ItemDao itemDao;
    late TagDao tagDao;
    late int categoryId;
    late int supplierId;
    late int itemId;

    setUp(() async {
      db = AppDatabase.test();
      final settingDao = SettingDao(db);
      itemDao = ItemDao(db);
      tagDao = TagDao(db);
      dao = ReceiptDao(
        db,
        settingDao: settingDao,
        itemDao: itemDao,
        tagDao: tagDao,
      );
      final categories = await db.select(db.categories).get();
      categoryId = categories.first.id;
      supplierId = await db.into(db.suppliers).insert(
            SuppliersCompanion.insert(
              name: 'Test Supplier',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
      itemId = await itemDao.createItem(
        ItemsCompanion.insert(
          name: 'Test Item',
          categoryId: categoryId,
          currentStock: const Value(10),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    /// Δημιουργία απόδειξης μέσω DAO.
    /// Default: 1 γραμμή (itemId, qty 2 @ 10.00, vat 24%, discount 0), χωρίς πληρωμές.
    Future<int> createReceipt({
      DateTime? date,
      int? supplier,
      String? paymentMethod,
      List<ReceiptItemInput>? items,
      List<PaymentInput>? payments,
      String? invoiceNumber,
      String? notes,
    }) {
      return dao.createReceipt(
        ReceiptInput(
          date: date ?? DateTime(2026, 5, 15),
          supplierId: supplier ?? supplierId,
          paymentMethod: paymentMethod ?? 'cash',
          invoiceNumber: invoiceNumber,
          items: items ?? [ReceiptItemInput(itemId: itemId, quantity: 2, unitPrice: 10.0)],
          payments: payments ?? const [],
          notes: notes,
        ),
      );
    }

    group('watchAllReceipts', () {
      test('αρχικά κενό', () async {
        expect(await dao.watchAllReceipts().first, isEmpty);
      });

      test('ordering: receiptDate desc + tiebreak id desc', () async {
        await createReceipt(date: DateTime(2026, 5, 10));
        await createReceipt(date: DateTime(2026, 5, 15));
        await createReceipt(date: DateTime(2026, 5, 10));

        final list = await dao.watchAllReceipts().first;
        expect(list.length, 3);
        expect(list[0].receiptDate, DateTime(2026, 5, 15));
        // Οι δύο ίδιας ημερομηνίας: μόνο το id desc τις ξεχωρίζει.
        expect(list[1].receiptDate, DateTime(2026, 5, 10));
        expect(list[2].receiptDate, DateTime(2026, 5, 10));
        expect(list[1].id > list[2].id, isTrue);
      });

      test('φίλτρο startDate (αποκλείει προγενέστερες)', () async {
        await createReceipt(date: DateTime(2026, 4, 30));
        await createReceipt(date: DateTime(2026, 5, 1));

        final list =
            await dao.watchAllReceipts(startDate: DateTime(2026, 5, 1)).first;
        expect(list.length, 1);
        expect(list.first.receiptDate, DateTime(2026, 5, 1));
      });

      test('φίλτρο endDate (αποκλείει μεταγενέστερες)', () async {
        await createReceipt(date: DateTime(2026, 4, 30));
        await createReceipt(date: DateTime(2026, 5, 1));

        final list =
            await dao.watchAllReceipts(endDate: DateTime(2026, 4, 30)).first;
        expect(list.length, 1);
      });

      test('φίλτρο supplierId', () async {
        final otherSupplier = await db.into(db.suppliers).insert(
              SuppliersCompanion.insert(
                name: 'Other Supplier',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
        await createReceipt(supplier: supplierId);
        await createReceipt(supplier: otherSupplier);

        final list = await dao.watchAllReceipts(supplierId: supplierId).first;
        expect(list.length, 1);
      });

      test('φίλτρο paymentStatus', () async {
        // Μερική πληρωμή → 'partial'
        await createReceipt(payments: [
          PaymentInput(amount: 10, date: DateTime(2026, 5, 15), method: 'cash'),
        ]);
        // Χωρίς πληρωμές → 'pending'
        await createReceipt();

        final partial =
            await dao.watchAllReceipts(paymentStatus: 'partial').first;
        final pending = await dao.watchAllReceipts(paymentStatus: 'pending').first;
        expect(partial.length, 1);
        expect(pending.length, 1);
      });
    });

    group('getReceiptById', () {
      test('βρίσκει την απόδειξη', () async {
        final id = await createReceipt();
        final r = await dao.getReceiptById(id);
        expect(r, isNotNull);
        expect(r!.supplierId, supplierId);
        expect(r.receiptNumber, 1);
      });

      test('ανύπαρκτο id → null', () async {
        expect(await dao.getReceiptById(99999), isNull);
      });
    });

    group('watchReceiptItems', () {
      test('χωρίς γραμμές → κενό', () async {
        final id = await createReceipt(items: const []);
        expect(await dao.watchReceiptItems(id).first, isEmpty);
      });

      test('επιστρέφει γραμμές σε σειρά id asc', () async {
        final id = await createReceipt(items: [
          ReceiptItemInput(itemId: itemId, quantity: 2, unitPrice: 10.0),
          ReceiptItemInput(itemId: itemId, quantity: 3, unitPrice: 5.0),
        ]);
        final items = await dao.watchReceiptItems(id).first;
        expect(items.length, 2);
        expect(items[0].id < items[1].id, isTrue);
      });
    });

    group('getNextReceiptNumber', () {
      test('αρχική τιμή 1 (seed counter)', () async {
        expect(await dao.getNextReceiptNumber(), 1);
      });

      test('αυξάνεται μετά από create', () async {
        await createReceipt();
        expect(await dao.getNextReceiptNumber(), 2);
        await createReceipt();
        expect(await dao.getNextReceiptNumber(), 3);
      });
    });

    group('createReceipt', () {
      test('βασική δημιουργία: πεδία, totals, status pending', () async {
        final id = await createReceipt();
        final r = (await dao.getReceiptById(id))!;
        expect(r.supplierId, supplierId);
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
        final id = await createReceipt();
        final line = (await dao.watchReceiptItems(id).first).single;
        expect(line.quantity, closeTo(2, 0.001));
        expect(line.unitPrice, closeTo(10, 0.001));
        expect(line.totalPrice, closeTo(20, 0.001));
        expect(line.vatAmount, closeTo(4.8, 0.001));
        expect(line.totalWithVat, closeTo(24.8, 0.001));
      });

      test('discount % μειώνει net/vat και καταγράφεται στο discountTotal',
          () async {
        final id = await createReceipt(items: [
          ReceiptItemInput(itemId: itemId, quantity: 2, unitPrice: 10.0, discount: 10),
        ]);
        final r = (await dao.getReceiptById(id))!;
        // net = 20 - 10% = 18, vat 24% = 4.32, gross 22.32
        expect(r.totalAmount, closeTo(18.0, 0.001));
        expect(r.vatTotal, closeTo(4.32, 0.001));
        expect(r.discountTotal, closeTo(2.0, 0.001));
        expect(r.remainingAmount, closeTo(22.32, 0.001));
      });

      test('κενά items: επιτρέπεται (block στο Validators) — totals 0',
          () async {
        final id = await createReceipt(items: const []);
        final r = (await dao.getReceiptById(id))!;
        expect(r.totalAmount, closeTo(0, 0.001));
        expect(r.vatTotal, closeTo(0, 0.001));
        // remaining = 0 → 'paid' (συνεπές με §4.3: remaining <= 0 → paid)
        expect(r.paymentStatus, 'paid');
      });

      test('διπλότυπες γραμμές ίδιου item: και οι δύο στον πίνακα', () async {
        final id = await createReceipt(items: [
          ReceiptItemInput(itemId: itemId, quantity: 2, unitPrice: 10.0),
          ReceiptItemInput(itemId: itemId, quantity: 3, unitPrice: 5.0),
        ]);
        final items = await dao.watchReceiptItems(id).first;
        expect(items.length, 2);
        final r = (await dao.getReceiptById(id))!;
        // totalAmount = 20 + 15 = 35, vat = 4.8 + 3.6 = 8.4
        expect(r.totalAmount, closeTo(35.0, 0.001));
        expect(r.vatTotal, closeTo(8.4, 0.001));
        // stock: 10 + 2 + 3 = 15
        expect((await itemDao.getItemById(itemId))!.currentStock, 15);
      });

      test('ακριβής πληρωμή → paid (ανοχή floating errors)', () async {
        final id = await createReceipt(payments: [
          PaymentInput(amount: 24.8, date: DateTime(2026, 5, 15), method: 'cash'),
        ]);
        final r = (await dao.getReceiptById(id))!;
        expect(r.paymentStatus, 'paid');
        expect(r.paidAmount, closeTo(24.8, 0.001));
        expect(r.remainingAmount, closeTo(0, 0.001));
      });

      test('μερική πληρωμή → partial', () async {
        final id = await createReceipt(payments: [
          PaymentInput(amount: 10, date: DateTime(2026, 5, 15), method: 'cash'),
        ]);
        final r = (await dao.getReceiptById(id))!;
        expect(r.paymentStatus, 'partial');
        expect(r.paidAmount, closeTo(10, 0.001));
        expect(r.remainingAmount, closeTo(14.8, 0.001));
      });

      test('υπερ-πληρωμή → paid με paidAmount = όσο πληρώθηκε', () async {
        final id = await createReceipt(payments: [
          PaymentInput(amount: 30, date: DateTime(2026, 5, 15), method: 'cash'),
        ]);
        final r = (await dao.getReceiptById(id))!;
        expect(r.paymentStatus, 'paid');
        expect(r.paidAmount, closeTo(30, 0.001));
        expect(r.remainingAmount, closeTo(-5.2, 0.001));
      });

      test('stock: αύξηση + lastPrice/lastSupplierId', () async {
        await createReceipt();
        final item = (await itemDao.getItemById(itemId))!;
        expect(item.currentStock, 12);
        expect(item.lastPrice, closeTo(10, 0.001));
        expect(item.lastSupplierId, supplierId);
      });

      test('price_history: εγγραφή για κάθε γραμμή', () async {
        await createReceipt();
        final rows = await db.select(db.priceHistory).get();
        expect(rows.length, 1);
        expect(rows.single.itemId, itemId);
        expect(rows.single.price, closeTo(10, 0.001));
        expect(rows.single.supplierId, supplierId);
        expect(rows.single.quantity, closeTo(2, 0.001));
      });

      test('ανύπαρκτος supplier → SqliteException', () async {
        await expectLater(
          createReceipt(supplier: 999999),
          throwsA(isA<SqliteException>()),
        );
      });

      test('ανύπαρκτο item → SqliteException', () async {
        await expectLater(
          createReceipt(items: [
            ReceiptItemInput(itemId: 999999, quantity: 1, unitPrice: 1),
          ]),
          throwsA(isA<SqliteException>()),
        );
      });

      test('μοναδικοί αριθμοί σε διαδοχικές δημιουργίες', () async {
        final a = await createReceipt();
        final b = await createReceipt();
        final receiptA = (await dao.getReceiptById(a))!;
        final receiptB = (await dao.getReceiptById(b))!;
        expect(receiptA.receiptNumber, 1);
        expect(receiptB.receiptNumber, 2);
      });
    });

    group('updateReceiptItem', () {
      test('επανυπολογισμός totals + stock delta + νέες τιμές γραμμής',
          () async {
        final id = await createReceipt(); // qty2 price10 → stock 12
        await dao.updateReceiptItem(id, itemId, const ReceiptItemUpdate(
          quantity: 3,
          unitPrice: 5,
          vatRate: 24,
          discount: 0,
        ));

        final r = (await dao.getReceiptById(id))!;
        expect(r.totalAmount, closeTo(15, 0.001));
        expect(r.vatTotal, closeTo(3.6, 0.001));
        expect(r.remainingAmount, closeTo(18.6, 0.001));
        // stock: 12 + (3-2) = 13
        expect((await itemDao.getItemById(itemId))!.currentStock, 13);
        final line = (await dao.watchReceiptItems(id).first).single;
        expect(line.unitPrice, closeTo(5, 0.001));
        expect(line.quantity, closeTo(3, 0.001));
      });

      test('status downgrade paid → partial μετά αύξηση ποσού', () async {
        final id = await createReceipt(payments: [
          PaymentInput(amount: 24.8, date: DateTime(2026, 5, 15), method: 'cash'),
        ]);
        expect((await dao.getReceiptById(id))!.paymentStatus, 'paid');

        await dao.updateReceiptItem(id, itemId, const ReceiptItemUpdate(
          quantity: 5,
          unitPrice: 10,
          vatRate: 24,
          discount: 0,
        ));

        // νέο gross = 50 + 12 = 62, πληρωμένα 24.8 → remaining 37.2 → partial
        final r = (await dao.getReceiptById(id))!;
        expect(r.paymentStatus, 'partial');
        expect(r.paidAmount, closeTo(24.8, 0.001));
        expect(r.remainingAmount, closeTo(37.2, 0.001));
      });

      test('ανύπαρκτη γραμμή → no-op χωρίς λάθος', () async {
        final id = await createReceipt();
        await dao.updateReceiptItem(id, 999999, const ReceiptItemUpdate(
          quantity: 1,
          unitPrice: 1,
          vatRate: 24,
          discount: 0,
        ));
        final r = (await dao.getReceiptById(id))!;
        expect(r.totalAmount, closeTo(20, 0.001));
      });
    });

    group('deleteReceiptItem', () {
      test('επαναφορά stock + επανυπολογισμός totals', () async {
        final id = await createReceipt(); // stock 12
        await dao.deleteReceiptItem(id, itemId);

        expect(await dao.watchReceiptItems(id).first, isEmpty);
        expect((await itemDao.getItemById(itemId))!.currentStock, 10);
        final r = (await dao.getReceiptById(id))!;
        expect(r.totalAmount, closeTo(0, 0.001));
        expect(r.vatTotal, closeTo(0, 0.001));
        // κενό υπόλοιπο → 'paid' (consistent semantics με κενή απόδειξη)
        expect(r.paymentStatus, 'paid');
      });

      test('ανύπαρκτη γραμμή → no-op', () async {
        final id = await createReceipt();
        await dao.deleteReceiptItem(id, 999999);
        expect((await dao.watchReceiptItems(id).first).length, 1);
      });
    });

    group('deleteReceipt', () {
      test('cascade: tags + items + payments + receipt', () async {
        final id = await createReceipt();
        // Προσθήκη tag (μέσω TagDao — SPoT)
        final tag = await tagDao.createTag('Test Tag');
        await tagDao.addTagToReceipt(id, tag!.id);

        await dao.deleteReceipt(id);

        expect(await dao.getReceiptById(id), isNull);
        expect(await dao.watchReceiptItems(id).first, isEmpty);
        expect(
          await (db.select(db.payments)
                ..where((p) => p.receiptId.equals(id)))
              .get(),
          isEmpty,
        );
        expect(
          await (db.select(db.receiptTags)
                ..where((rt) => rt.receiptId.equals(id)))
              .get(),
          isEmpty,
        );
        // Το tag παραμένει (δεν διαγράφεται)
        expect(await tagDao.getTagById(tag.id), isNotNull);
      });

      test('stock επιστρέφει στην αρχική τιμή', () async {
        await createReceipt(); // stock 12
        await createReceipt(); // stock 15
        final list = await dao.watchAllReceipts().first;

        // Ίδια ημερομηνία → tiebreak id desc: πρώτο = δεύτερη (νεότερη) απόδειξη.
        await dao.deleteReceipt(list.first.id);
        expect((await itemDao.getItemById(itemId))!.currentStock, 12);
        await dao.deleteReceipt(list.last.id);
        expect((await itemDao.getItemById(itemId))!.currentStock, 10);
      });

      test('price_history διατηρείται (ιστορικό)', () async {
        final id = await createReceipt();
        await dao.deleteReceipt(id);
        expect(await db.select(db.priceHistory).get(), isNotEmpty);
      });
    });

    group('aggregates', () {
      test('watchReceiptCount: 0 → N', () async {
        expect(await dao.watchReceiptCount().first, 0);
        await createReceipt();
        await createReceipt();
        expect(await dao.watchReceiptCount().first, 2);
      });

      test('watchTotalByDateRange: gross, φιλτράρει εύρος', () async {
        final id = await createReceipt(date: DateTime(2026, 5, 10));
        final r = (await dao.getReceiptById(id))!;

        final inRange = await dao
            .watchTotalByDateRange(DateTime(2026, 5, 1), DateTime(2026, 5, 31))
            .first;
        expect(inRange, closeTo(r.totalAmount + r.vatTotal, 0.001));

        final outOfRange = await dao
            .watchTotalByDateRange(DateTime(2026, 6, 1), DateTime(2026, 6, 30))
            .first;
        expect(outOfRange, closeTo(0, 0.001));
      });

      test('watchTotalByCategory: grouping + order desc', () async {
        final otherCategory = (await db.select(db.categories).get())[1];
        final itemB = await itemDao.createItem(
          ItemsCompanion.insert(
            name: 'Item B',
            categoryId: otherCategory.id,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        // Κατηγορία 'Οικιακά': qty1*50 → gross 62
        await createReceipt(items: [
          ReceiptItemInput(itemId: itemB, quantity: 1, unitPrice: 50),
        ]);
        // Κατηγορία 'Τρόφιμα' (itemId): qty2*10 → gross 24.8
        await createReceipt(items: [
          ReceiptItemInput(itemId: itemId, quantity: 2, unitPrice: 10),
        ]);

        final map = await dao
            .watchTotalByCategory(DateTime(2026, 5, 1), DateTime(2026, 5, 31))
            .first;
        expect(map.keys.first, otherCategory.name); // order desc
        expect(map[otherCategory.name], closeTo(62, 0.001));
        expect(map.values.first, closeTo(62, 0.001));
        expect(map.length, 2);
      });

      test('watchAverageAmount: μέσος όρος net total_amount', () async {
        expect(await dao.watchAverageAmount().first, closeTo(0, 0.001));
        await createReceipt(); // total_amount 20
        await createReceipt(); // total_amount 20
        expect(await dao.watchAverageAmount().first, closeTo(20, 0.001));
      });
    });
  });
}