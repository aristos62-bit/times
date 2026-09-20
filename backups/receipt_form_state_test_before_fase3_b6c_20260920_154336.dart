/// Unit tests — `ReceiptFormState` (Freezed · §2.2 / Φάση 3 Βήμα 3).
///
/// Freezed παράγει equality/copyWith — εδώ κλειδώνονται οι συμβάσεις
/// (immutability, equality, hashCode) που εξαρτά ο controller (setDate/
/// setSupplier). Σημ.: το `DateTime` δεν έχει const constructor → τα state
/// instances δημιουργούνται ως `final` (default factory των Freezed είναι
/// const, αλλά καλείται με runtime-δεδομένα εδώ).
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:times/data/local/app_database.dart';
import 'package:times/presentation/price_entry/state/receipt_form_state.dart';

void main() {
  final fixed = DateTime(2026, 9, 17);
  final other = DateTime(2026, 9, 18);

  /// Δεδομένος προμηθευτής (Drift data-class, value equality).
  Supplier supplier({int id = 1}) => Supplier(
        id: id,
        name: 'Μάρκος',
        normalizedName: 'μαρκοσ',
        createdAt: fixed,
      );

  group('ReceiptFormState', () {
    test('μεταφέρει την ημερομηνία', () {
      final state = ReceiptFormState(date: fixed);
      expect(state.date, fixed);
    });

    test('supplier default = null (κανένας επιλεγμένος)', () {
      final state = ReceiptFormState(date: fixed);
      expect(state.supplier, isNull);
    });

    test('draftLines default = κενή λίστα + isSaving default = false', () {
      final state = ReceiptFormState(date: fixed);
      expect(state.draftLines, isEmpty);
      expect(state.isSaving, isFalse);
    });

    test('μεταφέρει τον επιλεγμένο προμηθευτή', () {
      final s = supplier();
      final state = ReceiptFormState(date: fixed, supplier: s);
      expect(state.supplier, s);
    });

    test('equality: ίδια date → equal (+ hashCode consistency)', () {
      final a = ReceiptFormState(date: fixed);
      final b = ReceiptFormState(date: fixed);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('equality: ίδιος supplier → equal', () {
      final a = ReceiptFormState(date: fixed, supplier: supplier());
      final b = ReceiptFormState(date: fixed, supplier: supplier());
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('equality: διαφορετικός supplier → όχι equal', () {
      final a = ReceiptFormState(date: fixed, supplier: supplier(id: 1));
      final b = ReceiptFormState(date: fixed, supplier: supplier(id: 2));
      expect(a, isNot(b));
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

    test('copyWith αλλάζει μόνο τον supplier (αμετάβλητο το original)', () {
      final s = supplier();
      final a = ReceiptFormState(date: fixed);
      final b = a.copyWith(supplier: s);
      expect(b.supplier, s);
      expect(a.supplier, isNull);
      expect(a.date, fixed);
    });

    test('copyWith καθαρίζει τον supplier με ρητό null', () {
      final a = ReceiptFormState(date: fixed, supplier: supplier());
      final b = a.copyWith(supplier: null);
      expect(b.supplier, isNull);
      expect(a.supplier, isNotNull);
    });
  });

  group('DraftReceiptLine', () {
    /// Δεδομένη γραμμή «καλαθιού».
    DraftReceiptLine line({
      int itemId = 1,
      int unitId = 2,
      double quantity = 1.5,
      int priceCents = 250,
    }) =>
        DraftReceiptLine(
          itemId: itemId,
          unitId: unitId,
          quantity: quantity,
          priceCents: priceCents,
          itemName: 'Γάλα',
          unitAbbreviation: 'κιλ',
        );

    test('equality: ίδιες τιμές → equal (+ hashCode consistency)', () {
      expect(line(), line());
      expect(line().hashCode, line().hashCode);
    });

    test('equality: διαφορετικό πεδίο → όχι equal', () {
      expect(line(), isNot(line(itemId: 9)));
      expect(line(), isNot(line(unitId: 9)));
      expect(line(), isNot(line(quantity: 9.0)));
      expect(line(), isNot(line(priceCents: 999)));
    });
  });

  group('ReceiptFormState.draftLines (Βήμα 5γ)', () {
    DraftReceiptLine line(int itemId) => DraftReceiptLine(
          itemId: itemId,
          unitId: 2,
          quantity: 1.0,
          priceCents: 250,
          itemName: 'Γάλα',
          unitAbbreviation: 'κιλ',
        );

    test('draftLines default = κενή λίστα (κανένα «καλάθι»)', () {
      final state = ReceiptFormState(date: fixed);
      expect(state.draftLines, isEmpty);
    });

    test('equality: ίδιες γραμμές → equal', () {
      final a = ReceiptFormState(date: fixed, draftLines: [line(1)]);
      final b = ReceiptFormState(date: fixed, draftLines: [line(1)]);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('equality: διαφορετικές γραμμές → όχι equal', () {
      final a = ReceiptFormState(date: fixed, draftLines: [line(1)]);
      final b = ReceiptFormState(date: fixed, draftLines: [line(2)]);
      expect(a, isNot(b));
    });

    test('copyWith αλλάζει μόνο τις γραμμές (αμετάβλητο το original)', () {
      final a = ReceiptFormState(date: fixed);
      final b = a.copyWith(draftLines: [line(1), line(2)]);
      expect(b.draftLines.length, 2);
      expect(a.draftLines, isEmpty);
      expect(b.date, fixed);
    });

    test('copyWith isSaving true/false (αμετάβλητο το original)', () {
      final a = ReceiptFormState(date: fixed);
      final b = a.copyWith(isSaving: true);
      expect(b.isSaving, isTrue);
      expect(a.isSaving, isFalse);
      expect(b.copyWith(isSaving: false), a);
    });
  });
}