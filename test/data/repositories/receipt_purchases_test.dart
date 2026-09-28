/// Unit tests για το purchases passthrough του `ReceiptRepositoryImpl`
/// (§2.3 · 29-09-2026 — 2η ανάλυση): τιμές από το DAO + stream mapping σε
/// `DataLoadException` (pattern ledger/history).
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

/// DAO double — raw σφάλμα στο purchases για δοκιμή stream mapping.
class _FailingPurchasesLineDao extends ReceiptLineDao {
  _FailingPurchasesLineDao(super.db);

  @override
  Stream<List<PeriodPurchaseRow>> watchPeriodPurchases({
    required DateTime from,
    required DateTime to,
    required PurchasesSort sort,
    int? categoryId,
    int? subCategoryId,
    int? itemGroupId,
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

  group('ReceiptRepositoryImpl.watchPeriodPurchases (§2.3 · 29-09-2026)', () {
    test('passthrough: κατηγορία + σειρά sort', () async {
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
      final rows = await repo
          .watchPeriodPurchases(
            from: from,
            to: to,
            sort: PurchasesSort.dateAsc,
          )
          .first;
      expect(rows.single.itemName, 'Γάλα');
      expect(rows.single.categoryName, 'ΤΡΟΦΙΜΑ');
      expect(rows.single.receiptId, receiptId);
    });

    test('κενή περίοδος → []', () async {
      expect(
        await repo
            .watchPeriodPurchases(
              from: from,
              to: to,
              sort: PurchasesSort.supplier,
            )
            .first,
        isEmpty,
      );
    });

    test('raw stream σφάλμα → DataLoadException', () async {
      final failing =
          ReceiptRepositoryImpl(ReceiptDao(db), _FailingPurchasesLineDao(db));
      await expectLater(
        failing.watchPeriodPurchases(
          from: from,
          to: to,
          sort: PurchasesSort.category,
        ),
        emitsError(isA<DataLoadException>()),
      );
    });
  });
}
