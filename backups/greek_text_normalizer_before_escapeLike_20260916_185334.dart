/// SPoT: Ελληνικό normalization κειμένου για αναζήτηση (§2.0.4 DESIGN).
///
/// Μετατρέπει το κείμενο σε κανονική μορφή: αφαιρεί τόνους/διαλυτικά,
/// κατεβάζει σε πεζά και εξομοιώνει το τελικό «ς» σε «σ». Έτσι το query
/// «γαλα» βρίσκει «Γάλα», «ΓΑΛΑ», «γάλα», «ΓάλΑ» κ.λπ.
///
/// Εφαρμόζεται ΟΜΟΙΟΜΟΡΦΑ (ίδια μορφή παντού, §2.0.4):
///   1. UI input πριν το query «φύγει» (item_search_controller, Φάση 3).
///   2. SQL: `normalizedName` στήλη σε Item/Supplier (Φάση 1/3).
///   3. Duplicate-check: `normalizedName == :normalizedQuery` (§2.2, exact).
///
/// Clean χωρίς side effects: δεν διαβάζει UI/DB/theme, δεν κάνει log
/// (logger = Φάση 0 Βήμα 5, εκτός φάσης), δεν είναι async, δεν εμφανίζει
/// μηνύματα. Δεν κάνει trim — ευθύνη του validator. Μηδέν external
/// dependencies (zero-dependency: το transitive `characters` δεν
/// χρησιμοποιείται — το χειροκίνητο combining-strip το υπερκαλύπτει).
library;

/// SPoT namespace — μόνο static, δεν instantiate (pattern AppConstants).
abstract final class GreekTextNormalizer {
  /// Χάρτης πεζών με τόνο/διαλυτικά → άτονο. Εφαρμόζεται ΜΕΤΑ το
  /// toLowerCase, οπότε καλύπτει και τα κεφαλαία (Ά→ά→α). Το τελικό
  /// «ς» εξομοιώνεται σε «σ» για σωστό case/άτονο matching.
  static const Map<String, String> _toneMap = {
    'ά': 'α', 'έ': 'ε', 'ή': 'η', 'ί': 'ι', 'ό': 'ο', 'ύ': 'υ', 'ώ': 'ω',
    'ϊ': 'ι', 'ϋ': 'υ', 'ΐ': 'ι', 'ΰ': 'υ', 'ς': 'σ',
  };

  /// Πλήρες ελληνικό normalization: πεζά + άτονα + «ς»→«σ».
  /// Idempotent: normalize(normalize(x)) == normalize(x).
  /// Κενό input επιστρέφεται ως έχει.
  static String normalize(String value) {
    if (value.isEmpty) return value;
    final lower = _removeCombiningMarks(value).toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_toneMap[char] ?? char);
    }
    return buffer.toString();
  }

  /// Αφαιρεί combining diacritical marks (U+0300–U+036F) — προφύλαξη για
  /// decomposed εισαγωγή τόνου (ελληνικά και άλλα scripts) χωρίς external
  /// package. Επιπλέον κερδίζει λατινικά τόνικα σε decomposed μορφή
  /// (π.χ. «Cafe»+combining acute βρίσκει «cafe» με τη μορφή μας).
  static String _removeCombiningMarks(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      if (rune < 0x0300 || rune > 0x036F) {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }
}