/// Unit tests — `ReceiptLineDao.watchItemLedger` (§2.3 · 28-09-2026).
///
/// Καρτέλα είδους (1η στατιστική ανάλυση): σειρά (ημερομηνία ASC, id ASC),
/// όρια `[from, to)`, πλήρη στοιχεία (τιμή/έκπτωση χωριστά, συντομογραφία,
/// αριθμός απόδειξης), κενή περίοδος → `[]`.
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
  late int supplierId;

  /// Αλυσίδα 4 επιπέδων + Κιλό + είδος + προμηθευτής.
  Future<void> seedCatalog() async {
    kiloId = await UnitDao(db).insert(
      name: 'Κιλό',
      abbreviation: 'κιλ',
      allowsDecimal: true,
    );
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
    supplierId = await SupplierDao(db).insert(name: 'Μάρκος');
  }

  /// Γραμμή σε απόδειξη της [date].
  Future<void> seedLine({
    required DateTime date,
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
      unitId: kiloId,
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

  group('ReceiptLineDao.watchItemLedger (§2.3 · 28-09-2026)', () {
    test('πλήρη στοιχεία + σειρά (τιμή/έκπτωση χωριστά)', () async {
      await seedLine(date: DateTime(2026, 1, 20), quantity: 1);
      await seedLine(date: DateTime(2026, 1, 5));
      final rows = await dao
          .watchItemLedger(
            itemId: itemId,
            from: DateTime(2026, 1, 1),
            to: DateTime(2026, 2, 1),
          )
          .first;
      expect(rows, hasLength(2));
      // Σειρά ημερομηνίας (όχι εισαγωγής).
      expect(rows[0].date, DateTime(2026, 1, 5));
      expect(rows[1].date, DateTime(2026, 1, 20));
      // Αριθμός απόδειξης = id κεφαλίδας (§3).
      expect(rows[0].receiptId, greaterThan(0));
      expect(rows[0].supplierName, 'Μάρκος');
      expect(rows[0].quantity, 2);
      expect(rows[0].unitAbbreviation, 'κιλ');
      // Stored τιμές §3 (η καθαρή παράγεται στην προβολή, Δ-stat).
      expect(rows[0].priceCents, 250);
      expect(rows[0].discountCents, 50);
    });

    test('όρια [from, to): εκτός → έξω', () async {
      await seedLine(date: DateTime(2025, 12, 31));
      await seedLine(date: DateTime(2026, 1, 15));
      await seedLine(date: DateTime(2026, 2, 1));
      final rows = await dao
          .watchItemLedger(
            itemId: itemId,
            from: DateTime(2026, 1, 1),
            to: DateTime(2026, 2, 1),
          )
          .first;
      expect(rows, hasLength(1));
      expect(rows.single.date, DateTime(2026, 1, 15));
    });

    test('κενή περίοδος → [] (όχι loading για πάντα)', () async {
      await seedLine(date: DateTime(2026, 1, 5));
      final rows = await dao
          .watchItemLedger(
            itemId: itemId,
            from: DateTime(2025, 1, 1),
            to: DateTime(2025, 2, 1),
          )
          .first;
      expect(rows, isEmpty);
    });

    test('νέο insert → νέα εκπομπή (auto-refresh save)', () async {
      await seedLine(date: DateTime(2026, 1, 5));
      final first = await dao
          .watchItemLedger(
            itemId: itemId,
            from: DateTime(2026, 1, 1),
            to: DateTime(2026, 2, 1),
          )
          .first;
      expect(first, hasLength(1));
      await seedLine(date: DateTime(2026, 1, 6));
      final second = await dao
          .watchItemLedger(
            itemId: itemId,
            from: DateTime(2026, 1, 1),
            to: DateTime(2026, 2, 1),
          )
          .first;
      expect(second, hasLength(2));
    });
  });
}
