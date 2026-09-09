import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateFormatter', () {
    test('formatShort 15/01/2026', () {
      expect(DateFormatter.formatShort(DateTime(2026, 1, 15)), '15/01/2026');
    });

    test('formatFull ελληνικά', () {
      expect(
        DateFormatter.formatFull(DateTime(2026, 1, 15)),
        '15 Ιανουαρίου 2026',
      );
    });

    test('formatMonthYear', () {
      expect(
        DateFormatter.formatMonthYear(DateTime(2026, 1, 15)),
        'Ιανουάριος 2026',
      );
    });

    test('formatTime', () {
      expect(DateFormatter.formatTime(DateTime(2026, 1, 15, 14, 30)), '14:30');
    });

    test('formatRelative σήμερα', () {
      expect(DateFormatter.formatRelative(DateTime.now()), 'Σήμερα');
    });

    test('formatRelative χθες', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(DateFormatter.formatRelative(yesterday), 'Χθες');
    });

    test('formatRelative μέλλον → formatShort (όχι αρνητικές ημέρες)', () {
      final future = DateTime.now().add(const Duration(days: 5));
      expect(DateFormatter.formatRelative(future), DateFormatter.formatShort(future));
    });

    test('formatRelative παλιά → formatShort', () {
      final old = DateTime.now().subtract(const Duration(days: 10));
      expect(DateFormatter.formatRelative(old), DateFormatter.formatShort(old));
    });
  });
}
