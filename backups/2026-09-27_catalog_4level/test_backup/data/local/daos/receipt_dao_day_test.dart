/// Unit tests για `ReceiptDao.watchSummariesByDay` (§2.3 · Φάση Β).
///
/// Day-filter με σύνοψη (ίδιο SQL aggregation με `watchRecentSummaries` +
/// `WHERE` ημέρας): όρια `dayStart <= date < +1 ημέρα` (dateOnly, καλύπτουν
/// time-parts) · σειρά date desc, id desc · limit · κενή ημέρα → [].
/// In-memory βάση (Βήμα 3, §4.1) — ΚΑΝΕΝΑ widget (real async, όχι FakeAsync).
library;

import 'package:flutter_test/flutter_test.dart';

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
  late ReceiptDao dao;
  late ReceiptLineDao lineDao;

  late int itemId;
  late int unitId;
  late int supplierId;

  setUp(() async {
    db = inMemoryDb();
    dao = ReceiptDao(db);
    lineDao = ReceiptLineDao(db);

    unitId = await UnitDao(db).insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
    final categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    final subId = await SubCategoryDao(db)
        .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
    itemId = await ItemDao(db).insert(subCategoryId: subId, name: 'Γάλα');
    supplierId = await SupplierDao(db).insert(name: 'Μάρκος');
  });

  tearDown(() async => await db.close());

  /// Απόδειξη 1 γραμμής σε [date].
  Future<int> seedReceipt(DateTime date) async {
    final id = await dao.insert(date: date, supplierId: supplierId);
    await lineDao.insert(
      receiptId: id,
      itemId: itemId,
      unitId: unitId,
      quantity: 2,
      priceCents: 199,
    );
    return id;
  }

  group('ReceiptDao.watchSummariesByDay (Φάση Β)', () {
    test('επιστρέφει ΜΟΝΟ της ημέρας (γείτονες εκτός)', () async {
      final inDay = await seedReceipt(DateTime(2026, 3, 10));
      await seedReceipt(DateTime(2026, 3, 9));
      await seedReceipt(DateTime(2026, 3, 11));

      final rows = await dao
          .watchSummariesByDay(day: DateTime(2026, 3, 10), limit: 100)
          .first;

      expect(rows.map((r) => r.id), [inDay]);
      expect(rows.single.supplierName, 'Μάρκος');
      expect(rows.single.lineCount, 1);
      expect(rows.single.totalCents, 398);
    });

    test('time-parts: 23:59 μέσα · 00:00 επομένης εκτός', () async {
      final late = await seedReceipt(DateTime(2026, 3, 10, 23, 59));
      await seedReceipt(DateTime(2026, 3, 11, 0, 0));

      final rows = await dao
          .watchSummariesByDay(day: DateTime(2026, 3, 10, 12, 30), limit: 100)
          .first;

      expect(
        rows.map((r) => r.id),
        [late],
        reason: 'τα όρια υπολογίζονται dateOnly (query με time-part δουλεύει)',
      );
    });

    test('σειρά: date desc — ίδια ημέρα: id desc', () async {
      final first = await seedReceipt(DateTime(2026, 3, 10));
      final second = await seedReceipt(DateTime(2026, 3, 10));

      final rows = await dao
          .watchSummariesByDay(day: DateTime(2026, 3, 10), limit: 100)
          .first;

      expect(rows.map((r) => r.id), [second, first]);
    });

    test('limit: κόβει στα Ν νεότερα', () async {
      await seedReceipt(DateTime(2026, 3, 10));
      await seedReceipt(DateTime(2026, 3, 10));
      await seedReceipt(DateTime(2026, 3, 10));

      final rows = await dao
          .watchSummariesByDay(day: DateTime(2026, 3, 10), limit: 2)
          .first;

      expect(rows.length, 2);
    });

    test('κενή ημέρα → []', () async {
      await seedReceipt(DateTime(2026, 3, 10));

      final rows = await dao
          .watchSummariesByDay(day: DateTime(2026, 5, 5), limit: 100)
          .first;

      expect(rows, isEmpty);
    });

    test('απόδειξη χωρίς γραμμές → 0/0 (δεν χάνεται)', () async {
      final id = await dao.insert(
        date: DateTime(2026, 3, 10),
        supplierId: supplierId,
      );

      final rows = await dao
          .watchSummariesByDay(day: DateTime(2026, 3, 10), limit: 100)
          .first;

      expect(rows.map((r) => r.id), [id]);
      expect(rows.single.lineCount, 0);
      expect(rows.single.totalCents, 0);
    });
  });
}
