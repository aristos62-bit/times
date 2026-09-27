/// Unit tests για το `ItemRepositoryImpl` (Φάση 2, Βήμα 2) — CRUD, mapping,
/// και κυρίως `searchByNormalizedName` (LIKE στο normalizedName).
///
/// Search contract: input ήδη-normalized (προσομοίωση με GreekTextNormalizer),
/// escape `%`/`_` literal (drift `escapeChar`), default/ατομικό limit,
/// ordering normalizedName, κενό query → αμέσως `[]`.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/core/utils/greek_text_normalizer.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/receipt_dao.dart';
import 'package:times/data/local/daos/receipt_line_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/supplier_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/repositories/item_repository_impl.dart';

import '../local/helpers/in_memory_db.dart';

/// DAO double — raw σφάλμα στο watchAll για δοκιμή stream mapping.
/// (Η αναζήτηση χρησιμοποιεί το ίδιο `.handleError` — δοκιμάζεται εδώ
/// μέσω του DAO-backed watchAll.)
class _FailingStreamItemDao extends ItemDao {
  _FailingStreamItemDao(super.db);

  @override
  Stream<List<Item>> watchAll() =>
      Stream.error(SqliteException(extendedResultCode: 1, message: 'test'));
}

void main() {
  late dynamic db;
  late ItemRepositoryImpl repo;
  late CategoryDao categoryDao;
  late SubCategoryDao subDao;
  late SupplierDao supplierDao;
  late ReceiptDao receiptDao;
  late ReceiptLineDao lineDao;
  late int subCategoryId;

  setUp(() async {
    db = inMemoryDb();
    repo = ItemRepositoryImpl(ItemDao(db));
    categoryDao = CategoryDao(db);
    subDao = SubCategoryDao(db);
    supplierDao = SupplierDao(db);
    receiptDao = ReceiptDao(db);
    lineDao = ReceiptLineDao(db);

    final categoryId = await categoryDao.insert(name: 'ΤΡΟΦΙΜΑ');
    subCategoryId =
        await subDao.insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
  });

  tearDown(() async => await db.close());

  group('ItemRepositoryImpl.insert/getById', () {
    test('insert + getById', () async {
      final id = await repo.insert(subCategoryId: subCategoryId, name: 'Γάλα');
      final row = await repo.getById(id);

      expect(row, isNotNull);
      expect(row!.name, 'Γάλα');
      expect(row.subCategoryId, subCategoryId);
    });

    test('getById ανύπαρκτο id → null', () async {
      expect(await repo.getById(999), isNull);
    });

    test('UNIQUE normalizedName: «Γάλα» vs «γαλα» → DataLoadException', () async {
      await repo.insert(subCategoryId: subCategoryId, name: 'Γάλα');

      await expectLater(
        repo.insert(subCategoryId: subCategoryId, name: 'γαλα'),
        throwsA(isA<DataLoadException>()),
      );
    });
  });

  group('ItemRepositoryImpl.searchByNormalizedName', () {
    Future<void> seedTypical() async {
      await repo.insert(subCategoryId: subCategoryId, name: 'Γάλα');
      await repo.insert(subCategoryId: subCategoryId, name: 'Γάλα σκόνη');
      await repo.insert(subCategoryId: subCategoryId, name: 'Γαλακτομπούρεκο');
      await repo.insert(subCategoryId: subCategoryId, name: 'Ψωμί');
    }

    test('partial match από κανονικοποιημένο input (case/tone) ', () async {
      await seedTypical();

      // Query όπως θα το έστελνε το UI (Φάση 3): normalize πριν το LIKE.
      final results = await repo
          .searchByNormalizedName(GreekTextNormalizer.normalize('ΓΆΛΑ'))
          .first;

      expect(
        results.map((i) => i.name).toList(),
        // Σειρά: normalizedName asc.
        ['Γάλα', 'Γάλα σκόνη', 'Γαλακτομπούρεκο'],
      );
    });

    test('καμία αντιστοίχιση → [] (όχι error)', () async {
      await seedTypical();
      expect(await repo.searchByNormalizedName('κανενασ').first, isEmpty);
    });

    test('κενό query → άμεσα [] χωρίς stream query', () async {
      final results = await repo.searchByNormalizedName('').first;
      expect(results, isEmpty);
    });

    test('escape `%`: «100% φυσικό» αλλά ΟΧΙ «100x»', () async {
      await repo.insert(subCategoryId: subCategoryId, name: '100% φυσικό');
      await repo.insert(subCategoryId: subCategoryId, name: '100x');

      final results = await repo.searchByNormalizedName('100%').first;
      expect(results.map((i) => i.name), ['100% φυσικό']);
    });

    test('escape `_`: «a_b» αλλά ΟΧΙ «aXb»', () async {
      await repo.insert(subCategoryId: subCategoryId, name: 'a_b');
      await repo.insert(subCategoryId: subCategoryId, name: 'aXb');

      final results = await repo.searchByNormalizedName('a_b').first;
      expect(results.map((i) => i.name), ['a_b']);
    });

    test('default limit AppConstants.searchResultsLimit (15)', () async {
      for (var i = 1; i <= 20; i++) {
        await repo.insert(subCategoryId: subCategoryId, name: 'Α αλφα $i');
      }

      final results = await repo.searchByNormalizedName('α αλφα').first;
      expect(results.length, 15);
    });

    test('limit: ατομικό όριο 5', () async {
      for (var i = 1; i <= 10; i++) {
        await repo.insert(subCategoryId: subCategoryId, name: 'Α αλφα $i');
      }

      final results = await repo.searchByNormalizedName('α αλφα', limit: 5).first;
      expect(results.length, 5);
    });

    test('limit ≤ 0 → πέφτει στο default (15)', () async {
      for (var i = 1; i <= 20; i++) {
        await repo.insert(subCategoryId: subCategoryId, name: 'Α αλφα $i');
      }

      final viaZero = await repo.searchByNormalizedName('α αλφα', limit: 0).first;
      expect(viaZero.length, 15);
    });

    test('ordering: normalizedName asc στο match', () async {
      await repo.insert(subCategoryId: subCategoryId, name: 'Α ωμέγα');
      await repo.insert(subCategoryId: subCategoryId, name: 'Α βήτα');
      await repo.insert(subCategoryId: subCategoryId, name: 'Α άλφα');

      final results = await repo.searchByNormalizedName('α ').first;
      expect(
        results.map((i) => i.name).toList(),
        ['Α άλφα', 'Α βήτα', 'Α ωμέγα'],
      );
    });

    test('raw stream σφάλμα → DataLoadException', () async {
      final failing = ItemRepositoryImpl(_FailingStreamItemDao(db));
      await expectLater(
        failing.watchAll(),
        emitsError(isA<DataLoadException>()),
      );
    });
  });

  group('ItemRepositoryImpl.updateById', () {
    test('αλλάζει name και ξανα-κανονικοποιεί (SPoT §3)', () async {
      final id = await repo.insert(subCategoryId: subCategoryId, name: 'Γάλα');
      expect(await repo.updateById(id, name: 'Γάλα πλήρες'), isTrue);

      final row = await repo.getById(id);
      expect(row!.name, 'Γάλα πλήρες');
      expect(row.normalizedName, GreekTextNormalizer.normalize('Γάλα πλήρες'));
    });

    test('defaultUnitId: Value(null) καθαρίζει, Value.absent() αφήνει', () async {
      final unitDao = UnitDao(db);
      final unitId = await unitDao.insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
      final id = await repo.insert(
        subCategoryId: subCategoryId,
        name: 'Γάλα',
        defaultUnitId: unitId,
      );
      expect((await repo.getById(id))!.defaultUnitId, unitId);

      // Value.absent(): καμία αλλαγή.
      await repo.updateById(id, defaultUnitId: const Value.absent());
      expect((await repo.getById(id))!.defaultUnitId, unitId);

      // Value(null): καθαρισμός.
      await repo.updateById(id, defaultUnitId: const Value(null));
      expect((await repo.getById(id))!.defaultUnitId, isNull);
    });

    test('ανύπαρκτο id → false', () async {
      expect(await repo.updateById(999), isFalse);
    });
  });

  group('ItemRepositoryImpl.deleteById', () {
    test('διαγράφει ελεύθερο είδος → getById null', () async {
      final id = await repo.insert(subCategoryId: subCategoryId, name: 'Γάλα');
      expect(await repo.deleteById(id), isTrue);
      expect(await repo.getById(id), isNull);
    });

    test('RESTRICT: με receipt lines → DataLoadException', () async {
      final itemId = await repo.insert(subCategoryId: subCategoryId, name: 'Γάλα');
      final unitId = await UnitDao(db).insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
      final supplierId = await supplierDao.insert(name: 'Μάρκος');
      final receiptId =
          await receiptDao.insert(date: DateTime(2026, 1, 1), supplierId: supplierId);
      await lineDao.insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 1,
        priceCents: 199,
      );

      await expectLater(
        repo.deleteById(itemId),
        throwsA(isA<DataLoadException>()),
      );
      expect(await repo.getById(itemId), isNotNull);
    });
  });

  group('ItemRepositoryImpl error mapping', () {
    test('insert με ανύπαρκτο subCategoryId → DataLoadException', () async {
      await expectLater(
        repo.insert(subCategoryId: 9999, name: 'Χ'),
        throwsA(isA<DataLoadException>()),
      );
    });
  });
}