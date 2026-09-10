// test/unit/features/category/data/repositories/category_repository_impl_test.dart
//
// Επαληθεύει ότι το CategoryRepositoryImpl (pure delegate) προωθεί σωστά τις
// κλήσεις στον CategoryDao — κυρίως ότι το createCategory πετάει την
// CategoryDuplicateNameException (Fix #4, category_dao.dart:128-135) χωρίς να
// την καταπνίγει, και ότι το softDelete μπλοκάρει κατηγορίες με ενεργά παιδιά.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/database/daos/daos.dart';
import 'package:expense_tracker/features/category/data/repositories/category_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoryRepositoryImpl', () {
    late AppDatabase db;
    late CategoryRepositoryImpl repo;

    setUp(() async {
      db = AppDatabase.test();
      repo = CategoryRepositoryImpl(CategoryDao(db));
    });

    tearDown(() async {
      await db.close();
    });

    test('watchAll: 8 seeded, όλες active', () async {
      final categories = await repo.watchAll().first;
      expect(categories, hasLength(8));
      for (final c in categories) {
        expect(c.isActive, isTrue);
      }
    });

    test('getById: βρίσκει seeded', () async {
      final seeded = await db.select(db.categories).get();
      final byId = await repo.getById(seeded.first.id);
      expect(byId?.id, seeded.first.id);
    });

    test('create: υποκατηγορία με parent (δεδομένα μέσω repo)', () async {
      final seeded = await db.select(db.categories).get();
      final parent = seeded.first;

      final id = await repo.create(CategoriesCompanion.insert(
        name: 'Παιδικό Τρόφιμο',
        parentId: Value(parent.id),
        level: Value(parent.level + 1),
        sortOrder: const Value(1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final created = await repo.getById(id);
      expect(created!.parentId, parent.id);
      expect(created.level, parent.level + 1);
    });

    test('create: duplicate name στο ίδιο επίπεδο → CategoryDuplicateNameException', () async {
      // Κατάργηση του UNIQUE(name) constraint (db-level) για να δοκιμαστεί
      // ο app-level έλεγχος του DAO μέσα από το repository.
      await repo.create(CategoriesCompanion.insert(
        name: 'Διπλότυπο',
        level: const Value(0),
        sortOrder: const Value(99),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await expectLater(
        repo.create(CategoriesCompanion.insert(
          name: 'Διπλότυπο',
          level: const Value(0),
          sortOrder: const Value(100),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )),
        throwsA(isA<CategoryDuplicateNameException>()),
      );
    });

    test('watchTree: περιλαμβάνει και ανενεργές', () async {
      final seeded = await db.select(db.categories).get();
      final id = seeded.first.id;

      await (db.update(db.categories)..where((c) => c.id.equals(id))).write(
        CategoriesCompanion(
          isActive: const Value(false),
          updatedAt: Value(DateTime.now()),
        ),
      );

      final tree = await repo.watchTree().first;
      expect(tree.any((c) => c.id == id), isTrue);
    });

    test('softDelete: φύλλο χωρίς παιδιά → διαγράφεται', () async {
      final seeded = await db.select(db.categories).get();
      final noChildren = seeded.first;
      final ok = await repo.softDelete(noChildren.id);
      expect(ok, isTrue);
      final list = await repo.watchAll().first;
      expect(list.any((c) => c.id == noChildren.id), isFalse);
    });

    test('softDelete: με ενεργά παιδιά → false και δεν διαγράφει', () async {
      final seeded = await db.select(db.categories).get();
      final parent = seeded.first;

      await repo.create(CategoriesCompanion.insert(
        name: 'Ενεργό Παιδί',
        parentId: Value(parent.id),
        level: Value(parent.level + 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final ok = await repo.softDelete(parent.id);
      expect(ok, isFalse);
      expect((await repo.getById(parent.id))?.isActive, isTrue);
    });
  });
}