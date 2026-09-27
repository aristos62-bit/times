/// Κοινοί τύποι δεδομένων seed (Dart records) — Refactor 4 επιπέδων 27-09-2026.
///
/// Τα seed δεδομένα γράφονται με **ονόματα** (όχι αριθμητικά IDs) για να
/// παραμένουν αναγνώσιμα και ανεξάρτητα από τη σειρά εισαγωγής. Οι μετατροπές
/// σε αριθμητικά references γίνονται κεντρικά στο `seed_runner.dart`.
/// Καταλόγου 4 επιπέδων: Category ▸ SubCategory ▸ ItemGroup (Τμήμα).
/// Είδη ΔΕΝ seed-άρονται (απόφαση 27-09-2026 — δημιουργούνται από το UI).
library;

/// Μονάδα μέτρησης που θα γίνει γραμμή του πίνακα `units`.
typedef UnitSeed = ({
  String name,
  String abbreviation,
  bool allowsDecimal,
});

/// Κατηγορία προϊόντων που θα γίνει γραμμή του πίνακα `categories`.
typedef CategorySeed = ({
  String name,
});

/// Υποκατηγορία που αναφέρεται στην κατηγορία [CategorySeed.name].
typedef SubCategorySeed = ({
  String name,
  String categoryName,
});

/// Τμήμα που αναφέρεται στην υποκατηγορία [SubCategorySeed.name].
/// Ορατό όνομα UI: «Τμήμα» (27-09-2026).
typedef ItemGroupSeed = ({
  String name,
  String subCategoryName,
});
