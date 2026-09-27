/// Unit tests για το `CategoryRepositoryImpl` (Φάση 2, Βήμα 2) — mapping.
///
/// Καθαρό CRUD + streams πάνω στον CategoryDao, με τη διαφορά ότι τα
/// σφάλματα φτάνουν ΕΔΩ ως `DataLoadException` (ποτέ raw SqliteException):
/// FK RESTRICT (υποκατηγορίες) στη διαγραφή + stream error μετά από close.
///
/// Refactor 4 επιπέδων (27-09-2026): τα είδη ζουν σε Τμήματα — η αλυσίδα
/// seed είναι category → subCategory → itemGroup → item.
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/core/utils/greek_text_normalizer.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/item_group_dao.dart';
import 'package:times/data/local/daos/receipt_dao.dart';
import 'package:times/data/local/daos/receipt_line_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/supplier_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/repositories/category_repository_impl.dart';

import '../local/helpers/in_memory_db.dart';

/// DAO double που εκπέμπει raw σφάλμα — ντετερμινιστικός έλεγχος ότι το
/// repository mapάρει σφάλματα stream σε `DataLoadException`.
class _FailingStreamCategoryDao extends CategoryDao {
  _FailingStreamCategoryDao(super.db);

  @override
  Stream<List<Category>> watchAll() =>
      Stream.error(SqliteException(extendedResultCode: 1, message: 'test'));
}

/// DAO double που αποτυγχάνει στο count — ντετερμινιστικός έλεγχος mapping
/// του `countItemsInUse` (Βήμα 3). `Future.error` (όχι sync throw) ώστε το
/// σφάλμα να ταξιδέψει ως future error μέσα από το `_guard`.
class _FailingCountCategoryDao extends CategoryDao {
  _FailingCountCategoryDao(super.db);

  @override
  Future<int> countItemsInUseByCategoryId(int categoryId) =>
      Future.error(SqliteException(extendedResultCode: 1, message: 'test'));
}

void main() {
  late dynamic db;
  late CategoryRepositoryImpl repo;
  late SubCategoryDao subDao;
  late ItemGroupDao groupDao;

  setUp(() {
    db = inMemoryDb();
    repo = CategoryRepositoryImpl(CategoryDao(db));
    subDao = SubCategoryDao(db);
    groupDao = ItemGroupDao(db);
  });

  tearDown(() async => await db.close());

  /// Αλυσίδα 4 επιπέδων: sub + group κάτω από την κατηγορία, επιστρέφει
  /// το groupId για inserts ειδών.
  Future<int> seedGroup(int categoryId, String subName) async {
    final subId = await subDao.insert(
      categoryId: categoryId,
      name: subName,
    );
    return groupDao.insert(subCategoryId: subId, name: 'Τμήμα $subName');
  }

  group('CategoryRepositoryImpl.insert/getById', () {
    test('επιστρέφει id και η εγγραφή διαβάζεται', () async {
      final id = await repo.insert(name: 'ΤΡΟΦΙΜΑ');
      final row = await repo.getById(id);

      expect(row, isNotNull);
      expect(row!.name, 'ΤΡΟΦΙΜΑ');
    });

    test('getById ανύπαρκτο id → null', () async {
      expect(await repo.getById(999), isNull);
    });
  });

  /// Αναζήτηση exact-match στο κανονικοποιημένο όνομα (soft dup-check
  /// §2.2 — ο πίνακας ΕΧΕΙ UNIQUE `normalizedName`, §3).
  group('CategoryRepositoryImpl.getByNormalizedName', () {
    test('exact-match βρίσκει την κατηγορία', () async {
      final id = await repo.insert(name: 'ΤΡΟΦΙΜΑ');
      final row = await repo.getByNormalizedName(
        GreekTextNormalizer.normalize('ΤΡΟΦΙΜΑ'),
      );

      expect(row, isNotNull);
      expect(row!.id, id);
    });

    test('case/tone-insensitive (ήδη-normalized input)', () async {
      await repo.insert(name: 'Γαλακτοκομικά');
      final row = await repo.getByNormalizedName(
        GreekTextNormalizer.normalize('ΓΑΛΑΚΤΟΚΟΜΙΚΑ'),
      );

      expect(row, isNotNull);
      expect(row!.name, 'Γαλακτοκομικά');
    });

    test('καμία αντιστοίχιση → null', () async {
      await repo.insert(name: 'ΤΡΟΦΙΜΑ');
      expect(await repo.getByNormalizedName('ανυπαρκτο'), isNull);
    });
  });

  group('CategoryRepositoryImpl.watchAll', () {
    test('αρχικά άδειο, μετά insert εμφανίζεται (real-time)', () async {
      expect(await repo.watchAll().first, isEmpty);

      await repo.insert(name: 'ΤΡΟΦΙΜΑ');

      final rows = await repo.watchAll().first;
      expect(rows.single.name, 'ΤΡΟΦΙΜΑ');
    });

    test('ordering: αλφαβητικά κατά name', () async {
      final id2 = await repo.insert(name: 'Β');
      final id1 = await repo.insert(name: 'Α');
      final id3 = await repo.insert(name: 'Γ');

      final rows = await repo.watchAll().first;
      expect(rows.map((c) => c.id), [id1, id2, id3]);
    });
  });

  group('CategoryRepositoryImpl.updateById/deleteById', () {
    test('updateById αλλάζει το name', () async {
      final id = await repo.insert(name: 'ΠΑΛΙΟ');
      expect(await repo.updateById(id, name: 'ΝΕΟ'), isTrue);
      expect((await repo.getById(id))!.name, 'ΝΕΟ');
    });

    test('updateById ανύπαρκτο id → false', () async {
      expect(await repo.updateById(999, name: 'Χ'), isFalse);
    });

    test('deleteById διαγράφει → getById null', () async {
      final id = await repo.insert(name: 'ΠΡΟΣ ΔΙΑΓΡΑΦΗ');
      expect(await repo.deleteById(id), isTrue);
      expect(await repo.getById(id), isNull);
    });
  });

  group('CategoryRepositoryImpl handling σφαλμάτων (mapping)', () {
    test('FK RESTRICT: deleteById με υποκατηγορίες → DataLoadException',
        () async {
      final categoryId = await repo.insert(name: 'ΤΡΟΦΙΜΑ');
      await subDao.insert(categoryId: categoryId, name: 'Γαλακτοκομικά');

      // Το repository mapάρει: ποτέ raw SqliteException στα UI/controllers.
      await expectLater(
        repo.deleteById(categoryId),
        throwsA(isA<DataLoadException>()),
      );
      // Atomicity: η κατηγορία παραμένει.
      expect(await repo.getById(categoryId), isNotNull);
    });

    test('raw stream σφάλμα → DataLoadException (stream mapping)',
        () async {
      final failing = CategoryRepositoryImpl(_FailingStreamCategoryDao(db));
      await expectLater(
        failing.watchAll(),
        emitsError(isA<DataLoadException>()),
      );
    });
  });

  group('CategoryRepositoryImpl.countItemsInUse (Βήμα 3)', () {
    /// Δημιουργεί μονάδα + προμηθευτή (απαραίτητα για γραμμές απόδειξης).
    Future<({int unitId, int supplierId})> seedUnitAndSupplier() async {
      final unitId =
          await UnitDao(db).insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
      final supplierId = await SupplierDao(db).insert(name: 'Μάρκος');
      return (unitId: unitId, supplierId: supplierId);
    }

    /// Δημιουργεί απόδειξη + γραμμή για το είδος.
    Future<void> seedReceiptLine({
      required int itemId,
      required int unitId,
      required int supplierId,
    }) async {
      final receiptId = await ReceiptDao(db)
          .insert(date: DateTime(2026, 1, 1), supplierId: supplierId);
      await ReceiptLineDao(db).insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 1,
        priceCents: 100,
      );
    }

    test('είδη χωρίς γραμμές → 0', () async {
      final categoryId = await repo.insert(name: 'ΤΡΟΦΙΜΑ');
      final groupId = await seedGroup(categoryId, 'Γαλακτοκομικά');
      await ItemDao(db).insert(itemGroupId: groupId, name: 'Γάλα');

      expect(await repo.countItemsInUse(categoryId), 0);
    });

    test('είδος με γραμμή → 1', () async {
      final seed = await seedUnitAndSupplier();
      final categoryId = await repo.insert(name: 'ΤΡΟΦΙΜΑ');
      final groupId = await seedGroup(categoryId, 'Γαλακτοκομικά');
      final itemId =
          await ItemDao(db).insert(itemGroupId: groupId, name: 'Γάλα');
      await seedReceiptLine(
        itemId: itemId,
        unitId: seed.unitId,
        supplierId: seed.supplierId,
      );

      expect(await repo.countItemsInUse(categoryId), 1);
    });

    test('ανύπαρκτο id → 0', () async {
      expect(await repo.countItemsInUse(999), 0);
    });

    test('raw σφάλμα DAO → DataLoadException (mapping)', () async {
      final failing = CategoryRepositoryImpl(_FailingCountCategoryDao(db));
      await expectLater(
        failing.countItemsInUse(1),
        throwsA(isA<DataLoadException>()),
      );
    });
  });
}
