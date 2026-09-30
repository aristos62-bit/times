# Κεφ. 73 — Retention auto-backups (keep 5) (30-09-2026)

> Κάθε restore άφηνε μόνιμο `auto_<ts>.sqlite` στο docs. Τώρα κρατιούνται τα 5 νεότερα μετά από επιτυχημένο restore.

## Σχεδιασμός (Q ✓)

- `AppConstants.autoBackupRetentionCount = 5` (δίπλα στο `backupFileNamePattern`).
- `BackupService.pruneAutoBackups({keep})`: list docs → φίλτρο `auto_times_backup_*.sqlite` → sort φθίνον (filenames χρονολογικά) → delete πέραν keep via `deleteTemp`. Ποτέ throw (try/catch + `keep<1` no-op) — το restore δεν αποτυγχάνει εξαιτίας retention.
- Κλήση στον controller μετά το finally, πριν το success-return — μόνο σε επιτυχία· αποτυχία = όλα μένουν· rollback ανεπηρέαστο (path).

## Αλλαγές (0 νέα strings)

service + const + 2 service-tests + 1 controller-test · `DESIGN.md` §2.3 (μία φράση).

## Ευρήματα

- P3 ήθελε καθαρισμό παλιών autos (ίδιο wart `VACUUM INTO`-σε-υπάρχον ίδιου second με το R4) — fixture, όχι implementation.
- Εκτός scope (καταγεγραμμένα): ορφανά `export_tmp_*` από crash · dangling ref «§1.9» στο DESIGN.

## Επαλήθευση (30-09-2026)

- Service **22/22** ✓ · controller **13/13** ✓ · `flutter analyze` No issues ✓.
- Backup `backups/2026-09-30_auto_retention/` (service + const + 2 tests + DESIGN + oldsessions).
