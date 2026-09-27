/// Unit tests — `createSupplier` του `ReceiptFormController` (§2.2 · Βήμα 6β).
///
/// Χρειάζονται πραγματική in-memory βάση (Drift): `ProviderContainer.test` +
/// `inMemoryDb()` + `addTearDown(db.close)` (override `appDatabaseProvider`
/// προσπερνά το onDispose). Μέρος του split housekeeping του
/// `receipt_form_controller_test.dart` (Βήμα 8 · κανόνας 7: < 500 γρ. ανά
/// αρχείο) — τα υπόλοιπα groups ζουν στα:
///   * `receipt_form_controller_test.dart` (state mutations)
///   * `receipt_form_controller_save_receipt_test.dart` (saveReceipt)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/core/logging/app_logger.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/repositories/supplier_repository.dart';
import 'package:times/presentation/price_entry/controllers/receipt_form_controller.dart';

import '../../../data/local/helpers/in_memory_db.dart';

void main() {
  setUp(() {
    AppLogger.resetTestSink();
  });
  tearDown(() {
    AppLogger.resetTestSink();
  });

  ProviderContainer containerWithDb() {
    final db = inMemoryDb();
    addTearDown(db.close);
    return ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  }

  group('createSupplier', () {
    test('νέος → trim + insert + επιλέγεται στο state + log [UI]', () async {
      final container = containerWithDb();
      final logged = StringBuffer();
      AppLogger.testSink = logged.write;
      final notifier = container.read(receiptFormControllerProvider.notifier);

      final result = await notifier.createSupplier('  Lidl  ');
      expect(result.supplier, isNotNull);
      expect(result.supplier!.name, 'Lidl'); // trim
      expect(result.created, isTrue, reason: 'Νέα γραμμή στη βάση');
      expect(container.read(receiptFormControllerProvider).supplier,
          result.supplier);
      expect(logged.toString(), contains('[UI]'));
      expect(logged.toString(), contains('Επιλογή προμηθευτή'));
    });

    test('υπάρχον exact-normalized → ΔΕΝ εισάγει· επιλέγει τον υπάρχοντα',
        () async {
      final container = containerWithDb();
      final existingId =
          await container.read(supplierRepositoryProvider).insert(name: 'Μάρκος');
      final logged = StringBuffer();
      AppLogger.testSink = logged.write;
      final notifier = container.read(receiptFormControllerProvider.notifier);

      // «Μάρκος» (τόνος) κανονικοποιείται σε «μαρκοσ» — exact-match.
      final result = await notifier.createSupplier('ΜΑΡΚΟΣ');
      expect(result.supplier?.id, existingId);
      expect(result.created, isFalse, reason: 'Δεν μπήκε νέα γραμμή');
      expect(container.read(receiptFormControllerProvider).supplier?.id,
          existingId);
      expect(logged.toString(), contains('Επιλογή προμηθευτή'));

      final all = await container.read(supplierRepositoryProvider).watchAll()
          .first;
      expect(all.length, 1, reason: 'Καμία δεύτερη εγγραφή (soft dup-check)');
    });

    test('κενό/whitespace → (null, false), χωρίς αλλαγή state', () async {
      final container = containerWithDb();
      final notifier = container.read(receiptFormControllerProvider.notifier);

      final result = await notifier.createSupplier('   ');
      expect(result.supplier, isNull);
      expect(result.created, isFalse);
      expect(container.read(receiptFormControllerProvider).supplier, isNull);
    });

    test('σφάλμα DB → DataLoadException ανεβαίνει (χωρίς αλλαγή state)',
        () async {
      final container = ProviderContainer.test(
        overrides: [
          supplierRepositoryProvider
              .overrideWithValue(const _FailingSupplierRepo()),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(receiptFormControllerProvider.notifier);

      await expectLater(
        notifier.createSupplier('Lidl'),
        throwsA(isA<DataLoadException>()),
      );
      expect(container.read(receiptFormControllerProvider).supplier, isNull);
    });
  });
}

/// Σκόπιμα αποτυγχάνων repository — δοκιμή propagation σφάλματος χωρίς DB.
class _FailingSupplierRepo implements SupplierRepository {
  const _FailingSupplierRepo();

  @override
  Stream<List<Supplier>> watchAll() => throw const DataLoadException();
  @override
  Future<Supplier?> getById(int id) => throw const DataLoadException();
  @override
  Future<Supplier?> getByNormalizedName(String normalizedName) =>
      throw const DataLoadException();
  @override
  Stream<List<Supplier>> searchByNormalizedName(String query, {int? limit}) =>
      throw const DataLoadException();
  @override
  Future<int> insert({required String name}) => throw const DataLoadException();
  @override
  Future<bool> updateById(int id, {required String name}) =>
      throw const DataLoadException();
  @override
  Future<bool> deleteById(int id) => throw const DataLoadException();
}