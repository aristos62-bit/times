/// Unit tests — `ReceiptFormState` (Freezed · §2.2 / Φάση 3 Βήμα 2).
///
/// Freezed παράγει equality/copyWith — εδώ κλειδώνονται οι συμβάσεις
/// (immutability, equality, hashCode) που εξαρτά ο `setDate` του controller.
/// Σημ.: το `DateTime` δεν έχει const constructor → τα state instances
/// δημιουργούνται ως `final` (default factory των Freezed είναι const,
/// αλλά καλείται με runtime-δεδομένα εδώ).
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:times/presentation/price_entry/state/receipt_form_state.dart';

void main() {
  final fixed = DateTime(2026, 9, 17);
  final other = DateTime(2026, 9, 18);

  group('ReceiptFormState', () {
    test('μεταφέρει την ημερομηνία', () {
      final state = ReceiptFormState(date: fixed);
      expect(state.date, fixed);
    });

    test('equality: ίδια date → equal (+ hashCode consistency)', () {
      final a = ReceiptFormState(date: fixed);
      final b = ReceiptFormState(date: fixed);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('equality: διαφορετική date → όχι equal', () {
      final a = ReceiptFormState(date: fixed);
      final b = ReceiptFormState(date: other);
      expect(a, isNot(b));
    });

    test('copyWith αλλάζει μόνο το date (αμετάβλητο το original)', () {
      final a = ReceiptFormState(date: fixed);
      final b = a.copyWith(date: other);
      expect(b.date, other);
      expect(a.date, fixed);
    });
  });
}