/// SPoT: Theme — light/dark ThemeData από ColorScheme.fromSeed(AppColors.brandSeed).
/// Το ThemeMode προέρχεται από εδώ (§1.5: system default) και το wiring γίνεται
/// στο MaterialApp (main.dart / Φάση 4 themeModeProvider persisted §2.3).
/// NOTE(Φάση0-Βήμα4): textTheme ορίζεται σε επόμενη φάση (ref app_constants).
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Abstract SPoT namespace — μόνο static, δεν instantiate (pattern AppConstants).
abstract final class AppTheme {
  /// Προεπιλεγμένο ThemeMode (§1.5 DESIGN — system, override ανά χρήστη Φάση 4).
  static const ThemeMode defaultMode = ThemeMode.system;

  /// Light ThemeData (teal seed §0).
  static final ThemeData light = _build(Brightness.light);

  /// Dark ThemeData (teal seed §0).
  static final ThemeData dark = _build(Brightness.dark);

  // Μία υλοποίηση — μόνο το brightness διαφέρει (§1.5). Εκτελείται μία φορά
  // (static final → memoized), καμία επιβάρυνση σε rebuild/hot reload.
  static ThemeData _build(Brightness brightness) => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.brandSeed,
          brightness: brightness,
        ),
      );
}