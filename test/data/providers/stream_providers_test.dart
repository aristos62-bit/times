/// Unit tests για τα StreamProviders (stream_providers.dart) — Φάση 2, Βήμα 3.
///
/// Μέρος 1/3 — catalog streams + family list: κατηγορίες, υποκατηγορίες,
/// μονάδες, είδη, προμηθευτές + `subCategoriesByCategoryProvider`. Τα
/// search families ζουν στο `stream_providers_search_test.dart` και τα
/// receipts στο `stream_providers_receipts_test.dart`.
///
/// Riverpod 3.4.3: το `.future` του StreamProvider ΔΕΝ πιάνει την πρώτη
/// εκπομπή drift stream queries (hang μέχρι timeout) → `container.listen` +
/// `Completer` με predicate (επιλεκτική ακρόαση).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/data/local/app_database.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/providers/stream_providers.dart';

import '../local/helpers/in_memory_db.dart';

/// Ακούει μέσω του [subscribe] μέχρι μια εκπομπή να ικανοποιήσει το
/// [predicate] και επιστρέφει τη λίστα. Fails fast (5s) αντί για 30s timeout.
Future<T> waitForValue<T>(
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

  group('categoryStreamProvider', () {
    test('αρχικά [] · μετά insert εκπέμπει την κατηγορία (real-time)',
        () async {
      final container = containerWithDb();

      expect(
        await waitForValue<List<Category>>(
          (listen) => container.listen(categoryStreamProvider, listen),
          (v) => v.isEmpty,
        ),
        isEmpty,
      );

      await container
          .read(categoryRepositoryProvider)
          .insert(name: 'ΤΡΟΦΙΜΑ');
      final rows = await waitForValue<List<Category>>(
        (listen) => container.listen(categoryStreamProvider, listen),
        (v) => v.any((r) => r.name == 'ΤΡΟΦΙΜΑ'),
      );
      expect(rows.map((r) => r.name), contains('ΤΡΟΦΙΜΑ'));
    });
  });

  group('subCategoriesStreamProvider', () {
    test('εκπέμπει όλες τις υποκατηγορίες αλφαβητικά', () async {
      final container = containerWithDb();
      final categoryId = await container
          .read(categoryRepositoryProvider)
          .insert(name: 'ΤΡΟΦΙΜΑ');
      await container
          .read(subCategoryRepositoryProvider)
          .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
      await container
          .read(subCategoryRepositoryProvider)
          .insert(categoryId: categoryId, name: 'Κρέας');

      final rows = await waitForValue<List<SubCategory>>(
        (listen) => container.listen(subCategoriesStreamProvider, listen),
        (v) => v.length == 2,
      );
      expect(rows.map((r) => r.name), ['Γαλακτοκομικά', 'Κρέας']);
    });
  });

  group('unitsStreamProvider', () {
    test('εκπέμπει τις μονάδες', () async {
      final container = containerWithDb();
      await container
          .read(unitRepositoryProvider)
          .insert(name: 'Τεμάχιο', abbreviation: 'τεμ');

      final rows = await waitForValue<List<Unit>>(
        (listen) => container.listen(unitsStreamProvider, listen),
        (v) => v.any((r) => r.name == 'Τεμάχιο'),
      );
      expect(rows.map((r) => r.name), contains('Τεμάχιο'));
    });
  });

  group('itemsStreamProvider', () {
    test('εκπέμπει τα είδη (με σειρά normalizedName)', () async {
      final container = containerWithDb();
      final categoryId = await container
          .read(categoryRepositoryProvider)
          .insert(name: 'ΤΡΟΦΙΜΑ');
      final subId = await container
          .read(subCategoryRepositoryProvider)
          .insert(categoryId: categoryId, name: 'Φρούτα');
      await container
          .read(itemRepositoryProvider)
          .insert(subCategoryId: subId, name: 'Μήλο');

      final rows = await waitForValue<List<Item>>(
        (listen) => container.listen(itemsStreamProvider, listen),
        (v) => v.any((r) => r.name == 'Μήλο'),
      );
      expect(rows.map((r) => r.name), contains('Μήλο'));
    });
  });

  group('suppliersStreamProvider', () {
    test('εκπέμπει τους προμηθευτές', () async {
      final container = containerWithDb();
      await container.read(supplierRepositoryProvider).insert(name: 'Μάρκος');

      final rows = await waitForValue<List<Supplier>>(
        (listen) => container.listen(suppliersStreamProvider, listen),
        (v) => v.any((r) => r.name == 'Μάρκος'),
      );
      expect(rows.map((r) => r.name), contains('Μάρκος'));
    });
  });

  group('subCategoriesByCategoryProvider (family)', () {
    test('επιστρέφει ΜΟΝΟ τις υποκατηγορίες της κατηγορίας', () async {
      final container = containerWithDb();
      final catA = await container
          .read(categoryRepositoryProvider)
          .insert(name: 'Φρούτα');
      final catB = await container
          .read(categoryRepositoryProvider)
          .insert(name: 'Λαχανικά');
      await container
          .read(subCategoryRepositoryProvider)
          .insert(categoryId: catA, name: 'Μήλα');
      await container
          .read(subCategoryRepositoryProvider)
          .insert(categoryId: catB, name: 'Μαρούλι');

      final rows = await waitForValue<List<SubCategory>>(
        (listen) =>
            container.listen(subCategoriesByCategoryProvider(catA), listen),
        (v) => v.length == 1,
      );
      expect(rows.map((r) => r.name), ['Μήλα']);
    });
  });
}