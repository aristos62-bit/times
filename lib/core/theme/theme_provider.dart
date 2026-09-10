// core/theme/theme_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../database/daos/daos.dart';

/// SPO: Theme state management — persistence μέσω SettingDao (Drift),
/// reactive μέσω Stream. Δεν χρησιμοποιεί SharedPreferences.
///
/// Το ThemeProvider κάνει subscribe σε stream από το SettingDao,
/// οπότε η αλλαγή theme είναι reactive/live και δουλεύει παντού
/// (multi-window desktop) χωρίς διπλό STORAGE.
///
/// NOTE: Αυτό είναι SPoT για το theme state. Ο SettingDao παρέχει
/// το persistence layer (Phase 2 Step 3 — user_settings table).
/// Το ThemeProvider είναι ο μόνος τρόπος πρόσβασης στο theme mode
/// από τα widgets.
///
/// DI: ο SettingDao περνιέται από το constructor (για testing με
/// AppDatabase.test()). Default: SettingDao(database) — το global
/// singleton DB. Δεν χρησιμοποιείται Repository pattern για settings
/// (απόφαση Phase 2 Step 4: συνειδητά εκτός scope).
class ThemeProvider extends ChangeNotifier {
  /// DAO για theme persistence (default: global singleton database).
  final SettingDao _settingsDao;
  final _streamController = StreamController<ThemeMode>.broadcast();

  StreamSubscription<ThemeMode?>? _sub;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider({SettingDao? settingsDao})
      : _settingsDao = settingsDao ?? SettingDao(database);

  ThemeMode get themeMode => _themeMode;

  Stream<ThemeMode> get themeStream => _streamController.stream;

  /// Ξεκινάει το listening στο stream (καλείται μια φορά στο app startup).
  /// Διαβάζει το τελευταίο αποθηκευμένο mode από τη βάση.
  Future<void> initialize() async {
    _themeMode = await _settingsDao.getThemeMode();
    notifyListeners();

    // Reactive: κάθε αλλαγή στη βάση (ακόμα και από άλλο window) ενημερώνει.
    // Το `watchThemeMode` είναι broadcast-φιλικό — ένα μόνο subscription.
    _sub ??= _settingsDao.watchThemeMode().listen(_onDbThemeChanged);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    // Εγγραφή στη βάση (SPoT persistence) — το reactive stream του
    // SettingDao καλεί τον _onDbThemeChanged έτσι κι αλλιώς.
    await _settingsDao.setThemeMode(mode);
    _applyThemeMode(mode);
  }

  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    await setThemeMode(newMode);
  }

  /// Ενημερώνει το state + stream + listeners (idempotent — αν το stream
  /// του SettingDao φτάσει πρώτο, το apply είναι no-op για το state).
  void _applyThemeMode(ThemeMode mode) {
    final changed = mode != _themeMode;
    _themeMode = mode;
    if (changed) {
      _streamController.add(mode);
      notifyListeners();
    }
  }

  /// Reflects updates από το reactive stream του SettingDao στο state.
  void _onDbThemeChanged(ThemeMode? mode) {
    if (mode == null) return;
    _applyThemeMode(mode);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _streamController.close();
    super.dispose();
  }
}