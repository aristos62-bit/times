/// Unit tests για τα StreamProviders — Μέρος 3/3 · receipt streams.
///
/// `receiptsStreamProvider`, `recentReceiptsStreamProvider` (Φάση 3,
/// Βήμα 7), `receiptLinesStreamProvider`. Τα catalog streams ζουν στο
/// `stream_providers_test.dart` (μέρος 1/3) και τα search families στο
/// `stream_providers_search_test.dart` (μέρος 2/3).
///
/// Riverpod 3.4.3: το `.future` του StreamProvider ΔΕΝ πιάνει την πρώτη
/// εκπομπή drift stream queries → `container.listen` + `Completer` με predicate.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/data/local/app_database.dart';
import 'package:times/data/models/receipt_summary.dart';
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

  group('recentReceiptsStreamProvider (Φάση 3, Βήμα 7)', () {
    test('επιστρέφει σύνοψη: γραμμές + σύνολο + supplier από join', () async {
      final container = containerWithDb();
      final chain = await seedReceiptChain(container);
      final receiptId = await container
          .read(receiptRepositoryProvider)
          .insertReceiptWithLines(
            date: DateTime(2026, 1, 1),
            supplierId: chain.supplierId,
            lines: [
              (itemId: chain.itemId,
                  unitId: chain.unitId,
                  quantity: 2,
                  priceCents: 199),
              (itemId: chain.itemId,
                  unitId: chain.unitId,
                  quantity: 1,
                  priceCents: 50),
            ],
          );

      final rows = await waitForValue<List<ReceiptSummary>>(
        (listen) => container.listen(recentReceiptsStreamProvider, listen),
        (v) => v.isNotEmpty,
      );
      expect(rows.first.id, receiptId);
      expect(rows.first.supplierName, 'Μάρκος');
      expect(rows.first.lineCount, 2);
      expect(rows.first.totalCents, 199 * 2 + 50);
    });

    test('κενή βάση → []', () async {
      final container = containerWithDb();

      final rows = await waitForValue<List<ReceiptSummary>>(
        (listen) => container.listen(recentReceiptsStreamProvider, listen),
        (v) => v.isEmpty,
      );
      expect(rows, isEmpty);
    });

    test('live: νέα απόδειξη εμφανίζεται αυτόματα (auto-refresh §2.2:212)',
        () async {
      final container = containerWithDb();
      final chain = await seedReceiptChain(container);
      final resultsFuture = waitForValue<List<ReceiptSummary>>(
        (listen) => container.listen(recentReceiptsStreamProvider, listen),
        (v) => v.any((s) => s.lineCount == 1),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await container
          .read(receiptRepositoryProvider)
          .insertReceiptWithLines(
            date: DateTime(2026, 1, 1),
            supplierId: chain.supplierId,
            lines: [
              (itemId: chain.itemId,
                  unitId: chain.unitId,
                  quantity: 1,
                  priceCents: 100),
            ],
          );

      final rows = await resultsFuture;
      expect(rows.single.lineCount, 1);
      expect(rows.single.totalCents, 100);
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