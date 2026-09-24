/// Unit tests — `SupplierManagementController` (§2.3 / CRUD 24-09-2026).
///
/// Validation/dup/no-op/gate μέσω record `(ok, error)` + `DataLoadException`
/// propagation σε DB αποτυχία. `ProviderContainer.test()` + in-memory βάση
/// (pattern `category_management_controller_test`).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_errors.dart';
import 'package:times/core/constants/app_messages.dart';
import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/receipt_dao.dart';
import 'package:times/data/local/daos/supplier_dao.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/repositories/supplier_repository.dart';
import 'package:times/data/repositories/supplier_repository_impl.dart';
import 'package:times/presentation/price_entry/controllers/receipt_form_controller.dart';
import 'package:times/presentation/settings/controllers/supplier_management_controller.dart';
import 'package:times/presentation/settings/state/settings_state.dart';

import '../../../data/local/helpers/in_memory_db.dart';

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

  SupplierManagementController controller() =>
      container.read(supplierManagementControllerProvider.notifier);

  Future<int> insertSupplier(String name) =>
      container.read(supplierRepositoryProvider).insert(name: name);

  group('SupplierManagementController — αρχική κατάσταση', () {
    test('isWorking=false αρχικά', () {
      expect(
        container.read(supplierManagementControllerProvider),
        const SettingsState(),
      );
    });

    test('isWorking=false μετά από op (finally)', () async {
      await controller().createSupplier('Μάρκος');
      expect(
        container.read(supplierManagementControllerProvider).isWorking,
        isFalse,
      );
    });
  });

  group('createSupplier', () {
    test('έγκυρο → ok + read-back (χωρίς select στη φόρμα)', () async {
      final result = await controller().createSupplier('Μάρκος');
      expect(result, (ok: true, error: null));
      expect(
        await container.read(supplierRepositoryProvider).watchAll().first,
        hasLength(1),
      );
      // Διαφορά από το header: καμία επιλογή στη φόρμα απόδειξης.
      expect(
        container.read(receiptFormControllerProvider).supplier,
        isNull,
      );
    });

    test('κενό → nameRequired, χωρίς DB write', () async {
      final result = await controller().createSupplier('   ');
      expect(result, (ok: false, error: AppErrors.nameRequired));
      expect(
        await container.read(supplierRepositoryProvider).watchAll().first,
        isEmpty,
      );
    });

    test('πολύ μεγάλο → nameTooLong, χωρίς DB write', () async {
      final tooLong = List.filled(101, 'α').join();
      final result = await controller().createSupplier(tooLong);
      expect(result, (ok: false, error: AppErrors.nameTooLong));
      expect(
        await container.read(supplierRepositoryProvider).watchAll().first,
        isEmpty,
      );
    });

    test('διπλότυπο (case/tone-insensitive) → nameExists', () async {
      await controller().createSupplier('Μάρκος');
      final result = await controller().createSupplier('μαρκος');
      expect(result, (ok: false, error: AppErrors.nameExists));
      expect(
        await container.read(supplierRepositoryProvider).watchAll().first,
        hasLength(1),
      );
    });

    test('DB σφάλμα → DataLoadException (propagation)', () async {
      final failing = ProviderContainer.test(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          supplierRepositoryProvider.overrideWithValue(
            _FailingSupplierRepository(db),
          ),
        ],
      );
      addTearDown(failing.dispose);
      await expectLater(
        failing
            .read(supplierManagementControllerProvider.notifier)
            .createSupplier('Μάρκος'),
        throwsA(isA<DataLoadException>()),
      );
    });
  });

  group('renameSupplier', () {
    test('έγκυρο → ok + read-back', () async {
      final id = await insertSupplier('Μάρκος');
      final result = await controller().renameSupplier(id, 'Νέος');
      expect(result, (ok: true, error: null));
      expect(
        (await container.read(supplierRepositoryProvider).getById(id))!.name,
        'Νέος',
      );
    });

    test('ίδιο όνομα → no-op ok, χωρίς write', () async {
      final id = await insertSupplier('Μάρκος');
      final result = await controller().renameSupplier(id, 'μάρκος');
      expect(result, (ok: true, error: null));
      expect(
        (await container.read(supplierRepositoryProvider).getById(id))!.name,
        'Μάρκος',
      );
    });

    test('διπλότυπο προς άλλον → nameExists', () async {
      final id = await insertSupplier('Μάρκος');
      await insertSupplier('Σκλαβενίτης');
      final result = await controller().renameSupplier(id, 'σκλαβενιτης');
      expect(result, (ok: false, error: AppErrors.nameExists));
    });

    test('ανύπαρκτο id → loadDataFailed', () async {
      final result = await controller().renameSupplier(9999, 'Νέος');
      expect(result, (ok: false, error: AppErrors.loadDataFailed));
    });

    test('κενό → nameRequired', () async {
      final id = await insertSupplier('Μάρκος');
      final result = await controller().renameSupplier(id, '  ');
      expect(result, (ok: false, error: AppErrors.nameRequired));
    });
  });

  group('deleteSupplier', () {
    test('καθαρός → ok + διαγράφεται', () async {
      final id = await insertSupplier('Μάρκος');
      final result = await controller().deleteSupplier(id);
      expect(result, (ok: true, error: null));
      expect(
        await container.read(supplierRepositoryProvider).getById(id),
        isNull,
      );
    });

    test('με αποδείξεις → tooltip, χωρίς διαγραφή (defense in depth)',
        () async {
      final id = await insertSupplier('Μάρκος');
      await ReceiptDao(
        db,
      ).insert(date: DateTime(2026, 1, 1), supplierId: id);
      final result = await controller().deleteSupplier(id);
      expect(
        result,
        (ok: false, error: AppMessages.supplierReceiptsTooltip(1)),
      );
      expect(
        await container.read(supplierRepositoryProvider).getById(id),
        isNotNull,
      );
    });

    test('ανύπαρκτο id → loadDataFailed', () async {
      final result = await controller().deleteSupplier(9999);
      expect(result, (ok: false, error: AppErrors.loadDataFailed));
    });

    test('σβησμένος ήταν draft-επιλεγμένος → αποεπιλογή φόρμας', () async {
      final id = await insertSupplier('Μάρκος');
      final supplier =
          await container.read(supplierRepositoryProvider).getById(id);
      container
          .read(receiptFormControllerProvider.notifier)
          .setSupplier(supplier);
      final result = await controller().deleteSupplier(id);
      expect(result, (ok: true, error: null));
      expect(container.read(receiptFormControllerProvider).supplier, isNull);
    });

    test('σβησμένος ΔΕΝ ήταν επιλεγμένος → φόρμα άθικτη', () async {
      final id = await insertSupplier('Μάρκος');
      final otherId = await insertSupplier('Σκλαβενίτης');
      final other =
          await container.read(supplierRepositoryProvider).getById(otherId);
      container
          .read(receiptFormControllerProvider.notifier)
          .setSupplier(other);
      await controller().deleteSupplier(id);
      expect(
        container.read(receiptFormControllerProvider).supplier?.id,
        otherId,
      );
    });
  });

  group('refreshGuards', () {
    test('δεν ρίχνει (invalidate families)', () async {
      final id = await insertSupplier('Μάρκος');
      controller().refreshGuards(supplierIds: [id]);
      expect(
        container.read(supplierManagementControllerProvider).isWorking,
        isFalse,
      );
    });
  });
}

/// Repository double που αποτυγχάνει στο insert — propagation check.
class _FailingSupplierRepository implements SupplierRepository {
  _FailingSupplierRepository(this.db);

  final AppDatabase db;

  SupplierRepository get _inner => SupplierRepositoryImpl(SupplierDao(db));

  @override
  Future<int> insert({required String name}) =>
      throw const DataLoadException();

  @override
  Stream<List<Supplier>> watchAll() => _inner.watchAll();

  @override
  Future<Supplier?> getById(int id) => _inner.getById(id);

  @override
  Future<Supplier?> getByNormalizedName(String normalizedName) =>
      _inner.getByNormalizedName(normalizedName);

  @override
  Stream<List<Supplier>> searchByNormalizedName(String query, {int? limit}) =>
      _inner.searchByNormalizedName(query, limit: limit);

  @override
  Future<bool> updateById(int id, {required String name}) =>
      _inner.updateById(id, name: name);

  @override
  Future<bool> deleteById(int id) => _inner.deleteById(id);
}
