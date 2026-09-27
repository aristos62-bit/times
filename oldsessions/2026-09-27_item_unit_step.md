# Κεφάλαιο 54 — Υποχρεωτική μονάδα στη δημιουργία είδους (27-09-2026)

> Το «θυμάται + εμφανίζει» υπήρχε ήδη (`_applyDefaultUnit`) — έλειπε μόνο η
> είσοδος. Υποχρεωτικό dropdown μονάδας στο Βήμα 4 του dialog → αποθήκευση
> ως `Item.defaultUnitId` → προεπιλογή στο entry.

## Αλλαγές (lib)

- `item_search_controller.createItem`: +`int? defaultUnitId` (προαιρετική —
  υπάρχοντα tests αθίκτα) · null → `(null,false)` · passthrough + log.
- `new_item_flow_dialog`: `Unit? _unit` · dropdown μονάδας στο `_buildNameStep`
  (show-all, reuse pattern `item_edit_dialog`, χωρίς «+») · guard + disabled-OR ·
  dup → stored άθικτο. Αρχείο 407→418 γρ. (<500).
- Docss: `item_search_field` τίτλοι 3→4 βήματα (+μονάδα) · DESIGN §2.2/§2.4.

## Tests (+5)

- Controller: με μονάδα (stored+re-read) · null→false (χωρίς εγγραφή).
- Dialog: χωρίς μονάδα→disabled · onCleared→disabled ξανά · created με
  `defaultUnitId` · dup/DB-error ροές με μονάδα.
- Field: creation μέσω dialog με μονάδα + `selectedItem.defaultUnitId`.
- Section prefill (S1) προϋπήρχε — αποδεικνύει το «εμφανίζει».

## Ευρήματα

- Ε1: `item_search_field` creation test έσπασε (save disabled χωρίς μονάδα) —
  διορθώθηκε με επιλογή μονάδας.
- Ε2: «κόλλημα» V12 — ψευδές, contention από υπολείμματα σκοτωμένου run
  (μόνο του 24/24). Κανόνας: ένα run τη φορά, σκοτώνουμε υπολείμματα.
- Τελικός έλεγχος από χρήστη: **1252/1252** ✓ · `flutter analyze` No issues.
- Backup `backups/2026-09-27_item_unit_step/`.
