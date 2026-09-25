# Φάση 4 — Βήμα 5: BackupService + UI (25-09-2026)

> Κατάσταση: **Κλειστό**. Backup `backups/2026-09-24_fase4_b5_backup/`
> (10 lib/test αρχεία + DESIGN + pubspec πριν το βήμα · tests με backup δικό τους).
> Βάση εκκίνησης: 995/995 (rows #35–36: migration v1→v2, έκπτωση+prefill v3).

---

## 1. Σκοπός

Export (`VACUUM INTO` + save dialog) · Restore (validate → confirm →
υποχρεωτικό auto-backup → `closeSafely` → replace → restart providers) —
DESIGN §2.3:295-298 + §4:486. 5ο collapsible Card «Αντίγραφα ασφαλείας»
στη SettingsPage. Μηδέν αλλαγές Φάσης 3.

## 2. Υλοποίηση

- `domain/services/backup_service.dart` (νέο, ~200 γρ.): `buildBackupFileName`
  (SPoT pattern, manual pad) · `exportSnapshot` (VACUUM INTO, εκτός
  transaction) · `validateBackupFile` (magic + 7 πίνακες, read-only,
  καμία αλλαγή) · `replaceDatabaseFile` (προϋπόθεση: closeSafely) ·
  `autoBackupCurrent` + `exportTempPath`/`currentDbFile` · σφάλματα → mapped
  `AppException` (pattern repos).
- `data/local/app_database.dart` (+~20): `_closed` + `closeSafely()`
  idempotent (απόφαση Β).
- `data/providers/database_providers.dart` (+3): `onDispose(db.closeSafely)`.
- `data/providers/backup_file_picker.dart` (νέο, 46 γρ.): `BackupFilePicker`
  interface + `FilePickerBackupPicker` (testability, pattern prefs/db).
- `data/providers/settings_providers.dart` (+~30): `backupServiceProvider` +
  `backupFilePickerProvider` (cascade invalidation μέσω DB provider).
- `presentation/settings/controllers/backup_restore_controller.dart` (νέο,
  ~150): plain Notifier + `_guarded` + export/validateCandidate/restoreBackup
  (reset φορμών `resetForm` + `onQueryChanged('')` — stale ids → FK).
- `presentation/settings/widgets/backup_restore_section.dart` (νέο, ~150):
  dumb, Wrap buttons + spinner (pattern save button), Confirm destructive,
  `runControllerOp`, καμία `AsyncValue` (όπως Theme — data-less section).
- `presentation/shared/controller_op_runner.dart` (+3): catch `AppException`
  (έπιανε μόνο DataLoadException — τα backup throws θα ξέφευγαν).
- `settings_page.dart` (+~25): 5ο Card (placeholder :30 σβήστηκε).
- SPoT: strings +3 (`titleBackupSection/backupExportAction/RestoreAction`) ·
  messages +2 (`backupCreated`, `restoreConfirmWithBackup`) · consts/errors 0.
- Deps: `path_provider` + `sqlite3` (main) · `path_provider_platform_interface`
  + `plugin_platform_interface` (dev, test fakes).

## 3. Ευρήματα (εκτέλεση, όχι θεωρία)

- **Ε1 — file_picker 12 `saveFile` θέλει bytes (δίνει `Uri?`, όχι path).**
  Το κλειδωμένο «save dialog → path → VACUUM INTO» ΔΕΝ υλοποιείται.
  Προσαρμογή (ΟΚ χρήστη): snapshot temp → bytes → `saveFile` · DESIGN §2.3
  ενημερώθηκε αντίστοιχα. `pickFile→PlatformFile?/path` για restore ΟΚ.
- **Ε2 — v12 API χωρίς `.platform`** (`FilePicker.saveFile/pickFile`
  απευθείας) + `pickFiles→List<PlatformFile>` (χρησιμοποιήθηκε το singular
  `pickFile`). Επιβεβαιώθηκε από source pub cache, όχι docs-μνήμης.
- **Ε3 — drift background isolate + widget fake-async = hang** (precedent Ε2
  Βήματος 4): VACUUM/submit μέσω tap κολλάει. Validate → sqlite3 read-only
  στο ίδιο isolate (zone-proof) · export/restore submits ΜΟΝΟ σε controller
  tests (real async) · widget tests = wiring/διαλόγοι μόνο.
- **Ε4 — async File IO κολλάει σε widget zone** (empirical: exists=true /
  open=false): validation με *Sync IO (`existsSync/openSync/readSync`) +
  σχόλιο αιτιολόγησης. Κόστος μs.
- **Ε5 — plugin_platform `implements` assertion + ctor χωρίς token** (v2.1.3):
  fake = `extends + MockPlatformInterfaceMixin`, χωρίς `super(token:)`.
- **Ε6 — `runControllerOp` έπιανε μόνο `DataLoadException`** → επέκταση σε
  `AppException` (backward compatible).
- **Ε7 — pumpAndSettle vs snackbar-timer**: σκέτο `pump` + `runAsync` delay
  (house pattern `new_item_flow_dialog`) · `pumpUntil` απορρίφθηκε.
- **Ε8 — Windows file-locks**: best-effort cleanup (precedent seed test).
- Μικρά: `probe.dispose→close` (deprecated) · `pickFile` με `FileType.custom`
  + extensions · sqlite3.dll lock από νεκρά test processes (kill).
- Ενδιάμεση ανακάλυψη: το δέντρο είχε schemaVersion 3 (discount session) ενώ
  η πρόταση γράφτηκε πάνω σε v1 — καταγράφηκε διαφανώς, 0 επίπτωση
  (995 + 29 = 1024 ✓).

## 4. Tests (995 → 1024, +29)

- SPoT gates (+3: strings exact+gate · messages ×2+gate).
- ΝΕΟ `backup_service_test` (9): filename ×2 · export/validate ΟΚ ·
  export-fail → BackupCreation · auto (prefix+exists) · replace round-trip ·
  missing/junk/thin-tables → Invalid.
- ΝΕΟ `backup_restore_controller_test` (7): export ok/cancel/picker-throw ·
  validate ok/invalid · restore ok (auto + reset φόρμας) / invalid (βάση
  ανοιχτή).
- ΝΕΟ `backup_restore_section_test` (9): wiring · pick-cancel · invalid→error
  · valid→dialog · dialog-cancel · 3 μεγέθη · dark.
- `settings_page_test` (+1/updates: 3→4 tiles, expand backup).
- `test/helpers/fake_path_provider.dart` (shared fake, `extends`+mixin).
- `flutter analyze` No issues ✓ · `flutter test --timeout 60s` **1024/1024** ✓
  · κανένα `.dart` >500 γρ.

## 5. Συμβόλαια/ανοιχτά

- Web restore: `path==null` → no-op (MVP όριο, τεκμηριωμένο στο wrapper).
- Auto-backups μένουν στο docs (καθαρισμός = μελλοντικό Βήμα 6/επέκταση).
- Επόμενο: Βήμα 6 — Housekeeping (μόνο με ρητό OK).
