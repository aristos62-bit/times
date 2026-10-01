# Κεφ. 79 — Flaky auto-timestamp στο CI (01-10-2026)

> Τοπικά 1546/1546, αλλά το workflow έσπασε στο P1 retention test.

## Αιτία

`autoBackupCurrent` ονομάζει με ανάλυση δευτερολέπτου. Στο γρήγορο CI, το παλιό auto-test και το P1 έτρεξαν στο ίδιο second → ίδιο filename → `VACUUM INTO` σε υπάρχον target → `BackupCreationException`. Τοπικά περνούσε από τύχη χρονισμού. (Το ίδιο wart είχε φανεί στα R4/P3 — τώρα χτύπησε και το service test.)

## Fix (test-only)

Καθαρισμός παλιών `auto_*` πριν το `autoBackupCurrent`: στο P1 (έσπασε) + προληπτικά στο προϋπάρχον auto-test (ίδιο ρίσκο). Inline pattern R4/P3.

## Επαλήθευση

- 22/22 ✓ (από χρήστη) · `flutter analyze` No issues ✓.
- Commit `d2d8bc5` + push — workflow ξανατρέχει (αποτέλεσμα εκκρεμεί).
- Backup `backups/2026-10-01_auto_flaky/` (test + oldsessions).
