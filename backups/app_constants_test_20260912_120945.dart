import 'package:expense_tracker/core/constants/app_constants.dart';
import 'package:expense_tracker/core/strings/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConstants', () {
    test('vatRates περιέχει defaultVatRate', () {
      expect(AppConstants.vatRates, contains(AppConstants.defaultVatRate));
    });

    test('units ενοποιημένα με AppStrings (SPoT)', () {
      expect(AppConstants.units, [
        AppStrings.piece,
        AppStrings.kg,
        AppStrings.gram,
        AppStrings.liter,
        AppStrings.meter,
        AppStrings.package,
      ]);
    });

    test('paymentMethods μη κενά', () {
      expect(AppConstants.paymentMethods, isNotEmpty);
      for (final m in AppConstants.paymentMethods) {
        expect(m.isNotEmpty, isTrue);
      }
    });

    test('minReceiptDate 2000 + snackBarDuration 2s', () {
      expect(AppConstants.minReceiptDate, DateTime(2000, 1, 1));
      expect(AppConstants.snackBarDuration, const Duration(seconds: 2));
    });

    test('payment status constants (SPoT — αποθηκευμένες DB τιμές)', () {
      expect(AppConstants.paymentStatusPending, 'pending');
      expect(AppConstants.paymentStatusPartial, 'partial');
      expect(AppConstants.paymentStatusPaid, 'paid');
      expect(AppConstants.paymentStatusPending,
          isNot(AppConstants.paymentStatusPaid));
    });
  });
}
