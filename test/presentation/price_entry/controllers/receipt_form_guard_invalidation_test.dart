/// Tests ανανέωσης stale πυλών διαγραφής μετά από save/delete (§2.3:299).
///
/// Listen-based rebuild assertions (precedent Βήμα 3 Ε1 — listen+completer,
/// όχι `.future`+throwsA στα error paths): τα one-shot families διαβάζονται
/// πάντα φρέσκα, οπότε η ανανέωση παρατηρείται μόνο μέσω listener που μετρά
/// rebuilds. Real in-memory DB + real repos (ο helper διαβάζει `getById` —
/// σκόπιμα όχι fakes στο success path).
library;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/providers/settings_providers.dart';
import 'package:times/data/repositories/item_repository.dart';
import 'package:times/presentation/price_entry/controllers/receipt_form_controller.dart';
import 'package:times/presentation/price_entry/state/receipt_form_state.dart';

import '../../../data/local/helpers/in_memory_db.dart';

/// Fake που ρίχνει ΜΟΝΟ στο `getById` (resolution failure → swallow).
/// Οι υπόλοιπες μέθοδοι δεν καλούνται στο save path.
class _ThrowingItemRepo implements ItemRepository {
  const _ThrowingItemRepo();

  @override
  Future<Item?> getById(int id) => throw const DataLoadException();
  @override
  Stream<List<Item>> watchAll() => throw UnimplementedError();
  @override
  Stream<List<Item>> watchBySubCategoryId(int subCategoryId) =>
      throw UnimplementedError();
  @override
  Future<Item?> getByNormalizedName(String normalizedName) =>
      throw UnimplementedError();
  @override
  Stream<List<Item>> searchByNormalizedName(String query, {int? limit}) =>
      throw UnimplementedError();
  @override
  Future<int> insert({
    required int subCategoryId,
    required String name,
    int? defaultUnitId,
  }) =>
      throw UnimplementedError();
  @override
  Future<bool> updateById(
    int id, {
    int? subCategoryId,
    String? name,
    Value<int?>? defaultUnitId,
  }) =>
      throw UnimplementedError();
  @override
  Future<bool> deleteById(int id) => throw UnimplementedError();
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late int supplierId;
  late int unitId;
  late int catId;
  late int subId;
  late int itemId;

  setUp(() async {
    db = inMemoryDb();
    addTearDown(db.close);
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    supplierId =
        await container.read(supplierRepositoryProvider).insert(name: 'Μάρκος');
    unitId = await container.read(unitRepositoryProvider).insert(
          name: 'Τεμάχιο',
          abbreviation: 'τεμ',
        );
    catId =
        await container.read(categoryRepositoryProvider).insert(name: 'ΤΡΟΦΙΜΑ');
    subId = await container
        .read(subCategoryRepositoryProvider)
        .insert(categoryId: catId, name: 'Γάλα');
    itemId = await container
        .read(itemRepositoryProvider)
        .insert(subCategoryId: subId, name: 'Γάλα 1λ');
  });

  /// Γεμίζει τη φόρμα με 1 έγκυρη γραμμή (supplier + draft).
  Future<void> fillForm() async {
    final form = container.read(receiptFormControllerProvider.notifier);
    final supplier =
        await container.read(supplierRepositoryProvider).getById(supplierId);
    form.setSupplier(supplier);
    form.addDraftLine(
      DraftReceiptLine(
        itemId: itemId,
        unitId: unitId,
        quantity: 2,
        priceCents: 150,
        itemName: 'Γάλα 1λ',
        unitAbbreviation: 'τεμ',
      ),
    );
  }

  group('Guard invalidation μετά από save', () {
    test('save → rebuild πύλης προμηθευτή (true→false)', () async {
      var builds = 0;
      container.listen(
        canDeleteSupplierProvider(supplierId),
        (_, _) => builds++,
      );
      await fillForm();
      await container.read(receiptFormControllerProvider.notifier).saveReceipt();
      await container.read(canDeleteSupplierProvider(supplierId).future);
      expect(builds, greaterThanOrEqualTo(2));
      expect(
        container.read(canDeleteSupplierProvider(supplierId)).value,
        isFalse,
      );
    });

    test('save → rebuild πυλών κατηγορίας/υποκατηγορίας', () async {
      var catBuilds = 0;
      var subBuilds = 0;
      container.listen(
        canDeleteCategoryProvider(catId),
        (_, _) => catBuilds++,
      );
      container.listen(
        canDeleteSubCategoryProvider(subId),
        (_, _) => subBuilds++,
      );
      await fillForm();
      await container.read(receiptFormControllerProvider.notifier).saveReceipt();
      await container.read(canDeleteCategoryProvider(catId).future);
      await container.read(canDeleteSubCategoryProvider(subId).future);
      expect(catBuilds, greaterThanOrEqualTo(2));
      expect(subBuilds, greaterThanOrEqualTo(2));
      expect(
        container.read(canDeleteCategoryProvider(catId)).value,
        isFalse,
      );
      expect(
        container.read(canDeleteSubCategoryProvider(subId)).value,
        isFalse,
      );
    });

    test('resolution failure → save πετυχαίνει, πύλες stale (swallow)',
        () async {
      final throwing = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          itemRepositoryProvider.overrideWithValue(const _ThrowingItemRepo()),
        ],
      );
      addTearDown(throwing.dispose);
      var supplierBuilds = 0;
      var catBuilds = 0;
      throwing.listen(
        canDeleteSupplierProvider(supplierId),
        (_, _) => supplierBuilds++,
      );
      throwing.listen(
        canDeleteCategoryProvider(catId),
        (_, _) => catBuilds++,
      );
      final supplier =
          await throwing.read(supplierRepositoryProvider).getById(supplierId);
      final form = throwing.read(receiptFormControllerProvider.notifier);
      form.setSupplier(supplier);
      form.addDraftLine(
        DraftReceiptLine(
          itemId: itemId,
          unitId: unitId,
          quantity: 2,
          priceCents: 150,
          itemName: 'Γάλα 1λ',
          unitAbbreviation: 'τεμ',
        ),
      );
      // Δεν ρίχνει — το swallow κρατά το save πράσινο.
      await form.saveReceipt();
      await throwing.read(canDeleteSupplierProvider(supplierId).future);
      // Supplier (πριν το failing lookup) ανανεώθηκε· κατηγορία έμεινε stale.
      expect(supplierBuilds, greaterThanOrEqualTo(2));
      expect(catBuilds, equals(1));
    });
  });

  group('Guard invalidation μετά από delete', () {
    test('delete → rebuild πυλών (false→true, un-grey)', () async {
      await fillForm();
      await container.read(receiptFormControllerProvider.notifier).saveReceipt();
      final receipts =
          await container.read(receiptRepositoryProvider).watchAll().first;
      expect(receipts, hasLength(1));

      var supplierBuilds = 0;
      var catBuilds = 0;
      container.listen(
        canDeleteSupplierProvider(supplierId),
        (_, _) => supplierBuilds++,
      );
      container.listen(
        canDeleteCategoryProvider(catId),
        (_, _) => catBuilds++,
      );
      final result = await container
          .read(receiptFormControllerProvider.notifier)
          .deleteReceipt(receipts.single.id);
      expect(result.ok, isTrue);
      await container.read(canDeleteSupplierProvider(supplierId).future);
      await container.read(canDeleteCategoryProvider(catId).future);
      expect(supplierBuilds, greaterThanOrEqualTo(2));
      expect(catBuilds, greaterThanOrEqualTo(2));
      expect(
        container.read(canDeleteSupplierProvider(supplierId)).value,
        isTrue,
      );
      expect(
        container.read(canDeleteCategoryProvider(catId)).value,
        isTrue,
      );
    });
  });
}
