/// Migration baseline tests για το `AppDatabase` (30-09-2026) — §3 DESIGN.
///
/// Το `schemaVersion` 4 είναι το production baseline (μοναδική εγκατάσταση
/// με πραγματικά δεδομένα). Κανόνας: κάθε bump συνοδεύεται από migration
/// step στο `onUpgrade` + ενημέρωση αυτών των tests — ποτέ wipe, ποτέ
/// επανεγκατάσταση. Τρέχουν σε in-memory SQLite (κοινό helper
/// `in_memory_db.dart`, όχι δικό τους copy).
library;

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/in_memory_db.dart';

void main() {
  group('AppDatabase migration baseline (v4)', () {
    test('schemaVersion == 4 (tripwire: bump θέλει step + test update)', () {
      final db = inMemoryDb();
      addTearDown(db.close);

      // Αν αυτό σπάσει, κάποιος έκανε bump: προσθέτει migration step στο
      // `onUpgrade` (§3 DESIGN) και ενημερώνει το baseline εδώ.
      expect(db.schemaVersion, 4);
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
  });
}
