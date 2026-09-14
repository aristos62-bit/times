/// SPoT: Config ενεργοποίησης/απενεργοποίησης logging ανά κατηγορία
/// (DB, UI, NAV, STATS, BACKUP) και ανά release/debug (§1.7 DESIGN).
///
/// Ορίζεται ΕΔΩ και το `LogTag`: οι κατηγορίες logging είναι μέρος του
/// config (ποιο tag υπάρχει + αν είναι ενεργό). Έτσι:
///   - ο `AppLogger` εξαρτάται **μόνο** από το `DebugConfig`
///     (μονοκατεύθυνση `logging → debug`, καμία circular dependency),
///   - τα exceptions (`app_exceptions.dart`, Βήμα 4) παίρνουν το logging
///     tag από εδώ χωρίς «import μόνο για ένα enum».
///
/// Συμπεριφορά:
///   * `isEnabled` = `kDebugMode` (release build → **ΚΑΝΕΝΑ** log,
///     compile-time tree-shaking, μηδενικό κόστος σε production).
///   * `enabledTags` = ενεργές κατηγορίες σε debug (SPoT: απενεργοποίηση
///     κατηγορίας = αφαίρεση από τη σταθερά).
///   * `forceDisable`/`reset` μόνο για tests (release-like έλεγχος·
///     στα tests το `kDebugMode` είναι πάντα true).
library;

import 'package:flutter/foundation.dart';

/// Ομαδοποιημένες κατηγορίες log (§1.7 DESIGN): DB, UI, NAV, STATS, BACKUP.
enum LogTag { db, ui, nav, stats, backup }

/// SPoT namespace — μόνο static, δεν instantiate (pattern AppConstants).
abstract final class DebugConfig {
  /// Συνολικός διακόπτης logging. Σε release build (`kDebugMode == false`)
  /// επιστρέφει πάντα false — καμία κατηγορία δεν καταγράφεται.
  static bool get isEnabled => kDebugMode && !_forceDisabled;

  // Test-only: προσομοιώνει release-like συμπεριφορά όταν είναι true.
  static bool _forceDisabled = false;

  /// Ενεργές κατηγορίες σε debug mode (§1.7: «ενεργοποίηση/απενεργοποίηση
  /// ανά κατηγορία log»). Κάθε tag του §1.7 είναι αρχικά ενεργό.
  static const Set<LogTag> enabledTags = {
    LogTag.db,
    LogTag.ui,
    LogTag.nav,
    LogTag.stats,
    LogTag.backup,
  };

  /// True αν η κατηγορία [tag] καταγράφεται αυτή τη στιγμή.
  static bool isTagEnabled(LogTag tag) => isEnabled && enabledTags.contains(tag);

  /// Μόνο για tests — σβήνει όλο το logging (release-like συμπεριφορά).
  @visibleForTesting
  static void forceDisable() => _forceDisabled = true;

  /// Μόνο για tests — επαναφορά στην default (ενεργή) κατάσταση.
  @visibleForTesting
  static void reset() => _forceDisabled = false;
}