/// Unit tests για το SPoT `AppTheme` (core/theme/app_theme.dart) — §1.5.
///
/// Δεν χρειάζεται widget pump: ελέγχουμε τα ThemeData ως δεδομένα (δεν τα
/// εμφανίζουμε). Δεσμεύεται το seed (primary = ColorScheme.fromSeed(brandSeed))
/// ώστε το brand (§0) να φτάνει στο ColorScheme και στα δύο modes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/theme/app_colors.dart';
import 'package:times/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    // ─── Brightness ───────────────────────────────────────────────────────────
    test('light.colorScheme.brightness = light', () {
      expect(AppTheme.light.colorScheme.brightness, Brightness.light);
    });

    test('dark.colorScheme.brightness = dark', () {
      expect(AppTheme.dark.colorScheme.brightness, Brightness.dark);
    });

    // ─── Seed propagation (brand §0) ──────────────────────────────────────────
    test('light.primary = ColorScheme.fromSeed(brandSeed, light).primary', () {
      final expected = ColorScheme.fromSeed(
        seedColor: AppColors.brandSeed,
        brightness: Brightness.light,
      );
      expect(AppTheme.light.colorScheme.primary, expected.primary);
    });

    test('dark.primary = ColorScheme.fromSeed(brandSeed, dark).primary', () {
      final expected = ColorScheme.fromSeed(
        seedColor: AppColors.brandSeed,
        brightness: Brightness.dark,
      );
      expect(AppTheme.dark.colorScheme.primary, expected.primary);
    });

    // ─── ThemeMode default (§1.5) ─────────────────────────────────────────────
    test('defaultMode = ThemeMode.system (§1.5)', () {
      expect(AppTheme.defaultMode, ThemeMode.system);
    });
  });
}