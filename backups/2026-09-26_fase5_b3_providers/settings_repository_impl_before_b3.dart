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

  /// Το read είναι memory-read (προφορτωμένα prefs) → σύγχρονο, ορατό στο
  /// πρώτο frame (review fix 23-09: το προηγούμενο `Future.value` άφηνε 1
  /// frame με default — το «μηδέν flash» δεν ίσχυε).
  @override
  ThemeMode readThemeMode() =>
      _fromString(_prefs.getString(AppConstants.themeModeKey));

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    await _prefs.setString(AppConstants.themeModeKey, mode.name);
  }

  /// SPoT mapping (§2.3:270): γράφουμε `mode.name` και διαβάζουμε από τον
  /// ίδιο πίνακα (`asNameMap`) — καμία διπλή αναπαράσταση κωδικών (review
  /// fix 23-09). Τα Ελληνικά labels είναι ξεχωριστά στο AppStrings.
  /// Κάθε άλλη/κενή τιμή (π.χ. από παλιά έκδοση ή corrupt prefs) →
  /// `AppTheme.defaultMode` (SPoT default, όχι hardcoded system).
  static ThemeMode _fromString(String? raw) =>
      ThemeMode.values.asNameMap()[raw] ?? AppTheme.defaultMode;
}
