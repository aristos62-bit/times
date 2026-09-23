/// Riverpod providers των ρυθμίσεων — Φάση 4, Βήμα 1 (DESIGN §2.3).
///
/// Αλυσίδα: `SharedPreferences → SettingsRepository → themeModeProvider`.
/// Όλα NON-autoDispose (singletons, ζωή εφαρμογής — πρότυπο database_providers).
///
/// Το `SharedPreferences` ΔΙΝΕΤΑΙ ΠΑΝΤΑ με override:
///   * `main()` → `await SharedPreferences.getInstance()` ΠΡΙΝ το `runApp`
///     (Q4: μηδέν flash — το θέμα είναι γνωστό πριν το πρώτο frame) και
///     `sharedPreferencesProvider.overrideWithValue(prefs)`.
///   * tests → `SharedPreferences.setMockInitialValues({})` + `getInstance()`
///     στο setUp, ώστε ο provider να είναι πάντα injected (pattern
///     `appDatabaseProvider.overrideWithValue(db)` στα database tests).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/logging/app_logger.dart';
import '../../core/theme/app_theme.dart';
import '../repositories/settings_repository.dart';
import '../repositories/settings_repository_impl.dart';

/// Το προφορτωμένο `SharedPreferences` — σύγχρονο (όχι FutureProvider):
/// ο `settingsRepositoryProvider` μένει `Provider` singleton (§2.0.2
/// «xxxRepositoryProvider») και τα prefs είναι ήδη στη μνήμη. Χωρίς override
/// ρίχνει σκόπιμα UnimplementedError (μην ξεχαστεί injection σε test/main).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'Δώσε sharedPreferencesProvider με overrideWithValue (main ή test)',
  ),
);

/// Singleton `SettingsRepository` (DESIGN §2.5 data flow).
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.watch(sharedPreferencesProvider)),
);

/// Το επιλεγμένο `ThemeMode` (DESIGN §2.3:270) — read στο main.dart
/// (`MaterialApp.router.themeMode`) και στον selector της SettingsPage.
/// Μη autoDispose: με το IndexedStack η σελίδα χτίζεται στο launch → το
/// persisted mode φορτώνεται ΜΙΑ φορά (καμία επαναφόρτωση σε tab switch).
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// Controller του θέματος — **plain Notifier** (§2.0.1· κλειδωμένη απόφαση Β0):
/// το state είναι σύγχρονο (`ThemeMode` επιστρέφεται άμεσα, κανένα loading
/// flash)· το read είναι memory-read (Q4) → το persisted mode είναι ορατό στο
/// ΠΡΩΤΟ frame (review fix 23-09: το προηγούμενο async load άφηνε 1 frame με
/// default). Μόνο το save είναι async (unawaited, δική του μεταχείριση
/// σφαλμάτων). Equality gate + logging (πρότυπο `ReceiptFormController`).
class ThemeModeController extends Notifier<ThemeMode> {
  /// Σύγχρονο read (Q3 αναθεωρήθηκε με ΟΚ χρήστη 23-09): τα prefs είναι
  /// προφορτωμένα στη μνήμη (Q4) → το persisted mode επιστρέφεται άμεσα,
  /// ορατό στο πρώτο frame (αληθινό zero flash — χωρίς async κενό δεν
  /// υπάρχει race, ο `_userChanged` guard δεν χρειάζεται πια). Σφάλμα →
  /// default + log (κανένα crash). Default = `AppTheme.defaultMode`
  /// (system, SPoT §1.5).
  @override
  ThemeMode build() {
    try {
      return ref.read(settingsRepositoryProvider).readThemeMode();
    } catch (e, s) {
      AppLogger.error(LogTag.ui, 'Ανάγνωση θέματος απέτυχε — χρήση default', e, s);
      return AppTheme.defaultMode;
    }
  }

  /// Ορίζει το θέμα από τον χρήστη (selector). Equality gate: ίδιο mode →
  /// χωρίς re-notify και χωρίς περιττό save. Save αποτυχία → το state μένει
  /// στη μνήμη (η επιλογή ισχύει στην τρέχουσα συνεδρία· μόνο log — κανένα
  /// snackbar, κανένα νέο AppErrors· απόφαση Β1).
  void setMode(ThemeMode mode) {
    if (mode == state) return;
    state = mode;
    AppLogger.info(LogTag.ui, 'Θέμα: ${mode.name}');
    unawaited(_save(mode));
  }

  Future<void> _save(ThemeMode mode) async {
    if (!ref.mounted) return;
    try {
      await ref.read(settingsRepositoryProvider).saveThemeMode(mode);
    } catch (e, s) {
      AppLogger.error(LogTag.ui, 'Αποθήκευση θέματος απέτυχε', e, s);
    }
  }
}
