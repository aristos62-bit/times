/// Unit tests για το ledger provider (§2.3 · 28-09-2026 — 1η ανάλυση).
///
/// `itemLedgerProvider` (autoDispose family): τιμές + cap νεότερα + κενό +
/// error mapping. Πραγματική in-memory Drift βάση · Riverpod 3
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

/// DAO double — raw σφάλμα στο ledger για δοκιμή stream mapping.
class _FailingLedgerLineDao extends ReceiptLineDao {
  _FailingLedgerLineDao(super.db);

  @override
  Stream<List<ItemLedgerRow>> watchItemLedger({
    required int itemId,
    required DateTime from,
    required DateTime to,
  }) =>
      Stream.error(SqliteException(extendedResultCode: 1, message: 'test'));
}

/// Ακούει μέχρι μια εκπομπή να ικανοποιήσει το [predicate] (5s fail-fast).
Future<List<ItemLedgerRow>> waitForLedgerValue(
  void Function(
    void Function(
      AsyncValue<List<ItemLedgerRow>>? previous,
      AsyncValue<List<ItemLedgerRow>> next,
    ) onEmission,
  ) subscribe,
  bool Function(List<ItemLedgerRow> value) predicate,
) {
  final completer = Completer<List<ItemLedgerRow>>();
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

  final from = DateTime(2026, 1, 1);
  final to = DateTime(2026, 2, 1);

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

  group('itemLedgerProvider (§2.3 · 28-09-2026)', () {
    test('γραμμές με πλήρη στοιχεία', () async {
      await seedLine(date: DateTime(2026, 1, 5));
      final container = containerWithDb();
      final rows = await waitForLedgerValue(
        (listen) => container.listen(
          itemLedgerProvider((itemId: itemId, from: from, to: to)),
          listen,
        ),
        (value) => value.isNotEmpty,
      );
      expect(rows.single.receiptId, greaterThan(0));
      expect(rows.single.unitAbbreviation, 'κιλ');
      expect(rows.single.priceCents, 250);
    });

    test('κενή περίοδος → [] (όχι loading για πάντα)', () async {
      await seedLine(date: DateTime(2026, 1, 5));
      final container = containerWithDb();
      final rows = await waitForLedgerValue(
        (listen) => container.listen(
          itemLedgerProvider(
            (
              itemId: itemId,
              from: DateTime(2025, 1, 1),
              to: DateTime(2025, 2, 1),
            ),
          ),
          listen,
        ),
        (_) => true,
      );
      expect(rows, isEmpty);
    });

    test('cap: >statsTableMaxRows → οι νεότερες', () async {
      for (var i = 0; i < AppConstants.statsTableMaxRows + 5; i++) {
        await seedLine(
          date: DateTime(2026, 1, 1).add(Duration(days: i)),
          priceCents: 100 + i,
        );
      }
      final container = containerWithDb();
      final rows = await waitForLedgerValue(
        (listen) => container.listen(
          itemLedgerProvider(
            (
              itemId: itemId,
              from: DateTime(2026, 1, 1),
              to: DateTime(2026, 8, 1),
            ),
          ),
          listen,
        ),
        (value) => value.length == AppConstants.statsTableMaxRows,
      );
      expect(rows, hasLength(AppConstants.statsTableMaxRows));
      // Κρατήθηκαν οι νεότερες (price 105 … 304).
      expect(rows.first.priceCents, 105);
      expect(rows.last.priceCents, 304);
    });

    test('raw σφάλμα → DataLoadException (listen+completer)', () async {
      final container = ProviderContainer.test(
        overrides: [
          receiptRepositoryProvider.overrideWithValue(
            ReceiptRepositoryImpl(ReceiptDao(db), _FailingLedgerLineDao(db)),
          ),
        ],
      );
      addTearDown(container.dispose);
      final completer = Completer<Object?>();
      container.listen(
        itemLedgerProvider((itemId: itemId, from: from, to: to)),
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
