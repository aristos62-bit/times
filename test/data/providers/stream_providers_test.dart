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

  // ─── Item search families (Φάση 3 Βήμα 4) ──────────────────────────────

  group('categorySearchProvider (family · Φάση 3 Βήμα 4)', () {
    test('κενό query → άμεσα [] (χωρίς DB access)', () async {
      final container = containerWithDb();

      final rows = await waitForValue<List<Category>>(
        (listen) => container.listen(categorySearchProvider(''), listen),
        (v) => v.isEmpty,
      );
      expect(rows, isEmpty);
    });

    test('in-memory filter: ταιριάζει μόνο τις κατηγορίες με match',
        () async {
      final container = containerWithDb();
      await container
          .read(categoryRepositoryProvider)
          .insert(name: 'ΤΡΟΦΙΜΑ');
      await container
          .read(categoryRepositoryProvider)
          .insert(name: 'ΡΟΥΧΑ');

      final rows = await waitForValue<List<Category>>(
        (listen) =>
            container.listen(categorySearchProvider('ροφ'), listen),
        (v) => v.length == 1,
      );
      expect(rows.map((c) => c.name), contains('ΤΡΟΦΙΜΑ'));
    });

    test('case/tone-insensitive: ΓΑΛΑ ταιριάζει Γαλακτοκομικά', () async {
      final container = containerWithDb();
      await container
          .read(categoryRepositoryProvider)
          .insert(name: 'Γαλακτοκομικά');

      final rows = await waitForValue<List<Category>>(
        (listen) =>
            container.listen(categorySearchProvider('ΓΑΛΑ'), listen),
        (v) => v.isNotEmpty,
      );
      expect(rows.map((c) => c.name), contains('Γαλακτοκομικά'));
    });
  });

  group('subCategorySearchProvider (family · Φάση 3 Βήμα 4)', () {
    test('κενό query → άμεσα [] (χωρίς DB access)', () async {
      final container = containerWithDb();

      final rows = await waitForValue<List<SubCategory>>(
        (listen) => container.listen(
          subCategorySearchProvider((categoryId: 1, query: '')),
          listen,
        ),
        (v) => v.isEmpty,
      );
      expect(rows, isEmpty);
    });

    test('in-memory filter ανά categoryId + query', () async {
      final container = containerWithDb();
      final catA = await container
          .read(categoryRepositoryProvider)
          .insert(name: 'ΤΡΟΦΙΜΑ');
      final catB = await container
          .read(categoryRepositoryProvider)
          .insert(name: 'ΡΟΥΧΑ');
      await container
          .read(subCategoryRepositoryProvider)
          .insert(categoryId: catA, name: 'Γαλακτοκομικά');
      await container
          .read(subCategoryRepositoryProvider)
          .insert(categoryId: catA, name: 'Κρέας');
      await container
          .read(subCategoryRepositoryProvider)
          .insert(categoryId: catB, name: 'Παντελόνια');

      final rows = await waitForValue<List<SubCategory>>(
        (listen) => container.listen(
          subCategorySearchProvider((categoryId: catA, query: 'κρε')),
          listen,
        ),
        (v) => v.length == 1,
      );
      expect(rows.map((s) => s.name), contains('Κρέας'));
    });
  });

  group('unitSearchProvider (family · Φάση 3 Βήμα 5)', () {
    test('κενό query → άμεσα [] (χωρίς DB access)', () async {
      final container = containerWithDb();

      final rows = await waitForValue<List<Unit>>(
        (listen) => container.listen(unitSearchProvider(''), listen),
        (v) => v.isEmpty,
      );
      expect(rows, isEmpty);
    });

    test('in-memory filter: case/tone-insensitive match', () async {
      final container = containerWithDb();
      await container
          .read(unitRepositoryProvider)
          .insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
      await container
          .read(unitRepositoryProvider)
          .insert(name: 'Κιλό', abbreviation: 'κιλ');

      final rows = await waitForValue<List<Unit>>(
        (listen) => container.listen(unitSearchProvider('κιλ'), listen),
        (v) => v.length == 1,
      );
      expect(rows.map((u) => u.name), contains('Κιλό'));

      final toneRows = await waitForValue<List<Unit>>(
        (listen) => container.listen(unitSearchProvider('ΚΙΛ'), listen),
        (v) => v.length == 1,
      );
      expect(toneRows.map((u) => u.name), contains('Κιλό'));
    });

    test('match και στη συντομογραφία (Β5ε-3) · χωρίς διπλότυπα', () async {
      final container = containerWithDb();
      final repo = container.read(unitRepositoryProvider);
      await repo.insert(name: 'Λίτρο', abbreviation: 'λτ');
      await repo.insert(name: 'Κιλό', abbreviation: 'κιλ');
      await repo.insert(name: 'Γραμμάριο', abbreviation: 'γρ');

      // «ΛΤ» υπάρχει ΜΟΝΟ στη συντομογραφία του Λίτρο (όχι στο όνομα).
      final abbr = await waitForValue<List<Unit>>(
            (listen) => container.listen(unitSearchProvider('ΛΤ'), listen),
            (v) => v.length == 1,
      );
      expect(abbr.map((u) => u.name), ['Λίτρο']);

      // «γρ» ταιριάζει και στο όνομα ΚΑΙ στη συντομογραφία → 1 γραμμή.
      final both = await waitForValue<List<Unit>>(
            (listen) => container.listen(unitSearchProvider('γρ'), listen),
            (v) => v.isNotEmpty,
      );
      expect(both.map((u) => u.name), ['Γραμμάριο']);
    });

    test('live: νέα μονάδα εμφανίζεται στα αποτελέσματα (real-time)', () async {
      final container = containerWithDb();
      final resultsFuture = waitForValue<List<Unit>>(
        (listen) => container.listen(unitSearchProvider('δωδ'), listen),
        (v) => v.any((u) => u.name == 'Δωδεκάδα'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await container
          .read(unitRepositoryProvider)
          .insert(name: 'Δωδεκάδα', abbreviation: 'δωδ');

      final rows = await resultsFuture;
      expect(rows.map((u) => u.name), contains('Δωδεκάδα'));
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