import 'package:expense_tracker/core/strings/app_strings.dart';
import 'package:expense_tracker/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.validateReceiptDate', () {
    test('null → receiptDateRequired', () {
      expect(Validators.validateReceiptDate(null), AppStrings.receiptDateRequired);
    });

    test('DateTime.now() → null (ανοχή ms)', () {
      expect(Validators.validateReceiptDate(DateTime.now()), isNull);
    });

    test('μακρινό μέλλον → receiptDateInFuture', () {
      expect(
        Validators.validateReceiptDate(DateTime(2100)),
        AppStrings.receiptDateInFuture,
      );
    });
  });

  group('Validators ονόματα (trim)', () {
    test('" a " → nameTooShort', () {
      expect(Validators.validateItemName(' a '), AppStrings.nameTooShort);
    });

    test('έγκυρο όνομα → null', () {
      expect(Validators.validateItemName('Γάλα'), isNull);
    });
  });

  group('Validators αριθμοί (ελληνικό κόμμα)', () {
    test('ποσότητα 1,5 → null', () {
      expect(Validators.validateQuantity('1,5'), isNull);
    });

    test('τιμή 1.234,56 → null', () {
      expect(Validators.validatePrice('1.234,56'), isNull);
    });

    test('αρνητική τιμή → priceNegative', () {
      expect(Validators.validatePrice('-5'), AppStrings.priceNegative);
    });

    test('ΦΠΑ 24 → null', () {
      expect(Validators.validateVatRate('24'), isNull);
    });

    test('ΦΠΑ 24,0 → null', () {
      expect(Validators.validateVatRate('24,0'), isNull);
    });

    test('ΦΠΑ 99 → invalidVatRateValue', () {
      expect(Validators.validateVatRate('99'), AppStrings.invalidVatRateValue);
    });
  });

  group('Validators ΑΦΜ (EL prefix μόνο)', () {
    test('EL123456789 → null', () {
      expect(Validators.validateVatNumber('EL123456789'), isNull);
    });

    test('12EL3456789 → invalidVatNumber', () {
      expect(
        Validators.validateVatNumber('12EL3456789'),
        AppStrings.invalidVatNumber,
      );
    });
  });

  group('Validators τηλέφωνο/email', () {
    test('0030 prefix + 10 ψηφία → null', () {
      expect(Validators.validatePhone('00302101234567'), isNull);
    });

    test('μακρύ TLD → null', () {
      expect(Validators.validateEmail('a@example.travel'), isNull);
    });

    test('άκυρο email → invalidEmail', () {
      expect(Validators.validateEmail('όχι-email'), AppStrings.invalidEmail);
    });
  });

  group('Validators.validateReceipt', () {
    test('άδεια είδη → receiptMustHaveItems', () {
      final result = Validators.validateReceipt(
        date: DateTime.now(),
        supplierId: 1,
        paymentMethod: 'Μετρητά',
        items: const [],
      );
      expect(result.isValid, isFalse);
      expect(result.errors, contains(AppStrings.receiptMustHaveItems));
    });

    test('όλα άκυρα → 3+ σφάλματα', () {
      final result = Validators.validateReceipt(
        date: null,
        supplierId: 0,
        paymentMethod: '',
        items: const [],
      );
      expect(result.isValid, isFalse);
      expect(result.errors.length, greaterThanOrEqualTo(3));
      expect(result.errorMessage.isNotEmpty, isTrue);
    });

    test('έγκυρη απόδειξη με είδη → valid', () {
      const items = [
        ReceiptItemInput(quantity: 2, unitPrice: 1.5),
      ];
      final result = Validators.validateReceipt(
        date: DateTime.now(),
        supplierId: 1,
        paymentMethod: 'Μετρητά',
        items: items,
      );
      expect(result.isValid, isTrue);
      expect(result.errorMessage, isEmpty);
    });

    test('κακά είδη → per-item σφάλματα', () {
      const items = [
        ReceiptItemInput(quantity: 0, unitPrice: -5),
      ];
      final result = Validators.validateReceipt(
        date: DateTime.now(),
        supplierId: 1,
        paymentMethod: 'Μετρητά',
        items: items,
      );
      expect(result.isValid, isFalse);
      expect(result.errors.length, 2);
    });
  });

  group('Validators κατηγορία/προμηθευτής', () {
    test('validateCategoryName', () {
      expect(
        Validators.validateCategoryName(null),
        AppStrings.categoryNameRequired,
      );
      expect(
        Validators.validateCategoryName('  a  '),
        AppStrings.nameTooShort,
      );
      expect(
        Validators.validateCategoryName('Τρόφιμα'),
        isNull,
      );
      expect(
        Validators.validateCategoryName('x' * 51),
        AppStrings.categoryNameTooLong,
      );
    });

    test('validateSupplierName', () {
      expect(
        Validators.validateSupplierName(''),
        AppStrings.supplierNameRequired,
      );
      expect(Validators.validateSupplierName('AB'), isNull);
    });

    test('validateSupplierId invalid', () {
      expect(
        Validators.validateSupplierId(null),
        AppStrings.supplierRequired,
      );
      expect(
        Validators.validateSupplierId(-1),
        AppStrings.supplierRequired,
      );
      expect(Validators.validateSupplierId(3), isNull);
    });

    test('validatePaymentMethod', () {
      expect(
        Validators.validatePaymentMethod(null),
        AppStrings.paymentMethodRequired,
      );
      expect(Validators.validatePaymentMethod('Κάρτα'), isNull);
    });
  });

  group('Validators ΑΦΜ/τηλέφωνο/email/budget', () {
    test('έγκυρο ΑΦΜ → null', () {
      expect(Validators.validateVatNumber('123456789'), isNull);
      expect(Validators.validateVatNumber(null), isNull);
    });

    test('έγκυρο τηλέφωνο → null', () {
      expect(Validators.validatePhone('6971234567'), isNull);
      expect(Validators.validatePhone(null), isNull);
    });

    test('έγκυρο email/κενό → null', () {
      expect(Validators.validateEmail('a@example.gr'), isNull);
      expect(Validators.validateEmail(''), isNull);
    });

    test('validateBudgetAmount', () {
      expect(
        Validators.validateBudgetAmount(null),
        AppStrings.budgetAmountRequired,
      );
      expect(
        Validators.validateBudgetAmount('abc'),
        AppStrings.invalidNumber,
      );
      expect(
        Validators.validateBudgetAmount('0'),
        AppStrings.budgetAmountMustBePositive,
      );
      expect(Validators.validateBudgetAmount('1,5'), isNull);
    });
  });
}
