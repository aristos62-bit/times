/// Υλοποίηση `SettingsRepository` πάνω σε SharedPreferences — Φάση 4, Βήμα 1.
///
/// Λεπτό repository layer (DESIGN §1.2, ίδιο πρότυπο με τα repos της
/// Φάσης 2): ΚΑΝΕΝΑ business logic — μόνο το mapping string↔ThemeMode και ο
/// SPoT key/default. Το instance του SharedPreferences έρχεται έτοιμο
/// (injection, ίδιο πρότυπο με `CategoryRepositoryImpl(dao)`): προφορτώνεται
/// στο `main()` (Q4 — μηδέν flash, κανένα platform channel στο build).
///
/// Χωρίς logging εδώ: το logging των αλλαγών θέματος γίνεται στον
/// `ThemeModeController` (settings_providers.dart, tag UI) — πρότυπο των
/// controllers του codebase (receipt_form_controller).
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import 'settings_repository.dart';

/// Σκέτο mapping SharedPreferences ↔ ThemeMode με SPoT key/default.
final class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  /// Το load είναι memory-read (προφορτωμένα prefs) → ολοκληρώνεται σε
  /// microtask πριν το πρώτο frame — κανένα ορατό «φλας» στην εκκίνηση.
  @override
  Future<ThemeMode> loadThemeMode() =>
      Future.value(_fromString(_prefs.getString(AppConstants.themeModeKey)));

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    await _prefs.setString(AppConstants.themeModeKey, mode.name);
  }

  /// SPoT mapping (§2.3:270): αποθηκεύονται οι σταθεροί κωδικοί του enum
  /// (`mode.name`: 'light'/'dark'/'system') — τα Ελληνικά labels είναι ξεχωριστά
  /// στο AppStrings. Κάθε άλλη/κενή τιμή (π.χ. από παλιά έκδοση ή corrupt
  /// prefs) → `AppTheme.defaultMode` (SPoT default, όχι hardcoded system) —
  /// το billing της αποτυχίας γίνεται στον controller (log, tag UI).
  static ThemeMode _fromString(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => AppTheme.defaultMode,
      };
}