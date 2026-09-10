import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/database/daos/daos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ItemDao', () {
    late AppDatabase db;
    late ItemDao dao;
    late int categoryId;

    setUp(() async {
      db = AppDatabase.test();
      dao = ItemDao(db);
      final categories = await db.select(db.categories).get();
      categoryId = categories.first.id;
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> createItem(
      String name, {
      double? currentStock,
      double? reorderLevel,
      String? barcode,
      int? supplierId,
    }) {
      return dao.createItem(ItemsCompanion.insert(
        name: name,
        categoryId: categoryId,
        barcode: Value(barcode),
        currentStock: currentStock == null ? const Value.absent() : Value(currentStock),
        reorderLevel: reorderLevel == null ? const Value.absent() : Value(reorderLevel),
        lastSupplierId: supplierId == null ? const Value.absent() : Value(supplierId),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    test('watchAllItems: αρχικά κενό', () async {
      expect(await dao.watchAllItems().first, isEmpty);
    });

    test('createItem + getItemById', () async {
      final id = await createItem('Γάλα 1L', currentStock: 10);
      final item = await dao.getItemById(id);
      expect(item, isNotNull);
      expect(item!.categoryId, categoryId);
      expect(item.currentStock, 10);
      expect(item.uuid, isNotEmpty);
    });

    test('getItemById: άκυρο id → null', () async {
      expect(await dao.getItemById(99999), isNull);
    });

    test('watchAllItems: μόνο active, sorted by name', () async {
      await createItem('Ζάχαρη');
      await createItem('Αλάτι');
      await createItem('Λάδι');

      final items = await dao.watchAllItems().first;
      expect(items.length, 3);
      expect(items[0].name, 'Αλάτι');
      expect(items[1].name, 'Ζάχαρη');
      expect(items[2].name, 'Λάδι');
    });

    test('watchItemsByCategory: φιλτράρει ανά κατηγορία', () async {
      final otherCat = (await db.select(db.categories).get())[1];
      final id1 = await createItem('Στο δικό μου');
      await dao.createItem(ItemsCompanion.insert(
        name: 'Σε άλλο',
        categoryId: otherCat.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final items = await dao.watchItemsByCategory(categoryId).first;
      expect(items.map((i) => i.id), [id1]);
    });

    test('watchItemsByBarcode: ακριβές match', () async {
      await createItem('Με Barcode', barcode: '5201234567890');
      final byBarcode = await dao.watchItemsByBarcode('5201234567890').first;
      expect(byBarcode.length, 1);

      final wrong = await dao.watchItemsByBarcode('5200000000000').first;
      expect(wrong, isEmpty);
    });

    test('searchItemsByName: case-insensitive LIKE + μόνο active', () async {
      final id = await createItem('MacBook Air');
      await createItem('Μηδέν Ενδιαφέρον');

      final results = await dao.searchItemsByName('MAC').first;
      expect(results.map((i) => i.id), [id]);

      await dao.softDeleteItem(id);
      expect(await dao.searchItemsByName('MAC').first, isEmpty);
    });

    test('watchLowStock: currentStock <= reorderLevel, reorderLevel > 0',
        () async {
      await createItem('Εντάξει Απόθεμα', currentStock: 10, reorderLevel: 5);
      await createItem('Να Ξαναπαραγγελθεί', currentStock: 3, reorderLevel: 5);
      await createItem('Όριο', currentStock: 5, reorderLevel: 5);

      final low = await dao.watchLowStock().first;
      expect(low.map((i) => i.name).toSet(),
          {'Να Ξαναπαραγγελθεί', 'Όριο'});
    });

    test('updateItem: full replace με rename', () async {
      final id = await createItem('Παλιό');
      final item = (await dao.getItemById(id))!;

      final ok = await dao.updateItem(
        item.toCompanion(true).copyWith(
              name: const Value('Νέο'),
              updatedAt: Value(DateTime.now()),
            ),
      );
      expect(ok, isTrue);
      expect((await dao.getItemById(id))?.name, 'Νέο');
    });

    test('softDeleteItem: εξαφανίζεται από active λίστα', () async {
      final id = await createItem('Προς Διαγραφή');
      await dao.softDeleteItem(id);

      expect(await dao.watchAllItems().first, isEmpty);
      expect((await dao.getItemById(id))?.isActive, isFalse);
    });

    test('increaseStock: αύξηση currentStock + ενημέρωση lastPrice', () async {
      final id = await createItem('Stock Item', currentStock: 10);

      await dao.increaseStock(id, 5, unitPrice: 1.99, supplierId: null);

      final item = await dao.getItemById(id);
      expect(item?.currentStock, 15);
      expect(item?.lastPrice, 1.99);

      await dao.increaseStock(id, 2);
      expect((await dao.getItemById(id))?.currentStock, 17);
      expect((await dao.getItemById(id))?.lastPrice, 1.99);
    });

    test('Duplicate (name, categoryId) → SqliteException', () async {
      await createItem('Διπλότυπο');
      await expectLater(
        createItem('Διπλότυπο'),
        throwsA(isA<SqliteException>()),
      );
    });
  });
}