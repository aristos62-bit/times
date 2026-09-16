/// Κοινοί τύποι δεδομένων seed (Dart records) — Φάση 1, Βήμα 3.
///
/// Τα seed δεδομένα γράφονται με **ονόματα** (όχι αριθμητικά IDs) για να
/// παραμένουν αναγνώσιμα και ανεξάρτητα από τη σειρά εισαγωγής. Οι μετατροπές
/// σε αριθμητικά references γίνονται κεντρικά στο `seed_runner.dart`.
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

/// Είδος που αναφέρεται στην υποκατηγορία [SubCategorySeed.name] και —
/// προαιρετικά — στη μονάδα [UnitSeed.name] ως προτεινόμενη `defaultUnitId`.
/// Το [defaultUnitName] είναι `null` όταν η φύση του προϊόντος δεν είναι
/// μονοσήμαντη (π.χ. κονσέρβες, αξεσουάρ).
typedef ItemSeed = ({
  String name,
  String subCategoryName,
  String? defaultUnitName,
});