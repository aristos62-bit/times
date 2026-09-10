// core/theme/theme_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';

/// SPO: Theme state management — persistence μέσω SettingDao (Drift),
/// reactive μέσω Stream. Δεν χρησιμοποιεί SharedPreferences.
///
/// Το ThemeProvider κάνει subscribe σε stream από το SettingDao,
/// οπότε η αλλαγή theme είναι reactive/live και δουλεύει παντού
/// (multi-window desktop) χωρίς διπλό STORAGE.
///
/// NOTE: Αυτό είναι SPoT για το theme state. Ο SettingDao παρέχει
/// το persistence layer. Το ThemeProvider είναι ο μόνος τρόπος
/// πρόσβασης στο theme mode από τα widgets.
///
/// WIP Phase 2: το SettingDao δεν υπάρχει ακόμα — initialize()/setThemeMode()
/// κρατούν το mode μόνο στη μνήμη (χάνεται σε restart). Μην χρησιμοποιηθεί
/// για persistence μέχρι την υλοποίηση του SettingDao.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  // Stream controller για το theme mode (placeholder χωρίς SettingDao)
  final _controller = StreamController<ThemeMode>.broadcast();
  
  ThemeProvider();
  
  ThemeMode get themeMode => _themeMode;
  
  Stream<ThemeMode> get themeStream => _controller.stream;
  
  /// Ξεκινάει το listening στο stream (καλείται μια φορά στο app startup)
  Future<void> initialize() async {
    // Default: system mode
    // Μετά την υλοποίηση του SettingDao, θα διαβάζει από τη βάση
    _themeMode = ThemeMode.system;
    notifyListeners();
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    _controller.add(mode);
    notifyListeners();
    // Μετά την υλοποίηση του SettingDao:
    // await _settingsDao.setThemeMode(mode);
  }
  
  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    await setThemeMode(newMode);
  }
  
  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}
