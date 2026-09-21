/// Unit tests για τα StreamProviders — Μέρος 2/3 · search families.
///
/// supplierSearchProvider (Φάση 3 Βήμα 3), categorySearchProvider,
/// subCategorySearchProvider, unitSearchProvider (Φάση 3 Βήμα 4/5).
/// Τα plain streams ζουν στο `stream_providers_test.dart` (μέρος 1/3)
/// και τα receipt streams στο `stream_providers_receipts_test.dart` (μέρος 3/3).
///
/// Riverpod 3.4.3: το `.future` του StreamProvider ΔΕΝ πιάνει την πρώτη
/// εκπομπή drift stream queries → `container.listen` + `Completer` με predicate.
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
  ProviderContainer containerWithDb() {
    final db = inMemoryDb();
    addTearDown(db.close);
    return ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  }

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
}