import 'package:expense_tracker/core/constants/app_constants.dart';
import 'package:expense_tracker/features/receipt/domain/models/receipt_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReceiptItemInput', () {
    test('defaults: vatRate = AppConstants.defaultVatRate, discount = 0', () {
      const input = ReceiptItemInput(itemId: 1, quantity: 2, unitPrice: 1.5);
      expect(input.itemId, 1);
      expect(input.quantity, 2);
      expect(input.unitPrice, 1.5);
      expect(input.vatRate, AppConstants.defaultVatRate);
      expect(input.discount, 0);
    });

    test('custom vatRate/discount κρατούνται (χωρίς literals εκτός AppConstants)', () {
      const input = ReceiptItemInput(
        itemId: 10,
        quantity: 3,
        unitPrice: 2.5,
        vatRate: 13,
        discount: 10,
      );
      expect(input.vatRate, 13);
      expect(input.discount, 10);
    });

    test('const canonicalization: δύο ίδια const instances → identical', () {
      const a = ReceiptItemInput(itemId: 1, quantity: 2, unitPrice: 1.5);
      const b = ReceiptItemInput(itemId: 1, quantity: 2, unitPrice: 1.5);
      expect(identical(a, b), isTrue);
    });
  });

  group('ReceiptInput', () {
    test('πεδία αποδίδονται 1:1', () {
      final input = ReceiptInput(
        date: DateTime(2026, 1, 15),
        supplierId: 7,
        invoiceNumber: 'Α-100',
        invoiceSeries: 'Σ1',
        paymentMethod: 'Μετρητά',
        items: const [ReceiptItemInput(itemId: 1, quantity: 2, unitPrice: 1.5)],
        payments: [
          PaymentInput(
            amount: 10,
            date: DateTime(2026, 1, 15),
            method: 'Μετρητά',
          ),
        ],
        notes: 'Σημείωση',
      );
      expect(input.date, DateTime(2026, 1, 15));
      expect(input.supplierId, 7);
      expect(input.invoiceNumber, 'Α-100');
      expect(input.invoiceSeries, 'Σ1');
      expect(input.paymentMethod, 'Μετρητά');
      expect(input.items.single.itemId, 1);
      expect(input.payments.single.amount, 10);
      expect(input.notes, 'Σημείωση');
    });

    test('defaults: payments = const [], nullables = null', () {
      final input = ReceiptInput(
        date: DateTime(2026, 1, 15),
        supplierId: 1,
        paymentMethod: 'Μετρητά',
        items: const [],
      );
      expect(input.invoiceNumber, isNull);
      expect(input.invoiceSeries, isNull);
      expect(input.payments, isEmpty);
      expect(input.notes, isNull);
    });

    test('ρητό const [] items είναι τύπου-έγκυρο (pure carrier)', () {
      final input = ReceiptInput(
        date: DateTime(2026, 1, 15),
        supplierId: 1,
        paymentMethod: 'Κάρτα',
        items: const [],
      );
      expect(input.items, isEmpty);
    });
  });

  group('PaymentInput', () {
    test('πεδία αποδίδονται, reference default null', () {
      final input = PaymentInput(
        amount: 42.5,
        date: DateTime(2026, 1, 15),
        method: 'Κάρτα',
      );
      expect(input.amount, 42.5);
      expect(input.date, DateTime(2026, 1, 15));
      expect(input.method, 'Κάρτα');
      expect(input.reference, isNull);
    });
  });

  group('ReceiptItemUpdate', () {
    test('4 required fields αποδίδονται', () {
      const input = ReceiptItemUpdate(
        quantity: 3,
        unitPrice: 2.5,
        vatRate: 13,
        discount: 5,
      );
      expect(input.quantity, 3);
      expect(input.unitPrice, 2.5);
      expect(input.vatRate, 13);
      expect(input.discount, 5);
    });

    test('const canonicalization: δύο ίδια const instances → identical', () {
      const a = ReceiptItemUpdate(
        quantity: 3,
        unitPrice: 2.5,
        vatRate: 13,
        discount: 5,
      );
      const b = ReceiptItemUpdate(
        quantity: 3,
        unitPrice: 2.5,
        vatRate: 13,
        discount: 5,
      );
      expect(identical(a, b), isTrue);
    });
  });

  group('Συμβόλαιο pure carrier (validation ≠ models)', () {
    test('αρνητική ποσότητα περνάει χωρίς exception', () {
      const input = ReceiptItemInput(itemId: 1, quantity: -2, unitPrice: 1.5);
      expect(input.quantity, -2);
    });

    test('NaN ποσότητα περνάει χωρίς exception', () {
      const input = ReceiptItemInput(itemId: 1, quantity: double.nan, unitPrice: 1.5);
      expect(input.quantity.isNaN, isTrue);
    });

    test('αρνητική τιμή περνάει χωρίς exception', () {
      const input = ReceiptItemInput(itemId: 1, quantity: 2, unitPrice: -1.5);
      expect(input.unitPrice, -1.5);
    });
  });
}