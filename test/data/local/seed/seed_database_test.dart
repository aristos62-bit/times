/// DB integration tests για seed — Φάση 1, Βήμα 3.
///
/// Επαληθεύει ότι το seed εισάγει σωστά τα δεδομένα στη βάση.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:times/data/local/seed/seed_units.dart';

import '../helpers/in_memory_db.dart';

void main() {
  group('Seed Database Integration', () {
    test('skipSeed=true → κενοί πίνακες', () async {
      final db = inMemoryDb(skipSeed: true);
      addTearDown(db.close);

      // Trigger migrations.
      await db.select(db.units).get();
      await db.select(db.categories).get();
      await db.select(db.subCategories).get();
      await db.select(db.items).get();

      expect(await db.select(db.units).get(), isEmpty);
      expect(await db.select(db.categories).get(), isEmpty);
      expect(await db.select(db.subCategories).get(), isEmpty);
      expect(await db.select(db.items).get(), isEmpty);
    });

    test('skipSeed=false → seed εισάγει δεδομένα', () async {
      final db = inMemoryDb(skipSeed: false);
      addTearDown(db.close);

      // Trigger migrations + seed.
      final units = await db.select(db.units).get();
      final categories = await db.select(db.categories).get();
      final subCategories = await db.select(db.subCategories).get();
      final items = await db.select(db.items).get();

      expect(units.length, 5);
      expect(categories.length, 9);
      expect(subCategories.length, 53);
      expect(items.length, 535);
    });

    test('seed εισάγει σωστές μονάδες', () async {
      final db = inMemoryDb(skipSeed: false);
      addTearDown(db.close);

      final units = await db.select(db.units).get();
      final names = units.map((u) => u.name).toSet();

      for (final u in seedUnits) {
        expect(names, contains(u.name));
      }
    });

    test('seed θέτει normalizedName στα είδη', () async {
      final db = inMemoryDb(skipSeed: false);
      addTearDown(db.close);

      final items = await db.select(db.items).get();

      // Κάθε είδος πρέπει να έχει non-empty normalizedName.
      for (final item in items) {
        expect(item.normalizedName.isNotEmpty, isTrue,
            reason: 'Item ${item.name} has empty normalizedName');
      }
    });

    test('seed θέτει foreign keys σωστά (subCategoryId, defaultUnitId)', () async {
      final db = inMemoryDb(skipSeed: false);
      addTearDown(db.close);

      final items = await db.select(db.items).get();
      final unitIds = (await db.select(db.units).get()).map((u) => u.id).toSet();
      final subCatIds =
          (await db.select(db.subCategories).get()).map((s) => s.id).toSet();

      for (final item in items) {
        expect(subCatIds, contains(item.subCategoryId),
            reason: 'Item ${item.name} has invalid subCategoryId');
        // defaultUnitId μπορεί να είναι null.
        if (item.defaultUnitId != null) {
          expect(unitIds, contains(item.defaultUnitId),
              reason: 'Item ${item.name} has invalid defaultUnitId');
        }
      }
    });
  });
}