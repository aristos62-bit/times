# Κεφ. 68 — Migration scaffold: `onUpgrade` χωρίς `StateError` (30-09-2026)

> Baseline παραγωγής v4. Το `onUpgrade` έπαψε να ρίχνει `StateError` — log + scaffold για μελλοντικά steps. Καμία αλλαγή σχήματος, κανένα ρίσκο δεδομένων.

## Πρόβλημα

Το `onUpgrade` (`lib/data/local/app_database.dart:77`) έριχνε **πάντα** `StateError` («δεν υπάρχουν χρήστες»). Η εφαρμογή έχει release signing με μοναδική εγκατάσταση σε v4 **με πραγματικές αποδείξεις** — το πρώτο μελλοντικό bump σε v5 θα έσπαγε το άνοιγμα σε υπάρχουσες εγκαταστάσεις (η Drift τρέχει το migration πριν το `beforeOpen`, χωρίς UI recovery).

## Απόφαση (κλειδωμένη με τον χρήστη)

- `schemaVersion` μένει 4 — καμία αλλαγή σχήματος τώρα.
- Καμία εγκατάσταση < v4 σε κυκλοφορία → **κανένα legacy path**, καμία νέα exception, κανένα νέο SPoT string (η ιδέα `SchemaMigrationException` αποσύρθηκε ρητά).
- Κανόνας: κάθε μελλοντικό bump = migration step στο `onUpgrade` + test — ποτέ wipe, ποτέ επανεγκατάσταση.

## Αλλαγές

1. `lib/data/local/app_database.dart` (μόνο αρχείο βήματος 1): header docstring → «baseline παραγωγής v4» · `onUpgrade` → `AppLogger.info(LogTag.db, ...)` + placeholder `if (from < 5)` (τίποτα δεν ρίχνει πια).
2. `test/data/local/app_migration_test.dart` (νέο, 53 γρ.): T1 tripwire `schemaVersion == 4` (σπάει επίτηδες σε bump — αναγκάζει step + update) · T2 smoke 8 πινάκων (reuse `in_memory_db`, όχι copy).
3. `DESIGN.md` §3 (migration note, schema v4) + §4 Φάση 1 (προ-παραγωγή vs baseline) — μηδέν άλλες ενότητες.

## Επαλήθευση

- `flutter analyze` (lib αρχείο + test) — No issues.
- `app_database_test.dart` 4/4 ✓ · `app_migration_test.dart` 2/2 ✓ (πλήρης σουίτα δεν ξανατρέχτηκε — μόνο τα άμεσα σχετικά).
- Backup `backups/2026-09-30_migration_scaffold/` (app_database + DESIGN + oldsessions, hashes ταυτίζονται).

## Ανοιχτά (εκτός scope, μελλοντικά)

- Version-check (`PRAGMA user_version`) στο `validateBackupFile` — το validation ελέγχει μόνο magic+πίνακες.
- `stepByStep` generated (drift codegen) όταν έρθει πραγματική αλλαγή σχήματος v5.
