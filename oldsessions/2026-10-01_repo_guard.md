# Κεφ. 81 — Shared `guardRepo` (01-10-2026)

> Στην παραγωγή τα DB σφάλματα φτάνουν ως `DriftRemoteException` (όχι `SqliteException`) — τα 10 catches έχαναν (catalog crash / receipts degraded).

## Απόδειξη (πηγή drift 2.35, όχι εικασία)

`protocol.dart:32-36` (error→String) → `communication.dart` (client ρίχνει `DriftRemoteException`) · `serialize` default-true στα isolate channels. Τα tests βλέπουν `SqliteException` (ίδιο isolate) — γι' αυτό δεν φαινόταν.

## Αλλαγές (0 νέα strings)

- Νέο `lib/data/repositories/repo_guard.dart` (`on Exception`· `Error` εκτός σκόπιμα).
- 8 `_guard` → διαγραφή + κλήση (46 call sites) · receipt ×2 inline · 5 headers + abstract + NOTE ξαναγραμμένα.
- Tests: double `Exception('boom')` → `DataLoadException` (red-green) · FK receipt υπάρχει ήδη.

## Επαλήθευση (01-10-2026, από χρήστη)

- Νέο test + receipt **19/19** ✓ · όλα τα repos **184/184** ✓ · `flutter analyze` No issues ✓.
- Device UNIQUE test (production topology) — εκκρεμεί από χρήστη.
- Backup `backups/2026-10-01_repo_guard/` (10 lib/test).
