/// Unit tests για το SPoT `AppLogger` (core/logging/app_logger.dart) — §1.7.
///
/// Χρησιμοποιείται η `testSink` (αντί debugPrint) για καταγραφή της εξόδου.
/// Κάθε test ορίζει δική του sink και το tearDown καθαρίζει: `resetTestSink`
/// + `DebugConfig.reset()` ώστε τυχόν `forceDisable` να μην «τρέξει» στο
/// επόμενο test (τα tests του group εκτελούνται ίδιο isolate, σειριακά).
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/debug/debug_config.dart';
import 'package:times/core/logging/app_logger.dart';

void main() {
  group('AppLogger', () {
    tearDown(() {
      AppLogger.resetTestSink();
      DebugConfig.reset();
    });

    // Ενεργοποιεί sink καταγραφής και επιστρέφει τη λίστα γραμμών.
    List<String> useSink() {
      final lines = <String>[];
      AppLogger.testSink = lines.add;
      return lines;
    }

    test('info εγγράφει [TAG] + μήνυμα στη sink', () {
      final lines = useSink();

      AppLogger.info(LogTag.db, 'Απόδειξη αποθηκεύτηκε');

      expect(lines, ['[DB] Απόδειξη αποθηκεύτηκε']);
    });

    test('error εγγράφει tag + [ERROR] + μήνυμα + error object', () {
      final lines = useSink();

      AppLogger.error(LogTag.ui, 'Αποτυχία', Exception('boom'));

      expect(lines.single, contains('[UI][ERROR] Αποτυχία'));
      expect(lines.single, contains('Exception: boom'));
    });

    test('error χωρίς error/stack → μόνο tag+μήνυμα, κανένα crash', () {
      final lines = useSink();

      AppLogger.error(LogTag.nav, 'Σφάλμα');

      expect(lines, ['[NAV][ERROR] Σφάλμα']);
    });

    test('κενό message → καμία έξοδος (info & error)', () {
      final lines = useSink();

      AppLogger.info(LogTag.ui, '');
      AppLogger.error(LogTag.ui, '');

      expect(lines, isEmpty);
    });

    test('forceDisable → καμία έξοδος (release-like)', () {
      final lines = useSink();
      DebugConfig.forceDisable();

      AppLogger.info(LogTag.db, 'Απόδειξη');
      AppLogger.error(LogTag.db, 'Σφάλμα');

      expect(lines, isEmpty);
    });

    test('formatting όλων των tags — κεφαλαία ονόματα (DB, UI, ...)', () {
      final lines = useSink();

      for (final tag in LogTag.values) {
        AppLogger.info(tag, 'x');
      }

      expect(lines, ['[DB] x', '[UI] x', '[NAV] x', '[STATS] x', '[BACKUP] x']);
    });

    test('ποτέ δεν κάνει throw με ασυνήθιστες εισόδους', () {
      final lines = useSink();

      // Τεράστιο μήνυμα — το χειρίζεται ο debugPrint (chunking), όχι εμάς.
      expect(() => AppLogger.info(LogTag.db, 'a' * 10000), returnsNormally);
      // error με error object + stackTrace.
      expect(
        () => AppLogger.error(
          LogTag.db,
          'σφάλμα',
          StateError('x'),
          StackTrace.current,
        ),
        returnsNormally,
      );
      // Και οι δύο κλήσεις έγραψαν (όχι αθόρυβο no-op λόγω exception).
      expect(lines.length, 2);
    });
  });
}