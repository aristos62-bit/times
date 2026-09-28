/// Unit tests — `ReceiptLineDao.watchItemHistory` (§2.1 · 28-09-2026).
///
/// Ιστορικό γραμμών είδους σε περίοδο για το 6ο γράφημα «Πορεία τιμής»:
/// σειρά (ημερομηνία ASC, id ASC — backdated), όρια `[from, to)`, καθαρή
/// μοναδιαία (`price − discount`, Δ-stat §3), κενή περίοδος → `[]`.
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
  late ReceiptLineDao dao;

  late int itemId;
  late int kiloId;
  late int pieceId;
  late int supplierA;
  late int supplierB;

  /// Αλυσίδα 4 επιπέδων + 2 μονάδες + είδος (default Κιλό) + 2 προμηθευτές.
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
    final groupId =
        await ItemGroupDao(db).insert(subCategoryId: subId, name: 'Φρέσκα');
    itemId = await ItemDao(db).insert(
      itemGroupId: groupId,
      name: 'Γάλα',
      defaultUnitId: kiloId,
    );
    supplierA = await SupplierDao(db).insert(name: 'Μάρκος');
    supplierB = await SupplierDao(db).insert(name: 'Ερμής');
  }

  /// Γραμμή σε απόδειξη της [date] (ημερομηνία κεφαλίδας).
  Future<void> seedLine({
    required DateTime date,
    required int supplierId,
    required int unitId,
    double quantity = 2,
    int priceCents = 250,
    int discountCents = 50,
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
      discountCents: discountCents,
    );
  }

  setUp(() async {
    db = inMemoryDb();
    dao = ReceiptLineDao(db);
    await seedCatalog();
  });

  tearDown(() async => await db.close());

  group('ReceiptLineDao.watchItemHistory (§2.1 · 28-09-2026)', () {
    test('σειρά + καθαρή τιμή + πεδία (Δ-stat §3)', () async {
      await seedLine(
        date: DateTime(2026, 1, 5),
        supplierId: supplierA,
        unitId: kiloId,
      );
      await seedLine(
        date: DateTime(2026, 1, 20),
        supplierId: supplierB,
        unitId: kiloId,
        quantity: 1,
        priceCents: 300,
        discountCents: 0,
      );
      final rows = await dao
          .watchItemHistory(
            itemId: itemId,
            from: DateTime(2026, 1, 1),
            to: DateTime(2026, 2, 1),
          )
          .first;
      expect(rows, hasLength(2));
      // Καθαρή μοναδιαία: (250−50) · (300−0) — ποτέ σκέτο priceCents.
      expect(rows[0].netPriceCents, 200);
      expect(rows[1].netPriceCents, 300);
      expect(rows[0].date, DateTime(2026, 1, 5));
      expect(rows[0].quantity, 2);
      expect(rows[0].unitId, kiloId);
      expect(rows[0].supplierName, 'Μάρκος');
      expect(rows[1].supplierName, 'Ερμής');
    });

    test('όρια [from, to): εκτός → έξω', () async {
      await seedLine(
        date: DateTime(2025, 12, 31),
        supplierId: supplierA,
        unitId: kiloId,
      );
      await seedLine(
        date: DateTime(2026, 1, 1),
        supplierId: supplierA,
        unitId: kiloId,
      );
      await seedLine(
        date: DateTime(2026, 2, 1),
        supplierId: supplierA,
        unitId: kiloId,
      );
      final rows = await dao
          .watchItemHistory(
            itemId: itemId,
            from: DateTime(2026, 1, 1),
            to: DateTime(2026, 2, 1),
          )
          .first;
      expect(rows, hasLength(1));
      expect(rows.single.date, DateTime(2026, 1, 1));
    });

    test('backdated απόδειξη (παλιό date, νέο id) → πρώτη', () async {
      await seedLine(
        date: DateTime(2026, 1, 20),
        supplierId: supplierA,
        unitId: kiloId,
      );
      await seedLine(
        date: DateTime(2026, 1, 2),
        supplierId: supplierB,
        unitId: kiloId,
      );
      final rows = await dao
          .watchItemHistory(
            itemId: itemId,
            from: DateTime(2026, 1, 1),
            to: DateTime(2026, 2, 1),
          )
          .first;
      expect(rows, hasLength(2));
      // Σειρά από ημερομηνία (όχι id) — precedent `getLatestByItemId`.
      expect(rows[0].date, DateTime(2026, 1, 2));
      expect(rows[1].date, DateTime(2026, 1, 20));
    });

    test('επιστρέφει όλες τις μονάδες (το φίλτρο Q2 είναι του provider)',
        () async {
      await seedLine(
        date: DateTime(2026, 1, 5),
        supplierId: supplierA,
        unitId: kiloId,
      );
      await seedLine(
        date: DateTime(2026, 1, 6),
        supplierId: supplierA,
        unitId: pieceId,
      );
      final rows = await dao
          .watchItemHistory(
            itemId: itemId,
            from: DateTime(2026, 1, 1),
            to: DateTime(2026, 2, 1),
          )
          .first;
      expect(rows, hasLength(2));
      expect(rows[0].unitId, kiloId);
      expect(rows[1].unitId, pieceId);
    });

    test('κενή περίοδος → [] (όχι loading για πάντα)', () async {
      await seedLine(
        date: DateTime(2026, 1, 5),
        supplierId: supplierA,
        unitId: kiloId,
      );
      final rows = await dao
          .watchItemHistory(
            itemId: itemId,
            from: DateTime(2025, 1, 1),
            to: DateTime(2025, 2, 1),
          )
          .first;
      expect(rows, isEmpty);
    });

    test('νέο insert → νέα εκπομπή (auto-refresh save)', () async {
      await seedLine(
        date: DateTime(2026, 1, 5),
        supplierId: supplierA,
        unitId: kiloId,
      );
      final first = await dao
          .watchItemHistory(
            itemId: itemId,
            from: DateTime(2026, 1, 1),
            to: DateTime(2026, 2, 1),
          )
          .first;
      expect(first, hasLength(1));
      await seedLine(
        date: DateTime(2026, 1, 6),
        supplierId: supplierB,
        unitId: kiloId,
      );
      final second = await dao
          .watchItemHistory(
            itemId: itemId,
            from: DateTime(2026, 1, 1),
            to: DateTime(2026, 2, 1),
          )
          .first;
      expect(second, hasLength(2));
    });
  });
}
