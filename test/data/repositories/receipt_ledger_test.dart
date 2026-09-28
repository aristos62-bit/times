/// Unit tests για το ledger passthrough του `ReceiptRepositoryImpl`
/// (§2.3 · 28-09-2026 — 1η στατιστική ανάλυση): τιμές από το DAO + stream
/// mapping σε `DataLoadException` (pattern totals/history).
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

/// DAO double — raw σφάλμα στο ledger για δοκιμή stream mapping.
class _FailingLedgerLineDao extends ReceiptLineDao {
  _FailingLedgerLineDao(super.db);

  @override
  Stream<List<ItemLedgerRow>> watchItemLedger({
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

  group('ReceiptRepositoryImpl.watchItemLedger (§2.3 · 28-09-2026)', () {
    test('passthrough: πλήρη στοιχεία γραμμής', () async {
      final receiptId = await ReceiptDao(db).insert(
        date: DateTime(2026, 1, 5),
        supplierId: supplierId,
      );
      await ReceiptLineDao(db).insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 0.456,
        priceCents: 1296,
        discountCents: 35,
      );
      final rows =
          await repo.watchItemLedger(itemId: itemId, from: from, to: to).first;
      expect(rows.single.receiptId, receiptId);
      expect(rows.single.supplierName, 'Μάρκος');
      expect(rows.single.quantity, 0.456);
      expect(rows.single.unitAbbreviation, 'κιλ');
      expect(rows.single.priceCents, 1296);
      expect(rows.single.discountCents, 35);
    });

    test('κενή περίοδος → []', () async {
      expect(
        await repo.watchItemLedger(itemId: itemId, from: from, to: to).first,
        isEmpty,
      );
    });

    test('raw stream σφάλμα → DataLoadException', () async {
      final failing =
          ReceiptRepositoryImpl(ReceiptDao(db), _FailingLedgerLineDao(db));
      await expectLater(
        failing.watchItemLedger(itemId: itemId, from: from, to: to),
        emitsError(isA<DataLoadException>()),
      );
    });
  });
}
