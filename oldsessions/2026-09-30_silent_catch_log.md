# Κεφ. 74 — Log σε corrupt chart-config (30-09-2026)

> Δύο σιωπηλά `catch (_)`: το save-button αποδείχθηκε καλυμμένο (καμία αλλαγή)· το chart-config πήρε error log.

## Spot 1 — `save_receipt_button:56`: καμία ενέργεια (αποδεδειγμένα)

- Validation → controller:199 (UI tag) · απρόβλεπτο → controller:252-258 (DB tag + stack) · DB → DAO guard (log+rethrow) + repo mapping. Κάθε δρόμος λογκαρίστηκε ακριβώς μία φορά upstream· το widget κάνει σωστά μόνο feedback (§2.0.6/§1.7).

## Spot 2 — `settings_repository_impl:73`: fix

- `catch (_) → catch (e, s)` + `AppLogger.error(LogTag.ui, 'Ανάγνωση γραφημάτων απέτυχε — χρήση defaults', e, s)` (καθρέφτης `ThemeModeController.build:78`).
- Ίδιο log στο non-Map early-return· null/empty σιωπηλά (πρώτο run)· συμπεριφορά (defaults) αμετάβλητη· header-doc ενημερωμένο· import ακίνδυνο (logger ← foundation/debug_config).

## Επαλήθευση (30-09-2026)

- **31/31** ✓ (+2: corrupt JSON + array → defaults + log) · `flutter analyze` No issues ✓.
- Backup `backups/2026-09-30_silent_catch_log/` (impl + test + oldsessions).
- `DESIGN.md` αμετάβλητο (§1.7 ήδη το επιβάλλει).
