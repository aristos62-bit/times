# Restore: timeout στο `close()` (27-09-2026)

> Κατάσταση: **Κλειστό.**
> Σύμπτωμα χρήστη: η Επαναφορά κολάει μετά το «Ναι» του confirm —
> χρειάζεται kill της εφαρμογής, το restore δεν γίνεται.

---

## 1. Διάγνωση (αποδεδειγμένη, όχι υποθέσεις)

- Προστέθηκαν 12 `AppLogger.info` πριν από κάθε await του restore
  (controller/service/widget/`closeSafely`) + 2 probes — όλα υπάρχον
  infra (`LogTag.backup`/`db`, debug-only).
- Log συσκευής: validation ΟΚ ×2 · auto-backup ΟΚ · **όλα τα streams
  `false`** (η θεωρία των ανοιχτών συνδρομών καταρρίφθηκε) · **probe
  `SELECT 1` ΟΚ σε 45ms** (ο executor ζωντανός, κανένα transaction) ·
  μετά `κλείσιμο βάσης…` → σιωπή. **Κρεμάει το ίδιο το drift `close()`**
  (teardown background isolate).

## 2. Fix

- `closeSafely`: `await close().timeout(restoreCloseTimeoutSeconds=5,
  SPoT)` → `on TimeoutException`: info log + συνέχεια στο replace
  (αντί freeze)· αποτυχία replace → mapped `RestoreBackupException` +
  snackbar (ήδη σχεδιασμένο path).
- Νέο test (`app_database_test`, με `timeout: 30s`): subclass με `close()`
  που κρεμάει → το `closeSafely` ολοκληρώνεται (~5'') + asserts στα logs.
- Απόδειξη συσκευής: `TIMEOUT` → replace → `Επαναφορά ολοκληρώθηκε` +
  snackbar · δεδομένα επαληθευμένα από χρήστη. Drift warning
  multiple-instances (debug-only, αβλαβές — η παλιά instance μένει ορφανή).
- Τα διαγνωστικά logs ΜΕΝΟΥΝ (debug-only, κόβονται σε release).

## 3. Tests / Docs

- Targeted: backup 27/27 + app_database (με το νέο) ✓ · `flutter
  analyze` **No issues** ✓ (full suite δεν ξανατρέχθηκε — εκκρεμεί).
- DESIGN.md: ΚΑΜΙΑ αλλαγή (συμπεριφορά + safety net αμετάβλητα).
- Backups: `backups/2026-09-27_restore_debug_logs/` (pre-logs + `.probe.bak`
  + test `.bak`) · revert μίας εντολής: `git checkout --` στα 6 αρχεία
  (όλα uncommitted, §4).
