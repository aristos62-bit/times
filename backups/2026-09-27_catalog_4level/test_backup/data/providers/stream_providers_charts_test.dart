/// Unit tests για τα chart StreamProviders — Μέρος 4/4 · γραφήματα (§2.1).
///
/// `supplier/category/subCategory/topItemsTotalsProvider` (Φάση 5, Βήμα 3):
/// emit τιμών από in-memory DB + slice top-N/«Λοιπά» + error mapping.
/// Τα catalog/search/receipt streams ζουν στα μέρη 1-3.
///
/// Riverpod 3.4.3: `container.listen` + `Completer` με predicate (όχι `.future`).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/receipt_dao.dart';
import 'package:times/data/local/daos/receipt_line_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/supplier_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/models/chart_totals.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/providers/stream_providers.dart';

import '../local/helpers/in_memory_db.dart';

/// Ακούει μέχρι μια εκπομπή να ικανοποιήσει το [predicate]. Fails fast (5s) —
/// τοπικό αντίγραφο του `waitForValue` (τα test αρχεία είναι ανεξάρτητα,
/// pattern μέρους 3/3).
Future<List<ChartSlice>> waitForChartValue(
  void Function(
    void Function(
      AsyncValue<List<ChartSlice>>? previous,
      AsyncValue<List<ChartSlice>> next,
    ) onEmission,
  ) subscribe,
  bool Function(List<ChartSlice> value) predicate,
) {
  final completer = Completer<List<ChartSlice>>();
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
  late dynamic db;

  setUp(() async {
    db = inMemoryDb();
  });

  tearDown(() async => await db.close());

  ProviderContainer containerWithDb() => ProviderContainer.test(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );

  /// Πλήρης αλυσίδα seed + 1 απόδειξη 2 τεμαχίων × 199.
  Future<ChartQuery> seedMonth() async {
    final unitId = await UnitDao(db).insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
    final categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    final subId = await SubCategoryDao(db)
        .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
    final itemId = await ItemDao(db).insert(subCategoryId: subId, name: 'Γάλα');
    final supplierId = await SupplierDao(db).insert(name: 'Μάρκος');
    final receiptId = await ReceiptDao(db).insert(
      date: DateTime(2026, 1, 5),
      supplierId: supplierId,
    );
    await ReceiptLineDao(db).insert(
      receiptId: receiptId,
      itemId: itemId,
      unitId: unitId,
      quantity: 2,
      priceCents: 199,
    );
    return (from: DateTime(2026, 1, 1), to: DateTime(2026, 2, 1));
  }

  group('chart totals providers', () {
    test('supplierTotalsProvider — φέτα με σύνολο + label', () async {
      final query = await seedMonth();
      final container = containerWithDb();
      final slices = await waitForChartValue(
        (listen) => container.listen(supplierTotalsProvider(query), listen),
        (value) => value.isNotEmpty,
      );
      expect(slices.single.label, 'Μάρκος');
      expect(slices.single.totalCents, 199 * 2);
    });

    test('categoryTotalsProvider — φέτα κατηγορίας', () async {
      final query = await seedMonth();
      final container = containerWithDb();
      final slices = await waitForChartValue(
        (listen) => container.listen(categoryTotalsProvider(query), listen),
        (value) => value.isNotEmpty,
      );
      expect(slices.single.label, 'ΤΡΟΦΙΜΑ');
      expect(slices.single.totalCents, 199 * 2);
    });

    test('subCategoryTotalsProvider — φέτα υποκατηγορίας', () async {
      final query = await seedMonth();
      final container = containerWithDb();
      final slices = await waitForChartValue(
        (listen) =>
            container.listen(subCategoryTotalsProvider(query), listen),
        (value) => value.isNotEmpty,
      );
      expect(slices.single.label, 'Γαλακτοκομικά');
    });

    test('topItemsTotalsProvider — φέτα είδους', () async {
      final query = await seedMonth();
      final container = containerWithDb();
      final slices = await waitForChartValue(
        (listen) => container.listen(topItemsTotalsProvider(query), listen),
        (value) => value.isNotEmpty,
      );
      expect(slices.single.label, 'Γάλα');
      expect(slices.single.totalCents, 199 * 2);
    });

    test('κενή περίοδος → [] (όχι loading για πάντα)', () async {
      await seedMonth();
      final container = containerWithDb();
      final emptyQuery = (from: DateTime(2025, 1, 1), to: DateTime(2025, 2, 1));
      final slices = await waitForChartValue(
        (listen) => container.listen(supplierTotalsProvider(emptyQuery), listen),
        (_) => true,
      );
      expect(slices, isEmpty);
    });

    test('slice: 10 προμηθευτές → 8 + «Λοιπά» (SPoT pieMaxSlices)', () async {
      final unitId =
          await UnitDao(db).insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
      final categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
      final subId = await SubCategoryDao(db)
          .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
      final itemId = await ItemDao(db).insert(subCategoryId: subId, name: 'Γάλα');
      for (var i = 0; i < 10; i++) {
        final supplierId =
            await SupplierDao(db).insert(name: 'Προμηθευτής $i');
        final receiptId = await ReceiptDao(db).insert(
          date: DateTime(2026, 1, 5),
          supplierId: supplierId,
        );
        await ReceiptLineDao(db).insert(
          receiptId: receiptId,
          itemId: itemId,
          unitId: unitId,
          quantity: 1,
          priceCents: (i + 1) * 100,
        );
      }
      final query = (from: DateTime(2026, 1, 1), to: DateTime(2026, 2, 1));
      final container = containerWithDb();
      final slices = await waitForChartValue(
        (listen) => container.listen(supplierTotalsProvider(query), listen),
        (value) => value.length == 9,
      );
      expect(slices.length, 8 + 1);
      expect(slices.last.label, 'Λοιπά');
      // Top-8: 1000+900+...+300 = 5200 · Λοιπά: 200+100 = 300.
      expect(slices.first.totalCents, 1000);
      expect(slices.last.totalCents, 300);
    });
  });
}
