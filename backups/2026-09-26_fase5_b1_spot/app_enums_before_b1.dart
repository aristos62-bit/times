/// SPoT: Μονάδες μέτρησης και τύποι κατηγοριών — «σταθερές τύπων» (οι
/// αριθμητικές τιμές τους). Ο ορισμός των ίδιων των μονάδων γίνεται στη βάση
/// (βλ. DESIGN.md §3), εδώ ζουν οι αναγώγιμες σταθερές/labels.
///
/// NOTE(Φάση0-Βήμα4): οι μονάδες/κατηγορίες είναι ΔΕΔΟΜΕΝΑ στη ΒΔ (§3 — seed
/// Phase 1 στο data/local/seed/). Εδώ θα μπουν ΜΟΝΟ αναγώγιμες σταθερές/labels
/// όταν εμφανιστεί καταναλωτής. Όχι UnitType/CategoryType τώρα: θα δημιουργούσε
/// δεύτερη πηγή αλήθειας (§1.1). PeriodType (μήνας/τρίμηνο/έτος/custom range,
/// §2.1:140 → period_filter_bar) → Φάση 5, όποτε το DESIGN δηλώνει σήμερα
/// `StateProvider<DateRange>`. ThemeMode = built-in Flutter (app_theme) ·
/// LogTag = debug_config.
library;