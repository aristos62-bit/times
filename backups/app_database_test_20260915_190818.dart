/// Unit tests για το `AppDatabase` (Φάση 1, Βήμα 1) — §3 + §4.1 DESIGN.
///
/// Τρέχουν σε in-memory SQLite (`NativeDatabase.memory()`), όχι σε αρχείο.
/// Το `closeStreamsSynchronously: true` αποτρέπει στάσιμους stream queries
/// από το να κρατούν ανοιχτή τη βάση (drift teardown warning).
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/debug/debug_config.dart';
import 'package:times/core/logging/app_logger.dart';
import 'package:times/data/local/app_database.dart';

void main() {
  group('AppDatabase', () {
    tearDown(() {
      AppLogger.resetTestSink();
      DebugConfig.reset();
    });

    // Στιγμιότυπο σε μνήμη· το κλείσιμο ανατίθεται στο test framework.
    AppDatabase inMemoryDb() {
      return AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
    }

    test('δημιουργούνται όλοι οι πίνακες (sqlite_master)', () async {
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
          'Categories',
          'SubCategories',
          'Units',
          'Items',
          'Suppliers',
          'Receipts',
          'ReceiptLines',
        }),
      );
    });

    test('PRAGMA foreign_keys = ON μετά τη δημιουργία', () async {
      final db = inMemoryDb();
      addTearDown(db.close);

      final result = await db.customSelect('PRAGMA foreign_keys').get();

      expect(result.single.read<int>('foreign_keys'), 1);
    });

    test('onCreate + beforeOpen καταγράφονται (AppLogger, tag DB)', () async {
      final lines = <String>[];
      AppLogger.testSink = lines.add;

      final db = inMemoryDb();
      addTearDown(db.close);

      // Trigger migrations (lazy open).
      await db.customSelect('SELECT 1').get();

      expect(
        lines,
        containsAllInOrder(<Matcher>[
          contains('Δημιουργία βάσης'),
          contains('PRAGMA foreign_keys'),
        ]),
      );
    });
  });
}