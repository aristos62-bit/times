/// DB integration tests για το seed — πηγή `supermarket_categories_v3.md`.
///
/// Seed: 3 μονάδες + κατάλογος (6 κατηγορίες · 28 υποκατηγορίες ·
/// 183 τμήματα · 0 είδη). Επαληθεύει: κενούς πίνακες με skipSeed, default
/// seed (πλήθη + δειγματοληπτικές εγγραφές + normalizedName), μονάδες,
/// createdAt, αλυσίδα 4 επιπέδων, ατομικότητα (rollback), onCreate μία φορά.
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/utils/greek_text_normalizer.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/item_group_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/seed/seed_runner.dart';
import 'package:times/data/local/seed/seed_units.dart';

import '../helpers/in_memory_db.dart';

void main() {
  group('Seed Database Integration (4 επίπεδα)', () {
    test('skipSeed=true → κενοί πίνακες (και item_groups)', () async {
      final db = inMemoryDb(skipSeed: true);
      addTearDown(db.close);

      // Trigger migrations.
      await db.select(db.units).get();
      await db.select(db.categories).get();
      await db.select(db.subCategories).get();
      await db.select(db.itemGroups).get();
      await db.select(db.items).get();

      expect(await db.select(db.units).get(), isEmpty);
      expect(await db.select(db.categories).get(), isEmpty);
      expect(await db.select(db.subCategories).get(), isEmpty);
      expect(await db.select(db.itemGroups).get(), isEmpty);
      expect(await db.select(db.items).get(), isEmpty);
    });

    test('default seed: 3 μονάδες + κατάλογος 6/28/183/0', () async {
      final db = inMemoryDb(skipSeed: false);
      addTearDown(db.close);

      // Trigger migrations + seed.
      final units = await db.select(db.units).get();
      final categories = await db.select(db.categories).get();
      final subCategories = await db.select(db.subCategories).get();
      final groups = await db.select(db.itemGroups).get();
      final items = await db.select(db.items).get();

      expect(units.length, 3);
      expect(categories.length, 6);
      expect(subCategories.length, 28);
      expect(groups.length, 183);
      expect(items, isEmpty);
    });

    test('seed normalizedName = GreekTextNormalizer.normalize (δείγμα)',
        () async {
      final db = inMemoryDb(skipSeed: false);
      addTearDown(db.close);

      final categories = await db.select(db.categories).get();
      for (final c in categories) {
        expect(c.normalizedName, GreekTextNormalizer.normalize(c.name));
      }
      final groups = await db.select(db.itemGroups).get();
      final feta =
          groups.firstWhere((g) => g.name == 'Φέτα', orElse: () => groups.first);
      expect(feta.normalizedName, 'φετα');
    });

    test('seed εισάγει σωστές μονάδες (όνομα+abbreviation+allowsDecimal)',
        () async {
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
        expect(
          byName[su.name]!.allowsDecimal,
          su.allowsDecimal,
          reason: 'Λάθος allowsDecimal για "${su.name}"',
        );
      }
    });

    test('createdAt κατηγορίας: default βάσης (κοντά στο τώρα)', () async {
      final db = inMemoryDb(skipSeed: true);
      addTearDown(db.close);

      final before = DateTime.now().subtract(const Duration(minutes: 5));
      final id = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
      final row = await CategoryDao(db).getById(id);

      expect(row, isNotNull);
      expect(row!.createdAt, isNot(isNull));
      expect(row.createdAt.isAfter(before), isTrue);
    });

    test('αλυσίδα 4 επιπέδων end-to-end: FK έγκυρα + normalizedName', () async {
      final db = inMemoryDb(skipSeed: true);
      addTearDown(db.close);

      final catId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
      final subId = await SubCategoryDao(db)
          .insert(categoryId: catId, name: 'Γαλακτοκομικά');
      final groupId = await ItemGroupDao(db)
          .insert(subCategoryId: subId, name: 'Φέτα');
      final itemId =
          await ItemDao(db).insert(itemGroupId: groupId, name: 'Γάλα');

      final item = await ItemDao(db).getById(itemId);
      expect(item!.itemGroupId, groupId);
      expect(item.normalizedName, GreekTextNormalizer.normalize('Γάλα'));
      expect(item.defaultUnitId, isNull);

      final group = await ItemGroupDao(db).getById(groupId);
      expect(group!.subCategoryId, subId);
      expect(group.normalizedName, GreekTextNormalizer.normalize('Φέτα'));
    });

    test('ατομικότητα: αποτυχία στο seed → rollback, καμία εγγραφή', () async {
      final db = inMemoryDb(skipSeed: true);
      addTearDown(db.close);

      // Άνοιγμα + createAll (κενοί πίνακες).
      await db.customSelect('SELECT 1').get();

      // Σκόπιμη αποτυχία στο 2ο unit (Κιλό): το runSeed τυλίγει όλο το σώμα
      // σε ένα transaction — πρέπει να γίνει rollback και του 1ου (Τεμάχιο).
      await db.customStatement(
        'CREATE TRIGGER seed_fail_trigger BEFORE INSERT ON units '
        "WHEN NEW.name = 'Κιλό' "
        "BEGIN SELECT RAISE(ABORT, 'σκοπιμη αποτυχια seed'); END;",
      );

      await expectLater(
        () => runSeed(db),
        throwsA(isA<SqliteException>()),
      );

      // Rollback: δεν έμεινε ΚΑΜΙΑ seed εγγραφή (ούτε το Τεμάχιο).
      expect(await db.select(db.units).get(), isEmpty);
      expect(await db.select(db.categories).get(), isEmpty);
      expect(await db.select(db.subCategories).get(), isEmpty);
      expect(await db.select(db.itemGroups).get(), isEmpty);
      expect(await db.select(db.items).get(), isEmpty);
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

      // 1ο άνοιγμα: νέο DB → createAll + seed (3 μονάδες + 6/28/183).
      final db1 = AppDatabase(executor: NativeDatabase(file), skipSeed: false);
      await db1.customSelect('SELECT 1').get();
      expect(await db1.select(db1.units).get(), hasLength(3));
      expect(await db1.select(db1.categories).get(), hasLength(6));
      expect(await db1.select(db1.items).get(), isEmpty);
      await db1.close();

      // 2ο άνοιγμα του ΙΔΙΟΥ αρχείου: το onCreate ΔΕΝ ξανα-τρέχει.
      final db2 = AppDatabase(executor: NativeDatabase(file), skipSeed: false);
      addTearDown(db2.close);
      await db2.customSelect('SELECT 1').get();

      expect(await db2.select(db2.units).get(), hasLength(3),
          reason: 'Reopen χωρίς re-seed (units)');
      expect(await db2.select(db2.categories).get(), hasLength(6));
      expect(await db2.select(db2.subCategories).get(), hasLength(28));
      expect(await db2.select(db2.itemGroups).get(), hasLength(183));
      expect(await db2.select(db2.items).get(), isEmpty,
          reason: 'Reopen χωρίς re-seed (κατάλογος)');
    });
  });
}
