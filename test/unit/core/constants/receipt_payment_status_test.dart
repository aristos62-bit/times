// test/unit/core/constants/receipt_payment_status_test.dart
//
// SPoT Status Pattern — μονάδες για το ReceiptPaymentStatus enum.
// Καλύπτει: dbValue mapping προς AppConstants (SPoT), roundtrip
// fromDbValue, fail-fast ArgumentError σε άγνωστη τιμή και exhaustive
// members (3/3). Η συνοχή enum↔constants ελέγχεται και εδώ + στο
// app_constants_test.dart (cross-file guard).
import 'package:expense_tracker/core/constants/app_constants.dart';
import 'package:expense_tracker/core/constants/receipt_payment_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReceiptPaymentStatus', () {
    test('members: 3 κατάστασεις, χωρίς διπλές dbValue', () {
      expect(ReceiptPaymentStatus.values, hasLength(3));
      final distinct =
          ReceiptPaymentStatus.values.map((s) => s.dbValue).toSet();
      expect(distinct, hasLength(3));
    });

    test('dbValue ταυτίζεται με τα AppConstants (SPoT)', () {
      expect(ReceiptPaymentStatus.pending.dbValue,
          AppConstants.paymentStatusPending);
      expect(ReceiptPaymentStatus.partial.dbValue,
          AppConstants.paymentStatusPartial);
      expect(ReceiptPaymentStatus.paid.dbValue,
          AppConstants.paymentStatusPaid);
    });

    test('fromDbValue: γνωστές τιμές → σωστό enum (roundtrip)', () {
      expect(ReceiptPaymentStatus.fromDbValue('pending'),
          ReceiptPaymentStatus.pending);
      expect(ReceiptPaymentStatus.fromDbValue('partial'),
          ReceiptPaymentStatus.partial);
      expect(ReceiptPaymentStatus.fromDbValue('paid'),
          ReceiptPaymentStatus.paid);
      // Στάθμη με τους constants (και όχι μόνο magic strings).
      expect(ReceiptPaymentStatus.fromDbValue(AppConstants.paymentStatusPending),
          ReceiptPaymentStatus.pending);
    });

    test('fromDbValue: unknown → ArgumentError (fail-fast, χωρίς fallback)', () {
      expect(() => ReceiptPaymentStatus.fromDbValue('void'),
          throwsArgumentError);
      expect(() => ReceiptPaymentStatus.fromDbValue(''),
          throwsArgumentError);
      // Διάκριση κεφαλαίων: 'Paid' είναι άγνωστη τιμή (case-sensitive DB).
      expect(() => ReceiptPaymentStatus.fromDbValue('Paid'),
          throwsArgumentError);
    });
  });
}