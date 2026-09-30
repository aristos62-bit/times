# Κεφ. 78 — Docs audit σελίδων + SPoT parse (30-09-2026)

> Έλεγχος τεκμηρίωσης σε όλες τις σελίδες (4 subagents) + 2 μικρές code-αλλαγές που έκαναν τα docs αληθή.

## Ευρήματα (~20, όλα επαληθευμένα με ανάγνωση πριν το edit)

- home: «5 πίτες» (6 κάρτες) · family-instance → 3 κάρτες · stray doc πάνω σε picker · «κάρτα Βήματος 4» (3 widgets) · top_items «κάτω από period» (δίπλα-δίπλα Row).
- price_entry: «μόνη repo πρόσβαση» (save/load/delete/guards) · «Βήμα 3» (όνομα = 4) · «προτεινόμενη μονάδα» ×2 (κλείδωμα) · discount απόλυτο (total-mode) · «καθρέφτης ορισμάτων» (+4 display πεδία) · onCleared scope.
- settings: sections/watches/θέση/Backup data-less · recase (2 controllers: γράφεται, όχι no-op) · «9 στήλες» (8+N) · «δύο κουμπιά» (3) · tree «4 επιπέδων» (3 ορατά) · dialog χωρίς Τμήμα · state «Κατηγοριών» (5 controllers).
- shared: `/` → `./,` · «στους δύο» (τρεις) · INVARIANT χωρίς assert · parse hardcoded vs «χωρίς hardcoded» · «πάντα μη-κενή» (χωρίς createLabel αδειάζει).

## Code (Βήμα 2 — έκανε 2 docs αληθή)

- `assert(createLabel == null || onCreate != null)` (όλοι οι καλούντες συμμορφώνονται — grep).
- `parseCents`/`formatCents`/`parseQuantity` παραγόμενα από `priceDecimalDigits`/`quantityDecimalDigits` (`pow`, ίδια συμπεριφορά).

## Πάθημα (format)

Bare `dart format lib/presentation` → 51 αρχεία churn + νέο lint (`curly_braces` από reflow — ο formatter έσπασε same-line `if`) → πλήρες revert + replay 20 edits. Κανόνας: format μόνο σε αγγιγμένα αρχεία, ποτέ directory (το repo δεν είναι format-clean).

## Επαλήθευση (30-09-2026, από χρήστη)

- Full **1546/1546** ✓ · parse/format **23/23** ✓ · dropdown **18/18** ✓ · `flutter analyze` No issues ✓.
- Backups `backups/2026-09-30_docs_audit/` (19 lib) + `backups/2026-09-30_spot_code/` (3 lib).
