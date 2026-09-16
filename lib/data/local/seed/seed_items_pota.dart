/// Είδη Seed — Κατηγορία «ΠΟΤΑ & ΡΟΦΗΜΑΤΑ» (60 είδη) — Φάση 1, Βήμα 3.
///
/// Προέλευση: `supermarket_categories_v2.md`. Το `subCategoryName` είναι
/// κλειδί προς το `seed_sub_categories.dart`· το `defaultUnitName` (προτάσεις
/// από τη φύση του προϊόντος) είναι κλειδί προς το `seed_units.dart`.
library;

import 'seed_types.dart';

const List<ItemSeed> seedItemsPota = <ItemSeed>[
  // ── Καφές (10) ───────────────────────────────────────────────────────────
  (name: 'Καφές φίλτρου κλασικός', subCategoryName: 'Καφές', defaultUnitName: 'Γραμμάριο'),
  (name: 'Καφές espresso κόκκοι', subCategoryName: 'Καφές', defaultUnitName: 'Γραμμάριο'),
  (name: 'Νες καφέ', subCategoryName: 'Καφές', defaultUnitName: 'Γραμμάριο'),
  (name: 'Καφές στιγμιαίος', subCategoryName: 'Καφές', defaultUnitName: 'Γραμμάριο'),
  (name: 'Καψούλες espresso', subCategoryName: 'Καφές', defaultUnitName: 'Τεμάχιο'),
  (name: 'Καφές decaf', subCategoryName: 'Καφές', defaultUnitName: 'Γραμμάριο'),
  (name: 'Φραπέ', subCategoryName: 'Καφές', defaultUnitName: 'Γραμμάριο'),
  (name: 'Καφές ελληνικός', subCategoryName: 'Καφές', defaultUnitName: 'Γραμμάριο'),
  (name: 'Cappuccino στιγμιαίο', subCategoryName: 'Καφές', defaultUnitName: 'Γραμμάριο'),
  (name: 'Latte στιγμιαίο', subCategoryName: 'Καφές', defaultUnitName: 'Γραμμάριο'),

  // ── Τσάι & Ροφήματα (10) ────────────────────────────────────────────────
  (name: 'Τσάι μαύρο', subCategoryName: 'Τσάι & Ροφήματα', defaultUnitName: 'Τεμάχιο'),
  (name: 'Τσάι πράσινο', subCategoryName: 'Τσάι & Ροφήματα', defaultUnitName: 'Τεμάχιο'),
  (name: 'Τσάι βουνού', subCategoryName: 'Τσάι & Ροφήματα', defaultUnitName: 'Τεμάχιο'),
  (name: 'Τσάι χαμομήλι', subCategoryName: 'Τσάι & Ροφήματα', defaultUnitName: 'Τεμάχιο'),
  (name: 'Τσάι φασκόμηλο', subCategoryName: 'Τσάι & Ροφήματα', defaultUnitName: 'Τεμάχιο'),
  (name: 'Τσάι τίλιο', subCategoryName: 'Τσάι & Ροφήματα', defaultUnitName: 'Τεμάχιο'),
  (name: 'Σοκολάτα ρόφημα', subCategoryName: 'Τσάι & Ροφήματα', defaultUnitName: 'Τεμάχιο'),
  (name: 'Κακάο', subCategoryName: 'Τσάι & Ροφήματα', defaultUnitName: 'Γραμμάριο'),
  (name: 'Matcha', subCategoryName: 'Τσάι & Ροφήματα', defaultUnitName: 'Γραμμάριο'),
  (name: 'Ρόφημα βανίλια', subCategoryName: 'Τσάι & Ροφήματα', defaultUnitName: 'Τεμάχιο'),

  // ── Αναψυκτικά (10) ─────────────────────────────────────────────────────
  (name: 'Coca-Cola', subCategoryName: 'Αναψυκτικά', defaultUnitName: 'Λίτρο'),
  (name: 'Coca-Cola light/zero', subCategoryName: 'Αναψυκτικά', defaultUnitName: 'Λίτρο'),
  (name: 'Pepsi', subCategoryName: 'Αναψυκτικά', defaultUnitName: 'Λίτρο'),
  (name: '7UP', subCategoryName: 'Αναψυκτικά', defaultUnitName: 'Λίτρο'),
  (name: 'Sprite', subCategoryName: 'Αναψυκτικά', defaultUnitName: 'Λίτρο'),
  (name: 'Fanta πορτοκάλι', subCategoryName: 'Αναψυκτικά', defaultUnitName: 'Λίτρο'),
  (name: 'Fanta λεμόνι', subCategoryName: 'Αναψυκτικά', defaultUnitName: 'Λίτρο'),
  (name: 'Soda water', subCategoryName: 'Αναψυκτικά', defaultUnitName: 'Λίτρο'),
  (name: 'Tonic water', subCategoryName: 'Αναψυκτικά', defaultUnitName: 'Λίτρο'),
  (name: 'Ginger ale', subCategoryName: 'Αναψυκτικά', defaultUnitName: 'Λίτρο'),

  // ── Χυμοί & Νερά (10) ───────────────────────────────────────────────────
  (name: 'Χυμός πορτοκάλι', subCategoryName: 'Χυμοί & Νερά', defaultUnitName: 'Λίτρο'),
  (name: 'Χυμός μήλο', subCategoryName: 'Χυμοί & Νερά', defaultUnitName: 'Λίτρο'),
  (name: 'Χυμός ανάμεικτος', subCategoryName: 'Χυμοί & Νερά', defaultUnitName: 'Λίτρο'),
  (name: 'Χυμός ανανά', subCategoryName: 'Χυμοί & Νερά', defaultUnitName: 'Λίτρο'),
  (name: 'Χυμός ροδάκινο', subCategoryName: 'Χυμοί & Νερά', defaultUnitName: 'Λίτρο'),
  (name: 'Νερό επιτραπέζιο 1.5L', subCategoryName: 'Χυμοί & Νερά', defaultUnitName: 'Λίτρο'),
  (name: 'Νερό μεταλλικό 500ml', subCategoryName: 'Χυμοί & Νερά', defaultUnitName: 'Λίτρο'),
  (name: 'Νερό ανθρακούχο', subCategoryName: 'Χυμοί & Νερά', defaultUnitName: 'Λίτρο'),
  (name: 'Smoothie φρούτων', subCategoryName: 'Χυμοί & Νερά', defaultUnitName: 'Λίτρο'),
  (name: 'Χυμός καρότο', subCategoryName: 'Χυμοί & Νερά', defaultUnitName: 'Λίτρο'),

  // ── Κρασιά & Μπύρες (10) ────────────────────────────────────────────────
  (name: 'Κρασί ερυθρό', subCategoryName: 'Κρασιά & Μπύρες', defaultUnitName: 'Λίτρο'),
  (name: 'Κρασί λευκό', subCategoryName: 'Κρασιά & Μπύρες', defaultUnitName: 'Λίτρο'),
  (name: 'Κρασί ροζέ', subCategoryName: 'Κρασιά & Μπύρες', defaultUnitName: 'Λίτρο'),
  (name: 'Μπύρα lager', subCategoryName: 'Κρασιά & Μπύρες', defaultUnitName: 'Λίτρο'),
  (name: 'Μπύρα pilsner', subCategoryName: 'Κρασιά & Μπύρες', defaultUnitName: 'Λίτρο'),
  (name: 'Μπύρα weiss', subCategoryName: 'Κρασιά & Μπύρες', defaultUnitName: 'Λίτρο'),
  (name: 'Μπύρα alcohol free', subCategoryName: 'Κρασιά & Μπύρες', defaultUnitName: 'Λίτρο'),
  (name: 'Κρασί αφρώδες (σαμπάνια/prosecco)', subCategoryName: 'Κρασιά & Μπύρες', defaultUnitName: 'Λίτρο'),
  (name: 'Κρασί γλυκό', subCategoryName: 'Κρασιά & Μπύρες', defaultUnitName: 'Λίτρο'),
  (name: 'Μπύρα craft', subCategoryName: 'Κρασιά & Μπύρες', defaultUnitName: 'Λίτρο'),

  // ── Οινοπνευματώδη (10) ─────────────────────────────────────────────────
  (name: 'Ουίσκι', subCategoryName: 'Οινοπνευματώδη', defaultUnitName: 'Λίτρο'),
  (name: 'Βότκα', subCategoryName: 'Οινοπνευματώδη', defaultUnitName: 'Λίτρο'),
  (name: 'Τζιν', subCategoryName: 'Οινοπνευματώδη', defaultUnitName: 'Λίτρο'),
  (name: 'Ρούμι', subCategoryName: 'Οινοπνευματώδη', defaultUnitName: 'Λίτρο'),
  (name: 'Τεκίλα', subCategoryName: 'Οινοπνευματώδη', defaultUnitName: 'Λίτρο'),
  (name: 'Μπράντι', subCategoryName: 'Οινοπνευματώδη', defaultUnitName: 'Λίτρο'),
  (name: 'Λικέρ', subCategoryName: 'Οινοπνευματώδη', defaultUnitName: 'Λίτρο'),
  (name: 'Ούζο', subCategoryName: 'Οινοπνευματώδη', defaultUnitName: 'Λίτρο'),
  (name: 'Τσίπουρο', subCategoryName: 'Οινοπνευματώδη', defaultUnitName: 'Λίτρο'),
  (name: 'Κονιάκ', subCategoryName: 'Οινοπνευματώδη', defaultUnitName: 'Λίτρο'),
];