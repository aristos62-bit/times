/// Abstract repository για τις ρυθμίσεις της εφαρμογής (SharedPreferences) —
/// Φάση 4, Βήμα 1 (DESIGN §2.3).
///
/// SPoT: Μοναδικό σημείο πρόσβασης στις τοπικές ρυθμίσεις. Όπως και τα
/// υπόλοιπα repositories (§1.2), κανένα UI/controller δεν καλεί
/// SharedPreferences απευθείας — περνάει πάντα από εδώ → provider → widget.
///
/// API (Q3, κλειδωμένο): typed `ThemeMode` και στις δύο κατευθύνσεις — το
/// mapping string↔enum ζει ΜΟΝΟ στο implementation.
library;

import 'package:flutter/material.dart';

/// Abstract interface — υλοποιείται πάνω σε SharedPreferences.
abstract interface class SettingsRepository {
  /// Διαβάζει το αποθηκευμένο ThemeMode· κενό/άγνωστο → default
  /// (AppTheme.defaultMode, §1.5/§2.3).
  Future<ThemeMode> loadThemeMode();

  /// Αποθηκεύει το ThemeMode στον SPoT key `AppConstants.themeModeKey`.
  Future<void> saveThemeMode(ThemeMode mode);
}