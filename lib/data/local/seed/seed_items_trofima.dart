/// Είδη Seed — Κατηγορία «ΤΡΟΦΙΜΑ» (155 είδη) — Φάση 1, Βήμα 3.
///
/// Προέλευση: `supermarket_categories_v2.md`. Το `subCategoryName` είναι
/// κλειδί προς το `seed_sub_categories.dart`· το `defaultUnitName` (προτάσεις
/// από τη φύση του προϊόντος) είναι κλειδί προς το `seed_units.dart`.
library;

import 'seed_types.dart';

const List<ItemSeed> seedItemsTrofima = <ItemSeed>[
  // ── Γαλακτοκομικά & Ψυγείου (18) ───────────────────────────────────────
  (name: 'Γάλα φρέσκο', subCategoryName: 'Γαλακτοκομικά & Ψυγείου', defaultUnitName: 'Λίτρο'),
  (name: 'Γάλα μακράς διάρκειας', subCategoryName: 'Γαλακτοκομικά & Ψυγείου', defaultUnitName: 'Λίτρο'),
  (name: 'Γιαούρτι στραγγιστό', subCategoryName: 'Γαλακτοκομικά & Ψυγείου', defaultUnitName: 'Τεμάχιο'),
  (name: 'Γιαούρτι αγελάδος', subCategoryName: 'Γαλακτοκομικά & Ψυγείου', defaultUnitName: 'Τεμάχιο'),
  (name: 'Γιαούρτι πρόβειο', subCategoryName: 'Γαλακτοκομικά & Ψυγείου', defaultUnitName: 'Τεμάχιο'),
  (name: 'Γιαούρτι κατσικίσιο', subCategoryName: 'Γαλακτοκομικά & Ψυγείου', defaultUnitName: 'Τεμάχιο'),
  (name: 'Φέτα', subCategoryName: 'Γαλακτοκομικά & Ψυγείου', defaultUnitName: 'Κιλό'),
  (name: 'Γκούντα', subCategoryName: 'Γαλακτοκομικά & Ψυγείου', defaultUnitName: 'Κιλό'),
  (name: 'Ρεγγάτο', subCategoryName: 'Γαλακτοκομικά & Ψυγείου', defaultUnitName: 'Κιλό'),
  (name: 'Παρμεζάνα', subCategoryName: 'Γαλακτοκομικά & Ψυγείου', defaultUnitName: 'Κιλό'),
  (name: 'Γραβιέρα', subCategoryName: 'Γαλακτοκομικά & Ψυγείου', defaultUnitName: 'Κιλό'),
  (name: 'Πάριζα', subCategoryName: 'Γαλακτοκομικά & Ψυγείου', defaultUnitName: 'Κιλό'),
  (name: 'Τυρί τριμμένο αλμυρό Ολυμπος', subCategoryName: 'Γαλακτοκομικά & Ψυγείου', defaultUnitName: 'Κιλό'),
  (name: 'Τυρί τριμμένο 4 τυριά', subCategoryName: 'Γαλακτοκομικά & Ψυγείου', defaultUnitName: 'Κιλό'),
  (name: 'Βούτυρο αγελαδινό', subCategoryName: 'Γαλακτοκομικά & Ψυγείου', defaultUnitName: 'Κιλό'),
  (name: 'Κρέμα γάλακτος', subCategoryName: 'Γαλακτοκομικά & Ψυγείου', defaultUnitName: 'Λίτρο'),
  (name: 'Αυγά', subCategoryName: 'Γαλακτοκομικά & Ψυγείου', defaultUnitName: 'Τεμάχιο'),
  (name: 'Κρέμα τυρί Philadelphia', subCategoryName: 'Γαλακτοκομικά & Ψυγείου', defaultUnitName: 'Τεμάχιο'),

  // ── Κρέατα (7) ──────────────────────────────────────────────────────────
  (name: 'Μοσχάρι', subCategoryName: 'Κρέατα', defaultUnitName: 'Κιλό'),
  (name: 'Χοιρινό', subCategoryName: 'Κρέατα', defaultUnitName: 'Κιλό'),
  (name: 'Κοτόπουλο', subCategoryName: 'Κρέατα', defaultUnitName: 'Κιλό'),
  (name: 'Κιμάς μοσχαρίσιος', subCategoryName: 'Κρέατα', defaultUnitName: 'Κιλό'),
  (name: 'Γαλοπούλα', subCategoryName: 'Κρέατα', defaultUnitName: 'Κιλό'),
  (name: 'Κατσίκι', subCategoryName: 'Κρέατα', defaultUnitName: 'Κιλό'),
  (name: 'Αρνί', subCategoryName: 'Κρέατα', defaultUnitName: 'Κιλό'),

  // ── Αλλαντικά (8) ───────────────────────────────────────────────────────
  (name: 'Ζαμπόν', subCategoryName: 'Αλλαντικά', defaultUnitName: 'Κιλό'),
  (name: 'Μπέικον', subCategoryName: 'Αλλαντικά', defaultUnitName: 'Τεμάχιο'),
  (name: 'Γαλοπούλα σε φέτες', subCategoryName: 'Αλλαντικά', defaultUnitName: 'Κιλό'),
  (name: 'Σαλάμι αέρος', subCategoryName: 'Αλλαντικά', defaultUnitName: 'Κιλό'),
  (name: 'Παστουρμάς', subCategoryName: 'Αλλαντικά', defaultUnitName: 'Κιλό'),
  (name: 'Μορταδέλα', subCategoryName: 'Αλλαντικά', defaultUnitName: 'Κιλό'),
  (name: 'Λουκάνικο', subCategoryName: 'Αλλαντικά', defaultUnitName: 'Κιλό'),
  (name: 'Προσούτο', subCategoryName: 'Αλλαντικά', defaultUnitName: 'Κιλό'),

  // ── Ψάρια & Θαλασσινά (10) ──────────────────────────────────────────────
  (name: 'Σαρδέλα φρέσκια', subCategoryName: 'Ψάρια & Θαλασσινά', defaultUnitName: 'Κιλό'),
  (name: 'Γαύρος φρέσκος', subCategoryName: 'Ψάρια & Θαλασσινά', defaultUnitName: 'Κιλό'),
  (name: 'Μπακαλιάρος φιλέτο', subCategoryName: 'Ψάρια & Θαλασσινά', defaultUnitName: 'Κιλό'),
  (name: 'Σολομός φιλέτο', subCategoryName: 'Ψάρια & Θαλασσινά', defaultUnitName: 'Κιλό'),
  (name: 'Τόνος φρέσκος', subCategoryName: 'Ψάρια & Θαλασσινά', defaultUnitName: 'Κιλό'),
  (name: 'Γαρίδες κατεψυγμένες', subCategoryName: 'Ψάρια & Θαλασσινά', defaultUnitName: 'Κιλό'),
  (name: 'Καλαμάρι καθαρισμένο', subCategoryName: 'Ψάρια & Θαλασσινά', defaultUnitName: 'Κιλό'),
  (name: 'Χταπόδι', subCategoryName: 'Ψάρια & Θαλασσινά', defaultUnitName: 'Κιλό'),
  (name: 'Μύδια', subCategoryName: 'Ψάρια & Θαλασσινά', defaultUnitName: 'Κιλό'),
  (name: 'Στρείδια', subCategoryName: 'Ψάρια & Θαλασσινά', defaultUnitName: 'Κιλό'),

  // ── Αρτοποιήματα (11) ───────────────────────────────────────────────────
  (name: 'Ψωμί λευκό', subCategoryName: 'Αρτοποιήματα', defaultUnitName: 'Κιλό'),
  (name: 'Ψωμί ολικής άλεσης', subCategoryName: 'Αρτοποιήματα', defaultUnitName: 'Κιλό'),
  (name: 'Ψωμί πολύσπορο', subCategoryName: 'Αρτοποιήματα', defaultUnitName: 'Κιλό'),
  (name: 'Μπαγκέτα', subCategoryName: 'Αρτοποιήματα', defaultUnitName: 'Τεμάχιο'),
  (name: 'Κρουασάν βουτύρου', subCategoryName: 'Αρτοποιήματα', defaultUnitName: 'Τεμάχιο'),
  (name: 'Κρουασάν σοκολάτας', subCategoryName: 'Αρτοποιήματα', defaultUnitName: 'Τεμάχιο'),
  (name: 'Φρυγανιές', subCategoryName: 'Αρτοποιήματα', defaultUnitName: 'Τεμάχιο'),
  (name: 'Παξιμάδια', subCategoryName: 'Αρτοποιήματα', defaultUnitName: 'Κιλό'),
  (name: 'Τσουρέκι', subCategoryName: 'Αρτοποιήματα', defaultUnitName: 'Τεμάχιο'),
  (name: 'Κέικ', subCategoryName: 'Αρτοποιήματα', defaultUnitName: 'Τεμάχιο'),
  (name: 'Μπισκότα', subCategoryName: 'Αρτοποιήματα', defaultUnitName: 'Τεμάχιο'),

  // ── Ζυμαρικά (11) ───────────────────────────────────────────────────────
  (name: 'Σπαγγέτι', subCategoryName: 'Ζυμαρικά', defaultUnitName: 'Κιλό'),
  (name: 'Μακαρόνια ολικής', subCategoryName: 'Ζυμαρικά', defaultUnitName: 'Κιλό'),
  (name: 'Πέννες', subCategoryName: 'Ζυμαρικά', defaultUnitName: 'Κιλό'),
  (name: 'Κοφτό μακαρονάκι', subCategoryName: 'Ζυμαρικά', defaultUnitName: 'Κιλό'),
  (name: 'Φιογκάκια', subCategoryName: 'Ζυμαρικά', defaultUnitName: 'Κιλό'),
  (name: 'Χυλοπίτες', subCategoryName: 'Ζυμαρικά', defaultUnitName: 'Κιλό'),
  (name: 'Κανελόνια', subCategoryName: 'Ζυμαρικά', defaultUnitName: 'Κιλό'),
  (name: 'Λαζάνια', subCategoryName: 'Ζυμαρικά', defaultUnitName: 'Κιλό'),
  (name: 'Ριγκατόνι', subCategoryName: 'Ζυμαρικά', defaultUnitName: 'Κιλό'),
  (name: 'Τορτελίνια', subCategoryName: 'Ζυμαρικά', defaultUnitName: 'Κιλό'),
  (name: 'Ορζό', subCategoryName: 'Ζυμαρικά', defaultUnitName: 'Κιλό'),

  // ── Όσπρια & Δημητριακά (10) ────────────────────────────────────────────
  (name: 'Φασόλια μέτρια', subCategoryName: 'Όσπρια & Δημητριακά', defaultUnitName: 'Κιλό'),
  (name: 'Φακές', subCategoryName: 'Όσπρια & Δημητριακά', defaultUnitName: 'Κιλό'),
  (name: 'Ρεβίθια', subCategoryName: 'Όσπρια & Δημητριακά', defaultUnitName: 'Κιλό'),
  (name: 'Φάβα', subCategoryName: 'Όσπρια & Δημητριακά', defaultUnitName: 'Κιλό'),
  (name: 'Μαυρομάτικα', subCategoryName: 'Όσπρια & Δημητριακά', defaultUnitName: 'Κιλό'),
  (name: 'Ρύζι νυχάκι', subCategoryName: 'Όσπρια & Δημητριακά', defaultUnitName: 'Κιλό'),
  (name: 'Ρύζι καρολίνα', subCategoryName: 'Όσπρια & Δημητριακά', defaultUnitName: 'Κιλό'),
  (name: 'Ρύζι μπασμάτι', subCategoryName: 'Όσπρια & Δημητριακά', defaultUnitName: 'Κιλό'),
  (name: 'Κους κους', subCategoryName: 'Όσπρια & Δημητριακά', defaultUnitName: 'Κιλό'),
  (name: 'Κινόα', subCategoryName: 'Όσπρια & Δημητριακά', defaultUnitName: 'Κιλό'),

  // ── Λάδια, Ξίδια & Σάλτσες (10) ─────────────────────────────────────────
  (name: 'Ελαιόλαδο extra παρθένο', subCategoryName: 'Λάδια, Ξίδια & Σάλτσες', defaultUnitName: 'Λίτρο'),
  (name: 'Ηλιέλαιο', subCategoryName: 'Λάδια, Ξίδια & Σάλτσες', defaultUnitName: 'Λίτρο'),
  (name: 'Ξίδι λευκό', subCategoryName: 'Λάδια, Ξίδια & Σάλτσες', defaultUnitName: 'Λίτρο'),
  (name: 'Ξίδι κόκκινο', subCategoryName: 'Λάδια, Ξίδια & Σάλτσες', defaultUnitName: 'Λίτρο'),
  (name: 'Ξίδι βαλσαμικό', subCategoryName: 'Λάδια, Ξίδια & Σάλτσες', defaultUnitName: 'Λίτρο'),
  (name: 'Σάλτσα τομάτας κλασική', subCategoryName: 'Λάδια, Ξίδια & Σάλτσες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Σάλτσα τομάτας με βασιλικό', subCategoryName: 'Λάδια, Ξίδια & Σάλτσες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Pesto βασιλικό', subCategoryName: 'Λάδια, Ξίδια & Σάλτσες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Μουστάρδα απαλή', subCategoryName: 'Λάδια, Ξίδια & Σάλτσες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Μαγιονέζα', subCategoryName: 'Λάδια, Ξίδια & Σάλτσες', defaultUnitName: 'Τεμάχιο'),

  // ── Κονσέρβες (10) ──────────────────────────────────────────────────────
  (name: 'Τόνος σε ελαιόλαδο', subCategoryName: 'Κονσέρβες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Τόνος σε νερό', subCategoryName: 'Κονσέρβες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Σαρδέλα σε λάδι', subCategoryName: 'Κονσέρβες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Κονσέρβα τομάτας', subCategoryName: 'Κονσέρβες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Κονσέρβα αρακά', subCategoryName: 'Κονσέρβες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Κονσέρβα καλαμπόκι', subCategoryName: 'Κονσέρβες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Κονσέρβα φασόλια', subCategoryName: 'Κονσέρβες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Σολομός καπνιστός', subCategoryName: 'Κονσέρβες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Πάστα ελιάς', subCategoryName: 'Κονσέρβες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Κονσέρβα μανιτάρια', subCategoryName: 'Κονσέρβες', defaultUnitName: 'Τεμάχιο'),

  // ── Μαρμελάδες, Μέλια & Αλείμματα (10) ─────────────────────────────────
  (name: 'Μαρμελάδα φράουλα', subCategoryName: 'Μαρμελάδες, Μέλια & Αλείμματα', defaultUnitName: 'Τεμάχιο'),
  (name: 'Μαρμελάδα βερίκοκο', subCategoryName: 'Μαρμελάδες, Μέλια & Αλείμματα', defaultUnitName: 'Τεμάχιο'),
  (name: 'Μαρμελάδα πορτοκάλι', subCategoryName: 'Μαρμελάδες, Μέλια & Αλείμματα', defaultUnitName: 'Τεμάχιο'),
  (name: 'Μέλι ανθέων', subCategoryName: 'Μαρμελάδες, Μέλια & Αλείμματα', defaultUnitName: 'Κιλό'),
  (name: 'Μέλι δασόμελο', subCategoryName: 'Μαρμελάδες, Μέλια & Αλείμματα', defaultUnitName: 'Κιλό'),
  (name: 'Μέλι πευκόμελο', subCategoryName: 'Μαρμελάδες, Μέλια & Αλείμματα', defaultUnitName: 'Κιλό'),
  (name: 'Φυστικοβούτυρο', subCategoryName: 'Μαρμελάδες, Μέλια & Αλείμματα', defaultUnitName: 'Τεμάχιο'),
  (name: 'Μερέντα', subCategoryName: 'Μαρμελάδες, Μέλια & Αλείμματα', defaultUnitName: 'Κιλό'),
  (name: 'Άλειμμα σοκολάτας', subCategoryName: 'Μαρμελάδες, Μέλια & Αλείμματα', defaultUnitName: 'Κιλό'),
  (name: 'Ταχίνι', subCategoryName: 'Μαρμελάδες, Μέλια & Αλείμματα', defaultUnitName: 'Κιλό'),

  // ── Μπαχαρικά & Αλάτι (10) ──────────────────────────────────────────────
  (name: 'Αλάτι κλασικό', subCategoryName: 'Μπαχαρικά & Αλάτι', defaultUnitName: 'Κιλό'),
  (name: 'Αλάτι θαλασσινό', subCategoryName: 'Μπαχαρικά & Αλάτι', defaultUnitName: 'Κιλό'),
  (name: 'Πιπέρι μαύρο', subCategoryName: 'Μπαχαρικά & Αλάτι', defaultUnitName: 'Κιλό'),
  (name: 'Πάπρικα γλυκιά', subCategoryName: 'Μπαχαρικά & Αλάτι', defaultUnitName: 'Κιλό'),
  (name: 'Κανέλα', subCategoryName: 'Μπαχαρικά & Αλάτι', defaultUnitName: 'Κιλό'),
  (name: 'Ρίγανη', subCategoryName: 'Μπαχαρικά & Αλάτι', defaultUnitName: 'Κιλό'),
  (name: 'Μπαχάρι', subCategoryName: 'Μπαχαρικά & Αλάτι', defaultUnitName: 'Κιλό'),
  (name: 'Μείγμα κάρι', subCategoryName: 'Μπαχαρικά & Αλάτι', defaultUnitName: 'Κιλό'),
  (name: 'Ζάχαρη λευκή', subCategoryName: 'Μπαχαρικά & Αλάτι', defaultUnitName: 'Κιλό'),
  (name: 'Ζάχαρη καστανή', subCategoryName: 'Μπαχαρικά & Αλάτι', defaultUnitName: 'Κιλό'),

  // ── Ξηροί Καρποί & Αποξηραμένα (10) ────────────────────────────────────
  (name: 'Αμύγδαλα ωμά', subCategoryName: 'Ξηροί Καρποί & Αποξηραμένα', defaultUnitName: 'Κιλό'),
  (name: 'Φιστίκια αράπικα', subCategoryName: 'Ξηροί Καρποί & Αποξηραμένα', defaultUnitName: 'Κιλό'),
  (name: 'Κάσιους', subCategoryName: 'Ξηροί Καρποί & Αποξηραμένα', defaultUnitName: 'Κιλό'),
  (name: 'Καρύδια', subCategoryName: 'Ξηροί Καρποί & Αποξηραμένα', defaultUnitName: 'Κιλό'),
  (name: 'Φουντούκια', subCategoryName: 'Ξηροί Καρποί & Αποξηραμένα', defaultUnitName: 'Κιλό'),
  (name: 'Σταφίδα ξανθή', subCategoryName: 'Ξηροί Καρποί & Αποξηραμένα', defaultUnitName: 'Κιλό'),
  (name: 'Σταφίδα μαύρη', subCategoryName: 'Ξηροί Καρποί & Αποξηραμένα', defaultUnitName: 'Κιλό'),
  (name: 'Χουρμάδες', subCategoryName: 'Ξηροί Καρποί & Αποξηραμένα', defaultUnitName: 'Κιλό'),
  (name: 'Δαμάσκηνα αποξηραμένα', subCategoryName: 'Ξηροί Καρποί & Αποξηραμένα', defaultUnitName: 'Κιλό'),
  (name: 'Σύκα αποξηραμένα', subCategoryName: 'Ξηροί Καρποί & Αποξηραμένα', defaultUnitName: 'Κιλό'),

  // ── Σοκολάτες & Γλυκά (10) ──────────────────────────────────────────────
  (name: 'Σοκολάτα γάλακτος', subCategoryName: 'Σοκολάτες & Γλυκά', defaultUnitName: 'Τεμάχιο'),
  (name: 'Σοκολάτα υγείας', subCategoryName: 'Σοκολάτες & Γλυκά', defaultUnitName: 'Τεμάχιο'),
  (name: 'Σοκολάτα λευκή', subCategoryName: 'Σοκολάτες & Γλυκά', defaultUnitName: 'Τεμάχιο'),
  (name: 'Σοκολατάκια σοκολάτας', subCategoryName: 'Σοκολάτες & Γλυκά', defaultUnitName: 'Τεμάχιο'),
  (name: 'Καραμέλες μαλακές', subCategoryName: 'Σοκολάτες & Γλυκά', defaultUnitName: 'Τεμάχιο'),
  (name: 'Καραμέλες σκληρές', subCategoryName: 'Σοκολάτες & Γλυκά', defaultUnitName: 'Τεμάχιο'),
  (name: 'Τσίχλες', subCategoryName: 'Σοκολάτες & Γλυκά', defaultUnitName: 'Τεμάχιο'),
  (name: 'Παστίλιες', subCategoryName: 'Σοκολάτες & Γλυκά', defaultUnitName: 'Τεμάχιο'),
  (name: 'Μπισκότα sandwich', subCategoryName: 'Σοκολάτες & Γλυκά', defaultUnitName: 'Τεμάχιο'),
  (name: 'Μπισκότα digestive', subCategoryName: 'Σοκολάτες & Γλυκά', defaultUnitName: 'Τεμάχιο'),

  // ── Σνάκς & Πατατάκια (10) ──────────────────────────────────────────────
  (name: 'Πατατάκια απλά', subCategoryName: 'Σνάκς & Πατατάκια', defaultUnitName: 'Τεμάχιο'),
  (name: 'Πατατάκια με αλάτι', subCategoryName: 'Σνάκς & Πατατάκια', defaultUnitName: 'Τεμάχιο'),
  (name: 'Πατατάκια με ξύδι', subCategoryName: 'Σνάκς & Πατατάκια', defaultUnitName: 'Τεμάχιο'),
  (name: 'Πατατάκια με τσίλι', subCategoryName: 'Σνάκς & Πατατάκια', defaultUnitName: 'Τεμάχιο'),
  (name: 'Πατατάκια με cheddar', subCategoryName: 'Σνάκς & Πατατάκια', defaultUnitName: 'Τεμάχιο'),
  (name: 'Doritos', subCategoryName: 'Σνάκς & Πατατάκια', defaultUnitName: 'Τεμάχιο'),
  (name: 'Popcorn μικροκυμάτων', subCategoryName: 'Σνάκς & Πατατάκια', defaultUnitName: 'Τεμάχιο'),
  (name: 'Pretzels', subCategoryName: 'Σνάκς & Πατατάκια', defaultUnitName: 'Τεμάχιο'),
  (name: 'Corn nuts', subCategoryName: 'Σνάκς & Πατατάκια', defaultUnitName: 'Τεμάχιο'),
  (name: 'Nachos', subCategoryName: 'Σνάκς & Πατατάκια', defaultUnitName: 'Τεμάχιο'),

  // ── Έτοιμα Γεύματα & Ζύμες (10) ─────────────────────────────────────────
  (name: 'Πίτσα κατεψυγμένη μαργαρίτα', subCategoryName: 'Έτοιμα Γεύματα & Ζύμες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Πίτσα κατεψυγμένη pepperoni', subCategoryName: 'Έτοιμα Γεύματα & Ζύμες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Λαζάνια κατεψυγμένο', subCategoryName: 'Έτοιμα Γεύματα & Ζύμες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Κρέπες κατεψυγμένες', subCategoryName: 'Έτοιμα Γεύματα & Ζύμες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Σφολιάτα έτοιμη', subCategoryName: 'Έτοιμα Γεύματα & Ζύμες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Φύλλο κρούστας', subCategoryName: 'Έτοιμα Γεύματα & Ζύμες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Ζύμη πίτσας', subCategoryName: 'Έτοιμα Γεύματα & Ζύμες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Ψωμί του τόστ σε φέτες', subCategoryName: 'Έτοιμα Γεύματα & Ζύμες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Μπαγκέτα κατεψυγμένη', subCategoryName: 'Έτοιμα Γεύματα & Ζύμες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Burger patties κατεψυγμένα', subCategoryName: 'Έτοιμα Γεύματα & Ζύμες', defaultUnitName: 'Τεμάχιο'),
];