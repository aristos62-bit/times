/// Unit tests για τα totals passthrough του `ReceiptRepositoryImpl`
/// (§2.1 · Φάση 5 Βήμα 2) — τιμές από το DAO + stream mapping σε
/// `DataLoadException` (pattern `watchLines`).
///
/// Refactor 4 επιπέδων (27-09-2026): η πίτα υποκατηγορίας αντικαταστάθηκε
/// από πίτα Τμήματος — `watchTotalsByItemGroup` + `ItemGroupTotal`
/// (το `SubCategoryTotal` ΔΕΝ υπάρχει πια). Τα category totals ίδια.
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

/// DAO double — raw σφάλμα στα totals για δοκιμή stream mapping.
class _FailingTotalsReceiptDao extends ReceiptDao {
  _FailingTotalsReceiptDao(super.db);

  @override
  Stream<List<SupplierTotal>> watchTotalsBySupplier({
    required DateTime from,
    required DateTime to,
  }) =>
      Stream.error(SqliteException(extendedResultCode: 1, message: 'test'));

  @override
  Stream<List<CategoryTotal>> watchTotalsByCategory({
    required DateTime from,
    required DateTime to,
  }) =>
      Stream.error(SqliteException(extendedResultCode: 1, message: 'test'));

  @override
  Stream<List<ItemGroupTotal>> watchTotalsByItemGroup({
    required DateTime from,
    required DateTime to,
  }) =>
      Stream.error(SqliteException(extendedResultCode: 1, message: 'test'));

  @override
  Stream<List<ItemTotal>> watchTopItems({
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

  setUp(() async {
    db = inMemoryDb();
    repo = ReceiptRepositoryImpl(ReceiptDao(db), ReceiptLineDao(db));

    // Αλυσίδα 4 επιπέδων: unit → category → sub → group → item.
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

  final from = DateTime(2026, 1, 1);
  final to = DateTime(2026, 2, 1);

  group('ReceiptRepositoryImpl totals passthrough', () {
    test('watchTotalsBySupplier — τιμές DAO', () async {
      final receiptId =
          await repo.insert(date: DateTime(2026, 1, 5), supplierId: supplierId);
      await repo
          .watchLines(receiptId)
          .first; // warm-up stream (ίδιο idiom με watchLines tests)
      final lineDao = ReceiptLineDao(db);
      await lineDao.insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 2,
        priceCents: 199,
      );

      final rows =
          await repo.watchTotalsBySupplier(from: from, to: to).first;
      expect(rows.single.totalCents, 199 * 2);
      expect(rows.single.supplierName, 'Μάρκος');
    });

    test('watchTotalsByCategory — τιμές DAO (ίδια)', () async {
      final receiptId =
          await repo.insert(date: DateTime(2026, 1, 5), supplierId: supplierId);
      await ReceiptLineDao(db).insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 2,
        priceCents: 199,
      );

      final rows = await repo.watchTotalsByCategory(from: from, to: to).first;
      expect(rows.single.totalCents, 199 * 2);
      expect(rows.single.categoryName, 'ΤΡΟΦΙΜΑ');
    });

    test('watchTotalsByItemGroup — τιμές DAO (4 επίπεδα)', () async {
      final receiptId =
          await repo.insert(date: DateTime(2026, 1, 5), supplierId: supplierId);
      await ReceiptLineDao(db).insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 2,
        priceCents: 199,
      );

      final rows =
          await repo.watchTotalsByItemGroup(from: from, to: to).first;
      expect(rows.single.totalCents, 199 * 2);
      expect(rows.single.itemGroupName, 'Φέτα');
      expect(rows.single.itemGroupId, isNotNull);
    });

    test('watchTotalsByCategory/ItemGroup/TopItems — κενά', () async {
      expect(await repo.watchTotalsByCategory(from: from, to: to).first, isEmpty);
      expect(
        await repo.watchTotalsByItemGroup(from: from, to: to).first,
        isEmpty,
      );
      expect(await repo.watchTopItems(from: from, to: to).first, isEmpty);
    });

    test('raw stream σφάλμα → DataLoadException (×4)', () async {
      final failing =
          ReceiptRepositoryImpl(_FailingTotalsReceiptDao(db), ReceiptLineDao(db));
      await expectLater(
        failing.watchTotalsBySupplier(from: from, to: to),
        emitsError(isA<DataLoadException>()),
      );
      await expectLater(
        failing.watchTotalsByCategory(from: from, to: to),
        emitsError(isA<DataLoadException>()),
      );
      await expectLater(
        failing.watchTotalsByItemGroup(from: from, to: to),
        emitsError(isA<DataLoadException>()),
      );
      await expectLater(
        failing.watchTopItems(from: from, to: to),
        emitsError(isA<DataLoadException>()),
      );
    });
  });

  group('ReceiptRepositoryImpl.countLinesByItemId (§2.3 · πύλη είδους)', () {
    test('χωρίς γραμμές → 0 · με γραμμές → πλήθος', () async {
      expect(await repo.countLinesByItemId(itemId), 0);
      final receiptId = await repo.insert(
        date: DateTime(2026, 1, 1),
        supplierId: supplierId,
      );
      final lineDao = ReceiptLineDao(db);
      await lineDao.insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 1,
        priceCents: 100,
      );
      expect(await repo.countLinesByItemId(itemId), 1);
    });
  });
}
