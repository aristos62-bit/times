/// Unit tests για `ReceiptLineDao.countByItemId` (§2.3 · ενότητα Ειδών).
///
/// Πύλη διαγραφής είδους: `0` = καθαρό · `>0` = μπλοκαρισμένο. Typed drift
/// API (precedent `countBySupplierId`). In-memory βάση, real async.
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
  late ReceiptLineDao dao;

  late int itemId;
  late int unitId;
  late int supplierId;

  setUp(() async {
    db = inMemoryDb();
    dao = ReceiptLineDao(db);

    unitId = await UnitDao(db).insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
    final categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    final subId = await SubCategoryDao(db)
        .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
    itemId = await ItemDao(db).insert(subCategoryId: subId, name: 'Γάλα');
    supplierId = await SupplierDao(db).insert(name: 'Μάρκος');
  });

  tearDown(() async => await db.close());

  group('ReceiptLineDao.countByItemId', () {
    test('χωρίς γραμμές → 0 (καθαρό)', () async {
      expect(await dao.countByItemId(itemId), 0);
    });

    test('μετράει γραμμές του είδους (όχι άλλων)', () async {
      final receiptId = await ReceiptDao(db).insert(
        date: DateTime(2026, 1, 1),
        supplierId: supplierId,
      );
      await dao.insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 2,
        priceCents: 199,
      );
      await dao.insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 1,
        priceCents: 50,
      );

      expect(await dao.countByItemId(itemId), 2);
      expect(await dao.countByItemId(9999), 0);
    });
  });
}
