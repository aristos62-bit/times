/// Unit tests για `ReceiptRepositoryImpl.updateReceiptWithLines`
/// (Φάση Α · 24-09-2026) — update κεφαλίδας + αντικατάσταση γραμμών
/// σε ΜΙΑ transaction (atomicity §3).
///
/// Contract (§2.2): επιτυχία → κεφαλίδα + γραμμές ενημερωμένες (τα line-ids
/// αλλάζουν — αποδεκτό, SUM §3)· ανύπαρκτο id → `DataLoadException`·
/// FK-violation → `SaveReceiptException` + rollback (οι παλιές γραμμές
/// μένουν άθικτες). Το `lineTotalCents` το υπολογίζει ο ReceiptLineDao
/// (SPoT §3).
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/receipt_dao.dart';
import 'package:times/data/local/daos/receipt_line_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/supplier_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/repositories/receipt_repository_impl.dart';

import '../local/helpers/in_memory_db.dart';

void main() {
  late dynamic db;
  late ReceiptRepositoryImpl repo;
  late ReceiptLineDao lineDao;

  late int itemId;
  late int secondItemId;
  late int unitId;
  late int supplierId;
  late int secondSupplierId;

  setUp(() async {
    db = inMemoryDb();
    repo = ReceiptRepositoryImpl(ReceiptDao(db), ReceiptLineDao(db));
    lineDao = ReceiptLineDao(db);

    unitId = await UnitDao(db).insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
    final categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    final subId =
        await SubCategoryDao(db).insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
    itemId = await ItemDao(db).insert(subCategoryId: subId, name: 'Γάλα');
    secondItemId = await ItemDao(db).insert(subCategoryId: subId, name: 'Τυρί');
    supplierId = await SupplierDao(db).insert(name: 'Μάρκος');
    secondSupplierId = await SupplierDao(db).insert(name: 'Προμηθευτής Β');
  });

  tearDown(() async => await db.close());

  group('ReceiptRepositoryImpl.updateReceiptWithLines (Φάση Α)', () {
    test('επιτυχία: κεφαλίδα + αντικατάσταση γραμμών (όχι προσθήκη)', () async {
      final id = await repo.insertReceiptWithLines(
        date: DateTime(2026, 1, 1),
        supplierId: supplierId,
        lines: [
          (itemId: itemId, unitId: unitId, quantity: 2, priceCents: 199),
        ],
      );

      await repo.updateReceiptWithLines(
        id: id,
        date: DateTime(2026, 2, 5),
        supplierId: secondSupplierId,
        lines: [
          (itemId: secondItemId, unitId: unitId, quantity: 1, priceCents: 300),
          (itemId: itemId, unitId: unitId, quantity: 3, priceCents: 50),
        ],
      );

      final header = await repo.getById(id);
      expect(header, isNotNull);
      expect(header!.date, DateTime(2026, 2, 5));
      expect(header.supplierId, secondSupplierId);
      final lines = await repo.watchLines(id).first;
      expect(lines.length, 2, reason: 'αντικατάσταση — όχι 1+2=3');
      // SPoT §3: (300*1).round()=300 · (50*3).round()=150.
      expect(lines[0].lineTotalCents, 300);
      expect(lines[1].lineTotalCents, 150);
    });

    test('κενές γραμμές → κεφαλίδα ενημερωμένη, γραμμές σβησμένες', () async {
      final id = await repo.insertReceiptWithLines(
        date: DateTime(2026, 1, 1),
        supplierId: supplierId,
        lines: [
          (itemId: itemId, unitId: unitId, quantity: 2, priceCents: 199),
        ],
      );

      await repo.updateReceiptWithLines(
        id: id,
        date: DateTime(2026, 3, 1),
        supplierId: supplierId,
        lines: const [],
      );

      expect((await repo.getById(id))!.date, DateTime(2026, 3, 1));
      expect(await repo.watchLines(id).first, isEmpty);
    });

    test('ανύπαρκτο id → DataLoadException, τίποτα δεν αλλάζει', () async {
      final id = await repo.insertReceiptWithLines(
        date: DateTime(2026, 1, 1),
        supplierId: supplierId,
        lines: [
          (itemId: itemId, unitId: unitId, quantity: 1, priceCents: 100),
        ],
      );

      await expectLater(
        repo.updateReceiptWithLines(
          id: 9999,
          date: DateTime(2026, 2, 1),
          supplierId: supplierId,
          lines: const [],
        ),
        throwsA(isA<DataLoadException>()),
      );
      // Η υπάρχουσα απόδειξη άθικτη.
      expect((await repo.getById(id))!.date, DateTime(2026, 1, 1));
      expect((await repo.watchLines(id).first).length, 1);
    });

    test('FK σε γραμμή: ανύπαρκτο item → SaveReceiptException + rollback',
        () async {
      final id = await repo.insertReceiptWithLines(
        date: DateTime(2026, 1, 1),
        supplierId: supplierId,
        lines: [
          (itemId: itemId, unitId: unitId, quantity: 2, priceCents: 199),
        ],
      );

      await expectLater(
        repo.updateReceiptWithLines(
          id: id,
          date: DateTime(2026, 2, 1),
          supplierId: supplierId,
          lines: [
            (itemId: 9999, unitId: unitId, quantity: 1, priceCents: 100),
          ],
        ),
        throwsA(isA<SaveReceiptException>()),
      );

      // Rollback: κεφαλίδα + παλιές γραμμές άθικτες.
      expect((await repo.getById(id))!.date, DateTime(2026, 1, 1));
      final lines = await lineDao.watchByReceiptId(id).first;
      expect(lines.length, 1);
      expect(lines.single.lineTotalCents, 398);
    });

    test('FK σε κεφαλίδα: ανύπαρκτος supplier → SaveReceiptException + rollback',
        () async {
      final id = await repo.insertReceiptWithLines(
        date: DateTime(2026, 1, 1),
        supplierId: supplierId,
        lines: [
          (itemId: itemId, unitId: unitId, quantity: 1, priceCents: 100),
        ],
      );

      await expectLater(
        repo.updateReceiptWithLines(
          id: id,
          date: DateTime(2026, 2, 1),
          supplierId: 9999,
          lines: const [],
        ),
        throwsA(isA<SaveReceiptException>()),
      );

      expect((await repo.getById(id))!.date, DateTime(2026, 1, 1));
      expect((await repo.watchLines(id).first).length, 1);
    });
  });

  group('ReceiptRepositoryImpl.getLines (Φάση Α)', () {
    test('one-shot: ίδιες γραμμές με το watch, σειρά εισαγωγής', () async {
      final id = await repo.insertReceiptWithLines(
        date: DateTime(2026, 1, 1),
        supplierId: supplierId,
        lines: [
          (itemId: itemId, unitId: unitId, quantity: 2, priceCents: 199),
          (itemId: secondItemId, unitId: unitId, quantity: 1, priceCents: 50),
        ],
      );

      final rows = await repo.getLines(id);
      expect(rows.length, 2);
      expect(rows.first.itemId, itemId);
      expect(rows[0].lineTotalCents, 398);
    });

    test('χωρίς γραμμές → []', () async {
      final id = await repo.insert(
        date: DateTime(2026, 1, 1),
        supplierId: supplierId,
      );
      expect(await repo.getLines(id), isEmpty);
    });
  });
}
