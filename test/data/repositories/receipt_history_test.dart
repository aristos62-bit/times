/// Unit tests για το history passthrough του `ReceiptRepositoryImpl`
/// (§2.1 · 28-09-2026 — 6ο γράφημα «Πορεία τιμής»): τιμές από το DAO +
/// stream mapping σε `DataLoadException` (pattern totals Βήματος 2).
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/item_group_dao.dart';
import 'package:times/data/local/daos/receipt_dao.dart';
import 'package:times/data/local/daos/receipt_line_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/supplier_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/models/chart_totals.dart';
import 'package:times/data/repositories/receipt_repository_impl.dart';

import '../local/helpers/in_memory_db.dart';

/// DAO double — raw σφάλμα στο history για δοκιμή stream mapping.
class _FailingHistoryLineDao extends ReceiptLineDao {
  _FailingHistoryLineDao(super.db);

  @override
  Stream<List<ItemPricePoint>> watchItemHistory({
    required int itemId,
    required DateTime from,
    required DateTime to,
  }) =>
      Stream.error(SqliteException(extendedResultCode: 1, message: 'test'));
}

void main() {
  late dynamic db;
  late ReceiptRepositoryImpl repo;

  late int itemId;
  late int unitId;
  late int supplierId;

  final from = DateTime(2026, 1, 1);
  final to = DateTime(2026, 2, 1);

  setUp(() async {
    db = inMemoryDb();
    repo = ReceiptRepositoryImpl(ReceiptDao(db), ReceiptLineDao(db));

    unitId = await UnitDao(db).insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
    final categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    final subId = await SubCategoryDao(db)
        .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
    final groupId =
        await ItemGroupDao(db).insert(subCategoryId: subId, name: 'Φέτα');
    itemId = await ItemDao(db).insert(itemGroupId: groupId, name: 'Γάλα');
    supplierId = await SupplierDao(db).insert(name: 'Μάρκος');
  });

  tearDown(() async => await db.close());

  group('ReceiptRepositoryImpl.watchItemHistory (§2.1 · 28-09-2026)', () {
    test('passthrough: καθαρή τιμή + σειρά', () async {
      final receiptId = await ReceiptDao(db).insert(
        date: DateTime(2026, 1, 5),
        supplierId: supplierId,
      );
      await ReceiptLineDao(db).insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 2,
        priceCents: 250,
        discountCents: 50,
      );
      final rows =
          await repo.watchItemHistory(itemId: itemId, from: from, to: to).first;
      expect(rows.single.netPriceCents, 200);
      expect(rows.single.supplierName, 'Μάρκος');
      expect(rows.single.unitId, unitId);
    });

    test('κενή περίοδος → []', () async {
      expect(
        await repo.watchItemHistory(itemId: itemId, from: from, to: to).first,
        isEmpty,
      );
    });

    test('raw stream σφάλμα → DataLoadException', () async {
      final failing =
          ReceiptRepositoryImpl(ReceiptDao(db), _FailingHistoryLineDao(db));
      await expectLater(
        failing.watchItemHistory(itemId: itemId, from: from, to: to),
        emitsError(isA<DataLoadException>()),
      );
    });
  });
}
