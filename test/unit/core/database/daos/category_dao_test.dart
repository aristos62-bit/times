import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/database/daos/daos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoryDao', () {
    late AppDatabase db;
    late CategoryDao dao;

    setUp(() async {
      db = AppDatabase.test();
      dao = CategoryDao(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('watchAllCategories: 8 seeded, όλες active, sorted', () async {
      final categories = await dao.watchAllCategories().first;
      expect(categories.length, 8);
      for (final c in categories) {
        expect(c.isActive, isTrue);
      }
      for (var i = 1; i < categories.length; i++) {
        final prev = categories[i - 1];
        final curr = categories[i];
        expect(
          prev.level < curr.level ||
              (prev.level == curr.level &&
                  prev.sortOrder <= curr.sortOrder),
          isTrue,
        );
      }
    });

    test('getCategoryById: βρίσκει seeded κατηγορία', () async {
      final seeded = await db.select(db.categories).get();
      final byId = await dao.getCategoryById(seeded.first.id);
      expect(byId?.id, seeded.first.id);
      expect(byId?.name, seeded.first.name);
    });

    test('getCategoryById: άκυρο id → null', () async {
      expect(await dao.getCategoryById(99999), isNull);
    });

    test('createCategory: υποκατηγορία με parent', () async {
      final seeded = await db.select(db.categories).get();
      final parent = seeded.first;

      final id = await dao.createCategory(CategoriesCompanion.insert(
        name: 'Παιδικό Τρόφιμο',
        parentId: Value(parent.id),
        level: Value(parent.level + 1),
        sortOrder: const Value(1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final created = await dao.getCategoryById(id);
      expect(created, isNotNull);
      expect(created!.parentId, parent.id);
      expect(created.level, parent.level + 1);
    });

    test('watchCategoryTree: περιλαμβάνει και ανενεργές', () async {
      final seeded = await db.select(db.categories).get();
      final id = seeded.first.id;

      await (db.update(db.categories)..where((c) => c.id.equals(id))).write(
        CategoriesCompanion(
          isActive: const Value(false),
          updatedAt: Value(DateTime.now()),
        ),
      );

      final tree = await dao.watchCategoryTree().first;
      expect(tree.any((c) => c.id == id), isTrue);
      expect(tree.length, 8);
    });

    test('updateCategory: rename', () async {
      final seeded = await db.select(db.categories).get();
      final target = seeded.first;

      final ok = await dao.updateCategory(
        target.toCompanion(true).copyWith(
          name: const Value('Νέα Ονομασία'),
          updatedAt: Value(DateTime.now()),
        ),
      );
      expect(ok, isTrue);

      final updated = await dao.getCategoryById(target.id);
      expect(updated?.name, 'Νέα Ονομασία');
    });

    test('softDeleteCategory: φύλλο χωρίς παιδιά → διαγράφεται', () async {
      final seeded = await db.select(db.categories).get();
      final target = seeded.first;

      final ok = await dao.softDeleteCategory(target.id);
      expect(ok, isTrue);

      final categories = await dao.watchAllCategories().first;
      expect(categories.any((c) => c.id == target.id), isFalse);
      expect((await dao.getCategoryById(target.id))?.isActive, isFalse);
    });

    test('softDeleteCategory: με ενεργά παιδιά → false και δεν διαγράφει',
        () async {
      final seeded = await db.select(db.categories).get();
      final parent = seeded.first;

      await dao.createCategory(CategoriesCompanion.insert(
        name: 'Ενεργό Παιδί',
        parentId: Value(parent.id),
        level: Value(parent.level + 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final ok = await dao.softDeleteCategory(parent.id);
      expect(ok, isFalse);
      expect((await dao.getCategoryById(parent.id))?.isActive, isTrue);
    });

    test('watchCategoryWithChildrenRecursively: root + έμμεσα παιδιά',
        () async {
      final seeded = await db.select(db.categories).get();
      final root = seeded.first;

      final lvl1 = await dao.createCategory(CategoriesCompanion.insert(
        name: 'L1',
        parentId: Value(root.id),
        level: Value(root.level + 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      final lvl2 = await dao.createCategory(CategoriesCompanion.insert(
        name: 'L2',
        parentId: Value(lvl1),
        level: Value(root.level + 2),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final tree = await db.transaction(
        () => dao.watchCategoryWithChildrenRecursively(root.id).first,
      );
      final ids = tree.map((c) => c.id).toList();
      expect(ids, contains(root.id));
      expect(ids, contains(lvl1));
      expect(ids, contains(lvl2));
    });
  });
}