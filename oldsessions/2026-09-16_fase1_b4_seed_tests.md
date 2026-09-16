# Φάση 1 — Βήμα 4: Seed-import tests στα DAOs

> Ημερομηνία: 16-09-2026 · Αναφορά: DESIGN §4.1.34 (απαιτήσεις Βήματος 4), κεφάλαιο 4 (Βήμα 3)

## Τι υλοποιήθηκε

- **`test/data/local/seed/seed_database_test.dart`** — συμπλήρωση με τα requests του DESIGN §4.1.34:
  - `normalizedName` **exact match** = `GreekTextNormalizer.normalize(name)` για κάθε ένα από τα 535 είδη στη βάση (όχι μόνο non-empty όπως στο Βήμα 3).
  - Units: **όνομα + abbreviation** επαληθευμένα ένα-προς-ένα από τα `seedUnits`.
  - Categories: `createdAt` ρυθμισμένο (default βάσης `currentDateAndTime`).
  - **Ατομικότητα σε σφάλμα**: seed αποτυγχάνει στη μέση → rollback, καμία εγγραφή.
  - **`onCreate` τρέχει μία φορά**: επανα-άνοιγμα του ίδιου DB αρχείου δεν ξανα-κάνει seed.

## Αποφάσεις που λήφθηκαν

- **Ατομικότητα**: ο έλεγχος τρέχει `runSeed(db)` μέσα σε ρητό `db.transaction`, αφού προ-εισαχθεί (εκτός transaction) ένα marker Item με `normalizedName` ίσο με του 1ου seed item → το seed προχωράει units/categories/subcategories και αποτυγχάνει στο 1ο insert είδους (UNIQUE `normalized_name`). Το rollback επιβεβαιώνει **μηδέν** εγγραφές seed (ούτε units). Αυτό προσομοιώνει τα semantics του transactional `onCreate` που απαιτεί ο §4.1.34.
- **ΔΕΝ προστέθηκε `db.transaction` μέσα στον ίδιο τον `runSeed`**: το `onCreate` εκτελείται μέσω του `_BeforeOpeningExecutor` της drift ενώ το open βρίσκεται σε εξέλιξη — ρητό `db.transaction` εκεί θα έκανε `ensureOpen` που βρίσκεται ήδη σε flight (ρίσκο deadlock). Η ατομικότητα έρχεται από το container του migration.
- **Reopen test**: χρειάζεται persistence → **file-based** `NativeDatabase(File)` σε temp dir (η in-memory δεν επιμένει). 1ο open → seed (5/9/53/535) · close · 2ο open του ίδιου αρχείου → counts παραμένουν ακριβώς (αν ξανα-έτρεχε seed, items=1070 ή UNIQUE violation).
- **`isNull`/`isNotNull` ambiguity**: drift exports δικά του `isNull`/`isNotNull` operators που συγκρούονται με τα matchers του `flutter_test`. Λύση: αφαιρέθηκε εντελώς το `import package:drift/drift.dart` από αυτό το test file — `SqliteException` έρχεται από το `drift/native.dart` και τα companions/data-classes από το `app_database.dart`.

## Verification

- `flutter analyze` → **No issues found**.
- `flutter test` → **227/227** ✓ (224 → 227: +3 νέα tests: createdAt · ατομικότητα · reopen-once; ισχυροποιήθηκαν counts, μονάδες+abbreviation, normalizedName exact).

## Debug που βρήκαμε

- Δεν χρειάστηκε `DelegatedQueryExecutor` wrapper για το atomicity test: η injection μέσω UNIQUE conflict marker είναι πιο αντιπροσωπευτική του μηχανισμού ελέγχου της βάσης (UNIQUE/FK) και αποφεύγει υποθέσεις για internals της drift.
- Η drift export-άρει `isNull`/`isNotNull` (query builders) — σε test files που κάνουν `import drift` + `flutter_test`, τα matchers πρέπει να έρχονται από το matcher (ή να κρύβονται τα drift operators). Εδώ λύθηκε με αφαίρεση του drift import.

## Backups

- `backups/seed_data_test_before_step4_20260916_113056.dart`
- `backups/seed_database_test_before_step4_20260916_113056.dart`

## Σημείωση DESIGN.md

- ΚΑΜΙΑ αλλαγή: το Βήμα 4 ήταν ήδη πλήρως σχεδιασμένο στον §4.1.34 (κανόνας 8 AGENTS).