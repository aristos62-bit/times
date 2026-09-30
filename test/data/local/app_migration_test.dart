/// Migration tests για το `AppDatabase` (30-09-2026) — §3 DESIGN.
///
/// Baseline παραγωγής v4 · τρέχουσα v5 (indexes) — μοναδική εγκατάσταση με
/// πραγματικά δεδομένα. Κανόνας: κάθε bump συνοδεύεται από migration step
/// στο `onUpgrade` + ενημέρωση αυτών των tests — ποτέ wipe, ποτέ
/// επανεγκατάσταση. In-memory SQLite (κοινό helper `in_memory_db.dart`) +
/// file-backed raw fixture για το upgrade (pattern `thin7`).
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:times/data/local/app_database.dart';

import 'helpers/in_memory_db.dart';

void main() {
  group('AppDatabase migration baseline (v5)', () {
    test('schemaVersion == 5 (tripwire: bump θέλει step + test update)', () {
      final db = inMemoryDb();
      addTearDown(db.close);

      // Αν αυτό σπάσει, κάποιος έκανε bump: προσθέτει migration step στο
      // `onUpgrade` (§3 DESIGN) και ενημερώνει το baseline εδώ.
      expect(db.schemaVersion, 5);
    });

    test('fresh open: onCreate φτιάχνει και τους 8 πίνακες', () async {
      final db = inMemoryDb();
      addTearDown(db.close);

      // Το πρώτο query ανοίγει/δημιουργεί τη βάση και τρέχει τα migrations.
      final tables = await db
          .customSelect(
            'SELECT name FROM sqlite_master '
            'WHERE type = ? AND name NOT LIKE ?',
            variables: [Variable('table'), Variable('sqlite_%')],
          )
          .get();

      final names = tables.map((r) => r.read<String>('name')).toSet();

      expect(
        names,
        containsAll(<String>{
          'categories',
          'sub_categories',
          'item_groups',
          'units',
          'items',
          'suppliers',
          'receipts',
          'receipt_lines',
        }),
      );
    });

    test('fresh open: και τα 4 ρητά indexes (§3)', () async {
      final db = inMemoryDb();
      addTearDown(db.close);

      final idx = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            'AND name NOT LIKE ?',
            variables: [Variable('sqlite_%')],
          )
          .get();

      final names = idx.map((r) => r.read<String>('name')).toSet();

      expect(
        names,
        containsAll(<String>{
          'idx_receipt_lines_item_id',
          'idx_receipt_lines_receipt_id',
          'idx_receipts_date',
          'idx_receipts_supplier_id',
        }),
      );
    });

    test('upgrade v4 → v5: indexes + δεδομένα + version', () async {
      final dir = Directory.systemTemp.createTempSync('migrate_v4_v5_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = '${dir.path}${Platform.pathSeparator}v4.sqlite';
      // Ελάχιστο v4 σχήμα (μόνο ό,τι αγγίζει το step) + version + 1 γραμμή.
      final raw = sqlite3.open(path);
      raw.execute(
        'CREATE TABLE receipts (id INTEGER PRIMARY KEY, date TEXT NOT NULL, '
        'supplier_id INTEGER NOT NULL)',
      );
      raw.execute(
        'CREATE TABLE receipt_lines (id INTEGER PRIMARY KEY, '
        'receipt_id INTEGER NOT NULL)',
      );
      raw.execute(
        "INSERT INTO receipts (id, date, supplier_id) "
        "VALUES (1, '2026-09-30', 7)",
      );
      raw.execute('PRAGMA user_version = 4');
      raw.close();

      final db = AppDatabase(
        executor: NativeDatabase(File(path)),
        skipSeed: true,
      );
      addTearDown(db.close);

      // Trigger open → onUpgrade(4 → 5).
      final idx = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
          .get();
      final names = idx.map((r) => r.read<String>('name')).toSet();
      expect(
        names,
        containsAll(<String>{
          'idx_receipt_lines_receipt_id',
          'idx_receipts_date',
          'idx_receipts_supplier_id',
        }),
      );
      // Δεδομένα άθικτα + version προχώρησε.
      final rows = await db
          .customSelect('SELECT id, supplier_id FROM receipts')
          .get();
      expect(rows.single.read<int>('supplier_id'), 7);
      final version = await db.customSelect('PRAGMA user_version').get();
      expect(version.single.read<int>('user_version'), 5);
    });
  });
}
