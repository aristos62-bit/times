/// Unit tests για το units provider (§2.1 · 29-09-2026 — μετρικές).
///
/// `topItemsByUnitProvider` (autoDispose family): slice top-10 + «Λοιπά» +
/// κενό + error mapping. Πραγματική in-memory Drift βάση · Riverpod 3
/// listen+Completer (όχι `.future` — εύρημα search tests).
library;

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_strings.dart';
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

/// DAO double — raw σφάλμα στα units για δοκιμή stream mapping.
class _FailingUnitsReceiptDao extends ReceiptDao {
  _FailingUnitsReceiptDao(super.db);

  @override
  Stream<List<ItemQtyTotal>> watchTopItemsByUnit({
    required DateTime from,
    required DateTime to,
    required int unitId,
  }) =>
      Stream.error(SqliteException(extendedResultCode: 1, message: 'test'));
}

/// Ακούει μέχρι μια εκπομπή να ικανοποιήσει το [predicate] (5s fail-fast).
Future<List<ChartQtySlice>> waitForQtyValue(
  void Function(
    void Function(
      AsyncValue<List<ChartQtySlice>>? previous,
      AsyncValue<List<ChartQtySlice>> next,
    ) onEmission,
  ) subscribe,
  bool Function(List<ChartQtySlice> value) predicate,
) {
  final completer = Completer<List<ChartQtySlice>>();
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

  late int kiloId;
  late int supplierId;
  late int groupId;

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
    groupId = await ItemGroupDao(db).insert(subCategoryId: subId, name: 'Φρέσκα');
    supplierId = await SupplierDao(db).insert(name: 'Μάρκος');
  });

  tearDown(() async => await db.close());

  ProviderContainer containerWithDb() => ProviderContainer.test(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );

  Future<int> seedItem(String name) => ItemDao(db).insert(
        itemGroupId: groupId,
        name: name,
        defaultUnitId: kiloId,
      );

  Future<void> seedLine({
    required int itemId,
    required double quantity,
  }) async {
    final receiptId = await ReceiptDao(db).insert(
      date: DateTime(2026, 1, 5),
      supplierId: supplierId,
    );
    await ReceiptLineDao(db).insert(
      receiptId: receiptId,
      itemId: itemId,
      unitId: kiloId,
      quantity: quantity,
      priceCents: 100,
    );
  }

  group('topItemsByUnitProvider (§2.1 · 29-09-2026)', () {
    test('φέτες ποσοτήτων κατά σειρά', () async {
      final milkId = await seedItem('Γάλα');
      final yogurtId = await seedItem('Γιαούρτι');
      await seedLine(itemId: milkId, quantity: 2.5);
      await seedLine(itemId: yogurtId, quantity: 1);
      final container = containerWithDb();
      final slices = await waitForQtyValue(
        (listen) => container.listen(
          topItemsByUnitProvider((from: from, to: to, unitId: kiloId)),
          listen,
        ),
        (value) => value.isNotEmpty,
      );
      expect(
        [for (final s in slices) s.label],
        ['Γάλα', 'Γιαούρτι'],
      );
      expect(slices.first.qty, 2.5);
    });

    test('slice: 11 είδη → 10 + «Λοιπά» (SPoT topItemsLimit)', () async {
      for (var i = 0; i < 11; i++) {
        final id = await seedItem('Είδος $i');
        await seedLine(itemId: id, quantity: (i + 1).toDouble());
      }
      final container = containerWithDb();
      final slices = await waitForQtyValue(
        (listen) => container.listen(
          topItemsByUnitProvider((from: from, to: to, unitId: kiloId)),
          listen,
        ),
        (value) => value.length == 11,
      );
      expect(slices.length, 10 + 1);
      expect(slices.last.label, AppStrings.othersSliceLabel);
      expect(slices.first.qty, 11);
      expect(slices.last.qty, 1);
    });

    test('κενή περίοδος → [] (όχι loading για πάντα)', () async {
      final milkId = await seedItem('Γάλα');
      await seedLine(itemId: milkId, quantity: 1);
      final container = containerWithDb();
      final slices = await waitForQtyValue(
        (listen) => container.listen(
          topItemsByUnitProvider(
            (
              from: DateTime(2025, 1, 1),
              to: DateTime(2025, 2, 1),
              unitId: kiloId,
            ),
          ),
          listen,
        ),
        (_) => true,
      );
      expect(slices, isEmpty);
    });

    test('raw σφάλμα → DataLoadException (listen+completer)', () async {
      final container = ProviderContainer.test(
        overrides: [
          receiptRepositoryProvider.overrideWithValue(
            ReceiptRepositoryImpl(_FailingUnitsReceiptDao(db), ReceiptLineDao(db)),
          ),
        ],
      );
      addTearDown(container.dispose);
      final completer = Completer<Object?>();
      container.listen(
        topItemsByUnitProvider((from: from, to: to, unitId: kiloId)),
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
