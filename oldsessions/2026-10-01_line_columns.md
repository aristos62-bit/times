# Κεφ. 88 — Parity + στήλες συνόλων (01-10-2026)

> Edit-parity (stored lineTotalCents) + στήλες Τιμή/Έκπτωση/Σύνολο/Καθαρή σε οθόνη+Excel+PDF.

## Α. Parity (edit → entry ίδιο σύνολο)

- `receipt_form_controller.dart:347` → `enteredTotalCents: l.lineTotalCents` (ακριβέστερο του typed στο ±1).
- Docs controller/state/widget + `DESIGN:509` · discount-κλάδος/save άθικτα.
- Tests 398-update + 695-regression (προηγούμενο βήμα).

## Β. Στήλες (Τιμή unit · Έκπτωση d×q · Σύνολο p×q · Καθαρή stored-net)

- `line_total.dart:21-32` → `grossTotalCents` + `discountTotalCents` (pure, ±1 doc).
- `app_strings.dart:247` → `statsColumnTotal='Σύνολο'`.
- UI: `statistics_table.dart` 8 · `purchases_table.dart` 9+N · `statistics_analysis_shared.dart` headers/body 9+N · preview/grouped auto via reuse.
- Export: ledger 7→8 (headers/cells/footer G→H) · purchases 8+N→9+N (`priceCol+2`→`+3`, footer) · ledger PDF inline 7→8.
- Part-fix: import `line_total` από part → library (`statistics_section.dart:18`) — `non_part_of_directive_in_part`.
- `DESIGN.md:366-367` → 8 στήλες + 4 ονόματα.

## Επαλήθευση

- `flutter analyze` No issues (ολικό).
- Tests: export 18/18 · line_total 8/8 (+2) · strings 44/44 · tables 3/3+3/3 · section 33/33.
- Backups `backups/2026-10-01_line_columns/` + `backups/2026-10-01_edit_parity/`.
