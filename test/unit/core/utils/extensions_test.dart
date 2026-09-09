import 'package:expense_tracker/core/utils/extensions.dart';
import 'package:expense_tracker/core/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StringExtensions', () {
    test('κενό capitalize → κενό (όχι RangeError)', () {
      expect(''.capitalize, '');
    });

    test('hello → Hello', () {
      expect('hello'.capitalize, 'Hello');
    });

    test('isNumeric', () {
      expect('1.5'.isNumeric, isTrue);
      expect('abc'.isNumeric, isFalse);
    });

    test('Helpers.isNumeric reuse', () {
      expect(Helpers.isNumeric('1.5'), isTrue);
      expect(Helpers.isNumeric('abc'), isFalse);
    });
  });

  group('DateTimeExtensions', () {
    test('startOfDay', () {
      final d = DateTime(2026, 1, 15, 14, 30).startOfDay;
      expect(d, DateTime(2026, 1, 15));
    });

    test('endOfDay 999ms', () {
      final d = DateTime(2026, 1, 15).endOfDay;
      expect(d.millisecond, 999);
    });

    test('endOfMonth 999ms', () {
      final d = DateTime(2026, 1, 15).endOfMonth;
      expect(d.millisecond, 999);
    });

    test('isToday', () {
      expect(DateTime.now().isToday, isTrue);
    });
  });

  group('DoubleExtensions', () {
    test('approximates 0.1+0.2 ≈ 0.3', () {
      expect((0.1 + 0.2).approximates(0.3), isTrue);
    });

    test('toCurrency', () {
      expect(1234.56.toCurrency(), '1.234,56€');
    });
  });
}
