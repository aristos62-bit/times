# Post-closure: sidecar cleanup στο restore (25-09-2026)

> Κατάσταση: **Κλειστό**. Backup `backups/2026-09-25_sidecar_cleanup/`
> (service + tests + DESIGN πριν το hardening).

---

## 1. Παρατήρηση (όχι bug)

Το `replaceDatabaseFile` αντικαθιστούσε μόνο το main `.sqlite`, χωρίς να
αγγίζει `-wal`/`-shm` (`-journal`). Evidence: drift default = rollback-journal
(WAL opt-in) + `closeSafely()` πριν το copy + salt-protection → πρακτικό
ρίσκο ~0. Σκλήρυνση παρόλα αυτά (future-WAL, καθαρό next-open).

## 2. Υλοποίηση (μόνο `replaceDatabaseFile`, +8 γρ.)

- Reuse `deleteTemp` ×3 (0 νέες μέθοδοι — η v1 με νέο helper απορρίφθηκε).
- Σειρά copy-ΠΡΩΤΑ, cleanup-ΜΕΤΑ (η v1 pre-cleanup απορρίφθηκε: διπλό-σφάλμα
  close+copy θα άφηνε την παλιά βάση χωρίς journal· atomic rename
  απορρίφθηκε: αποτυγχάνει σε υπάρχον target στα Windows).
- Candidate-side sidecars: σκόπιμα άθικτα (αρχεία χρήστη).
- DESIGN §2.3 βήμα 3 (+1 γραμμή).

## 3. Tests (+2, στο υπάρχον αρχείο — κανένα νέο)

- Double-replace με dummy sidecars → περιεχόμενο σωστό + sidecars σβησμένα
  (empirical copy-overwrite Windows).
- Ανύπαρκτο source → `RestoreBackupException` ΚΑΙ target + sidecars άθικτα.
- `flutter analyze` No issues ✓ · σουίτα **1035/1035** ✓ (+2).
