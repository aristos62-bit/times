/// Unit tests για τα StreamProviders (stream_providers.dart) — Φάση 2, Βήμα 3.
///
/// Επαληθεύει ότι κάθε `xxxStreamProvider` εκπέμπει τα δεδομένα από το
/// αντίστοιχο repository (seeding μέσω repositories, ίδιο idiom με τα
/// repository impl tests) και τα `.family` φιλτράρουν σωστά. Loading/error
/// state διαχειρίζεται το UI (AsyncValueView, Φάση 3) — εδώ μόνο data.
///
/// Δύο αναγκαίες τεχνικές επιλογές (Riverpod 3.4.3):
///   * Το `.future` του StreamProvider ΔΕΝ πιάνει την πρώτη εκπομπή των
///     drift stream queries (αποδεδειγμένο empirικά — hang μέχρι timeout).
///     Αντί αυτού: `container.listen` + `Completer` με predicate.
///   * Το `ProviderListenable` είναι internal (annotation `@publicInMisc`),
///     δεν είναι ορατό στα tests → το helper παίρνει το provider μέσω
///     callback subscribe. Ο T δίνεται ΡΗΤΑ σε κάθε κλήση (περιορισμός
///     inference του Dart μεταξύ κλεισίματος subscribe και predicate).
///
/// `ProviderContainer.test()` διαθέτει το container αυτόματα (Riverpod 3.x)·
/// το override `overrideWithValue` προσπερνά το `onDispose` → χειροκίνητο
/// `addTearDown(db.close)`.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_constants.dart';
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
  // ─── Helpers ───────────────────────────────────────────────────────────────

  ProviderContainer containerWithDb() {
    final db = inMemoryDb();
    addTearDown(db.close);
    return ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  }

  /// Πλήρης αλυσίδα seed για αποδείξεις (unit → category → sub → items →
  /// supplier) — επιστρέφει τα id που χρειάζονται τα receipt tests.
  Future<({int supplierId, int itemId, int unitId})> seedReceiptChain(
    ProviderContainer container,
  ) async {
    final unitId = await container.read(unitRepositoryProvider).insert(
          name: 'Τεμάχιο',
          abbreviation: 'τεμ',
        );
    final categoryId = await container
        .read(categoryRepositoryProvider)
        .insert(name: 'ΤΡΟΦΙΜΑ');
    final subId = await container
        .read(subCategoryRepositoryProvider)
        .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
    final itemId = await container
        .read(itemRepositoryProvider)
        .insert(subCategoryId: subId, name: 'Γάλα');
    final supplierId =
        await container.read(supplierRepositoryProvider).insert(name: 'Μάρκος');
    return (supplierId: supplierId, itemId: itemId, unitId: unitId);
  }

  // ─── Plain stream providers ────────────────────────────────────────────────

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

  group('supplierSearchProvider (family · Φάση 3 Βήμα 3)', () {
    test('κενό query → άμεσα [] (χωρίς DB access)', () async {
      final container = containerWithDb();

      final rows = await waitForValue<List<Supplier>>(
        (listen) => container.listen(supplierSearchProvider(''), listen),
        (v) => v.isEmpty,
      );
      expect(rows, isEmpty);
    });

    test('LIKE match από RAW query — κανονικοποίηση εσωτερικά', () async {
      final container = containerWithDb();
      await container.read(supplierRepositoryProvider).insert(name: 'Μάρκος');
      await container
          .read(supplierRepositoryProvider)
          .insert(name: 'Μαρκοπούλου');
      await container.read(supplierRepositoryProvider).insert(name: 'Καφενείο');

      // Το key είναι RAW: κεφαλαία + τόνος κανονικοποιούνται εδώ. Το
      // «ΜΆΡΚΟ» → «μαρκο» ταιριάζει σε «Μάρκος» (μαρκοσ) ΚΑΙ «Μαρκοπούλου».
      final rows = await waitForValue<List<Supplier>>(
        (listen) => container.listen(supplierSearchProvider('ΜΆΡΚΟ'), listen),
        (v) => v.length == 2,
      );
      expect(
        rows.map((s) => s.name),
        containsAll(['Μάρκος', 'Μαρκοπούλου']),
      );
    });

    test('καμία αντιστοιχία → [] (όχι error)', () async {
      final container = containerWithDb();
      await container.read(supplierRepositoryProvider).insert(name: 'Μάρκος');

      final rows = await waitForValue<List<Supplier>>(
        (listen) => container.listen(supplierSearchProvider('ζζζ'), listen),
        (v) => v.isEmpty,
      );
      expect(rows, isEmpty);
    });

    test('όριο AppConstants.searchResultsLimit (15)', () async {
      final container = containerWithDb();
      for (var i = 1; i <= 20; i++) {
        await container.read(supplierRepositoryProvider).insert(name: 'Μ αρ $i');
      }

      final rows = await waitForValue<List<Supplier>>(
        (listen) => container.listen(supplierSearchProvider('μ αρ'), listen),
        (v) => v.length == AppConstants.searchResultsLimit,
      );
      expect(rows.length, AppConstants.searchResultsLimit);
    });

    test('live: insert προμηθευτή εμφανίζεται στα αποτελέσματα (real-time)',
        () async {
      final container = containerWithDb();
      // Ξεκινά η ακρόαση· το insert επαν-εκπέμπει το ζωντανό stream.
      final resultsFuture = waitForValue<List<Supplier>>(
        (listen) => container.listen(supplierSearchProvider('lidl'), listen),
        (v) => v.any((s) => s.name == 'Lidl'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await container.read(supplierRepositoryProvider).insert(name: 'Lidl');

      final rows = await resultsFuture;
      expect(rows.map((s) => s.name), contains('Lidl'));
    });
  });

  group('receiptsStreamProvider', () {
    test('εκπέμπει τις αποδείξεις νεότερες πρώτα', () async {
      final container = containerWithDb();
      final chain = await seedReceiptChain(container);
      await container.read(receiptRepositoryProvider).insert(
            date: DateTime(2026, 1, 1),
            supplierId: chain.supplierId,
          );
      final later = await container.read(receiptRepositoryProvider).insert(
            date: DateTime(2026, 2, 1),
            supplierId: chain.supplierId,
          );

      final rows = await waitForValue<List<Receipt>>(
        (listen) => container.listen(receiptsStreamProvider, listen),
        (v) => v.length == 2,
      );
      expect(rows.first.id, later);
    });
  });

  // ─── Family providers ──────────────────────────────────────────────────────

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

  group('receiptLinesStreamProvider (family)', () {
    test('επιστρέφει τις γραμμές της συγκεκριμένης απόδειξης', () async {
      final container = containerWithDb();
      final chain = await seedReceiptChain(container);
      final receiptId = await container
          .read(receiptRepositoryProvider)
          .insertReceiptWithLines(
            date: DateTime(2026, 1, 1),
            supplierId: chain.supplierId,
            lines: [
              (itemId: chain.itemId, unitId: chain.unitId, quantity: 2, priceCents: 199),
            ],
          );

      final rows = await waitForValue<List<ReceiptLine>>(
        (listen) => container.listen(receiptLinesStreamProvider(receiptId), listen),
        (v) => v.length == 1,
      );
      expect(rows.first.itemId, chain.itemId);
      expect(rows.first.lineTotalCents, 398);
    });

    test('απόδειξη χωρίς γραμμές → []', () async {
      final container = containerWithDb();
      final chain = await seedReceiptChain(container);
      final receiptId = await container
          .read(receiptRepositoryProvider)
          .insert(date: DateTime(2026, 1, 1), supplierId: chain.supplierId);

      final rows = await waitForValue<List<ReceiptLine>>(
        (listen) => container.listen(receiptLinesStreamProvider(receiptId), listen),
        (v) => v.isEmpty,
      );
      expect(rows, isEmpty);
    });
  });
}