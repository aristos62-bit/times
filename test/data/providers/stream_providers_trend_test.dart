/// Unit tests για τους trend providers (§2.1 · 28-09-2026 — 6ο γράφημα).
///
/// `itemTrendSearchProvider` (LIKE, κενό → []) + `itemTrendProvider`
/// (φίλτρο κλειδωμένης μονάδας + other-count + cap νεότερα + error mapping).
/// Πραγματική in-memory Drift βάση · Riverpod 3 listen+Completer (όχι `.future`).
library;

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/core/constants/app_constants.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/item_group_dao.dart';
import 'package:times/data/local/daos/receipt_dao.dart';
import 'package:times/data/local/daos/receipt_line_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/supplier_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/models/chart_totals.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/providers/stream_providers.dart';
import 'package:times/data/repositories/receipt_repository_impl.dart';

import '../local/helpers/in_memory_db.dart';

/// DAO double — raw σφάλμα στο history για δοκιμή stream mapping.
class _FailingHistoryLineDao extends ReceiptLineDao {
  _FailingHistoryLineDao(super.db);

  @override
  Stream<List<ItemPricePoint>> watchItemHistory({
    required int itemId,
    required DateTime from,
    required DateTime to,
  }) =>
      Stream.error(SqliteException(extendedResultCode: 1, message: 'test'));
}

/// Ακούει μέχρι μια εκπομπή να ικανοποιήσει το [predicate] (5s fail-fast).
Future<ItemTrendData> waitForTrendValue(
  void Function(
    void Function(
      AsyncValue<ItemTrendData>? previous,
      AsyncValue<ItemTrendData> next,
    ) onEmission,
  ) subscribe,
  bool Function(ItemTrendData value) predicate,
) {
  final completer = Completer<ItemTrendData>();
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

  late int itemId;
  late int kiloId;
  late int pieceId;
  late int supplierId;

  final from = DateTime(2026, 1, 1);
  final to = DateTime(2026, 2, 1);

  setUp(() async {
    db = inMemoryDb();
    kiloId = await UnitDao(db).insert(
      name: 'Κιλό',
      abbreviation: 'κιλ',
      allowsDecimal: true,
    );
    pieceId = await UnitDao(db).insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
    final categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    final subId = await SubCategoryDao(db)
        .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
    final groupId =
        await ItemGroupDao(db).insert(subCategoryId: subId, name: 'Φρέσκα');
    itemId = await ItemDao(db).insert(
      itemGroupId: groupId,
      name: 'Γάλα',
      defaultUnitId: kiloId,
    );
    supplierId = await SupplierDao(db).insert(name: 'Μάρκος');
  });

  tearDown(() async => await db.close());

  ProviderContainer containerWithDb() => ProviderContainer.test(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );

  Future<void> seedLine({
    required DateTime date,
    required int unitId,
    int priceCents = 250,
    int discountCents = 50,
  }) async {
    final receiptId = await ReceiptDao(db).insert(
      date: date,
      supplierId: supplierId,
    );
    await ReceiptLineDao(db).insert(
      receiptId: receiptId,
      itemId: itemId,
      unitId: unitId,
      quantity: 1,
      priceCents: priceCents,
      discountCents: discountCents,
    );
  }

  group('itemTrendSearchProvider (§2.1 · 28-09-2026)', () {
    test('query βρίσκει (τόνοι/κεφαλαία αδιάφορα)', () async {
      final container = containerWithDb();
      // Εύρημα search tests: το `.future` ΔΕΝ πιάνει την πρώτη εκπομπή
      // drift queries → listen + Completer.
      final completer = Completer<List<Item>>();
      container.listen(
        itemTrendSearchProvider('γαλα'),
        (previous, next) {
          if (next.hasValue && !completer.isCompleted) {
            completer.complete(next.requireValue);
          }
        },
      );
      final results =
          await completer.future.timeout(const Duration(seconds: 5));
      expect(results.map((i) => i.name), contains('Γάλα'));
    });

    test('κενό query → [] χωρίς DB access', () async {
      final container = containerWithDb();
      Future<List<Item>> readEmpty(String query) {
        final completer = Completer<List<Item>>();
        container.listen(
          itemTrendSearchProvider(query),
          (previous, next) {
            if (next.hasValue && !completer.isCompleted) {
              completer.complete(next.requireValue);
            }
          },
        );
        return completer.future.timeout(const Duration(seconds: 5));
      }

      expect(await readEmpty(''), isEmpty);
      expect(await readEmpty('   '), isEmpty);
    });
  });

  group('itemTrendProvider (§2.1 · 28-09-2026)', () {
    test('points καθαρής τιμής + otherUnitCount 0', () async {
      await seedLine(date: DateTime(2026, 1, 5), unitId: kiloId);
      await seedLine(
        date: DateTime(2026, 1, 6),
        unitId: kiloId,
        priceCents: 300,
        discountCents: 0,
      );
      final container = containerWithDb();
      final data = await waitForTrendValue(
        (listen) => container.listen(
          itemTrendProvider(
            (itemId: itemId, unitId: kiloId, from: from, to: to),
          ),
          listen,
        ),
        (value) => value.points.isNotEmpty,
      );
      expect(
        [for (final p in data.points) p.netPriceCents],
        [200, 300],
      );
      expect(data.otherUnitCount, 0);
    });

    test('ξένες μονάδες μετριούνται, δεν σχεδιάζονται (Q2)', () async {
      await seedLine(date: DateTime(2026, 1, 5), unitId: kiloId);
      await seedLine(date: DateTime(2026, 1, 6), unitId: pieceId);
      await seedLine(date: DateTime(2026, 1, 7), unitId: pieceId);
      final container = containerWithDb();
      final data = await waitForTrendValue(
        (listen) => container.listen(
          itemTrendProvider(
            (itemId: itemId, unitId: kiloId, from: from, to: to),
          ),
          listen,
        ),
        (value) => value.points.isNotEmpty,
      );
      expect(data.points, hasLength(1));
      expect(data.otherUnitCount, 2);
    });

    test('κενή περίοδος → κενά points (όχι loading για πάντα)', () async {
      await seedLine(date: DateTime(2026, 1, 5), unitId: kiloId);
      final container = containerWithDb();
      final data = await waitForTrendValue(
        (listen) => container.listen(
          itemTrendProvider(
            (
              itemId: itemId,
              unitId: kiloId,
              from: DateTime(2025, 1, 1),
              to: DateTime(2025, 2, 1),
            ),
          ),
          listen,
        ),
        (_) => true,
      );
      expect(data.points, isEmpty);
      expect(data.otherUnitCount, 0);
    });

    test('cap: >trendMaxPoints → τα 200 νεότερα (Q4)', () async {
      for (var i = 0; i < AppConstants.trendMaxPoints + 5; i++) {
        await seedLine(
          date: DateTime(2026, 1, 1).add(Duration(days: i)),
          unitId: kiloId,
          priceCents: 100 + i,
        );
      }
      final container = containerWithDb();
      final data = await waitForTrendValue(
        (listen) => container.listen(
          itemTrendProvider(
            (
              itemId: itemId,
              unitId: kiloId,
              from: DateTime(2026, 1, 1),
              to: DateTime(2026, 8, 1),
            ),
          ),
          listen,
        ),
        (value) => value.points.length == AppConstants.trendMaxPoints,
      );
      expect(data.points, hasLength(AppConstants.trendMaxPoints));
      // Κρατήθηκαν οι νεότερες (net = price−50): 55 … 254.
      expect(data.points.first.netPriceCents, 55);
      expect(data.points.last.netPriceCents, 254);
      expect(data.otherUnitCount, 0);
    });

    test('raw σφάλμα → DataLoadException (listen+completer, όχι .future)',
        () async {
      final container = ProviderContainer.test(
        overrides: [
          receiptRepositoryProvider.overrideWithValue(
            ReceiptRepositoryImpl(ReceiptDao(db), _FailingHistoryLineDao(db)),
          ),
        ],
      );
      addTearDown(container.dispose);
      // Εύρημα Βήματος 3 (Riverpod 3 retry): το `.future` δεν ολοκληρώνεται
      // σε error-path — ακρόαση με completer στο `hasError`.
      final completer = Completer<Object?>();
      container.listen(
        itemTrendProvider(
          (itemId: itemId, unitId: kiloId, from: from, to: to),
        ),
        (previous, next) {
          if (next.hasError && !completer.isCompleted) {
            completer.complete(next.error);
          }
        },
      );
      final error =
          await completer.future.timeout(const Duration(seconds: 5));
      expect(error, isA<DataLoadException>());
    });
  });
}
