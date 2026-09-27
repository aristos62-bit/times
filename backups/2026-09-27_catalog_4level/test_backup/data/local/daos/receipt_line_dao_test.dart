/// Unit tests για το `ReceiptLineDao` (Φάση 1, Βήμα 2) — CRUD + streams.
///
/// SPoT §3: το `lineTotalCents` υπολογίζεται ΠΑΝΤΑ εσωτερικά — `(priceCents *
/// quantity).round()` στο insert και ξανά στο updateById όταν αλλάζουν.
/// Ελέγχει φιλτράρισμα ανά απόδειξη, ordering (id), FK raw errors σε όλους
/// τους δείκτες, και RESTRICT σε προστατευμένα parent rows.
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/receipt_dao.dart';
import 'package:times/data/local/daos/receipt_line_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/supplier_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';

import '../helpers/in_memory_db.dart';

void main() {
  late dynamic db;
  late ReceiptLineDao dao;
  late int supplierId;
  late int receiptId;
  late int unitId;
  late int itemId;

  // Πλήρης αλυσίδα: unit, category→subcategory→item, supplier→receipt.
  Future<void> seed() async {
    final unitDao = UnitDao(db);
    unitId = await unitDao.insert(name: 'Τεμάχιο', abbreviation: 'τεμ');

    final categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    final subId = await SubCategoryDao(db)
        .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
    itemId = await ItemDao(db).insert(
      subCategoryId: subId,
      name: 'Γάλα',
      defaultUnitId: unitId,
    );

    supplierId = await SupplierDao(db).insert(name: 'Μάρκος');
    receiptId = await ReceiptDao(db)
        .insert(date: DateTime(2026, 1, 1), supplierId: supplierId);
  }

  setUp(() async {
    db = inMemoryDb();
    dao = ReceiptLineDao(db);
    await seed();
  });

  tearDown(() async => await db.close());

  group('ReceiptLineDao.insert (SPoT lineTotalCents)', () {
    test('υπολογίζει lineTotalCents: 2.5 * 199 = 497.5 → 498', () async {
      final id = await dao.insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 2.5,
        priceCents: 199,
      );
      final row = await dao.getById(id);

      expect(row!.lineTotalCents, 498);
    });

    test('ακέραιο αποτέλεσμα: 3 * 100 = 300', () async {
      final id = await dao.insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 3,
        priceCents: 100,
      );
      expect((await dao.getById(id))!.lineTotalCents, 300);
    });

    test('FK raw errors: ανύπαρκτο receipt/item/unit', () async {
      for (final params in [
        (receiptId: 9999, itemId: itemId, unitId: unitId),
        (receiptId: receiptId, itemId: 9999, unitId: unitId),
        (receiptId: receiptId, itemId: itemId, unitId: 9999),
      ]) {
        await expectLater(
          dao.insert(
            receiptId: params.receiptId,
            itemId: params.itemId,
            unitId: params.unitId,
            quantity: 1,
            priceCents: 100,
          ),
          throwsA(allOf(isA<SqliteException>(), isNot(isA<AppException>()))),
        );
      }
    });
  });

  group('ReceiptLineDao.watchByReceiptId', () {
    test('φιλτράρει μόνο τις γραμμές της απόδειξης, order id', () async {
      final id1 = await dao.insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 1,
        priceCents: 100,
      );
      final id2 = await dao.insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 2,
        priceCents: 200,
      );

      final ids = (await dao.watchByReceiptId(receiptId).first)
          .map((l) => l.id)
          .toList();
      expect(ids, [id1, id2]);
    });
  });

  group('ReceiptLineDao.updateById', () {
    test('αλλαγή quantity → ξανά-υπολογισμός lineTotalCents (SPoT §3)',
        () async {
      final id = await dao.insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 1,
        priceCents: 100,
      );

      expect(await dao.updateById(id, quantity: 2), isTrue);
      final row = await dao.getById(id);
      expect(row!.quantity, 2);
      expect(row.lineTotalCents, 200);
    });

    test('αλλαγή priceCents → ξανά-υπολογισμός (SPoT §3)', () async {
      final id = await dao.insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 2,
        priceCents: 100,
      );

      expect(await dao.updateById(id, priceCents: 150), isTrue);
      expect((await dao.getById(id))!.lineTotalCents, 300);
    });

    test('αλλαγή και quantity και priceCents → βάσει ΝΕΩΝ τιμών', () async {
      final id = await dao.insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 1,
        priceCents: 100,
      );

      await dao.updateById(id, quantity: 3, priceCents: 50);
      expect((await dao.getById(id))!.lineTotalCents, 150);
    });

    test('ανύπαρκτο id → false', () async {
      expect(await dao.updateById(9999, quantity: 1), isFalse);
    });
  });

  group('ReceiptLineDao.insert — με έκπτωση (SPoT §3)', () {
    test('lineTotalCents = ((250−50)×2).round() = 400', () async {
      final id = await dao.insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 2,
        priceCents: 250,
        discountCents: 50,
      );
      final row = await dao.getById(id);

      expect(row!.discountCents, 50);
      expect(row.lineTotalCents, 400);
    });

    test('έκπτωση = τιμή → σύνολο 0 (έγκυρη δωρεάν γραμμή)', () async {
      final id = await dao.insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 3,
        priceCents: 100,
        discountCents: 100,
      );
      expect((await dao.getById(id))!.lineTotalCents, 0);
    });

    test('default (χωρίς όρισμα) → discountCents 0, σύνολο αμετάβλητο',
        () async {
      final id = await dao.insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 2,
        priceCents: 199,
      );
      final row = await dao.getById(id);

      expect(row!.discountCents, 0);
      expect(row.lineTotalCents, 398);
    });
  });

  group('ReceiptLineDao.updateById — με έκπτωση (SPoT §3)', () {
    test('αλλαγή ΜΟΝΟ discountCents → ξανά-υπολογισμός', () async {
      final id = await dao.insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 2,
        priceCents: 250,
      );

      expect(await dao.updateById(id, discountCents: 50), isTrue);
      final row = await dao.getById(id);
      expect(row!.discountCents, 50);
      expect(row.lineTotalCents, 400);
    });

    test('αλλαγή priceCents + discountCents → βάσει ΝΕΩΝ τιμών', () async {
      final id = await dao.insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 1,
        priceCents: 100,
      );

      await dao.updateById(id, priceCents: 300, discountCents: 100);
      expect((await dao.getById(id))!.lineTotalCents, 200);
    });
  });

  group('ReceiptLineDao.getLatestByItemId (§2.2 prefill)', () {
    Future<int> receipt(DateTime date) => ReceiptDao(db)
        .insert(date: date, supplierId: supplierId);

    test('επιστρέφει τη γραμμή της νεότερης απόδειξης (όχι του max id)',
        () async {
      final oldId = await receipt(DateTime(2026, 3, 1));
      final newId = await receipt(DateTime(2026, 1, 1));
      await dao.insert(
        receiptId: oldId,
        itemId: itemId,
        unitId: unitId,
        quantity: 1,
        priceCents: 100,
      );
      await dao.insert(
        receiptId: newId,
        itemId: itemId,
        unitId: unitId,
        quantity: 2,
        priceCents: 250,
        discountCents: 50,
      );
      // Backdated: παλιότερη ημερομηνία μπαίνει ΤΕΛΕΥΤΑΙΑ (μεγαλύτερο id).
      final backdatedId = await receipt(DateTime(2025, 12, 1));
      await dao.insert(
        receiptId: backdatedId,
        itemId: itemId,
        unitId: unitId,
        quantity: 5,
        priceCents: 90,
      );

      final latest = await dao.getLatestByItemId(itemId);

      expect(latest, isNotNull);
      expect(latest!.receiptId, oldId, reason: 'Νεότερη ΗΜΕΡΟΜΗΝΙΑ, όχι id');
      expect(latest.priceCents, 100);
    });

    test('ίδια ημέρα → tiebreak με max id', () async {
      final id = await receipt(DateTime(2026, 1, 1));
      await dao.insert(
        receiptId: id,
        itemId: itemId,
        unitId: unitId,
        quantity: 1,
        priceCents: 100,
      );
      final second = await dao.insert(
        receiptId: id,
        itemId: itemId,
        unitId: unitId,
        quantity: 1,
        priceCents: 120,
        discountCents: 20,
      );

      final latest = await dao.getLatestByItemId(itemId);

      expect(latest!.id, second);
      expect(latest.priceCents, 120);
      expect(latest.discountCents, 20);
    });

    test('είδος χωρίς γραμμές → null', () async {
      expect(await dao.getLatestByItemId(9999), isNull);
    });

    test('γραμμές άλλου είδους αγνοούνται', () async {
      final id = await receipt(DateTime(2026, 1, 1));
      await dao.insert(
        receiptId: id,
        itemId: itemId,
        unitId: unitId,
        quantity: 1,
        priceCents: 100,
      );

      expect(await dao.getLatestByItemId(itemId + 9999), isNull);
    });
  });

  group('ReceiptLineDao.deleteById', () {
    test('διαγράφει τη γραμμή', () async {
      final id = await dao.insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 1,
        priceCents: 100,
      );

      expect(await dao.deleteById(id), isTrue);
      expect(await dao.getById(id), isNull);
    });
  });

  group('RESTRICT (lines προστατεύουν parents)', () {
    test('item με γραμμή δεν διαγράφεται (raw error)', () async {
      await dao.insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 1,
        priceCents: 100,
      );

      await expectLater(
        ItemDao(db).deleteById(itemId),
        throwsA(allOf(isA<SqliteException>(), isNot(isA<AppException>()))),
      );
      expect(await ItemDao(db).getById(itemId), isNotNull);
    });
  });
}