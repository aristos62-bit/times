/// Unit tests για το SPoT `ReceiptValidator` (domain/validators) — §2.2
/// «Validation πριν την αποθήκευση» · Φάση 3 Βήμα 6β.
///
/// Plain `test()` χωρίς widget pump — καθαρή λογική. Καλύπτει όλα τα όρια
/// (κάτω/πάνω), τη σταθερή σειρά σφαλμάτων και τον κανόνα ακέραιας ποσότητας.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_constants.dart';
import 'package:times/core/constants/app_errors.dart';
import 'package:times/core/constants/app_messages.dart';
import 'package:times/domain/validators/receipt_validator.dart';

void main() {
  final limitMessage =
  AppMessages.receiptLinesLimitReached(AppConstants.maxReceiptLines);

  group('ReceiptValidator.validateUnit', () {
    test('υπάρχει μονάδα → null', () {
      expect(ReceiptValidator.validateUnit(true), isNull);
    });

    test('δεν υπάρχει μονάδα → unitRequired', () {
      expect(ReceiptValidator.validateUnit(false), AppErrors.unitRequired);
    });
  });

  group('ReceiptValidator.validatePriceCents', () {
    test('0 → priceMustBePositive (αποκλειστικό κατώτατο)', () {
      expect(ReceiptValidator.validatePriceCents(0),
          AppErrors.priceMustBePositive);
    });

    test('αρνητική → priceMustBePositive', () {
      expect(ReceiptValidator.validatePriceCents(-1),
          AppErrors.priceMustBePositive);
    });

    test('1 λεπτό → null (ελάχιστη αποδεκτή)', () {
      expect(ReceiptValidator.validatePriceCents(1), isNull);
    });

    test('ακριβώς maxPriceCents → null (όριο αποδεκτό)', () {
      expect(
          ReceiptValidator.validatePriceCents(AppConstants.maxPriceCents),
          isNull);
    });

    test('maxPriceCents + 1 → priceTooLarge', () {
      expect(
        ReceiptValidator.validatePriceCents(AppConstants.maxPriceCents + 1),
        AppErrors.priceTooLarge,
      );
    });
  });

  group('ReceiptValidator.validateQuantity', () {
    test('0 → quantityMustBePositive', () {
      expect(ReceiptValidator.validateQuantity(0, allowsDecimal: true),
          AppErrors.quantityMustBePositive);
    });

    test('αρνητική → quantityMustBePositive', () {
      expect(ReceiptValidator.validateQuantity(-1.5, allowsDecimal: true),
          AppErrors.quantityMustBePositive);
    });

    test('NaN → quantityMustBePositive (defensive)', () {
      expect(
          ReceiptValidator.validateQuantity(double.nan, allowsDecimal: true),
          AppErrors.quantityMustBePositive);
    });

    test('0.001 → null (ελάχιστο βήμα των 3 δεκαδικών)', () {
      expect(ReceiptValidator.validateQuantity(0.001, allowsDecimal: true),
          isNull);
    });

    test('δεκαδική 2.5 όταν επιτρέπονται δεκαδικά → null', () {
      expect(ReceiptValidator.validateQuantity(2.5, allowsDecimal: true),
          isNull);
    });

    test('ακριβώς maxQuantity → null (όριο αποδεκτό)', () {
      expect(
        ReceiptValidator.validateQuantity(AppConstants.maxQuantity,
            allowsDecimal: true),
        isNull,
      );
    });

    test('maxQuantity + 0.001 → quantityTooLarge', () {
      expect(
        ReceiptValidator.validateQuantity(AppConstants.maxQuantity + 0.001,
            allowsDecimal: true),
        AppErrors.quantityTooLarge,
      );
    });

    test('άπειρο → quantityTooLarge', () {
      expect(
          ReceiptValidator.validateQuantity(double.infinity,
              allowsDecimal: true),
          AppErrors.quantityTooLarge);
    });

    test('integer-only: 2.0 → null', () {
      expect(ReceiptValidator.validateQuantity(2.0, allowsDecimal: false),
          isNull);
    });

    test('integer-only: 2.5 → quantityMustBeInteger (§2.2:218)', () {
      expect(ReceiptValidator.validateQuantity(2.5, allowsDecimal: false),
          AppErrors.quantityMustBeInteger);
    });

    test('integer-only: 0.5 → quantityMustBeInteger', () {
      expect(ReceiptValidator.validateQuantity(0.5, allowsDecimal: false),
          AppErrors.quantityMustBeInteger);
    });

    test('integer-only: 0 → quantityMustBePositive (προηγείται του integer)',
            () {
          expect(ReceiptValidator.validateQuantity(0, allowsDecimal: false),
              AppErrors.quantityMustBePositive);
        });
  });

  group('ReceiptValidator.validateLine', () {
    test('έγκυρη γραμμή → null', () {
      expect(
        ReceiptValidator.validateLine(
            quantity: 1.5, priceCents: 250, allowsDecimal: true),
        isNull,
      );
    });

    test('άκυρα και τα δύο → πρώτο σφάλμα η ποσότητα', () {
      expect(
        ReceiptValidator.validateLine(
            quantity: 0, priceCents: 0, allowsDecimal: true),
        AppErrors.quantityMustBePositive,
      );
    });

    test('άκυρη μόνο η τιμή → σφάλμα τιμής', () {
      expect(
        ReceiptValidator.validateLine(
            quantity: 1, priceCents: 0, allowsDecimal: true),
        AppErrors.priceMustBePositive,
      );
    });

    test('δεκαδική ποσότητα σε integer-only μονάδα → quantityMustBeInteger',
            () {
          expect(
            ReceiptValidator.validateLine(
                quantity: 2.5, priceCents: 100, allowsDecimal: false),
            AppErrors.quantityMustBeInteger,
          );
        });
  });

  group('ReceiptValidator.validateLineCount', () {
    test('0 → receiptLinesRequired', () {
      expect(ReceiptValidator.validateLineCount(0),
          AppErrors.receiptLinesRequired);
    });

    test('αρνητικό (defensive) → receiptLinesRequired', () {
      expect(ReceiptValidator.validateLineCount(-1),
          AppErrors.receiptLinesRequired);
    });

    test('1 → null', () {
      expect(ReceiptValidator.validateLineCount(1), isNull);
    });

    test('ακριβώς maxReceiptLines → null (όριο αποδεκτό)', () {
      expect(
          ReceiptValidator.validateLineCount(AppConstants.maxReceiptLines),
          isNull);
    });

    test('maxReceiptLines + 1 → AppMessages.receiptLinesLimitReached', () {
      expect(
        ReceiptValidator.validateLineCount(AppConstants.maxReceiptLines + 1),
        limitMessage,
      );
    });
  });

  group('ReceiptValidator.validateReceipt', () {
    test('χωρίς προμηθευτή και χωρίς γραμμές → πρώτα οι γραμμές', () {
      expect(
        ReceiptValidator.validateReceipt(hasSupplier: false, lineCount: 0),
        AppErrors.receiptLinesRequired,
      );
    });

    test('γραμμές αλλά χωρίς προμηθευτή → supplierRequired', () {
      expect(
        ReceiptValidator.validateReceipt(hasSupplier: false, lineCount: 1),
        AppErrors.supplierRequired,
      );
    });

    test('προμηθευτής αλλά χωρίς γραμμές → receiptLinesRequired', () {
      expect(
        ReceiptValidator.validateReceipt(hasSupplier: true, lineCount: 0),
        AppErrors.receiptLinesRequired,
      );
    });

    test('προμηθευτής + γραμμές → null', () {
      expect(
        ReceiptValidator.validateReceipt(hasSupplier: true, lineCount: 1),
        isNull,
      );
    });

    test('πάνω από το όριο γραμμών → μήνυμα ορίου', () {
      expect(
        ReceiptValidator.validateReceipt(
            hasSupplier: true, lineCount: AppConstants.maxReceiptLines + 1),
        limitMessage,
      );
    });

    test('πάνω από το όριο ΚΑΙ χωρίς προμηθευτή → πρώτα το όριο γραμμών', () {
      expect(
        ReceiptValidator.validateReceipt(
            hasSupplier: false, lineCount: AppConstants.maxReceiptLines + 1),
        limitMessage,
      );
    });
  });

  group('ReceiptValidator.isIncompleteNumber', () {
    test('τελικό κόμμα («5,») → true', () {
      expect(ReceiptValidator.isIncompleteNumber('5,'), isTrue);
    });

    test('τελική τελεία («5.») → true', () {
      expect(ReceiptValidator.isIncompleteNumber('5.'), isTrue);
    });

    test('με κενά στα άκρα («  5,  ») → true', () {
      expect(ReceiptValidator.isIncompleteNumber('  5,  '), isTrue);
    });

    test('πλήρης δεκαδικός («5,5») → false', () {
      expect(ReceiptValidator.isIncompleteNumber('5,5'), isFalse);
    });

    test('ακέραιος («5») και κενό → false', () {
      expect(ReceiptValidator.isIncompleteNumber('5'), isFalse);
      expect(ReceiptValidator.isIncompleteNumber(''), isFalse);
    });
  });
}