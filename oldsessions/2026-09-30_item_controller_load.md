# Κεφ. 71 — §2.0.5: lookups είδους → controller (30-09-2026)

> Το `_editItem` του widget διάβαζε 4 repositories κατευθείαν — μοναδική παράβαση §2.0.5 σε όλο το `presentation/`. Μετακόμιση σε `loadItemForEdit`.

## Απόφαση (Q1–Q3, εγκεκριμένες)

- **Q1**: plain μέθοδος (όχι `_guarded` — read-only, κανένα `isWorking`).
- **Q2**: nullable record (υπάρχων null→snackbar δρόμος, όχι throw).
- **Q3**: ένα info log `LogTag.db` στο missing path.

## Αλλαγές (3 αρχεία, 0 νέα strings, dialog/API αμετάβλητα)

1. `lib/presentation/settings/controllers/item_management_controller.dart`: `loadItemForEdit` (αλυσίδα είδος→τμήμα→υποκατηγορία→κατηγορία+μονάδα, `ref.mounted` guards · missing unit → null, όχι abort · + import `app_database.dart`).
2. `lib/presentation/settings/widgets/item_list_editor.dart`: `_editItem` → μία κλήση (3 duplicated blocks → 1) · έφυγε το νεκρό import `database_providers`.
3. Tests (+4, reuse fixture): πλήρης αλυσίδα · χωρίς μονάδα → null · ανύπαρκτο → null · σβησμένη μονάδα (SET NULL) → null.

## Σημειώσεις επανελέγχου

- Το `(ok,error)+isSaving` του `loadReceiptForEdit` δεν ταιριάζει (καταναλωτής dialog-params, όχι controller-state) — υιοθετήθηκαν μόνο τα αμυντικά του (null→`loadDataFailed`, mounted guards).
- Fork: ο controller είναι global singleton → root repos, ταυτόσημα instances — κανένα regression.
- Grep `getById|loadItem|resolveItem` στα providers = 0 — καμία διπλή υλοποίηση.

## Επαλήθευση (από χρήστη, 30-09-2026)

- Controller **14/14** ✓ · editor **7/7** ✓ · `flutter analyze` No issues ✓.
- Backup `backups/2026-09-30_item_controller_load/` (controller + editor + test + oldsessions).
- `DESIGN.md` αμετάβλητο (συμμόρφωση με §2.0.5).
