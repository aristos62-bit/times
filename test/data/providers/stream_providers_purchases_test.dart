/// Unit tests για το purchases provider (§2.3 · 29-09-2026 — 2η ανάλυση).
///
/// `periodPurchasesProvider` (autoDispose family): τιμές + cap/truncated +
/// κενό + error mapping. Πραγματική in-memory Drift βάση · Riverpod 3
/// listen+Completer (όχι `.future` — εύρημα search tests).
library;

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_constants.dart';
import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/data/local/daos/category_dao.dart';
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

/// DAO double — raw σφάλμα στο purchases για δοκιμή stream mapping.
class _FailingPurchasesLineDao extends ReceiptLineDao {
  _FailingPurchasesLineDao(super.db);

  @override
  Stream<List<PeriodPurchaseRow>> watchPeriodPurchases({
    required DateTime from,
    required DateTime to,
    required PurchasesSort sort,
  }) =>
      Stream.error(SqliteException(extendedResultCode: 1, message: 'test'));
}

/// Ακούει μέχρι μια εκπομπή να ικανοποιήσει το [predicate] (5s fail-fast).
Future<PeriodPurchasesData> waitForPurchasesValue(
  void Function(
    void Function(
      AsyncValue<PeriodPurchasesData>? previous,
      AsyncValue<PeriodPurchasesData> next,
    ) onEmission,
  ) subscribe,
  bool Function(PeriodPurchasesData value) predicate,
) {
  final completer = Completer<PeriodPurchasesData>();
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
  late int supplierId;

  setUp(() async {
    db = inMemoryDb();
    kiloId = await UnitDao(db).insert(
      name: 'Κιλό',
      abbreviation: 'κιλ',
      allowsDecimal: true,
    );
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

  Future<void> seedLine({required DateTime date, int priceCents = 250}) async {
    final receiptId = await ReceiptDao(db).insert(
      date: date,
      supplierId: supplierId,
    );
    await ReceiptLineDao(db).insert(
      receiptId: receiptId,
      itemId: itemId,
      unitId: kiloId,
      quantity: 1,
      priceCents: priceCents,
      discountCents: 0,
    );
  }

  PeriodPurchasesQuery query({
    DateTime? from,
    DateTime? to,
    PurchasesSort sort = PurchasesSort.dateAsc,
  }) =>
      (
        from: from ?? DateTime(2026, 1, 1),
        to: to ?? DateTime(2026, 2, 1),
        sort: sort,
      );

  group('periodPurchasesProvider (§2.3 · 29-09-2026)', () {
    test('γραμμές + truncated=false', () async {
      await seedLine(date: DateTime(2026, 1, 5));
      final container = containerWithDb();
      final data = await waitForPurchasesValue(
        (listen) => container.listen(
          periodPurchasesProvider(query()),
          listen,
        ),
        (value) => value.rows.isNotEmpty,
      );
      expect(data.rows.single.itemName, 'Γάλα');
      expect(data.rows.single.categoryName, 'ΤΡΟΦΙΜΑ');
      expect(data.truncated, isFalse);
    });

    test('κενή περίοδος → κενές γραμμές', () async {
      await seedLine(date: DateTime(2026, 1, 5));
      final container = containerWithDb();
      final data = await waitForPurchasesValue(
        (listen) => container.listen(
          periodPurchasesProvider(
            query(from: DateTime(2025, 1, 1), to: DateTime(2025, 2, 1)),
          ),
          listen,
        ),
        (_) => true,
      );
      expect(data.rows, isEmpty);
      expect(data.truncated, isFalse);
    });

    test('cap: >statsTableMaxRows → νεότερες + truncated', () async {
      for (var i = 0; i < AppConstants.statsTableMaxRows + 5; i++) {
        await seedLine(
          date: DateTime(2026, 1, 1).add(Duration(days: i)),
          priceCents: 100 + i,
        );
      }
      final container = containerWithDb();
      final data = await waitForPurchasesValue(
        (listen) => container.listen(
          periodPurchasesProvider(
            query(to: DateTime(2026, 8, 1)),
          ),
          listen,
        ),
        (value) => value.rows.length == AppConstants.statsTableMaxRows,
      );
      expect(data.rows, hasLength(AppConstants.statsTableMaxRows));
      expect(data.rows.first.priceCents, 105);
      expect(data.rows.last.priceCents, 304);
      expect(data.truncated, isTrue);
    });

    test('raw σφάλμα → DataLoadException (listen+completer)', () async {
      final container = ProviderContainer.test(
        overrides: [
          receiptRepositoryProvider.overrideWithValue(
            ReceiptRepositoryImpl(ReceiptDao(db), _FailingPurchasesLineDao(db)),
          ),
        ],
      );
      addTearDown(container.dispose);
      final completer = Completer<Object?>();
      container.listen(
        periodPurchasesProvider(query()),
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
