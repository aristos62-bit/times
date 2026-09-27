/// SPoT validator ονομάτων Κατηγορίας/Υποκατηγορίας/Είδους/Προμηθευτή
/// (§2.2:214-218 DESIGN · Φάση 3 Βήμα 4).
///
/// [validate]: ελέγχει ένα raw input και επιστρέφει `null` όταν είναι
/// αποδεκτό ή το SPoT AppErrors μήνυμα που δείχνει το πεδίο. ΚΑΝΕΝΑ
/// exception — String? contract (απόφαση Βήμα 4, αντί για ValidationException).
/// [isDuplicate]: case/tone-insensitive duplicate-check μέσω GreekTextNormalizer
/// — ίδιο matching με το `normalizedName` της βάσης (§2.0.4, exact-match).
/// Clean χωρίς side effects (όχι DB/UI/logging).
library;

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_errors.dart';
import '../../core/utils/greek_text_normalizer.dart';

/// SPoT namespace — μόνο static, δεν instantiate (pattern AppConstants).
abstract final class NameValidator {
  /// Ελέγχει [name]: κενό / μόνο-whitespace → nameRequired · μήκος πάνω από
  /// [AppConstants.maxItemNameLength] → nameTooLong · αλλιώς `null` (ΟΚ).
  ///
  /// Ο έλεγχος γίνεται ΠΑΝΤΑ πάνω στο trimmed name — ο καλών αποθηκεύει το
  /// trimmed (το trim γίνεται ΕΔΩ και επιστρέφεται από τον καλούντα).
  static String? validate(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return AppErrors.nameRequired;
    if (trimmed.length > AppConstants.maxItemNameLength) {
      return AppErrors.nameTooLong;
    }
    return null;
  }

  /// True όταν το [name] ταιριάζει (normalized exact) με κάποιο από τα
  /// [existing] ονόματα. Δεν κάνει trim στο ίδιο το [name] — ο καλών
  /// περνάει ήδη-επικυρωμένο (validation πριν τον dup-check).
  static bool isDuplicate(String name, Iterable<String> existing) {
    final normalized = GreekTextNormalizer.normalize(name);
    return existing.any(
      (candidate) =>
          GreekTextNormalizer.normalize(candidate) == normalized,
    );
  }
}