/// SPoT ημερολογιακών πράξεων (§2.1/§2.3 DESIGN · 01-10-2026).
///
/// `dayOnly` + `addDays`: αριθμητική ΗΜΕΡΟΛΟΓΙΟΥ (όχι `Duration`) — ο
/// κατασκευαστής `DateTime(y, m, d+n)` κανονικοποιεί overflow μπρος/πίσω
/// και δίνει τοπικά μεσάνυχτα ΠΑΝΤΑ, και στις 23ωρες/25ωρες μέρες
/// (Europe/Athens: τελευταία Κυριακή Μαρτίου/Οκτωβρίου). Το `Duration`
/// σε τοπικά μεσάνυχτα σπάει εκεί (π.χ. 29-03-2026 +24h = 30-03 01:00).
/// Χρήση: όρια περιόδων `[from, to)` (charts, στατιστικές, φίλτρο ημέρας).
/// Pure (χωρίς state/IO/logging) — testable χωρίς βάση/ζώνη.
library;

/// Κανονικοποιεί σε τοπικά μεσάνυχτα (χωρίς ώρα).
DateTime dayOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Προσθέτει [days] ημερολογιακές μέρες (αρνητικό = πίσω) — DST-ασφαλές,
/// αντί του `date.add(Duration(days: n))` που χάνει τα μεσάνυχτα στις
/// αλλαγές ώρας.
DateTime addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);
