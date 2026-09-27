/// Unit tests — Βήμα 3 providers ελέγχου (DESIGN §2.3:274-275 · §4:463).
///
/// `categoryTreeStreamProvider` (ζωντανό δέντρο, in-memory σύνθεση χωρίς νέο
/// DB query) + `canDelete*Provider` (πύλη `countItemsInUse == 0`).
///
/// `ProviderContainer.test()` + override του `appDatabaseProvider` με
/// in-memory βάση (πρότυπο `stream_providers_test`). Για τα families
/// αρκεί το `.future` (το τεκμηριωμένο hang αφορούσε ΜΟΝΟ StreamProvider +
/// drift)· για το tree (StreamProvider) `container.listen` + Completer με
/// predicate (επιλεκτική ακρόαση, fail-fast 5s).
library;

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:times/data/models/category_tree_node.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/providers/settings_providers.dart';
import 'package:times/data/repositories/category_repository_impl.dart';
import 'package:times/data/repositories/sub_category_repository_impl.dart';

import '../local/helpers/in_memory_db.dart';

/// DAO double που αποτυγχάνει στο count — έλεγχος mapping του canDelete
/// σε `DataLoadException`. `Future.error` (όχι sync throw).
class _FailingCountCategoryDao extends CategoryDao {
  _FailingCountCategoryDao(super.db);

  @override
  Future<int> countItemsInUseByCategoryId(int categoryId) =>
      Future.error(SqliteException(extendedResultCode: 1, message: 'test'));
}

/// DAO double με σπασμένο stream — έλεγχος error-path του tree.
class _FailingStreamCategoryDao extends CategoryDao {
  _FailingStreamCategoryDao(super.db);

  @override
  Stream<List<Category>> watchAll() =>
      Stream.error(SqliteException(extendedResultCode: 1, message: 'test'));
}

/// DAO double που αποτυγχάνει στο count υποκατηγορίας.
class _FailingCountSubCategoryDao extends SubCategoryDao {
  _FailingCountSubCategoryDao(super.db);

  @override
  Future<int> countItemsInUseBySubCategoryId(int subCategoryId) =>
      Future.error(SqliteException(extendedResultCode: 1, message: 'test'));
}

/// Ακούει μέσω του [subscribe] μέχρι μια εκπομπή να ικανοποιήσει το
/// [predicate] και επιστρέφει τη λίστα. Fails fast (5s) αντί για 30s timeout
/// (μίνι-αντίγραφο του `waitForValue` του `stream_providers_test` — τα test
/// αρχεία δεν εισάγουν το ένα το άλλο, precedent Βήματος 2).
Future<T> waitForTreeValue<T>(
  void Function(
    void Function(AsyncValue<T>? previous, AsyncValue<T> next) onEmission,
  ) subscribe,
  bool Function(T value) predicate,
) async {
  final completer = Completer<T>();
  subscribe((previous, next) {
    if (next.hasValue &&
        predicate(next.requireValue) &&
        !completer.isCompleted) {
      completer.complete(next.requireValue);
    }
  });
  return completer.future.timeout(const Duration(seconds: 5));
}

void main() {
  ProviderContainer containerWithDb() {
    final db = inMemoryDb();
    addTearDown(db.close);
    return ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  }

  /// Δημιουργεί μονάδα + προμηθευτή (απαραίτητα για γραμμές απόδειξης).
  Future<({int unitId, int supplierId})> seedUnitAndSupplier(
    AppDatabase db,
  ) async {
    final unitId =
        await UnitDao(db).insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
    final supplierId = await SupplierDao(db).insert(name: 'Μάρκος');
    return (unitId: unitId, supplierId: supplierId);
  }

  /// Δημιουργεί απόδειξη + γραμμή για το είδος.
  Future<void> seedReceiptLine(
    AppDatabase db, {
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

  group('canDeleteCategoryProvider', () {
    test('άδεια κατηγορία → true', () async {
      final container = containerWithDb();
      final id = await container
          .read(categoryRepositoryProvider)
          .insert(name: 'ΤΡΟΦΙΜΑ');

      expect(await container.read(canDeleteCategoryProvider(id).future), isTrue);
    });

    test('είδη χωρίς γραμμές → true (cascade-επιτρέψιμο)', () async {
      final container = containerWithDb();
      final db = container.read(appDatabaseProvider);
      final id = await container
          .read(categoryRepositoryProvider)
          .insert(name: 'ΤΡΟΦΙΜΑ');
      final subId = await container
          .read(subCategoryRepositoryProvider)
          .insert(categoryId: id, name: 'Γαλακτοκομικά');
      await ItemDao(db).insert(subCategoryId: subId, name: 'Γάλα');

      expect(await container.read(canDeleteCategoryProvider(id).future), isTrue);
    });

    test('είδος με γραμμή → false', () async {
      final container = containerWithDb();
      final db = container.read(appDatabaseProvider);
      final seed = await seedUnitAndSupplier(db);
      final id = await container
          .read(categoryRepositoryProvider)
          .insert(name: 'ΤΡΟΦΙΜΑ');
      final subId = await container
          .read(subCategoryRepositoryProvider)
          .insert(categoryId: id, name: 'Γαλακτοκομικά');
      final itemId =
          await ItemDao(db).insert(subCategoryId: subId, name: 'Γάλα');
      await seedReceiptLine(
        db,
        itemId: itemId,
        unitId: seed.unitId,
        supplierId: seed.supplierId,
      );

      expect(
        await container.read(canDeleteCategoryProvider(id).future),
        isFalse,
      );
    });

    test('απομόνωση: άλλη μπλοκαρισμένη, αυτή true', () async {
      final container = containerWithDb();
      final db = container.read(appDatabaseProvider);
      final seed = await seedUnitAndSupplier(db);
      final foodId = await container
          .read(categoryRepositoryProvider)
          .insert(name: 'ΤΡΟΦΙΜΑ');
      final homeId = await container
          .read(categoryRepositoryProvider)
          .insert(name: 'ΟΙΚΙΑΚΑ');
      final subDao = SubCategoryDao(db);
      final foodSub =
          await subDao.insert(categoryId: foodId, name: 'Γαλακτοκομικά');
      final homeSub =
          await subDao.insert(categoryId: homeId, name: 'Καθαριότητα');
      final itemDao = ItemDao(db);
      final milkId =
          await itemDao.insert(subCategoryId: foodSub, name: 'Γάλα');
      await itemDao.insert(subCategoryId: homeSub, name: 'Σφουγγάρι');
      await seedReceiptLine(
        db,
        itemId: milkId,
        unitId: seed.unitId,
        supplierId: seed.supplierId,
      );

      expect(
        await container.read(canDeleteCategoryProvider(foodId).future),
        isFalse,
      );
      expect(
        await container.read(canDeleteCategoryProvider(homeId).future),
        isTrue,
      );
    });

    test('ανύπαρκτο id → true (τίποτα δεν μπλοκάρει)', () async {
      final container = containerWithDb();

      expect(
        await container.read(canDeleteCategoryProvider(999).future),
        isTrue,
      );
    });

    test('σφάλμα DAO → DataLoadException (όχι raw)', () async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final container = ProviderContainer.test(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          categoryRepositoryProvider.overrideWithValue(
            CategoryRepositoryImpl(_FailingCountCategoryDao(db)),
          ),
        ],
      );

      // NOTE: όχι `.future`+throwsA — το Riverpod 3 κάνει αυτόματο retry στα
      // αποτυχημένα futures και το future δεν ολοκληρώνεται (εύρημα Βήματος 3).
      final completer = Completer<Object?>();
      final sub = container.listen(canDeleteCategoryProvider(1), (prev, next) {
        if (next.hasError && !completer.isCompleted) {
          completer.complete(next.error);
        }
      });
      addTearDown(sub.close);

      expect(
        await completer.future.timeout(const Duration(seconds: 5)),
        isA<DataLoadException>(),
      );
    });
  });

  group('canDeleteSubCategoryProvider', () {
    test('κενή υποκατηγορία → true', () async {
      final container = containerWithDb();
      final catId = await container
          .read(categoryRepositoryProvider)
          .insert(name: 'ΤΡΟΦΙΜΑ');
      final subId = await container
          .read(subCategoryRepositoryProvider)
          .insert(categoryId: catId, name: 'Γαλακτοκομικά');

      expect(
        await container.read(canDeleteSubCategoryProvider(subId).future),
        isTrue,
      );
    });

    test('είδος με γραμμή → false', () async {
      final container = containerWithDb();
      final db = container.read(appDatabaseProvider);
      final seed = await seedUnitAndSupplier(db);
      final catId = await container
          .read(categoryRepositoryProvider)
          .insert(name: 'ΤΡΟΦΙΜΑ');
      final subId = await container
          .read(subCategoryRepositoryProvider)
          .insert(categoryId: catId, name: 'Γαλακτοκομικά');
      final itemId =
          await ItemDao(db).insert(subCategoryId: subId, name: 'Γάλα');
      await seedReceiptLine(
        db,
        itemId: itemId,
        unitId: seed.unitId,
        supplierId: seed.supplierId,
      );

      expect(
        await container.read(canDeleteSubCategoryProvider(subId).future),
        isFalse,
      );
    });

    test('ανύπαρκτο id → true', () async {
      final container = containerWithDb();

      expect(
        await container.read(canDeleteSubCategoryProvider(999).future),
        isTrue,
      );
    });

    test('σφάλμα DAO → DataLoadException (όχι raw)', () async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final container = ProviderContainer.test(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          subCategoryRepositoryProvider.overrideWithValue(
            SubCategoryRepositoryImpl(_FailingCountSubCategoryDao(db)),
          ),
        ],
      );

      // NOTE: όχι `.future`+throwsA — αυτόματο retry (εύρημα Βήματος 3).
      final completer = Completer<Object?>();
      final sub = container.listen(
        canDeleteSubCategoryProvider(1),
        (prev, next) {
          if (next.hasError && !completer.isCompleted) {
            completer.complete(next.error);
          }
        },
      );
      addTearDown(sub.close);

      expect(
        await completer.future.timeout(const Duration(seconds: 5)),
        isA<DataLoadException>(),
      );
    });
  });

  group('categoryTreeStreamProvider', () {
    test('άδεια βάση → [] (όχι hang)', () async {
      final container = containerWithDb();

      final tree = await waitForTreeValue<List<CategoryTreeNode>>(
        (listen) => container.listen(categoryTreeStreamProvider, listen),
        (v) => v.isEmpty,
      );
      expect(tree, isEmpty);
    });

    test('nesting + αλφαβητική σειρά', () async {
      final container = containerWithDb();
      final catRepo = container.read(categoryRepositoryProvider);
      final subRepo = container.read(subCategoryRepositoryProvider);
      final foodId = await catRepo.insert(name: 'ΤΡΟΦΙΜΑ');
      final homeId = await catRepo.insert(name: 'ΟΙΚΙΑΚΑ');
      await subRepo.insert(categoryId: foodId, name: 'Κρέας');
      await subRepo.insert(categoryId: foodId, name: 'Γαλακτοκομικά');
      await subRepo.insert(categoryId: homeId, name: 'Καθαριότητα');

      final tree = await waitForTreeValue<List<CategoryTreeNode>>(
        (listen) => container.listen(categoryTreeStreamProvider, listen),
        (v) => v.length == 2,
      );
      // Κατηγορίες αλφαβητικά (ΟΙΚΙΑΚΑ < ΤΡΟΦΙΜΑ).
      expect(tree.map((n) => n.category.name), ['ΟΙΚΙΑΚΑ', 'ΤΡΟΦΙΜΑ']);
      // Nested υποκατηγορίες αλφαβητικά ανά κατηγορία.
      expect(
        tree[1].subCategories.map((s) => s.name),
        ['Γαλακτοκομικά', 'Κρέας'],
      );
      expect(
        tree[0].subCategories.map((s) => s.name),
        ['Καθαριότητα'],
      );
    });

    test('κατηγορία χωρίς subs → node με []', () async {
      final container = containerWithDb();
      await container
          .read(categoryRepositoryProvider)
          .insert(name: 'ΜΟΝΗ');

      final tree = await waitForTreeValue<List<CategoryTreeNode>>(
        (listen) => container.listen(categoryTreeStreamProvider, listen),
        (v) => v.length == 1,
      );
      expect(tree.single.subCategories, isEmpty);
    });

    test('live re-emit μετά από insert', () async {
      final container = containerWithDb();
      final catRepo = container.read(categoryRepositoryProvider);
      await catRepo.insert(name: 'Α');

      await waitForTreeValue<List<CategoryTreeNode>>(
        (listen) => container.listen(categoryTreeStreamProvider, listen),
        (v) => v.length == 1,
      );
      await catRepo.insert(name: 'Β');

      final tree = await waitForTreeValue<List<CategoryTreeNode>>(
        (listen) => container.listen(categoryTreeStreamProvider, listen),
        (v) => v.length == 2,
      );
      expect(tree.map((n) => n.category.name), ['Α', 'Β']);
    });

    test('σφάλμα upstream → DataLoadException (όχι raw)', () async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final container = ProviderContainer.test(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          categoryRepositoryProvider.overrideWithValue(
            CategoryRepositoryImpl(_FailingStreamCategoryDao(db)),
          ),
        ],
      );

      final completer = Completer<Object>();
      final sub = container.listen(categoryTreeStreamProvider, (prev, next) {
        if (next.hasError && !completer.isCompleted) {
          completer.complete(next.error);
        }
      });
      addTearDown(sub.close);

      expect(
        await completer.future.timeout(const Duration(seconds: 5)),
        isA<DataLoadException>(),
      );
    });
  });
}
