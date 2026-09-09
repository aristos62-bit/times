import 'package:expense_tracker/core/debug/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLogger', () {
    test('όλες οι μέθοδοι δεν πετάνε', () {
      expect(() => AppLogger.db('q'), returnsNormally);
      expect(() => AppLogger.bloc('e'), returnsNormally);
      expect(() => AppLogger.network('n'), returnsNormally);
      expect(() => AppLogger.performance('p'), returnsNormally);
      expect(() => AppLogger.navigation('n'), returnsNormally);
      expect(() => AppLogger.info('i'), returnsNormally);
      expect(() => AppLogger.error('e'), returnsNormally);
      expect(
        () => AppLogger.error('e', StackTrace.current),
        returnsNormally,
      );
    });
  });
}
