/// Abstract repository για τις ρυθμίσεις της εφαρμογής (SharedPreferences) —
/// Φάση 4, Βήμα 1 (DESIGN §2.3).
///
/// SPoT: Μοναδικό σημείο πρόσβασης στις τοπικές ρυθμίσεις. Όπως και τα
/// υπόλοιπα repositories (§1.2), κανένα UI/controller δεν καλεί
/// SharedPreferences απευθείας — περνάει πάντα από εδώ → provider → widget.
///
/// API (Q3 — αναθεωρήθηκε με ΟΚ χρήστη 23-09, review fix «μηδέν flash»):
/// σύγχρονο `ThemeMode` read (τα prefs είναι memory-mapped στη μνήμη) +
/// async save. Το mapping string↔enum ζει ΜΟΝΟ στο implementation.
library;

import 'package:flutter/material.dart';

import '../../presentation/home/state/home_chart_config.dart';

/// Abstract interface — υλοποιείται πάνω σε SharedPreferences.
abstract interface class SettingsRepository {
  /// Διαβάζει το αποθηκευμένο ThemeMode ΣΥΓΧΡΟΝΩΣ· κενό/άγνωστο → default
  /// (AppTheme.defaultMode, §1.5/§2.3). Ορατό στο πρώτο frame (zero flash).
  ThemeMode readThemeMode();

  /// Αποθηκεύει το ThemeMode στον SPoT key `AppConstants.themeModeKey`.
  Future<void> saveThemeMode(ThemeMode mode);

  /// Διαβάζει τη ρύθμιση γραφημάτων ΣΥΓΧΡΟΝΩΣ (§2.1 · Φάση 5 Βήμα 3) —
  /// κενό/corrupt → `HomeChartConfig.defaults()` (pattern `readThemeMode`).
  HomeChartConfig readHomeChartConfig();

  /// Αποθηκεύει τη ρύθμιση γραφημάτων στον SPoT key
  /// `AppConstants.homeChartConfigKey` (JSON — mapping ΜΟΝΟ στο impl).
  Future<void> saveHomeChartConfig(HomeChartConfig config);
}
