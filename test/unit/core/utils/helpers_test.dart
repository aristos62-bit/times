import 'package:expense_tracker/core/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Helpers.formatPercentage', () {
    test('12.345 → 12.3%', () {
      expect(Helpers.formatPercentage(12.345), '12.3%');
    });

    test('0 → 0.0%', () {
      expect(Helpers.formatPercentage(0), '0.0%');
    });
  });

  group('Helpers.getTimestamp', () {
    test('UTC ISO8601 με Z', () {
      final ts = Helpers.getTimestamp();
      expect(ts.endsWith('Z'), isTrue);
      expect(() => DateTime.parse(ts), returnsNormally);
    });
  });

  group('Helpers.logPerformance', () {
    test('δεν πετάει', () {
      expect(
        () => Helpers.logPerformance('op', const Duration(milliseconds: 5)),
        returnsNormally,
      );
    });
  });
}
