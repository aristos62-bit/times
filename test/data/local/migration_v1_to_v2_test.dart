/// Tests για τη migration v1 → v2 — καθαρισμός Γραμμάριο/Χιλιοστόλιτρο.
///
/// Η migration είναι data-only (σχήμα v1≡v2): τα «v1-shape» δεδομένα
/// χτίζονται στο τρέχον σχήμα με `skipSeed: true` και καλείται η
/// `migrateV1ToV2` κατευθείαν, συν ένα file-based e2e με
/// `PRAGMA user_version = 1` για το πραγματικό `onUpgrade` μονοπάτι.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/migration_v1_to_v2.dart';

import 'helpers/in_memory_db.dart';

/// Χτίζει μονάδες v1-shape (3 + 2 legacy) — επιστρέφει τα ids.
Future<({int kiloId, int litroId, int gramId, int mlId})> _seedV1Units(
  AppDatabase db,
) async {
  await db.into(db.units).insert(
        UnitsCompanion.insert(
          name: 'Τεμάχιο',
          abbreviation: 'τεμ',
          allowsDecimal: const Value(false),
        ),
      );
  final kiloId = await db.into(db.units).insert(
        UnitsCompanion.insert(
          name: 'Κιλό',
          abbreviation: 'κιλ',
          allowsDecimal: const Value(true),
        ),
      );
  final litroId = await db.into(db.units).insert(
        UnitsCompanion.insert(
          name: 'Λίτρο',
          abbreviation: 'λτ',
          allowsDecimal: const Value(true),
        ),
      );
  final gramId = await db.into(db.units).insert(
        UnitsCompanion.insert(
          name: 'Γραμμάριο',
          abbreviation: 'γρ',
          allowsDecimal: const Value(true),
        ),
      );
  final mlId = await db.into(db.units).insert(
        UnitsCompanion.insert(
          name: 'Χιλιοστόλιτρο',
          abbreviation: 'χλτ',
          allowsDecimal: const Value(true),
        ),
      );
  return (kiloId: kiloId, litroId: litroId, gramId: gramId, mlId: mlId);
}

/// Χτίζει πλήρες v1-shape σκηνικό: κατάλογος + είδη + απόδειξη με γραμμές
/// σε legacy μονάδες (250 γρ × 2c = 5,00 € · 1500 χλτ × 1c = 15,00 €).
Future<({int kiloId, int litroId, int gramLineId, int mlLineId})> _seedV1Db(
  AppDatabase db,
) async {
  await db.customSelect('SELECT 1').get();
  final units = await _seedV1Units(db);
  final catId = await db.into(db.categories).insert(
        CategoriesCompanion.insert(name: 'TestCat'),
      );
  final subId = await db.into(db.subCategories).insert(
        SubCategoriesCompanion.insert(name: 'TestSub', categoryId: catId),
      );
  final butterId = await db.into(db.items).insert(
        ItemsCompanion.insert(
          name: 'Βούτυρο',
          normalizedName: 'βουτυρο',
          subCategoryId: subId,
          defaultUnitId: Value(units.gramId),
        ),
      );
  final milkId = await db.into(db.items).insert(
        ItemsCompanion.insert(
          name: 'Γάλα',
          normalizedName: 'γαλα',
          subCategoryId: subId,
          defaultUnitId: Value(units.mlId),
        ),
      );
  final supId = await db.into(db.suppliers).insert(
        SuppliersCompanion.insert(name: 'TestSup', normalizedName: 'testsup'),
      );
  final recId = await db.into(db.receipts).insert(
        ReceiptsCompanion.insert(
          date: DateTime(2026, 9, 1),
          supplierId: supId,
        ),
      );
  final gramLineId = await db.into(db.receiptLines).insert(
        ReceiptLinesCompanion.insert(
          receiptId: recId,
          itemId: butterId,
          unitId: units.gramId,
          quantity: 250.0,
          priceCents: 2,
          lineTotalCents: 500,
        ),
      );
  final mlLineId = await db.into(db.receiptLines).insert(
        ReceiptLinesCompanion.insert(
          receiptId: recId,
          itemId: milkId,
          unitId: units.mlId,
          quantity: 1500.0,
          priceCents: 1,
          lineTotalCents: 1500,
        ),
      );
  return (
    kiloId: units.kiloId,
    litroId: units.litroId,
    gramLineId: gramLineId,
    mlLineId: mlLineId,
  );
}

void main() {
  group('Migration v1→v2', () {
    test('καθαρή v1: remap ειδών + delete legacy (χωρίς γραμμές)', () async {
      final db = inMemoryDb(skipSeed: true);
      addTearDown(db.close);
      await db.customSelect('SELECT 1').get();
      final units = await _seedV1Units(db);
      final catId = await db.into(db.categories).insert(
            CategoriesCompanion.insert(name: 'TestCat'),
          );
      final subId = await db.into(db.subCategories).insert(
            SubCategoriesCompanion.insert(name: 'TestSub', categoryId: catId),
          );
      await db.into(db.items).insert(
            ItemsCompanion.insert(
              name: 'Βούτυρο',
              normalizedName: 'βουτυρο',
              subCategoryId: subId,
              defaultUnitId: Value(units.gramId),
            ),
          );

      await migrateV1ToV2(db);

      final names =
          (await db.select(db.units).get()).map((u) => u.name).toSet();
      expect(names, {'Τεμάχιο', 'Κιλό', 'Λίτρο'});
      final butter = await (db.select(db.items)
            ..where((t) => t.name.equals('Βούτυρο')))
          .getSingle();
      expect(butter.defaultUnitId, units.kiloId);
    });

    test('γραμμές: μετατροπή με ΑΚΡΙΒΩΣ ίδιο σύνολο', () async {
      final db = inMemoryDb(skipSeed: true);
      addTearDown(db.close);
      final ids = await _seedV1Db(db);

      await migrateV1ToV2(db);

      final gramLine = await (db.select(db.receiptLines)
            ..where((t) => t.id.equals(ids.gramLineId)))
          .getSingle();
      expect(gramLine.unitId, ids.kiloId);
      expect(gramLine.quantity, closeTo(0.25, 1e-9));
      expect(gramLine.priceCents, 2000);
      expect(gramLine.lineTotalCents, 500);

      final mlLine = await (db.select(db.receiptLines)
            ..where((t) => t.id.equals(ids.mlLineId)))
          .getSingle();
      expect(mlLine.unitId, ids.litroId);
      expect(mlLine.quantity, closeTo(1.5, 1e-9));
      expect(mlLine.priceCents, 1000);
      expect(mlLine.lineTotalCents, 1500);
    });

    test('idempotent: 2η κλήση no-op', () async {
      final db = inMemoryDb(skipSeed: true);
      addTearDown(db.close);
      await _seedV1Db(db);

      await migrateV1ToV2(db);
      await migrateV1ToV2(db);

      final units = await db.select(db.units).get();
      expect(units.length, 3);
      expect(
        (await db.select(db.receiptLines).get()).length,
        2,
      );
    });

    test('χωρίς legacy → no-op', () async {
      final db = inMemoryDb(skipSeed: true);
      addTearDown(db.close);
      await db.customSelect('SELECT 1').get();
      await db.into(db.units).insert(
            UnitsCompanion.insert(name: 'Κιλό', abbreviation: 'κιλ'),
          );

      await migrateV1ToV2(db);

      expect((await db.select(db.units).get()).length, 1);
    });

    test('λείπει στόχος → throws + rollback (τίποτα δεν αλλάζει)', () async {
      final db = inMemoryDb(skipSeed: true);
      addTearDown(db.close);
      await db.customSelect('SELECT 1').get();
      await db.into(db.units).insert(
            UnitsCompanion.insert(name: 'Τεμάχιο', abbreviation: 'τεμ'),
          );
      await db.into(db.units).insert(
            UnitsCompanion.insert(name: 'Γραμμάριο', abbreviation: 'γρ'),
          );

      await expectLater(() => migrateV1ToV2(db), throwsA(isA<StateError>()));

      final names =
          (await db.select(db.units).get()).map((u) => u.name).toSet();
      expect(names, {'Τεμάχιο', 'Γραμμάριο'});
    });

    test('κανένα orphan: FK check + όλα τα refs έγκυρα', () async {
      final db = inMemoryDb(skipSeed: true);
      addTearDown(db.close);
      await _seedV1Db(db);

      await migrateV1ToV2(db);

      final violations =
          await db.customSelect('PRAGMA foreign_key_check').get();
      expect(violations, isEmpty);
      final unitIds =
          (await db.select(db.units).get()).map((u) => u.id).toSet();
      for (final item in await db.select(db.items).get()) {
        if (item.defaultUnitId != null) {
          expect(unitIds, contains(item.defaultUnitId));
        }
      }
      for (final line in await db.select(db.receiptLines).get()) {
        expect(unitIds, contains(line.unitId));
      }
    });

    test('e2e: file-DB v1 → reopen → onUpgrade μετατρέπει', () async {
      final dir = await Directory.systemTemp.createTemp('times_migv1v2_');
      addTearDown(() async {
        try {
          await dir.delete(recursive: true);
        } catch (_) {
          // Windows file-handle best-effort καθαρισμός.
        }
      });
      final file = File('${dir.path}${Platform.pathSeparator}mig.db');

      final db1 = AppDatabase(executor: NativeDatabase(file), skipSeed: true);
      await _seedV1Db(db1);
      // Πραγματικό v1-shape: η στήλη έκπτωσης ΔΕΝ υπήρχε (προστέθηκε στη v3).
      await db1.customStatement(
        'ALTER TABLE receipt_lines DROP COLUMN discount_cents',
      );
      await db1.customStatement('PRAGMA user_version = 1');
      await db1.close();

      final db2 = AppDatabase(executor: NativeDatabase(file));
      addTearDown(db2.close);
      await db2.customSelect('SELECT 1').get();

      final names =
          (await db2.select(db2.units).get()).map((u) => u.name).toSet();
      expect(names, {'Τεμάχιο', 'Κιλό', 'Λίτρο'});
      final lines = await db2.select(db2.receiptLines).get();
      expect(lines.length, 2);
      expect(
        lines.map((l) => l.lineTotalCents).toList(),
        containsAll([500, 1500]),
      );
    });
  });
}
