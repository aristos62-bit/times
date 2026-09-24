/// Unit tests — `CategoryManagementController` (§2.3 / Φάση 4 Βήμα 4).
///
/// Validation/dup/no-op/gate μέσω record `(ok, error)` + `DataLoadException`
/// propagation σε DB αποτυχία. `ProviderContainer.test()` + in-memory βάση
/// (pattern `category_guard_providers_test`).
library;

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_errors.dart';
import 'package:times/core/constants/app_messages.dart';
import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/receipt_dao.dart';
import 'package:times/data/local/daos/receipt_line_dao.dart';
import 'package:times/data/local/daos/supplier_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/repositories/category_repository_impl.dart';
import 'package:times/presentation/settings/controllers/category_management_controller.dart';
import 'package:times/presentation/settings/state/settings_state.dart';

import '../../../data/local/helpers/in_memory_db.dart';

/// DAO double που αποτυγχάνει στο insert — propagation check.
class _FailingInsertCategoryDao extends CategoryDao {
  _FailingInsertCategoryDao(super.db);

  @override
  Future<int> insert({required String name}) =>
      Future.error(SqliteException(extendedResultCode: 1, message: 'test'));
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = inMemoryDb();
    addTearDown(db.close);
    container = ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() => container.dispose());

  CategoryManagementController controller() =>
      container.read(categoryManagementControllerProvider.notifier);

  /// Σπέρνει μονάδα + προμηθευτή + γραμμή για το είδος (μπλοκάρισμα).
  Future<void> seedLineInUse(int itemId) async {
    final unitId = await UnitDao(
      db,
    ).insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
    final supplierId = await SupplierDao(db).insert(name: 'Μάρκος');
    final receiptId = await ReceiptDao(
      db,
    ).insert(date: DateTime(2026, 1, 1), supplierId: supplierId);
    await ReceiptLineDao(db).insert(
      receiptId: receiptId,
      itemId: itemId,
      unitId: unitId,
      quantity: 1,
      priceCents: 100,
    );
  }

  group('CategoryManagementController — αρχική κατάσταση', () {
    test('isWorking=false αρχικά', () {
      expect(
        container.read(categoryManagementControllerProvider),
        const SettingsState(),
      );
    });

    test('isWorking=false μετά από op (finally)', () async {
      await controller().createCategory('ΤΡΟΦΙΜΑ');
      expect(
        container.read(categoryManagementControllerProvider).isWorking,
        isFalse,
      );
    });
  });

  group('createCategory', () {
    test('έγκυρο → ok + read-back', () async {
      final result = await controller().createCategory('ΤΡΟΦΙΜΑ');
      expect(result, (ok: true, error: null));
      expect(
        await container.read(categoryRepositoryProvider).watchAll().first,
        hasLength(1),
      );
    });

    test('κενό → nameRequired, χωρίς DB write', () async {
      final result = await controller().createCategory('   ');
      expect(result, (ok: false, error: AppErrors.nameRequired));
      expect(
        await container.read(categoryRepositoryProvider).watchAll().first,
        isEmpty,
      );
    });

    test('διπλότυπο (case/tone-insensitive) → nameExists', () async {
      await controller().createCategory('ΤΡΟΦΙΜΑ');
      final result = await controller().createCategory('τροφιμα');
      expect(result, (ok: false, error: AppErrors.nameExists));
    });
  });

  group('renameCategory', () {
    test('έγκυρο → ok + νέο όνομα', () async {
      final id = await container
          .read(categoryRepositoryProvider)
          .insert(name: 'ΠΑΛΙΟ');
      final result = await controller().renameCategory(id, 'ΝΕΟ');
      expect(result, (ok: true, error: null));
      expect(
        (await container.read(categoryRepositoryProvider).getById(id))!.name,
        'ΝΕΟ',
      );
    });

    test('ίδιο κείμενο → ok no-op, χωρίς write', () async {
      final id = await container
          .read(categoryRepositoryProvider)
          .insert(name: 'ΤΡΟΦΙΜΑ');
      final result = await controller().renameCategory(id, 'ΤΡΟΦΙΜΑ');
      expect(result, (ok: true, error: null));
      expect(
        (await container.read(categoryRepositoryProvider).getById(id))!.name,
        'ΤΡΟΦΙΜΑ',
      );
    });

    test('ίδιο όνομα, άλλη πεζότητα → ΓΡΑΦΕΤΑΙ (24-09-2026)', () async {
      final id = await container
          .read(categoryRepositoryProvider)
          .insert(name: 'ΤΡΟΦΙΜΑ');
      final result = await controller().renameCategory(id, 'Τρόφιμα');
      expect(result, (ok: true, error: null));
      expect(
        (await container.read(categoryRepositoryProvider).getById(id))!.name,
        'Τρόφιμα',
      );
    });

    test('διπλότυπο αδελφού → nameExists', () async {
      final id = await container
          .read(categoryRepositoryProvider)
          .insert(name: 'Α');
      await container.read(categoryRepositoryProvider).insert(name: 'Β');
      final result = await controller().renameCategory(id, 'β');
      expect(result, (ok: false, error: AppErrors.nameExists));
    });

    test('ανύπαρκτο id → loadDataFailed', () async {
      final result = await controller().renameCategory(999, 'Χ');
      expect(result, (ok: false, error: AppErrors.loadDataFailed));
    });
  });

  group('deleteCategory', () {
    test('καθαρή με είδη → ok + cascade', () async {
      final catId = await container
          .read(categoryRepositoryProvider)
          .insert(name: 'ΤΡΟΦΙΜΑ');
      final subId = await container
          .read(subCategoryRepositoryProvider)
          .insert(categoryId: catId, name: 'Γαλακτοκομικά');
      await ItemDao(db).insert(subCategoryId: subId, name: 'Γάλα');

      final result = await controller().deleteCategory(catId);
      expect(result, (ok: true, error: null));
      expect(
        await container.read(categoryRepositoryProvider).getById(catId),
        isNull,
      );
    });

    test('μπλοκαρισμένη → ok:false + itemsInUseTooltip', () async {
      final catId = await container
          .read(categoryRepositoryProvider)
          .insert(name: 'ΤΡΟΦΙΜΑ');
      final subId = await container
          .read(subCategoryRepositoryProvider)
          .insert(categoryId: catId, name: 'Γαλακτοκομικά');
      final itemId = await ItemDao(db).insert(
        subCategoryId: subId,
        name: 'Γάλα',
      );
      await seedLineInUse(itemId);

      final result = await controller().deleteCategory(catId);
      expect(result.ok, isFalse);
      expect(result.error, AppMessages.itemsInUseTooltip(1));
      // Τίποτα δεν σβήστηκε (gate πριν το transaction).
      expect(
        await container.read(categoryRepositoryProvider).getById(catId),
        isNotNull,
      );
    });

    test('ανύπαρκτο id → loadDataFailed', () async {
      final result = await controller().deleteCategory(999);
      expect(result, (ok: false, error: AppErrors.loadDataFailed));
    });
  });

  group('subCategory CRUD', () {
    test('create + rename + delete ροή', () async {
      final catId = await container
          .read(categoryRepositoryProvider)
          .insert(name: 'ΤΡΟΦΙΜΑ');

      var result = await controller().createSubCategory(
        categoryId: catId,
        name: 'Γαλακτοκομικά',
      );
      expect(result, (ok: true, error: null));

      // Dup εντός ίδιας κατηγορίας → nameExists.
      result = await controller().createSubCategory(
        categoryId: catId,
        name: 'γαλακτοκομικα',
      );
      expect(result, (ok: false, error: AppErrors.nameExists));

      // Ίδιο όνομα σε ΑΛΛΗ κατηγορία → επιτρέπεται (scope ανά κατηγορία).
      final otherCat = await container
          .read(categoryRepositoryProvider)
          .insert(name: 'ΟΙΚΙΑΚΑ');
      result = await controller().createSubCategory(
        categoryId: otherCat,
        name: 'Γαλακτοκομικά',
      );
      expect(result, (ok: true, error: null));

      final subs = await container
          .read(subCategoryRepositoryProvider)
          .watchByCategoryId(catId)
          .first;
      final subId = subs.single.id;

      result = await controller().renameSubCategory(subId, 'Τυροκομικά');
      expect(result, (ok: true, error: null));

      result = await controller().deleteSubCategory(subId);
      expect(result, (ok: true, error: null));
      expect(
        await container.read(subCategoryRepositoryProvider).getById(subId),
        isNull,
      );
    });

    test('delete μπλοκαρισμένης → tooltip, τίποτα δεν σβήνεται', () async {
      final catId = await container
          .read(categoryRepositoryProvider)
          .insert(name: 'ΤΡΟΦΙΜΑ');
      final subId = await container
          .read(subCategoryRepositoryProvider)
          .insert(categoryId: catId, name: 'Γαλακτοκομικά');
      final itemId = await ItemDao(db).insert(
        subCategoryId: subId,
        name: 'Γάλα',
      );
      await seedLineInUse(itemId);

      final result = await controller().deleteSubCategory(subId);
      expect(result.ok, isFalse);
      expect(result.error, AppMessages.itemsInUseTooltip(1));
    });
  });

  group('counts + refresh + σφάλματα', () {
    test('getCategoryItemCount/getSubCategoryItemCount', () async {
      final catId = await container
          .read(categoryRepositoryProvider)
          .insert(name: 'ΤΡΟΦΙΜΑ');
      final subId = await container
          .read(subCategoryRepositoryProvider)
          .insert(categoryId: catId, name: 'Γαλακτοκομικά');
      await ItemDao(db).insert(subCategoryId: subId, name: 'Γάλα');

      expect(await controller().getCategoryItemCount(catId), 1);
      expect(await controller().getSubCategoryItemCount(subId), 1);
    });

    test('refreshGuards → no-throw', () {
      expect(
        () => controller().refreshGuards(
          categoryIds: [1, 2],
          subCategoryIds: [3],
        ),
        returnsNormally,
      );
    });

    test('DB αποτυχία → DataLoadException (όχι record)', () async {
      final failContainer = ProviderContainer.test(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          categoryRepositoryProvider.overrideWithValue(
            CategoryRepositoryImpl(_FailingInsertCategoryDao(db)),
          ),
        ],
      );
      addTearDown(failContainer.dispose);
      await expectLater(
        failContainer
            .read(categoryManagementControllerProvider.notifier)
            .createCategory('Χ'),
        throwsA(isA<DataLoadException>()),
      );
    });
  });
}
