/// Είδη Seed — Κατηγορία «ΚΑΘΑΡΙΣΤΙΚΑ & ΟΙΚΙΑΚΑ» (80 είδη) — Φάση 1, Βήμα 3.
///
/// Προέλευση: `supermarket_categories_v2.md`. Το `subCategoryName` είναι
/// κλειδί προς το `seed_sub_categories.dart`· το `defaultUnitName` (προτάσεις
/// από τη φύση του προϊόντος) είναι κλειδί προς το `seed_units.dart`.
library;

import 'seed_types.dart';

const List<ItemSeed> seedItemsKatharistika = <ItemSeed>[
  // ── Απορρυπαντικά Ρούχων (10) ───────────────────────────────────────────
  (name: 'Απορρυπαντικό σκόνη κλασικό', subCategoryName: 'Απορρυπαντικά Ρούχων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Απορρυπαντικό σκόνη για λευκά', subCategoryName: 'Απορρυπαντικά Ρούχων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Απορρυπαντικό σκόνη για χρωματιστά', subCategoryName: 'Απορρυπαντικά Ρούχων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Απορρυπαντικό υγρό', subCategoryName: 'Απορρυπαντικά Ρούχων', defaultUnitName: 'Λίτρο'),
  (name: 'Απορρυπαντικό κάψουλες', subCategoryName: 'Απορρυπαντικά Ρούχων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Απορρυπαντικό gel', subCategoryName: 'Απορρυπαντικά Ρούχων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Απορρυπαντικό για ευαίσθητα', subCategoryName: 'Απορρυπαντικά Ρούχων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Απορρυπαντικό για μάλλινα', subCategoryName: 'Απορρυπαντικά Ρούχων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Απορρυπαντικό 2 σε 1', subCategoryName: 'Απορρυπαντικά Ρούχων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Απορρυπαντικό βιολογικό', subCategoryName: 'Απορρυπαντικά Ρούχων', defaultUnitName: 'Τεμάχιο'),

  // ── Μαλακτικά Ρούχων (10) ───────────────────────────────────────────────
  (name: 'Μαλακτικό κλασικό', subCategoryName: 'Μαλακτικά Ρούχων', defaultUnitName: 'Λίτρο'),
  (name: 'Μαλακτικό με λεβάντα', subCategoryName: 'Μαλακτικά Ρούχων', defaultUnitName: 'Λίτρο'),
  (name: 'Μαλακτικό με φρέσκο αέρα', subCategoryName: 'Μαλακτικά Ρούχων', defaultUnitName: 'Λίτρο'),
  (name: 'Μαλακτικό υγρό', subCategoryName: 'Μαλακτικά Ρούχων', defaultUnitName: 'Λίτρο'),
  (name: 'Μαλακτικό κάψουλες', subCategoryName: 'Μαλακτικά Ρούχων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Μαλακτικό concentrated', subCategoryName: 'Μαλακτικά Ρούχων', defaultUnitName: 'Λίτρο'),
  (name: 'Μαλακτικό για ευαίσθητα', subCategoryName: 'Μαλακτικά Ρούχων', defaultUnitName: 'Λίτρο'),
  (name: 'Μαλακτικό 3 σε 1', subCategoryName: 'Μαλακτικά Ρούχων', defaultUnitName: 'Λίτρο'),
  (name: 'Μαλακτικό με άρωμα', subCategoryName: 'Μαλακτικά Ρούχων', defaultUnitName: 'Λίτρο'),
  (name: 'Μαλακτικό βιολογικό', subCategoryName: 'Μαλακτικά Ρούχων', defaultUnitName: 'Λίτρο'),

  // ── Υγρά Πιάτων (10) ────────────────────────────────────────────────────
  (name: 'Υγρό πιάτων κλασικό', subCategoryName: 'Υγρά Πιάτων', defaultUnitName: 'Λίτρο'),
  (name: 'Υγρό πιάτων με λεμόνι', subCategoryName: 'Υγρά Πιάτων', defaultUnitName: 'Λίτρο'),
  (name: 'Υγρό πιάτων concentrated', subCategoryName: 'Υγρά Πιάτων', defaultUnitName: 'Λίτρο'),
  (name: 'Υγρό πιάτων για ευαίσθητα χέρια', subCategoryName: 'Υγρά Πιάτων', defaultUnitName: 'Λίτρο'),
  (name: 'Υγρό πιάτων αντιβακτηριδιακό', subCategoryName: 'Υγρά Πιάτων', defaultUnitName: 'Λίτρο'),
  (name: 'Υγρό πιάτων βιολογικό', subCategoryName: 'Υγρά Πιάτων', defaultUnitName: 'Λίτρο'),
  (name: 'Σφουγγάρι κουζίνας', subCategoryName: 'Υγρά Πιάτων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Σφουγγάρι με σύρμα', subCategoryName: 'Υγρά Πιάτων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Βούρτσα πιάτων', subCategoryName: 'Υγρά Πιάτων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Πιάστρα πιάτων', subCategoryName: 'Υγρά Πιάτων', defaultUnitName: 'Τεμάχιο'),

  // ── Καθαριστικά Γενικής Χρήσης (10) ─────────────────────────────────────
  (name: 'Καθαριστικό spray γενικής χρήσης', subCategoryName: 'Καθαριστικά Γενικής Χρήσης', defaultUnitName: 'Λίτρο'),
  (name: 'Καθαριστικό spray για γυαλί', subCategoryName: 'Καθαριστικά Γενικής Χρήσης', defaultUnitName: 'Λίτρο'),
  (name: 'Καθαριστικό spray για ανοξείδωτο', subCategoryName: 'Καθαριστικά Γενικής Χρήσης', defaultUnitName: 'Λίτρο'),
  (name: 'Καθαριστικό spray για ξύλο', subCategoryName: 'Καθαριστικά Γενικής Χρήσης', defaultUnitName: 'Λίτρο'),
  (name: 'Καθαριστικό spray για μπάνιο', subCategoryName: 'Καθαριστικά Γενικής Χρήσης', defaultUnitName: 'Λίτρο'),
  (name: 'Καθαριστικό spray για κουζίνα', subCategoryName: 'Καθαριστικά Γενικής Χρήσης', defaultUnitName: 'Λίτρο'),
  (name: 'Καθαριστικό spray για πάτωμα', subCategoryName: 'Καθαριστικά Γενικής Χρήσης', defaultUnitName: 'Λίτρο'),
  (name: 'Καθαριστικό spray για χαλιά', subCategoryName: 'Καθαριστικά Γενικής Χρήσης', defaultUnitName: 'Λίτρο'),
  (name: 'Καθαριστικό spray με ξίδι', subCategoryName: 'Καθαριστικά Γενικής Χρήσης', defaultUnitName: 'Λίτρο'),
  (name: 'Καθαριστικό spray με λεμόνι', subCategoryName: 'Καθαριστικά Γενικής Χρήσης', defaultUnitName: 'Λίτρο'),

  // ── Καθαριστικά Μπάνιου (10) ────────────────────────────────────────────
  (name: 'Καθαριστικό WC gel', subCategoryName: 'Καθαριστικά Μπάνιου', defaultUnitName: 'Λίτρο'),
  (name: 'Καθαριστικό WC σε σκόνη', subCategoryName: 'Καθαριστικά Μπάνιου', defaultUnitName: 'Τεμάχιο'),
  (name: 'Καθαριστικό WC με λεβάντα', subCategoryName: 'Καθαριστικά Μπάνιου', defaultUnitName: 'Λίτρο'),
  (name: 'Αποσμητικό WC', subCategoryName: 'Καθαριστικά Μπάνιου', defaultUnitName: 'Τεμάχιο'),
  (name: 'Καθαριστικό μπανιέρας', subCategoryName: 'Καθαριστικά Μπάνιου', defaultUnitName: 'Λίτρο'),
  (name: 'Καθαριστικό πλακιδίων', subCategoryName: 'Καθαριστικά Μπάνιου', defaultUnitName: 'Λίτρο'),
  (name: 'Καθαριστικό νιπτήρα', subCategoryName: 'Καθαριστικά Μπάνιου', defaultUnitName: 'Λίτρο'),
  (name: 'Καθαριστικό καθρέφτη', subCategoryName: 'Καθαριστικά Μπάνιου', defaultUnitName: 'Λίτρο'),
  (name: 'Απολυμαντικό μπάνιου', subCategoryName: 'Καθαριστικά Μπάνιου', defaultUnitName: 'Λίτρο'),
  (name: 'Βούρτσα τουαλέτας', subCategoryName: 'Καθαριστικά Μπάνιου', defaultUnitName: 'Τεμάχιο'),

  // ── Καθαριστικά Πλυντηρίου Πιάτων (10) ──────────────────────────────────
  (name: 'Κάψουλες πλυντηρίου πιάτων all in one', subCategoryName: 'Καθαριστικά Πλυντηρίου Πιάτων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Κάψουλες πλυντηρίου πιάτων 3 σε 1', subCategoryName: 'Καθαριστικά Πλυντηρίου Πιάτων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Σκόνη πλυντηρίου πιάτων', subCategoryName: 'Καθαριστικά Πλυντηρίου Πιάτων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Gel πλυντηρίου πιάτων', subCategoryName: 'Καθαριστικά Πλυντηρίου Πιάτων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Υγρό πλυντηρίου πιάτων', subCategoryName: 'Καθαριστικά Πλυντηρίου Πιάτων', defaultUnitName: 'Λίτρο'),
  (name: 'Αλάτι πλυντηρίου πιάτων', subCategoryName: 'Καθαριστικά Πλυντηρίου Πιάτων', defaultUnitName: 'Κιλό'),
  (name: 'Λαμπρυντικό πλυντηρίου πιάτων', subCategoryName: 'Καθαριστικά Πλυντηρίου Πιάτων', defaultUnitName: 'Λίτρο'),
  (name: 'Κάψουλες πλυντηρίου πιάτων concentrated', subCategoryName: 'Καθαριστικά Πλυντηρίου Πιάτων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Κάψουλες πλυντηρίου πιάτων βιολογικές', subCategoryName: 'Καθαριστικά Πλυντηρίου Πιάτων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Κάψουλες πλυντηρίου πιάτων για ευαίσθητα', subCategoryName: 'Καθαριστικά Πλυντηρίου Πιάτων', defaultUnitName: 'Τεμάχιο'),

  // ── Σκούπες, Πανάκια & Αξεσουάρ (10) ────────────────────────────────────
  (name: 'Σκούπα με κοντάρι', subCategoryName: 'Σκούπες, Πανάκια & Αξεσουάρ', defaultUnitName: 'Τεμάχιο'),
  (name: 'Σκούπα με σφουγγαρίστρα', subCategoryName: 'Σκούπες, Πανάκια & Αξεσουάρ', defaultUnitName: 'Τεμάχιο'),
  (name: 'Πανάκια μικροΐνες', subCategoryName: 'Σκούπες, Πανάκια & Αξεσουάρ', defaultUnitName: 'Τεμάχιο'),
  (name: 'Πανάκια γενικής χρήσης', subCategoryName: 'Σκούπες, Πανάκια & Αξεσουάρ', defaultUnitName: 'Τεμάχιο'),
  (name: 'Πανάκια κουζίνας', subCategoryName: 'Σκούπες, Πανάκια & Αξεσουάρ', defaultUnitName: 'Τεμάχιο'),
  (name: 'Πανάκια γυαλί', subCategoryName: 'Σκούπες, Πανάκια & Αξεσουάρ', defaultUnitName: 'Τεμάχιο'),
  (name: 'Πανάκια μπάνιου', subCategoryName: 'Σκούπες, Πανάκια & Αξεσουάρ', defaultUnitName: 'Τεμάχιο'),
  (name: 'Ξεσκονόπανο', subCategoryName: 'Σκούπες, Πανάκια & Αξεσουάρ', defaultUnitName: 'Τεμάχιο'),
  (name: 'Γάντια καθαρισμού', subCategoryName: 'Σκούπες, Πανάκια & Αξεσουάρ', defaultUnitName: 'Τεμάχιο'),
  (name: 'Σφουγγαρίστρα πατώματος', subCategoryName: 'Σκούπες, Πανάκια & Αξεσουάρ', defaultUnitName: 'Τεμάχιο'),

  // ── Σακούλες Απορριμμάτων (10) ──────────────────────────────────────────
  (name: 'Σακούλα απορριμμάτων 20L', subCategoryName: 'Σακούλες Απορριμμάτων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Σακούλα απορριμμάτων 35L', subCategoryName: 'Σακούλες Απορριμμάτων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Σακούλα απορριμμάτων 50L', subCategoryName: 'Σακούλες Απορριμμάτων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Σακούλα απορριμμάτων με γραβάτα', subCategoryName: 'Σακούλες Απορριμμάτων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Σακούλα απορριμμάτων με χερούλια', subCategoryName: 'Σακούλες Απορριμμάτων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Σακούλα απορριμμάτων αρωματική', subCategoryName: 'Σακούλες Απορριμμάτων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Σακούλα απορριμμάτων βιοδιασπώμενη', subCategoryName: 'Σακούλες Απορριμμάτων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Σακούλα απορριμμάτων για ανακύκλωση', subCategoryName: 'Σακούλες Απορριμμάτων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Σακούλα απορριμμάτων για οργανικά', subCategoryName: 'Σακούλες Απορριμμάτων', defaultUnitName: 'Τεμάχιο'),
  (name: 'Σακούλα απορριμμάτων XXL', subCategoryName: 'Σακούλες Απορριμμάτων', defaultUnitName: 'Τεμάχιο'),
];