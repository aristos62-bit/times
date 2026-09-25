/// Unit tests για το `ReceiptRepositoryImpl` (Φάση 2, Βήμα 2) — CRUD,
/// γραμμές, και `insertReceiptWithLines` (transaction + rollback).
///
/// Transaction contract (§3 atomicity): κεφαλίδα + γραμμές σε ΜΙΑ
/// transaction· αποτυχία (FK) → `SaveReceiptException` ΚΑΙ rollback
/// (η απόδειξη δεν μένει μισο-αποθηκευμένη). Το lineTotalCents το
/// υπολογίζει ο ReceiptLineDao (SPoT §3).
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/receipt_dao.dart';
import 'package:times/data/local/daos/receipt_line_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/supplier_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/models/receipt_summary.dart';
import 'package:times/data/repositories/receipt_repository_impl.dart';

import '../local/helpers/in_memory_db.dart';

/// DAO double — raw σφάλμα στο watchByReceiptId για δοκιμή stream mapping.
class _FailingStreamReceiptLineDao extends ReceiptLineDao {
  _FailingStreamReceiptLineDao(super.db);

  @override
  Stream<List<ReceiptLine>> watchByReceiptId(int receiptId) =>
      Stream.error(SqliteException(extendedResultCode: 1, message: 'test'));
}

/// DAO double — raw σφάλμα στο watchRecentSummaries για δοκιμή stream mapping.
class _FailingStreamReceiptDao extends ReceiptDao {
  _FailingStreamReceiptDao(super.db);

  @override
  Stream<List<ReceiptSummary>> watchRecentSummaries({required int limit}) =>
      Stream.error(SqliteException(extendedResultCode: 1, message: 'test'));
}

void main() {
  late dynamic db;
  late ReceiptRepositoryImpl repo;
  late CategoryDao categoryDao;
  late SubCategoryDao subDao;
  late ItemDao itemDao;
  late UnitDao unitDao;
  late SupplierDao supplierDao;
  late ReceiptLineDao lineDao;

  late int itemId;
  late int secondItemId;
  late int unitId;
  late int supplierId;

  setUp(() async {
    db = inMemoryDb();
    repo = ReceiptRepositoryImpl(ReceiptDao(db), ReceiptLineDao(db));
    categoryDao = CategoryDao(db);
    subDao = SubCategoryDao(db);
    itemDao = ItemDao(db);
    unitDao = UnitDao(db);
    supplierDao = SupplierDao(db);
    lineDao = ReceiptLineDao(db);

    // Πλήρης αλυσίδα seed: unit → category → subcategory → items → supplier.
    unitId = await unitDao.insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
    final categoryId = await categoryDao.insert(name: 'ΤΡΟΦΙΜΑ');
    final subId =
        await subDao.insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
    itemId = await itemDao.insert(subCategoryId: subId, name: 'Γάλα');
    secondItemId = await itemDao.insert(subCategoryId: subId, name: 'Τυρί');
    supplierId = await supplierDao.insert(name: 'Μάρκος');
  });

  tearDown(() async => await db.close());

  group('ReceiptRepositoryImpl.insert/getById/updateById', () {
    test('insert + getById (αριθμός απόδειξης = id)', () async {
      final id =
          await repo.insert(date: DateTime(2026, 1, 1), supplierId: supplierId);

      final row = await repo.getById(id);
      expect(row, isNotNull);
      expect(row!.supplierId, supplierId);
      expect(row.date, DateTime(2026, 1, 1));
    });

    test('getById ανύπαρκτο id → null', () async {
      expect(await repo.getById(999), isNull);
    });

    test('updateById αλλάζει date/supplierId', () async {
      final id =
          await repo.insert(date: DateTime(2026, 1, 1), supplierId: supplierId);
      expect(
        await repo.updateById(id, date: DateTime(2026, 2, 1)),
        isTrue,
      );
      final row = await repo.getById(id);
      expect(row!.date, DateTime(2026, 2, 1));
    });
  });

  group('ReceiptRepositoryImpl.watchAll', () {
    test('ordering: date desc, id desc', () async {
      await repo.insert(date: DateTime(2026, 1, 1), supplierId: supplierId);
      final mid = await repo.insert(date: DateTime(2026, 2, 1), supplierId: supplierId);
      final last = await repo.insert(date: DateTime(2026, 3, 1), supplierId: supplierId);

      final rows = await repo.watchAll().first;
      expect(rows.map((r) => r.id), [last, mid, mid - 1]);
    });
  });

  group('ReceiptRepositoryImpl.deleteById (CASCADE)', () {
    test('διαγράφει κεφαλίδα + γραμμές', () async {
      final receiptId = await repo.insertReceiptWithLines(
        date: DateTime(2026, 1, 1),
        supplierId: supplierId,
        lines: [
          (itemId: itemId, unitId: unitId, quantity: 2, priceCents: 199, discountCents: 0),
        ],
      );

      expect(await repo.deleteById(receiptId), isTrue);
      expect(await repo.getById(receiptId), isNull);
      // CASCADE §3: οι γραμμές σβήστηκαν μαζί.
      expect(await lineDao.watchByReceiptId(receiptId).first, isEmpty);
    });
  });

  group('ReceiptRepositoryImpl.watchLines', () {
    test('επιστρέφει τις γραμμές με σειρά εισαγωγής (id)', () async {
      final receiptId = await repo.insertReceiptWithLines(
        date: DateTime(2026, 1, 1),
        supplierId: supplierId,
        lines: [
          (itemId: itemId, unitId: unitId, quantity: 1, priceCents: 100, discountCents: 0),
          (itemId: secondItemId, unitId: unitId, quantity: 3, priceCents: 50, discountCents: 0),
        ],
      );

      final rows = await repo.watchLines(receiptId).first;
      expect(rows.length, 2);
      expect(rows.first.itemId, itemId);
    });

    test('χωρίς γραμμές → []', () async {
      await repo.insert(date: DateTime(2026, 1, 1), supplierId: supplierId);
      final receiptId =
          await repo.insert(date: DateTime(2026, 2, 1), supplierId: supplierId);
      expect(await repo.watchLines(receiptId).first, isEmpty);
    });

    test('raw stream σφάλμα → DataLoadException (stream mapping)', () async {
      final failing = ReceiptRepositoryImpl(
        ReceiptDao(db),
        _FailingStreamReceiptLineDao(db),
      );
      await expectLater(
        failing.watchLines(1),
        emitsError(isA<DataLoadException>()),
      );
    });
  });

  group('ReceiptRepositoryImpl.insertReceiptWithLines', () {
    test('επιτυχία: κεφαλίδα + γραμμές (lineTotalCents SPoT §3)', () async {
      final id = await repo.insertReceiptWithLines(
        date: DateTime(2026, 1, 1),
        supplierId: supplierId,
        lines: [
          (itemId: itemId, unitId: unitId, quantity: 2.5, priceCents: 199, discountCents: 0),
          (itemId: secondItemId, unitId: unitId, quantity: 1, priceCents: 300, discountCents: 0),
        ],
      );

      expect(await repo.getById(id), isNotNull);
      final lines = await repo.watchLines(id).first;
      expect(lines.length, 2);
      // (199 * 2.5).round() = 498 · (300 * 1).round() = 300.
      expect(lines[0].lineTotalCents, 498);
      expect(lines[1].lineTotalCents, 300);
    });

    test('κενή λίστα γραμμών → αποθήκευση κεφαλίδας μόνο', () async {
      final id = await repo.insertReceiptWithLines(
        date: DateTime(2026, 1, 1),
        supplierId: supplierId,
        lines: const [],
      );
      expect(await repo.getById(id), isNotNull);
    });

    test('FK σε γραμμή: ανύπαρκτο item → SaveReceiptException + rollback',
        () async {
      await expectLater(
        repo.insertReceiptWithLines(
          date: DateTime(2026, 1, 1),
          supplierId: supplierId,
          lines: [
            (itemId: 9999, unitId: unitId, quantity: 1, priceCents: 100, discountCents: 0),
          ],
        ),
        throwsA(isA<SaveReceiptException>()),
      );

      // Rollback: ΟΥΤΕ η κεφαλίδα έμεινε (atomicity).
      expect(await repo.watchAll().first, isEmpty);
    });

    test('FK σε κεφαλίδα: ανύπαρκτο supplier → SaveReceiptException + rollback',
        () async {
      await expectLater(
        repo.insertReceiptWithLines(
          date: DateTime(2026, 1, 1),
          supplierId: 9999,
          lines: [
            (itemId: itemId, unitId: unitId, quantity: 1, priceCents: 100, discountCents: 0),
          ],
        ),
        throwsA(isA<SaveReceiptException>()),
      );

      expect(await repo.watchAll().first, isEmpty);
    });

    test('FK σε γραμμή: ανύπαρκτο unit → SaveReceiptException + rollback',
        () async {
      await expectLater(
        repo.insertReceiptWithLines(
          date: DateTime(2026, 1, 1),
          supplierId: supplierId,
          lines: [
            (itemId: itemId, unitId: 9999, quantity: 1, priceCents: 100, discountCents: 0),
          ],
        ),
        throwsA(isA<SaveReceiptException>()),
      );

      expect(await repo.watchAll().first, isEmpty);
    });
  });

  group('ReceiptRepositoryImpl — με έκπτωση (§2.2)', () {
    test('insertReceiptWithLines: έκπτωση αποθηκεύεται, σύνολο καθαρό',
        () async {
      final id = await repo.insertReceiptWithLines(
        date: DateTime(2026, 1, 1),
        supplierId: supplierId,
        lines: [
          (
            itemId: itemId,
            unitId: unitId,
            quantity: 2,
            priceCents: 250,
            discountCents: 50
          ),
        ],
      );

      final lines = await repo.watchLines(id).first;
      expect(lines.single.discountCents, 50);
      expect(lines.single.lineTotalCents, 400);
    });

    test('getLatestByItemId: passthrough (data + null)', () async {
      expect(await repo.getLatestByItemId(9999), isNull);

      final id = await repo.insertReceiptWithLines(
        date: DateTime(2026, 1, 1),
        supplierId: supplierId,
        lines: [
          (
            itemId: itemId,
            unitId: unitId,
            quantity: 1,
            priceCents: 100,
            discountCents: 0
          ),
        ],
      );

      final latest = await repo.getLatestByItemId(itemId);
      expect(latest, isNotNull);
      expect(latest!.receiptId, id);
    });
  });

  group('ReceiptRepositoryImpl.watchRecentSummaries (Φάση 3, Βήμα 7)', () {
    test('επιστρέφει σύνοψη με γραμμές + προμηθευτή (delegation)', () async {
      final receiptId = await repo.insertReceiptWithLines(
        date: DateTime(2026, 1, 1),
        supplierId: supplierId,
        lines: [
          (itemId: itemId, unitId: unitId, quantity: 2, priceCents: 199, discountCents: 0),
          (itemId: secondItemId, unitId: unitId, quantity: 1, priceCents: 50, discountCents: 0),
        ],
      );

      final summary =
          (await repo.watchRecentSummaries(limit: 10).first).single;
      expect(summary.id, receiptId);
      expect(summary.supplierName, 'Μάρκος');
      expect(summary.lineCount, 2);
      expect(summary.totalCents, 199 * 2 + 50);
    });

    test('κενή βάση → κενή λίστα', () async {
      expect(await repo.watchRecentSummaries(limit: 10).first, isEmpty);
    });

    test('raw stream σφάλμα → DataLoadException (stream mapping)', () async {
      final failing = ReceiptRepositoryImpl(
        _FailingStreamReceiptDao(db),
        ReceiptLineDao(db),
      );
      await expectLater(
        failing.watchRecentSummaries(limit: 10),
        emitsError(isA<DataLoadException>()),
      );
    });
  });
}