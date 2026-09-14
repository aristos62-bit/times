/// Unit tests για το SPoT `AppException` family (core/errors/app_exceptions.dart).
///
/// Επιβεβαιώνουν: ιεραρχία (Exception), compile-time mapping κάθε κλάσης →
/// AppErrors const + σωστό LogTag (§1.7), SPoT quality, ενεργά tags στο
/// DebugConfig και integration με τον υπάρχοντα AppLogger (testSink — pattern
/// app_logger_test.dart). tearDown καθαρίζει sink + DebugConfig όπως στα
/// debug_config_test/app_logger_test (ίδιο isolate, σειριακή εκτέλεση).
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_errors.dart';
import 'package:times/core/debug/debug_config.dart';
import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/core/logging/app_logger.dart';

void main() {
  group('AppExceptions', () {
    // Κάθε test ξεκινά από καθαρή κατάσταση: κανένα forceDisable + κανονική sink.
    tearDown(() {
      AppLogger.resetTestSink();
      DebugConfig.reset();
    });

    // ─── Ιεραρχία ─────────────────────────────────────────────────────────────
    test('όλα τα στιγμιότυπα είναι Exception και AppException', () {
      for (final e in _allExceptions) {
        expect(e, isA<Exception>(), reason: '${e.runtimeType}');
        expect(e, isA<AppException>(), reason: '${e.runtimeType}');
      }
    });

    // ─── Exact mapping — κλάση → AppErrors const + LogTag (§2.1/§2.2/§2.3) ────
    test('SaveReceiptException → saveFailed + LogTag.db (§2.2:210-212)', () {
      const e = SaveReceiptException();
      expect(e.userMessage, AppErrors.saveFailed);
      expect(e.loggingTag, LogTag.db);
    });

    test('DataLoadException → loadDataFailed + LogTag.db (§2.1/§2.4)', () {
      const e = DataLoadException();
      expect(e.userMessage, AppErrors.loadDataFailed);
      expect(e.loggingTag, LogTag.db);
    });

    test('BackupCreationException → backupFailed + LogTag.backup (§2.3)', () {
      const e = BackupCreationException();
      expect(e.userMessage, AppErrors.backupFailed);
      expect(e.loggingTag, LogTag.backup);
    });

    test('InvalidBackupFileException → invalidBackupFile + LogTag.backup', () {
      const e = InvalidBackupFileException();
      expect(e.userMessage, AppErrors.invalidBackupFile);
      expect(e.loggingTag, LogTag.backup);
    });

    test('RestoreBackupException → restoreFailed + LogTag.backup (§2.3)', () {
      const e = RestoreBackupException();
      expect(e.userMessage, AppErrors.restoreFailed);
      expect(e.loggingTag, LogTag.backup);
    });

    // ─── SPoT quality ─────────────────────────────────────────────────────────
    test('κανένα userMessage μη-κενό ή με whitespace στα άκρα', () {
      for (final e in _allExceptions) {
        expect(e.userMessage, isNotEmpty, reason: '${e.runtimeType}');
        expect(e.userMessage, e.userMessage.trim(), reason: '${e.runtimeType}');
      }
    });

    // ─── DebugConfig σύμβαση (§1.7 / Βήμα 5) ─────────────────────────────────
    test('κάθε loggingTag είναι ενεργό στο DebugConfig (debug default)', () {
      for (final e in _allExceptions) {
        expect(DebugConfig.isTagEnabled(e.loggingTag), isTrue,
            reason: '${e.runtimeType} → ${e.loggingTag}');
      }
    });

    // ─── toString για τα logs ────────────────────────────────────────────────
    test('toString = "runtimeType: userMessage" — για το "| error" των logs', () {
      const e = SaveReceiptException();
      expect(e.toString(), 'SaveReceiptException: ${AppErrors.saveFailed}');
    });

    // ─── Integration: ο υπάρχων AppLogger δέχεται tag + object έτοιμα ────────
    test('AppLogger.error(e.loggingTag, msg, e) καταγράφει το toString', () {
      final lines = <String>[];
      AppLogger.testSink = lines.add;
      const e = SaveReceiptException();

      AppLogger.error(e.loggingTag, 'Σφάλμα αποθήκευσης', e);

      expect(lines.single, contains('[DB][ERROR] Σφάλμα αποθήκευσης'));
      expect(
        lines.single,
        contains('SaveReceiptException: ${AppErrors.saveFailed}'),
      );
    });
  });
}

/// Χειροκίνητα συντηρούμενη λίστα όλων των concrete exceptions του SPoT —
/// χρησιμοποιείται από τους looping ελέγχους. Νέο exception → προστίθεται εδώ.
const List<AppException> _allExceptions = [
  SaveReceiptException(),
  DataLoadException(),
  BackupCreationException(),
  InvalidBackupFileException(),
  RestoreBackupException(),
];