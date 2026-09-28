/// Unit tests — `ReceiptLineDao.watchPeriodPurchases` (§2.3 · 29-09-2026).
///
/// 2η ανάλυση «Συνολικές αγορές»: 4 sorts + tiebreak, όρια `[from, to)`,
/// κατηγορία/μονάδα joins, κενή περίοδος → `[]`.
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
import 'package:times/data/models/chart_totals.dart';

import '../helpers/in_memory_db.dart';

void main() {
  late dynamic db;
  late ReceiptLineDao dao;

  late int milkId;
  late int breadId;
  late int kiloId;
  late int pieceId;
  late int markosId;
  late int ermisId;

  /// Κατάλογος: 2 κατηγορίες × είδη + 2 μονάδες + 2 προμηθευτές.
  Future<void> seedCatalog() async {
    kiloId = await UnitDao(db).insert(
      name: 'Κιλό',
      abbreviation: 'κιλ',
      allowsDecimal: true,
    );
    pieceId = await UnitDao(db).insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
    final foodId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    final dairyId = await SubCategoryDao(db)
        .insert(categoryId: foodId, name: 'Γαλακτοκομικά');
    final freshId =
        await ItemGroupDao(db).insert(subCategoryId: dairyId, name: 'Φρέσκα');
    milkId = await ItemDao(db).insert(
      itemGroupId: freshId,
      name: 'Γάλα',
      defaultUnitId: kiloId,
    );
    final bakeryId = await CategoryDao(db).insert(name: 'ΑΡΤΟΣΚΕΥΑΣΜΑΤΑ');
    final breadSubId = await SubCategoryDao(db)
        .insert(categoryId: bakeryId, name: 'Ψωμιά');
    final breadGroupId = await ItemGroupDao(db)
        .insert(subCategoryId: breadSubId, name: 'Φραντζόλες');
    breadId = await ItemDao(db).insert(
      itemGroupId: breadGroupId,
      name: 'Ψωμί',
      defaultUnitId: pieceId,
    );
    markosId = await SupplierDao(db).insert(name: 'Μάρκος');
    ermisId = await SupplierDao(db).insert(name: 'Ερμής');
  }

  Future<void> seedLine({
    required DateTime date,
    required int itemId,
    required int supplierId,
    required int unitId,
    double quantity = 1,
    int priceCents = 100,
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
      priceCents: priceCents,
    );
  }

  final from = DateTime(2026, 1, 1);
  final to = DateTime(2026, 2, 1);

  Future<List<PeriodPurchaseRow>> read(PurchasesSort sort) =>
      dao.watchPeriodPurchases(from: from, to: to, sort: sort).first;

  setUp(() async {
    db = inMemoryDb();
    dao = ReceiptLineDao(db);
    await seedCatalog();
  });

  tearDown(() async => await db.close());

  group('ReceiptLineDao.watchPeriodPurchases (§2.3 · 29-09-2026)', () {
    test('dateAsc: παλιές → νέες + πλήρη στοιχεία', () async {
      await seedLine(
        date: DateTime(2026, 1, 20),
        itemId: breadId,
        supplierId: ermisId,
        unitId: pieceId,
        quantity: 2,
      );
      await seedLine(
        date: DateTime(2026, 1, 5),
        itemId: milkId,
        supplierId: markosId,
        unitId: kiloId,
      );
      final rows = await read(PurchasesSort.dateAsc);
      expect(rows, hasLength(2));
      expect(rows[0].itemName, 'Γάλα');
      expect(rows[0].categoryName, 'ΤΡΟΦΙΜΑ');
      expect(rows[0].supplierName, 'Μάρκος');
      expect(rows[0].unitAbbreviation, 'κιλ');
      expect(rows[1].itemName, 'Ψωμί');
      expect(rows[1].categoryName, 'ΑΡΤΟΣΚΕΥΑΣΜΑΤΑ');
      expect(rows[1].quantity, 2);
    });

    test('dateDesc: νέες → παλιές', () async {
      await seedLine(
        date: DateTime(2026, 1, 5),
        itemId: milkId,
        supplierId: markosId,
        unitId: kiloId,
      );
      await seedLine(
        date: DateTime(2026, 1, 20),
        itemId: breadId,
        supplierId: ermisId,
        unitId: pieceId,
      );
      final rows = await read(PurchasesSort.dateDesc);
      expect(rows[0].date, DateTime(2026, 1, 20));
      expect(rows[1].date, DateTime(2026, 1, 5));
    });

    test('supplier: αλφαβητικά + tiebreak ημερομηνίας', () async {
      await seedLine(
        date: DateTime(2026, 1, 10),
        itemId: milkId,
        supplierId: markosId,
        unitId: kiloId,
      );
      await seedLine(
        date: DateTime(2026, 1, 5),
        itemId: breadId,
        supplierId: ermisId,
        unitId: pieceId,
      );
      await seedLine(
        date: DateTime(2026, 1, 3),
        itemId: milkId,
        supplierId: ermisId,
        unitId: kiloId,
      );
      final rows = await read(PurchasesSort.supplier);
      expect(
        [for (final r in rows) r.supplierName],
        ['Ερμής', 'Ερμής', 'Μάρκος'],
      );
      // Tiebreak: 03 πριν 05 στον ίδιο προμηθευτή.
      expect(rows[0].date, DateTime(2026, 1, 3));
      expect(rows[1].date, DateTime(2026, 1, 5));
    });

    test('category: αλφαβητικά', () async {
      await seedLine(
        date: DateTime(2026, 1, 5),
        itemId: milkId,
        supplierId: markosId,
        unitId: kiloId,
      );
      await seedLine(
        date: DateTime(2026, 1, 6),
        itemId: breadId,
        supplierId: markosId,
        unitId: pieceId,
      );
      final rows = await read(PurchasesSort.category);
      expect(
        [for (final r in rows) r.categoryName],
        ['ΑΡΤΟΣΚΕΥΑΣΜΑΤΑ', 'ΤΡΟΦΙΜΑ'],
      );
    });

    test('όρια [from, to) + κενή περίοδος → []', () async {
      await seedLine(
        date: DateTime(2025, 12, 31),
        itemId: milkId,
        supplierId: markosId,
        unitId: kiloId,
      );
      await seedLine(
        date: DateTime(2026, 1, 15),
        itemId: milkId,
        supplierId: markosId,
        unitId: kiloId,
      );
      final rows = await read(PurchasesSort.dateAsc);
      expect(rows, hasLength(1));
      final empty = await dao
          .watchPeriodPurchases(
            from: DateTime(2025, 1, 1),
            to: DateTime(2025, 2, 1),
            sort: PurchasesSort.dateAsc,
          )
          .first;
      expect(empty, isEmpty);
    });
  });
}
