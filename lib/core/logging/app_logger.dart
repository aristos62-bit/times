/// SPoT logger με ομαδοποιημένα tags: DB, UI, NAV, STATS, BACKUP (§1.7 DESIGN).
///
/// Το ΜΟΝΟ σημείο εκτύπωσης μη-UI μηνυμάτων (dev-facing). Τα
/// repositories/services καταγράφουν με τα δύο επίπεδα:
///   AppLogger.info(LogTag.db, '...');   // create/update/delete, query results
///   AppLogger.error(LogTag.ui, '...');  // σφάλματα (προαιρετικό error+stack)
///
/// Όλη η έξοδος περνάει από `debugPrint` (όχι `print` — lint `avoid_print`):
///   * τεμαχίζει μεγάλα μηνύματα/stackTraces (chunking) χωρίς δικό μας κόψιμο,
///   * ελέγχεται πλήρως από το `DebugConfig` (release build → καμία έξοδος).
///
/// Καθαρό & σύγχρονο: χωρίς state, timers, context → κανένα leak/lifecycle
/// issue (αντίθεση με τον Debouncer που απαιτεί dispose).
///
/// Testability: η έξοδος γίνεται `(_testSink ?? debugPrint)(line)` — η
/// `testSink` (μόνο `@visibleForTesting`) καταγράφει αντί για debugPrint.
/// Πρέπει πάντα `resetTestSink()` στο tearDown των tests.
library;

import 'package:flutter/foundation.dart';

import '../debug/debug_config.dart';

/// Re-export: όσοι κάνουν import του logger παίρνουν και το [LogTag]
/// (π.χ. exceptions Βήμα 4, app_feedback) — ένα import για όλα.
export '../debug/debug_config.dart' show LogTag;

/// SPoT namespace — μόνο static, δεν instantiate (pattern AppConstants).
abstract final class AppLogger {
  // Test-only sink: αντικαθιστά το debugPrint — ποτέ σε production.
  // Η έξοδος είναι πάντα String, άρα ο sink δέχεται String.
  static void Function(String line)? _testSink;

  /// Μόνο για tests — καταγράφει την έξοδο αντί για debugPrint.
  @visibleForTesting
  static set testSink(void Function(String line) sink) => _testSink = sink;

  /// Μόνο για tests — επαναφορά στο κανονικό debugPrint.
  @visibleForTesting
  static void resetTestSink() => _testSink = null;

  /// Καταγραφή πληροφοριακού γεγονότος (create/update/delete ops,
  /// query results κ.λπ. — §1.7). Μορφή: `[TAG] μήνυμα`.
  static void info(LogTag tag, String message) {
    if (_shouldLog(tag, message)) {
      _emit('[${_tagName(tag)}] $message');
    }
  }

  /// Καταγραφή σφάλματος με προαιρετικό [error] object και [stackTrace]
  /// (multi-line μέσω StringBuffer· ο debugPrint αναλαμβάνει το chunking).
  /// Μορφή: `[TAG][ERROR] μήνυμα | error` + νέα γραμμή με το stackTrace.
  static void error(LogTag tag, String message,
      [Object? error, StackTrace? stackTrace]) {
    if (!_shouldLog(tag, message)) return;
    final buffer = StringBuffer('[${_tagName(tag)}][ERROR] $message');
    if (error != null) buffer.write(' | $error');
    if (stackTrace != null) buffer.writeln('\n$stackTrace');
    _emit(buffer.toString());
  }

  // Gate: κενό μήνυμα → skip χωρίς κενή γραμμή output. Ποτέ exception.
  static bool _shouldLog(LogTag tag, String message) =>
      message.isNotEmpty && DebugConfig.isTagEnabled(tag);

  // Κεφαλαίο tag στο output (DB) για αντιστοίχιση με την ονοματολογία §1.7.
  static String _tagName(LogTag tag) => tag.name.toUpperCase();

  static void _emit(String line) => (_testSink ?? debugPrint)(line);
}