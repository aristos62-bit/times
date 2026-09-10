// test/unit/features/item/data/repositories/item_repository_impl_test.dart
//
// Επαληθεύει ότι το ItemRepositoryImpl (pure delegate) προωθεί σωστά όλες τις
// κλήσεις προς τον ItemDao — και ότι δεν κρύβει/mpatizes exceptions ή όρια.
// Δεν επαναλαμβάνονται λεπτομερείς έλεγχοι του DAO (ήδη καλυμμένοι στο
// item_dao_test.dart) — εδώ ελέγχεται η σύνδεση contract → impl → DAO.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/database/daos/daos.dart';
import 'package:expense_tracker/features/item/data/repositories/item_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ItemRepositoryImpl', () {
    late AppDatabase db;
    late ItemRepositoryImpl repo;
    late int categoryId;

    setUp(() async {
      db = AppDatabase.test();
      repo = ItemRepositoryImpl(ItemDao(db));
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
    }) {
      return repo.create(ItemsCompanion.insert(
        name: name,
        categoryId: categoryId,
        barcode: Value(barcode),
        currentStock: currentStock == null ? const Value.absent() : Value(currentStock),
        reorderLevel: reorderLevel == null ? const Value.absent() : Value(reorderLevel),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    test('watchAll: αρχικά κενό', () async {
      expect(await repo.watchAll().first, isEmpty);
    });

    test('create + getById + watchAll (δεδομένα γραμμένα μέσω repo)', () async {
      final id = await createItem('Γάλα 1L', currentStock: 10);
      final item = await repo.getById(id);
      expect(item, isNotNull);
      expect(item!.currentStock, 10);
      expect(await repo.watchAll().first, hasLength(1));
    });

    test('watchByCategory: φιλτράρει ανά κατηγορία', () async {
      final otherCat = (await db.select(db.categories).get())[1];
      final mine = await createItem('Στο δικό μου');
      await repo.create(ItemsCompanion.insert(
        name: 'Σε άλλο',
        categoryId: otherCat.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final items = await repo.watchByCategory(categoryId).first;
      expect(items.map((i) => i.id), [mine]);
    });

    test('watchByBarcode: ακριβές match', () async {
      await createItem('Με Barcode', barcode: '5201234567890');
      expect(await repo.watchByBarcode('5201234567890').first, hasLength(1));
      expect(await repo.watchByBarcode('xxxx').first, isEmpty);
    });

    test('searchByName: case-insensitive LIKE + soft delete αφαιρεί', () async {
      final id = await createItem('MacBook Air');
      expect(await repo.searchByName('MAC').first, hasLength(1));
      await repo.softDelete(id);
      expect(await repo.searchByName('MAC').first, isEmpty);
    });

    test('watchLowStock: currentStock <= reorderLevel', () async {
      await createItem('ΟΚ', currentStock: 10, reorderLevel: 5);
      await createItem('Low', currentStock: 3, reorderLevel: 5);
      final low = await repo.watchLowStock().first;
      expect(low.map((i) => i.name), ['Low']);
    });

    test('update: full replace με rename', () async {
      final id = await createItem('Παλιό');
      final item = (await repo.getById(id))!;
      await repo.update(
        item.toCompanion(true).copyWith(
              name: const Value('Νέο'),
              updatedAt: Value(DateTime.now()),
            ),
      );
      expect((await repo.getById(id))?.name, 'Νέο');
    });

    test('increaseStock: atomic αύξηση + lastPrice', () async {
      final id = await createItem('Stock', currentStock: 10);
      await repo.increaseStock(id, 5, unitPrice: 1.99);
      final item = await repo.getById(id);
      expect(item?.currentStock, 15);
      expect(item?.lastPrice, 1.99);
    });

    test('create duplicate (name, categoryId) → SqliteException (ανεπηρέαστο)', () async {
      await createItem('Διπλότυπο');
      await expectLater(
        createItem('Διπλότυπο'),
        throwsA(isA<SqliteException>()),
      );
    });
  });
}