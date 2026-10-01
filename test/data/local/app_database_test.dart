/// Unit tests για το `AppDatabase` (Φάση 1, Βήμα 1) — §3 + §4.1 DESIGN.
///
/// Τρέχουν σε in-memory SQLite (Βήμα 2+: κοινό helper `in_memory_db.dart`).
library;

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/debug/debug_config.dart';
import 'package:times/core/logging/app_logger.dart';
import 'package:times/data/local/app_database.dart';

import 'helpers/in_memory_db.dart';

/// Βάση της οποίας το `close()` κρεμάει για πάντα (προσομοίωση hang
/// συσκευής 27-09-2026) — το probe `SELECT 1` απαντά κανονικά.
class _HangingCloseDb extends AppDatabase {
  _HangingCloseDb()
      : super(executor: NativeDatabase.memory(), skipSeed: true);

  @override
  Future<void> close() => Completer<void>().future;
}

void main() {
  group('AppDatabase', () {
    tearDown(() {
      AppLogger.resetTestSink();
      DebugConfig.reset();
    });

    // Στιγμιότυπο σε μνήμη (κοινό helper)· το κλείσιμο ανατίθεται στο framework.

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
          'categories',
          'sub_categories',
          'units',
          'items',
          'suppliers',
          'receipts',
          'receipt_lines',
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

  group('AppDatabase.closeSafely (restore)', () {
    test(
      'close που κρεμάει → ολοκληρώνεται μετά το timeout (χωρίς hang)',
      timeout: const Timeout(Duration(seconds: 30)),
      () async {
        final lines = <String>[];
        AppLogger.testSink = lines.add;
        addTearDown(AppLogger.resetTestSink);

        final db = _HangingCloseDb();
        await db.closeSafely();

        expect(lines.join('\n'), contains('probe SELECT 1 OK'));
        expect(lines.join('\n'), contains('TIMEOUT'));
      },
    );

    test(
      'timeout → flag επαναφορά: 2η κλήση ξαναδοκιμάζει (R1 · 01-10)',
      timeout: const Timeout(Duration(seconds: 60)),
      () async {
        final lines = <String>[];
        AppLogger.testSink = lines.add;
        addTearDown(AppLogger.resetTestSink);

        final db = _HangingCloseDb();
        await db.closeSafely();
        await db.closeSafely();

        // Δύο κύκλοι (όχι no-op στη 2η) — το retry επιτρέπεται.
        expect('TIMEOUT'.allMatches(lines.join('\n')).length, 2);
      },
    );
  });
}