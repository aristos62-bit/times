import 'package:expense_tracker/core/strings/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppStrings (SPoT — κανένα κενό user-facing string)', () {
    test('τίτλοι', () {
      expect(AppStrings.homeTitle, 'Αρχική');
      expect(AppStrings.receiptsTitle, 'Αποδείξεις');
      expect(AppStrings.budgetsTitle, 'Προϋπολογισμοί');
    });

    test('κουμπιά + retry', () {
      expect(AppStrings.save.isNotEmpty, isTrue);
      expect(AppStrings.retry, 'Επανάληψη');
    });

    test('ημερομηνίες', () {
      expect(AppStrings.today, 'Σήμερα');
      expect(AppStrings.yesterday, 'Χθες');
      expect(AppStrings.dayBeforeYesterday, 'Προχθές');
      expect(AppStrings.daysAgoSuffix, 'ημέρες πριν');
    });

    test('μονάδες', () {
      expect(AppStrings.gram, 'γραμμάρια');
      expect(AppStrings.package, 'συσκευασία');
    });
  });
}
