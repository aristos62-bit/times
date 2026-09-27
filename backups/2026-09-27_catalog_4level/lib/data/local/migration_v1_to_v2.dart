/// Data migration v1 → v2: καθαρισμός Γραμμάριο/Χιλιοστόλιτρο (§3 DESIGN).
///
/// Πλαίσιο: το seed 24-09-2026 κράτησε μόνο Τεμάχιο/Κιλό/Λίτρο, αλλά το
/// `runSeed` τρέχει ΜΟΝΟ στο `onCreate` — εγκατεστημένες βάσεις v1 έχουν
/// ακόμα Γραμμάριο/γρ και Χιλιοστόλιτρο/χλτ και το unit dropdown τα δείχνει.
/// Αυτή η migration τα καθαρίζει στο πρώτο open μετά την αναβάθμιση
/// (τρέχει ΜΙΑ φορά, `PRAGMA user_version` 1→2 — ισχύει και για παλιό
/// backup αρχείο που θα γίνει restore: ανοίγει ως v1 και μετατρέπεται).
///
/// Κανόνες μετατροπής (ίδια λογική με το seed rename 24-09, κεφ. 29):
///   * `Items.defaultUnitId`: remap legacy → στόχος (όχι SET NULL —
///     διατηρείται η προεπιλογή μονάδας στο dropdown, §2.2:236).
///   * `ReceiptLines`: `unit_id` → στόχος, `quantity / 1000`,
///     `price_cents × 1000` — το σύνολο διατηρείται ΑΚΡΙΒΩΣ για
///     οποιοδήποτε μοτίβο εισαγωγής (×1000/÷1000 αλληλοακυρώνονται).
///   * `line_total_cents` ΔΕΝ αγγίζεται: ήδη ισούται με το σωστό σύνολο —
///     minimal diff, μηδέν floating-point ρίσκο, ιστορικό byte-identical.
///   * Match με ΑΚΡΙΒΕΣ όνομα (όχι normalized): το seed έγραφε πάντα
///     ακριβώς «Γραμμάριο»/«Χιλιοστόλιτρο» — ποτέ διαγραφή user δεδομένων.
///   * Idempotent: χωρίς legacy μονάδες → no-op επιτυχία (καλύπτει και
///     βάσεις φτιαγμένες στο μεσοδιάστημα με 3 μονάδες σε v1).
/// Όλα σε ΕΝΑ transaction (είτε όλα είτε τίποτα), σειρά FK-ασφαλής
/// (children πριν parents — δουλεύει και με FK ON, defense in depth).
library;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../core/logging/app_logger.dart';
import 'app_database.dart';

/// Legacy μονάδα → μονάδα αντικατάστασης (μόνο εδώ — σκόπιμη εξαίρεση
/// SPoT: δεν είναι UI strings, οι σβησμένες μονάδες ΔΕΝ πρέπει να
/// εμφανίζονται πουθενά αλλού στο `lib/`).
const Map<String, String> _unitReplacement = <String, String>{
  'Γραμμάριο': 'Κιλό',
  'Χιλιοστόλιτρο': 'Λίτρο',
};

/// 1000 γρ = 1 κιλ · 1000 χλτ = 1 λίτρο (φυσική σταθερά μετατροπής).
const double _perBase = 1000.0;

/// Εκτελεί τη migration v1 → v2 πάνω στη [db].
///
/// Καλείται ΜΟΝΟ από το `onUpgrade` του `AppDatabase` — ποτέ απευθείας
/// από UI/repository (εξαίρεση: tests που ελέγχουν τη συνάρτηση).
/// Αποτυχία → log (tag DB) + rethrow (rollback αυτόματο, το open
/// αποτυγχάνει και τα streams δείχνουν το υπάρχον `loadDataFailed`).
Future<void> migrateV1ToV2(AppDatabase db) async {
  AppLogger.info(LogTag.db, 'Migration v1→v2: έναρξη');
  // OFF ΕΚΤΟΣ transaction (SQLite: no-op εντός — βλ. Drift migrations docs).
  await db.customStatement('PRAGMA foreign_keys = OFF');
  try {
    await db.transaction(() async {
      for (final entry in _unitReplacement.entries) {
        final legacy = await (db.select(db.units)
              ..where((t) => t.name.equals(entry.key)))
            .getSingleOrNull();
        if (legacy == null) {
          AppLogger.info(
            LogTag.db,
            'Migration v1→v2: "${entry.key}" απουσιάζει — skip',
          );
          continue;
        }
        final target = await (db.select(db.units)
              ..where((t) => t.name.equals(entry.value)))
            .getSingleOrNull();
        if (target == null) {
          throw StateError(
            'Migration v1→v2: λείπει η μονάδα στόχος "${entry.value}"',
          );
        }
        // Είδη: bulk remap προτεινόμενης μονάδας (typed drift API, Α2).
        final remappedItems = await (db.update(db.items)
              ..where((t) => t.defaultUnitId.equals(legacy.id)))
            .write(ItemsCompanion(defaultUnitId: Value(target.id)));
        // Γραμμές: bulk remap + μετατροπή (αριθμητική στήλης → raw SQL με
        // bound variables· το `updates` ξυπνά τα reactive streams).
        final remappedLines = await db.customUpdate(
          'UPDATE receipt_lines SET unit_id = ?1, '
          'quantity = quantity / $_perBase, '
          'price_cents = price_cents * ${_perBase.toInt()} '
          'WHERE unit_id = ?2',
          updates: {db.receiptLines},
          variables: [
            Variable.withInt(target.id),
            Variable.withInt(legacy.id),
          ],
        );
        await (db.delete(db.units)..where((t) => t.id.equals(legacy.id))).go();
        AppLogger.info(
          LogTag.db,
          'Migration v1→v2: "${entry.key}" → "${entry.value}" '
          '(είδη: $remappedItems, γραμμές: $remappedLines)',
        );
      }
    });
    if (kDebugMode) {
      final violations =
          await db.customSelect('PRAGMA foreign_key_check').get();
      assert(violations.isEmpty, 'Migration v1→v2: FK violations $violations');
    }
    AppLogger.info(LogTag.db, 'Migration v1→v2: ολοκληρώθηκε');
  } catch (e, s) {
    AppLogger.error(LogTag.db, 'Migration v1→v2 απέτυχε', e, s);
    rethrow;
  } finally {
    await db.customStatement('PRAGMA foreign_keys = ON');
  }
}
