/// Unit tests για το units passthrough του `ReceiptRepositoryImpl`
/// (§2.1 · 29-09-2026 — μετρικές): τιμές από το DAO + stream mapping σε
/// `DataLoadException` (pattern totals).
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

/// DAO double — raw σφάλμα στα units για δοκιμή stream mapping.
class _FailingUnitsReceiptDao extends ReceiptDao {
  _FailingUnitsReceiptDao(super.db);

  @override
  Stream<List<ItemQtyTotal>> watchTopItemsByUnit({
    required DateTime from,
    required DateTime to,
    required int unitId,
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

    unitId = await UnitDao(db).insert(
      name: 'Κιλό',
      abbreviation: 'κιλ',
      allowsDecimal: true,
    );
    final categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    final subId = await SubCategoryDao(db)
        .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
    final groupId =
        await ItemGroupDao(db).insert(subCategoryId: subId, name: 'Φρέσκα');
    itemId = await ItemDao(db).insert(itemGroupId: groupId, name: 'Γάλα');
    supplierId = await SupplierDao(db).insert(name: 'Μάρκος');
  });

  tearDown(() async => await db.close());

  group('ReceiptRepositoryImpl.watchTopItemsByUnit (§2.1 · 29-09-2026)', () {
    test('passthrough: άθροισμα ποσότητας', () async {
      final receiptId = await ReceiptDao(db).insert(
        date: DateTime(2026, 1, 5),
        supplierId: supplierId,
      );
      await ReceiptLineDao(db).insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 0.5,
        priceCents: 100,
      );
      final rows = await repo
          .watchTopItemsByUnit(from: from, to: to, unitId: unitId)
          .first;
      expect(rows.single.itemName, 'Γάλα');
      expect(rows.single.qty, closeTo(0.5, 0.0001));
    });

    test('κενό → []', () async {
      expect(
        await repo
            .watchTopItemsByUnit(from: from, to: to, unitId: unitId)
            .first,
        isEmpty,
      );
    });

    test('raw stream σφάλμα → DataLoadException', () async {
      final repoWithFailingDao = ReceiptRepositoryImpl(
        _FailingUnitsReceiptDao(db),
        ReceiptLineDao(db),
      );
      await expectLater(
        repoWithFailingDao.watchTopItemsByUnit(
          from: from,
          to: to,
          unitId: unitId,
        ),
        emitsError(isA<DataLoadException>()),
      );
    });
  });
}
