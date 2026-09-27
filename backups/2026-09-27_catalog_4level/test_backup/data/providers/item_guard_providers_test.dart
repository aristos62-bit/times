/// Unit tests — πύλη διαγραφής είδους (§2.3 · ενότητα Ειδών).
///
/// `canDeleteItemProvider` (`countLinesByItemId == 0`) +
/// `itemLinesCountProvider` (πλήθος για tooltip). `ProviderContainer.test()`
/// + in-memory DB. Για τα families αρκεί το `.future` (το hang αφορούσε
/// ΜΟΝΟ StreamProvider + drift — pattern `category_guard_providers_test`).
library;

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/receipt_dao.dart';
import 'package:times/data/local/daos/receipt_line_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/supplier_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/providers/settings_providers.dart';
import 'package:times/data/repositories/receipt_repository_impl.dart';

import '../local/helpers/in_memory_db.dart';

/// DAO double που αποτυγχάνει στο count — έλεγχος mapping σε
/// `DataLoadException` (`Future.error`, pattern guard test).
class _FailingCountLineDao extends ReceiptLineDao {
  _FailingCountLineDao(super.db);

  @override
  Future<int> countByItemId(int itemId) =>
      Future.error(SqliteException(extendedResultCode: 1, message: 'test'));
}

void main() {
  late dynamic db;

  late int itemId;
  late int unitId;
  late int supplierId;

  setUp(() async {
    db = inMemoryDb();
    unitId = await UnitDao(db).insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
    final categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    final subId = await SubCategoryDao(db)
        .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
    itemId = await ItemDao(db).insert(subCategoryId: subId, name: 'Γάλα');
    supplierId = await SupplierDao(db).insert(name: 'Μάρκος');
  });

  tearDown(() async => await db.close());

  ProviderContainer container() => ProviderContainer.test(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );

  Future<void> seedLine() async {
    final receiptId = await ReceiptDao(db).insert(
      date: DateTime(2026, 1, 1),
      supplierId: supplierId,
    );
    await ReceiptLineDao(db).insert(
      receiptId: receiptId,
      itemId: itemId,
      unitId: unitId,
      quantity: 1,
      priceCents: 100,
    );
  }

  group('canDeleteItemProvider / itemLinesCountProvider', () {
    test('καθαρό είδος → true / 0', () async {
      final c = container();
      expect(await c.read(canDeleteItemProvider(itemId).future), isTrue);
      expect(await c.read(itemLinesCountProvider(itemId).future), 0);
    });

    test('είδος με γραμμές → false / πλήθος', () async {
      await seedLine();
      await seedLine();
      final c = container();
      expect(await c.read(canDeleteItemProvider(itemId).future), isFalse);
      expect(await c.read(itemLinesCountProvider(itemId).future), 2);
    });

    test('σφάλμα count → DataLoadException (mapping, listen — E1)', () async {
      final c = ProviderContainer.test(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          receiptRepositoryProvider.overrideWith(
            (ref) => ReceiptRepositoryImpl(
              ReceiptDao(db),
              _FailingCountLineDao(db),
            ),
          ),
        ],
      );
      // NOTE: όχι `.future`+throwsA — Riverpod 3 retry (εύρημα Βήματος 3).
      final completer = Completer<Object?>();
      final sub = c.listen(canDeleteItemProvider(itemId), (prev, next) {
        if (next.hasError && !completer.isCompleted) {
          completer.complete(next.error);
        }
      });
      addTearDown(sub.close);
      expect(
        await completer.future.timeout(const Duration(seconds: 5)),
        isA<DataLoadException>(),
      );
    });
  });
}
