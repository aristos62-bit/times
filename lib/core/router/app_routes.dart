/// SPoT: Ονόματα/paths routes ως σταθερές — ποτέ raw strings σε context.go(...)
/// (§1.1:33). Το GoRouter config (route definitions) είναι ξεχωριστό αρχείο
/// στο router/ (§1.2:42) — εδώ ΜΟΝΟ σταθερές, μηδέν imports.
library;

/// Abstract SPoT namespace — μόνο σταθερές, δεν instantiate (pattern AppConstants).
abstract final class AppRoutes {
  // ─── Home (§2.1) — initial route ───────────────────────────────────────────
  /// Path της αρχικής σελίδας στατιστικών.
  static const String homePath = '/';

  /// Όνομα route (goNamed) της αρχικής σελίδας.
  static const String home = 'home';

  // ─── Price Entry (§2.2) ────────────────────────────────────────────────────
  /// Path της σελίδας εισαγωγής τιμών.
  static const String priceEntryPath = '/price-entry';

  /// Όνομα route (goNamed) της σελίδας εισαγωγής τιμών.
  static const String priceEntry = 'priceEntry';

  // ─── Settings (§2.3) ───────────────────────────────────────────────────────
  /// Path της σελίδας ρυθμίσεων.
  static const String settingsPath = '/settings';

  /// Όνομα route (goNamed) της σελίδας ρυθμίσεων.
  static const String settings = 'settings';
}