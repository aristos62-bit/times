// test/unit/core/database/daos/receipt_dao_aggregates_test.dart
import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/database/daos/daos.dart';
import 'package:expense_tracker/features/receipt/domain/models/receipt_input.dart';
import 'package:flutter_test/flutter_test.dart';

import 'receipt_dao_test_fixture.dart';

/// Tests για το aggregate extension του [ReceiptDao]:
/// watchReceiptCount, watchTotalByDateRange, watchTotalByCategory,
/// watchAverageAmount.
void main() {
  group('ReceiptDao aggregates', () {
    final fixture = ReceiptDaoFixture();

    setUp(fixture.setUp);
    tearDown(fixture.tearDown);

    test('watchReceiptCount: 0 → N', () async {
      expect(await fixture.dao.watchReceiptCount().first, 0);
      await fixture.createReceipt();
      await fixture.createReceipt();
      expect(await fixture.dao.watchReceiptCount().first, 2);
    });

    test('watchTotalByDateRange: gross, φιλτράρει εύρος', () async {
      final id = await fixture.createReceipt(date: DateTime(2026, 5, 10));
      final r = (await fixture.dao.getReceiptById(id))!;

      final inRange = await fixture.dao
          .watchTotalByDateRange(DateTime(2026, 5, 1), DateTime(2026, 5, 31))
          .first;
      expect(inRange, closeTo(r.totalAmount + r.vatTotal, 0.001));

      final outOfRange = await fixture.dao
          .watchTotalByDateRange(DateTime(2026, 6, 1), DateTime(2026, 6, 30))
          .first;
      expect(outOfRange, closeTo(0, 0.001));
    });

    test('watchTotalByCategory: grouping + order desc', () async {
      final otherCategory = (await fixture.db.select(fixture.db.categories).get())[1];
      final itemB = await fixture.itemDao.createItem(
        ItemsCompanion.insert(
          name: 'Item B',
          categoryId: otherCategory.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      // Κατηγορία 'Οικιακά': qty1*50 → gross 62
      await fixture.createReceipt(items: [
        ReceiptItemInput(itemId: itemB, quantity: 1, unitPrice: 50),
      ]);
      // Κατηγορία 'Τρόφιμα' (itemId): qty2*10 → gross 24.8
      await fixture.createReceipt(items: [
        ReceiptItemInput(itemId: fixture.itemId, quantity: 2, unitPrice: 10),
      ]);

      final map = await fixture.dao
          .watchTotalByCategory(DateTime(2026, 5, 1), DateTime(2026, 5, 31))
          .first;
      expect(map.keys.first, otherCategory.name); // order desc
      expect(map[otherCategory.name], closeTo(62, 0.001));
      expect(map.values.first, closeTo(62, 0.001));
      expect(map.length, 2);
    });

    test('watchAverageAmount: μέσος όρος net total_amount', () async {
      expect(await fixture.dao.watchAverageAmount().first, closeTo(0, 0.001));
      await fixture.createReceipt(); // total_amount 20
      await fixture.createReceipt(); // total_amount 20
      expect(await fixture.dao.watchAverageAmount().first, closeTo(20, 0.001));
    });
  });
}