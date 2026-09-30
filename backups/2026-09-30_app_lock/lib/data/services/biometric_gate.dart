/// SPoT wrapper γύρω από το `local_auth` για το κλείδωμα (§2.3 · 30-09-2026).
///
/// Απομονώνει το `LocalAuthentication` (platform channel — untestable
/// κατευθείαν + API που αλλάζει ανά έκδοση, evidence 3.0.2: direct named
/// params, όχι `AuthenticationOptions` wrapper): ο controller εξαρτάται
/// ΜΟΝΟ από το abstract (override με fake στα tests, pattern
/// `backupFilePickerProvider`/`sharedPreferencesProvider`). Dumb delegator:
/// καθόλου business logic, logging, SPoT strings — μόνο προώθηση +
/// false-contract (ακύρωση/σφάλμα → `false`, ο καλών κάνει log).
library;

import 'package:local_auth/local_auth.dart';

/// Συμβόλαιο τοπικής ταυτοποίησης (βιομετρικά ή PIN συσκευής — Q3).
abstract interface class BiometricGate {
  /// `true` = η συσκευή υποστηρίζει έλεγχο (Q4: αλλιώς η κάρτα κρύβεται).
  /// Pattern pub.dev docs: `canCheckBiometrics || isDeviceSupported()` —
  /// το `getAvailableBiometrics` ΔΕΝ καλείται (iOS permission side-effect).
  Future<bool> isSupported();

  /// Ταυτοποίηση με [reason] (SPoT non-empty — το API το απαιτεί).
  /// `true` = επιτυχία· `false` = αποτυχία/ακύρωση/σφάλμα πλατφόρμας
  /// (ο καλών κάνει log — κανένα throw).
  Future<bool> authenticate(String reason);
}

/// Παραγωγική υλοποίηση πάνω στο `LocalAuthentication`.
final class LocalAuthBiometricGate implements BiometricGate {
  LocalAuthBiometricGate([LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isSupported() async {
    if (await _auth.canCheckBiometrics) return true;
    return _auth.isDeviceSupported();
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        // Q3: fallback σε PIN/pattern/passcode συσκευής (ποτέ lockout).
        biometricOnly: false,
        // Το OS dialog βάζει την εφαρμογή σε background — χωρίς αυτό η
        // ταυτοποίηση θα απέτυχε στην επιστροφή (docs 3.0.2).
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
