/// Unit tests για το SPoT `AppColors` (core/theme/app_colors.dart) — §1.1/§1.5.
///
/// Απλές const → plain `test()`, χωρίς widget pump (στυλ app_strings_test).
/// Τιμές επαληθευμένες με το DESIGN (§0 seed teal #00897B · §4-Φάση 5 charts
/// semantic up/down) και το παράδειγμα χρήσης στο app_feedback_test.
library;

import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/theme/app_colors.dart';

void main() {
  group('AppColors', () {
    // ─── Brand (§0 DESIGN) ───────────────────────────────────────────────────
    test('brandSeed = teal #00897B (§0 branding + splash pubspec)', () {
      expect(AppColors.brandSeed, const Color(0xFF00897B));
    });

    // ─── Semantic (§4-Φάση 5 charts) ─────────────────────────────────────────
    test('priceUp = κόκκινο #D32F2F (άνοδος τιμής)', () {
      expect(AppColors.priceUp, const Color(0xFFD32F2F));
    });

    test('priceDown = πράσινο #2E7D32 (πτώση τιμής)', () {
      expect(AppColors.priceDown, const Color(0xFF2E7D32));
    });

    // ─── Καθολικός έλεγχος ποιότητας ────────────────────────────────────────
    test('διακριτές τιμές — κανένα χρώμα δεν επαναλαμβάνεται', () {
      expect(
        {AppColors.brandSeed, AppColors.priceUp, AppColors.priceDown}.length,
        3,
      );
    });
  });
}