/// Pure unit tests — SPoT `lineTotalCents` (§3, `core/utils/line_total.dart`).
///
/// Κατοπτρικά values με τα DAO tests (ίδια αριθμητική σε όλες τις στρώσεις,
/// χωρίς DB): stored writes + display mirrors συμφωνούν εξ ορισμού.
/// Χωρίς Flutter binding — καθαρή συνάρτηση.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/utils/line_total.dart';

void main() {
  group('lineTotalCents (§3)', () {
    test('2.5 × 199 = 497.5 → 498 (mirror DAO test)', () {
      expect(
        lineTotalCents(priceCents: 199, discountCents: 0, quantity: 2.5),
        498,
      );
    });

    test('(250−50) × 2 = 400 (mirror DAO test)', () {
      expect(
        lineTotalCents(priceCents: 250, discountCents: 50, quantity: 2),
        400,
      );
    });

    test('0,01 € × 0,004 → 0 (edge §5, mirror DAO test)', () {
      expect(
        lineTotalCents(priceCents: 1, discountCents: 0, quantity: 0.004),
        0,
      );
    });

    test('ακέραια ποσότητα, χωρίς έκπτωση', () {
      expect(
        lineTotalCents(priceCents: 250, discountCents: 0, quantity: 3),
        750,
      );
    });

    test('έκπτωση == τιμή → 0', () {
      expect(
        lineTotalCents(priceCents: 100, discountCents: 100, quantity: 2),
        0,
      );
    });

    test('κλασματικά κιλά: 3,50 € × 0,456 → 160', () {
      expect(
        lineTotalCents(priceCents: 350, discountCents: 0, quantity: 0.456),
        160,
      );
    });
  });

  group('grossTotalCents + discountTotalCents (§2.3 · 01-10)', () {
    test('μικτό: 12,96 € × 0,456 → 591 (στήλη Σύνολο)', () {
      expect(grossTotalCents(priceCents: 1296, quantity: 0.456), 591);
    });

    test('έκπτωση συνόλου: 0,35 € × 0,456 → 16 (στήλη Έκπτωση)', () {
      expect(discountTotalCents(discountCents: 35, quantity: 0.456), 16);
    });
  });
}
