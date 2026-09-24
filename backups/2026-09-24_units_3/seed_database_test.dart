/// DB integration tests για seed — Φάση 1, Βήμα 3 + Βήμα 4 (seed-import tests).
///
/// Επαληθεύει ότι το seed εισάγει σωστά τα δεδομένα στη βάση, καλύπτει requests
/// του DESIGN §4.1.34 (πλήθος εγγραφών, normalizedName exact match, createdAt/
/// abbreviation, ατομικότητα σε σφάλμα, onCreate μία φορά).
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/utils/greek_text_normalizer.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/seed/seed_runner.dart';
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

    test('seed εισάγει σωστό πλήθος εγγραφών (5/9/53/535)', () async {
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

    test('seed εισάγει σωστές μονάδες (όνομα + abbreviation)', () async {
      final db = inMemoryDb(skipSeed: false);
      addTearDown(db.close);

      final units = await db.select(db.units).get();
      final byName = <String, Unit>{for (final u in units) u.name: u};

      for (final su in seedUnits) {
        expect(byName[su.name], isNot(isNull),
            reason: 'Μονάδα "${su.name}" λείπει από τη βάση');
        expect(
          byName[su.name]!.abbreviation,
          su.abbreviation,
          reason: 'Λάθος abbreviation για "${su.name}"',
        );
      }
    });

    test('seed ρυθμίζει createdAt στις κατηγορίες (default βάσης)', () async {
      final db = inMemoryDb(skipSeed: false);
      addTearDown(db.close);

      final categories = await db.select(db.categories).get();
      expect(categories.length, 9);
      for (final c in categories) {
        expect(c.createdAt, isNot(isNull),
            reason: 'Κατηγορία "${c.name}" χωρίς createdAt');
      }
    });

    test('seed θέτει normalizedName = GreekTextNormalizer.normalize(name)', () async {
      final db = inMemoryDb(skipSeed: false);
      addTearDown(db.close);

      final items = await db.select(db.items).get();

      for (final item in items) {
        expect(
          item.normalizedName,
          GreekTextNormalizer.normalize(item.name),
          reason: 'Item "${item.name}" έχει λάθος normalizedName',
        );
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

    test('ατομικότητα: αποτυχία στη μέση του seed → rollback, καμία εγγραφή', () async {
      final db = inMemoryDb(skipSeed: true);
      addTearDown(db.close);

      // Άνοιγμα + createAll (κενά tables).
      await db.customSelect('SELECT 1').get();

      // Marker που θα συγκρουστεί με το 1ο seed item στο UNIQUE normalized_name.
      // Τοποθετείται ΕΚΤΟΣ transaction ώστε να επιζήσει στο rollback.
      final firstItem = seedItems.first;
      final catId = await db.into(db.categories).insert(
            CategoriesCompanion.insert(name: 'test-cat'),
          );
      final subId = await db.into(db.subCategories).insert(
            SubCategoriesCompanion.insert(name: 'test-sub', categoryId: catId),
          );
      await db.into(db.items).insert(
            ItemsCompanion.insert(
              name: 'seed-conflict-marker',
              normalizedName: GreekTextNormalizer.normalize(firstItem.name),
              subCategoryId: subId,
            ),
          );

      // Ο seed προχωράει (units/categories/subcategories) και αποτυγχάνει στο
      // 1ο item (UNIQUE violation). Το runSeed τυλίγει μόνο του το σώμα σε
      // transaction (§4.1.3) — ΕΔΩ ΔΕΝ βάζουμε εξωτερικό wrapper: ελέγχουμε
      // ακριβώς την production διαδρομή (ζήτημα §4.1.34).
      await expectLater(
        () => runSeed(db),
        throwsA(isA<SqliteException>()),
      );

      // Rollback: δεν έμεινε ΚΑΝΕΝΑ seed δεδομένο (ούτε units).
      expect(await db.select(db.units).get(), isEmpty);
      expect(await db.select(db.categories).get(), hasLength(1)); // μόνο marker
      expect(await db.select(db.subCategories).get(), hasLength(1));
      expect(await db.select(db.items).get(), hasLength(1));
    });

    test('onCreate τρέχει μία φορά: επανα-άνοιγμα χωρίς νέο seed', () async {
      final dir = await Directory.systemTemp.createTemp('times_seed_');
      addTearDown(() async {
        try {
          await dir.delete(recursive: true);
        } catch (_) {
          // Αν Windows κρατάνε το file handle, καθαρισμός best-effort.
        }
      });
      final file = File('${dir.path}${Platform.pathSeparator}seed_reopen.db');

      // 1ο άνοιγμα: νέο DB → createAll + seed.
      final db1 = AppDatabase(executor: NativeDatabase(file), skipSeed: false);
      await db1.customSelect('SELECT 1').get();
      expect(await db1.select(db1.units).get(), hasLength(5));
      expect(await db1.select(db1.items).get(), hasLength(535));
      await db1.close();

      // 2ο άνοιγμα του ΙΔΙΟΥ αρχείου: το onCreate ΔΕΝ ξανα-τρέχει.
      final db2 = AppDatabase(executor: NativeDatabase(file), skipSeed: false);
      addTearDown(db2.close);
      await db2.customSelect('SELECT 1').get();

      expect(await db2.select(db2.units).get(), hasLength(5),
          reason: 'Reopen χωρίς re-seed (units)');
      expect(await db2.select(db2.categories).get(), hasLength(9));
      expect(await db2.select(db2.subCategories).get(), hasLength(53));
      expect(await db2.select(db2.items).get(), hasLength(535),
          reason: 'Reopen χωρίς re-seed (items)');
    });
  });
}