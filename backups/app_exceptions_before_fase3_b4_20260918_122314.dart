/// SPoT: Custom exception classes (data/backup) με structured mapping προς
/// app_errors.dart — ποτέ raw string στα UI (§1.1 / σκελετός Βήμα 4).
///
/// Οι repositories/controllers πετούν ΜΟΝΟ αυτές τις exceptions όταν
/// αποτυγχάνει μια λειτουργία. Κάθε κλάση φέρει:
///   * [AppException.userMessage] — το SPoT string (AppErrors) που δείχνει
///     το UI μέσω AppFeedback.showError / AsyncValueView error,
///   * [AppException.loggingTag] — LogTag §1.7 για το AppLogger.error στο
///     σημείο σύλληψης. Το logging γίνεται ΕΚΕΙ (repo/service, §1.7), όχι
///     εδώ — καθαρά δεδομένα.
///
/// Το mapping είναι compile-time δεσμευμένο: [sealed] βάση + οι μόνες
/// υλοποιήσεις σε αυτό το αρχείο, κάθε constructor περνάει σταθερά
/// AppErrors — raw string αδύνατον (σε αντίθεση με Freezed-generated
/// κλάσεις που θα το επέτρεπαν ως παράμετρο).
///
/// NOTE(Φάση0-Βήμα4): validation exceptions (π.χ. ValidationException,
/// μηνύματα §2.2:214-218) ορίζονται στη Φάση 3 μαζί με τους validators —
/// βλ. αντίστοιχο NOTE στο app_errors.dart.
library;

import '../constants/app_errors.dart';
import '../debug/debug_config.dart';

/// Βάση όλων των app exceptions. [sealed]: καμία υλοποίηση εκτός του SPoT
/// αρχείου — ισχυρός εγγυητής του mapping.
sealed class AppException implements Exception {
  const AppException({required this.userMessage, required this.loggingTag});

  /// SPoT μήνυμα (AppErrors) — αυτό ακριβώς δείχνει το UI. Ποτέ κενό,
  /// ποτέ raw string εκτός SPoT.
  final String userMessage;

  /// Κατηγορία logging (§1.7) — το χρησιμοποιεί το AppLogger.error στο
  /// σημείο αποτυχίας. Προέρχεται από DebugConfig (σύμβαση Βήμα 5).
  final LogTag loggingTag;

  /// Ανθρώπινη αναπαράσταση για τα dev logs — ο AppLogger.error καταγράφει
  /// `| exception` μέσω toString() (app_logger.dart:57).
  @override
  String toString() => '$runtimeType: $userMessage';
}

// ─── Data / DB (§2.1, §2.2) ────────────────────────────────────────────────
/// Σφάλμα αποθήκευσης απόδειξης (§2.2:210-212) → AppErrors.saveFailed.
final class SaveReceiptException extends AppException {
  const SaveReceiptException()
      : super(userMessage: AppErrors.saveFailed, loggingTag: LogTag.db);
}

/// Generic σφάλμα φόρτωσης δεδομένων (§2.1 error state / §2.4 AsyncValueView)
/// → AppErrors.loadDataFailed.
final class DataLoadException extends AppException {
  const DataLoadException()
      : super(userMessage: AppErrors.loadDataFailed, loggingTag: LogTag.db);
}

// ─── Backup / Restore (§2.3) ───────────────────────────────────────────────
/// Αποτυχία δημιουργίας αντιγράφου — Export (Βήμα 1) ΚΑΙ auto-backup πριν το
/// Restore (Βήμα 3) → AppErrors.backupFailed (1 μήνυμα, 2 σημεία χρήσης).
final class BackupCreationException extends AppException {
  const BackupCreationException()
      : super(userMessage: AppErrors.backupFailed, loggingTag: LogTag.backup);
}

/// Άκυρο αρχείο backup (validation Βήμα 2 — SQLite header + πίνακες,
/// καμία αλλαγή στη βάση) → AppErrors.invalidBackupFile.
final class InvalidBackupFileException extends AppException {
  const InvalidBackupFileException()
      : super(
          userMessage: AppErrors.invalidBackupFile,
          loggingTag: LogTag.backup,
        );
}

/// Αποτυχία αντικατάστασης/επαναφοράς βάσης (Βήμα 4) → AppErrors.restoreFailed.
final class RestoreBackupException extends AppException {
  const RestoreBackupException()
      : super(userMessage: AppErrors.restoreFailed, loggingTag: LogTag.backup);
}