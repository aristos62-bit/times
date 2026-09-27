# Κεφάλαιο 53 — Seed καταλόγου v3 (27-09-2026)

> Προσαρμογή `supermarket_categories_v3.md`: 6 κατηγορίες · 28 υποκατηγορίες ·
> 183 τμήματα · 0 είδη. Διπλοεγγραφές του .md επιλύθηκαν εκεί από τον χρήστη
> (Γαλοπούλα εκτός Κρεάτων · «Σαρδέλα φρέσκια/Σολομός κομμάτι/Τόνος κομμάτι» ·
> «Σαμπουάν Μαλιών» · Σοκολάτα εκτός Μαρμελάδων).

## Αρχεία

- ΝΕΑ: `seed_categories.dart` (6) · `seed_sub_categories.dart` (28) ·
  `seed_item_groups.dart` (183) — όλα <500 γρ.
- Αλλαγμένα: `seed_runner.dart` (imports, doc) · `seed_data_test.dart`
  (counts 6/28/183, normalized-μοναδικότητα, αναφορές, spot checks) ·
  `seed_database_test.dart` (6/28/183/0 + normalizedName δείγμα).
- Reference: `supermarket_categories_v3.md` (root, committed όπως το v2).

## Επαλήθευση

- `flutter analyze` — No issues (διορθώθηκαν 2 unused imports).
- `flutter test --timeout 60s` — **1249/1249** ✓ (+3 net).
- Backup `backups/2026-09-27_catalog_v3_seed/` (+προηγούμενο `backups/2026-09-27_catalog_4level/`).
