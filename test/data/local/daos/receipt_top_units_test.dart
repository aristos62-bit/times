/// Unit tests — `ReceiptDao.watchTopItemsByUnit` (§2.1 · 29-09-2026).
///
/// Μετρικές Top-10: SUM ποσότητας ανά είδος σε ΜΙΑ μονάδα (ποτέ ανάμειξη),
/// σειρά (qty DESC + name), όρια `[from, to)`, κενό → `[]`.
/// Πραγματική in-memory Drift βάση (μοτίβο Βημάτων 4/5).
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/item_group_dao.dart';
import 'package:times/data/local/daos/receipt_dao.dart';
import 'package:times/data/local/daos/receipt_line_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/supplier_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';

import '../helpers/in_memory_db.dart';

void main() {
  late dynamic db;
  late ReceiptDao dao;

  late int milkId;
  late int breadId;
  late int kiloId;
  late int pieceId;
  late int supplierId;
  late int groupId;

  Future<void> seedCatalog() async {
    kiloId = await UnitDao(db).insert(
      name: 'Κιλό',
      abbreviation: 'κιλ',
      allowsDecimal: true,
    );
    pieceId = await UnitDao(db).insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
    final categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    final subId = await SubCategoryDao(db)
        .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
    groupId =
        await ItemGroupDao(db).insert(subCategoryId: subId, name: 'Φρέσκα');
    milkId = await ItemDao(db).insert(
      itemGroupId: groupId,
      name: 'Γάλα',
      defaultUnitId: kiloId,
    );
    breadId = await ItemDao(db).insert(
      itemGroupId: groupId,
      name: 'Ψωμί',
      defaultUnitId: pieceId,
    );
    supplierId = await SupplierDao(db).insert(name: 'Μάρκος');
  }

  Future<void> seedLine({
    required DateTime date,
    required int itemId,
    required int unitId,
    required double quantity,
  }) async {
    final receiptId = await ReceiptDao(db).insert(
      date: date,
      supplierId: supplierId,
    );
    await ReceiptLineDao(db).insert(
      receiptId: receiptId,
      itemId: itemId,
      unitId: unitId,
      quantity: quantity,
      priceCents: 100,
    );
  }

  final from = DateTime(2026, 1, 1);
  final to = DateTime(2026, 2, 1);

  setUp(() async {
    db = inMemoryDb();
    dao = ReceiptDao(db);
    await seedCatalog();
  });

  tearDown(() async => await db.close());

  group('ReceiptDao.watchTopItemsByUnit (§2.1 · 29-09-2026)', () {
    test('SUM/μονάδα + σειρά qty DESC', () async {
      await seedLine(
        date: DateTime(2026, 1, 5),
        itemId: milkId,
        unitId: kiloId,
        quantity: 0.5,
      );
      await seedLine(
        date: DateTime(2026, 1, 6),
        itemId: milkId,
        unitId: kiloId,
        quantity: 1.5,
      );
      await seedLine(
        date: DateTime(2026, 1, 7),
        itemId: breadId,
        unitId: pieceId,
        quantity: 3,
      );
      final kilos = await dao
          .watchTopItemsByUnit(from: from, to: to, unitId: kiloId)
          .first;
      // Μόνο κιλά (το ψωμί δεν μπαίνει) · SUM 0,5+1,5 = 2.
      expect(kilos.single.itemName, 'Γάλα');
      expect(kilos.single.qty, closeTo(2.0, 0.0001));
      final pieces = await dao
          .watchTopItemsByUnit(from: from, to: to, unitId: pieceId)
          .first;
      expect(pieces.single.itemName, 'Ψωμί');
      expect(pieces.single.qty, 3);
    });

    test('ties → name ASC (ντετερμινιστικό)', () async {
      // Δύο είδη Κιλού με ίδια ποσότητα: «Γάλα» < «Γιαούρτι».
      final yogurtId = await ItemDao(db).insert(
        itemGroupId: groupId,
        name: 'Γιαούρτι',
        defaultUnitId: kiloId,
      );
      await seedLine(
        date: DateTime(2026, 1, 5),
        itemId: yogurtId,
        unitId: kiloId,
        quantity: 2,
      );
      await seedLine(
        date: DateTime(2026, 1, 5),
        itemId: milkId,
        unitId: kiloId,
        quantity: 2,
      );
      final kilos = await dao
          .watchTopItemsByUnit(from: from, to: to, unitId: kiloId)
          .first;
      expect(
        [for (final r in kilos) r.itemName],
        ['Γάλα', 'Γιαούρτι'],
      );
    });

    test('όρια [from, to) + κενό → []', () async {
      await seedLine(
        date: DateTime(2025, 12, 31),
        itemId: milkId,
        unitId: kiloId,
        quantity: 5,
      );
      await seedLine(
        date: DateTime(2026, 1, 5),
        itemId: milkId,
        unitId: kiloId,
        quantity: 1,
      );
      final rows = await dao
          .watchTopItemsByUnit(from: from, to: to, unitId: kiloId)
          .first;
      expect(rows.single.qty, 1);
      final empty = await dao
          .watchTopItemsByUnit(
            from: DateTime(2025, 1, 1),
            to: DateTime(2025, 2, 1),
            unitId: kiloId,
          )
          .first;
      expect(empty, isEmpty);
    });
  });
}
