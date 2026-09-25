# Κεφάλαιο 35 — Migration v1→v2: καθαρισμός Γραμμάριο/Χιλιοστόλιτρο

**Ημερομηνία:** 25-09-2026 · **Κατάσταση:** Κλειστό

## Αίτημα χρήστη

Μετά το seed 3 μονάδων (κεφ. 29) τα Γραμμάρια/Χιλιοστόλιτρα συνέχιζαν να
εμφανίζονται στο unit dropdown — η παλιά βάση (v1) δεν ξανα-seedάρεται
(`runSeed` μόνο στο `onCreate`, `schemaVersion` 1). Εγκρίθηκε η τελική
πρόταση migration (3/3 ερωτήσεις: μετατροπή με διατήρηση συνόλου · remap
defaults · migration πρώτα).

## Υλοποίηση

- **ΝΕΟ `lib/data/local/migration_v1_to_v2.dart`** (~110 γρ.): `migrateV1ToV2`
  σε 1 transaction — `PRAGMA FK OFF` εκτός transaction → επίλυση IDs με
  ΑΚΡΙΒΕΣ όνομα (legacy missing→skip/idempotent· στόχος missing→StateError
  +rollback) → items bulk remap (typed API, Α2) → γραμμές bulk
  (`unit_id`→στόχος, `quantity/1000`, `price_cents×1000`, `updates` για
  streams) → deletes → debug `foreign_key_check` → `FK ON` · log tag DB.
- **`app_database.dart`**: import + `schemaVersion 1→2` + `onUpgrade`
  (`from==1`) + docstring (πριν: backup).
- Σκόπιμες αποφάσεις: `line_total_cents` ΑΘΙΚΤΟ (≡, μηδέν FP ρίσκο) ·
  mapping private const (εξαίρεση SPoT — όχι UI strings) · `kDebugMode`
  (Drift docs idiom) · καμία νέα DAO/repo/provider/SPoT/exception μέθοδος ·
  καμία regen `.g.dart` (σχήμα v1≡v2).

## Ευρήματα επανελέγχου (διορθώθηκαν πριν την υλοποίηση)

- Recompute `lineTotalCents` → ΑΘΙΚΤΟ (η τιμή ήδη σωστή).
- Dart row-loop → bulk SQL (6 statements).
- Fixed IDs → name lookup · νέο `AppErrors` → υπάρχον `loadDataFailed` ·
  DAO μέθοδοι → self-contained (όπως `seed_runner`).

## Tests

- ΝΕΟ `test/data/local/migration_v1_to_v2_test.dart` (7): καθαρή v1 ·
  σύνολα byte-identical (500/1500) · idempotent · no-op · missing
  στόχος→throws+rollback · FK/refs · e2e file-DB `user_version=1`→reopen.
- Full suite: **952/952** ✓ (+7) · `--timeout 60s` · `flutter analyze`
  **No issues** ✓.

## Docs/Backup

- `DESIGN.md`: §3 bullet + §5 (migration done → επόμενο BackupService).
- `backups/2026-09-25_migration_v1_v2/`: `app_database.dart`, `DESIGN.md`,
  `oldsessions.md` (πριν τις αλλαγές).
- Σημείωση: παλιό backup v1 αυτο-μετατρέπεται στο restore (open→onUpgrade).
