/// Είδη Seed — Κατηγορία «ΚΑΤΟΙΚΙΔΙΑ» (30 είδη) — Φάση 1, Βήμα 3.
///
/// Προέλευση: `supermarket_categories_v2.md`. Το `subCategoryName` είναι
/// κλειδί προς το `seed_sub_categories.dart`· το `defaultUnitName` (προτάσεις
/// από τη φύση του προϊόντος) είναι κλειδί προς το `seed_units.dart`.
library;

import 'seed_types.dart';

const List<ItemSeed> seedItemsKatikidia = <ItemSeed>[
  // ── Τροφές Σκύλου (10) ──────────────────────────────────────────────────
  (name: 'Ξηρά τροφή σκύλου ενήλικα', subCategoryName: 'Τροφές Σκύλου', defaultUnitName: 'Κιλό'),
  (name: 'Ξηρά τροφή σκύλου κουτάβι', subCategoryName: 'Τροφές Σκύλου', defaultUnitName: 'Κιλό'),
  (name: 'Ξηρά τροφή σκύλου light', subCategoryName: 'Τροφές Σκύλου', defaultUnitName: 'Κιλό'),
  (name: 'Κονσέρβα σκύλου κοτόπουλο', subCategoryName: 'Τροφές Σκύλου', defaultUnitName: 'Τεμάχιο'),
  (name: 'Κονσέρβα σκύλου μοσχάρι', subCategoryName: 'Τροφές Σκύλου', defaultUnitName: 'Τεμάχιο'),
  (name: 'Κονσέρβα σκύλου αρνί', subCategoryName: 'Τροφές Σκύλου', defaultUnitName: 'Τεμάχιο'),
  (name: 'Λιχουδιά σκύλου μπισκότο', subCategoryName: 'Τροφές Σκύλου', defaultUnitName: 'Τεμάχιο'),
  (name: 'Λιχουδιά σκύλου κοτόπουλο', subCategoryName: 'Τροφές Σκύλου', defaultUnitName: 'Τεμάχιο'),
  (name: 'Λιχουδιά σκύλου μπέικον', subCategoryName: 'Τροφές Σκύλου', defaultUnitName: 'Τεμάχιο'),
  (name: 'Ξηρά τροφή σκύλου grain free', subCategoryName: 'Τροφές Σκύλου', defaultUnitName: 'Κιλό'),

  // ── Τροφές Γάτας (10) ───────────────────────────────────────────────────
  (name: 'Ξηρά τροφή γάτας ενήλικη', subCategoryName: 'Τροφές Γάτας', defaultUnitName: 'Κιλό'),
  (name: 'Ξηρά τροφή γάτας γατάκι', subCategoryName: 'Τροφές Γάτας', defaultUnitName: 'Κιλό'),
  (name: 'Ξηρά τροφή γάτας light', subCategoryName: 'Τροφές Γάτας', defaultUnitName: 'Κιλό'),
  (name: 'Κονσέρβα γάτας τόνος', subCategoryName: 'Τροφές Γάτας', defaultUnitName: 'Τεμάχιο'),
  (name: 'Κονσέρβα γάτας σολομός', subCategoryName: 'Τροφές Γάτας', defaultUnitName: 'Τεμάχιο'),
  (name: 'Κονσέρβα γάτας κοτόπουλο', subCategoryName: 'Τροφές Γάτας', defaultUnitName: 'Τεμάχιο'),
  (name: 'Λιχουδιά γάτας', subCategoryName: 'Τροφές Γάτας', defaultUnitName: 'Τεμάχιο'),
  (name: 'Ξηρά τροφή γάτας hairball control', subCategoryName: 'Τροφές Γάτας', defaultUnitName: 'Κιλό'),
  (name: 'Ξηρά τροφή γάτας urinary', subCategoryName: 'Τροφές Γάτας', defaultUnitName: 'Κιλό'),
  (name: 'Ξηρά τροφή γάτας indoor', subCategoryName: 'Τροφές Γάτας', defaultUnitName: 'Κιλό'),

  // ── Περιποίηση & Αξεσουάρ Κατοικιδίων (10) ──────────────────────────────
  (name: 'Άμμος γάτας άργιλος', subCategoryName: 'Περιποίηση & Αξεσουάρ Κατοικιδίων', defaultUnitName: 'Κιλό'),
  (name: 'Άμμος γάτας silica', subCategoryName: 'Περιποίηση & Αξεσουάρ Κατοικιδίων', defaultUnitName: 'Κιλό'),
  (name: 'Σαμπουάν σκύλου', subCategoryName: 'Περιποίηση & Αξεσουάρ Κατοικιδίων', defaultUnitName: 'Λίτρο'),
  (name: 'Σαμπουάν γάτας', subCategoryName: 'Περιποίηση & Αξεσουάρ Κατοικιδίων', defaultUnitName: 'Λίτρο'),
  (name: 'Βούρτσα σκύλου', subCategoryName: 'Περιποίηση & Αξεσουάρ Κατοικιδίων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Βούρτσα γάτας', subCategoryName: 'Περιποίηση & Αξεσουάρ Κατοικιδίων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Κολάρο σκύλου', subCategoryName: 'Περιποίηση & Αξεσουάρ Κατοικιδίων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Λουρί σκύλου', subCategoryName: 'Περιποίηση & Αξεσουάρ Κατοικιδίων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Παιχνίδι σκύλου μπάλα', subCategoryName: 'Περιποίηση & Αξεσουάρ Κατοικιδίων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Παιχνίδι γάτας με φτερό', subCategoryName: 'Περιποίηση & Αξεσουάρ Κατοικιδίων', defaultUnitName: 'Τεμάχιο'),
];