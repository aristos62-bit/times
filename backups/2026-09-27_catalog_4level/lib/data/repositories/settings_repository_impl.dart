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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_enums.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/home/state/home_chart_config.dart';
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

  /// Διαβάζει τη ρύθμιση γραφημάτων ΣΥΓΧΡΟΝΩΣ (memory-read, pattern
  /// `readThemeMode`): κενό → defaults · corrupt (άγνωστο period, λάθος
  /// τύποι, άκυρες ημερομηνίες) → defaults στην οικεία entry (όχι ολικό
  /// reset — οι υγιείς entries κρατιούνται).
  @override
  HomeChartConfig readHomeChartConfig() {
    final raw = _prefs.getString(AppConstants.homeChartConfigKey);
    if (raw == null || raw.isEmpty) return HomeChartConfig.defaults();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return HomeChartConfig.defaults();
      return HomeChartConfig(
        supplier: _entryFromJson(decoded['supplier'], 0),
        category: _entryFromJson(decoded['category'], 1),
        subCategory: _entryFromJson(decoded['subCategory'], 2),
        topItems: _entryFromJson(decoded['topItems'], 3),
      );
    } catch (_) {
      return HomeChartConfig.defaults();
    }
  }

  /// Αποθηκεύει τη ρύθμιση γραφημάτων (JSON στον SPoT key).
  @override
  Future<void> saveHomeChartConfig(HomeChartConfig config) async {
    await _prefs.setString(
      AppConstants.homeChartConfigKey,
      jsonEncode({
        'supplier': _entryToJson(config.supplier),
        'category': _entryToJson(config.category),
        'subCategory': _entryToJson(config.subCategory),
        'topItems': _entryToJson(config.topItems),
      }),
    );
  }

  /// SPoT mapping περιόδου (§2.1): γράφουμε `period.name`, διαβάζουμε από
  /// τον ίδιο πίνακα — άγνωστο/κενό → `PeriodType.month` (default §2.1).
  static PeriodType _periodFromString(String? raw) =>
      PeriodType.values.asNameMap()[raw] ?? PeriodType.month;

  /// Αποκωδικοποιεί μία entry — οτιδήποτε μη-αναμενόμενο → default entry
  /// (visible, order από τα `defaults()` μέσω θέσης — ο καλών περνά το
  /// fallback order ρητά, βλ. `_entryFromJson(value, fallbackOrder)`).
  static ChartEntry _entryFromJson(dynamic value, [int fallbackOrder = 0]) {
    const fallback = ChartEntry(order: 0);
    if (value is! Map) return fallback.copyWith(order: fallbackOrder);
    final visible = value['visible'];
    final order = value['order'];
    final customFrom = value['customFrom'];
    final customTo = value['customTo'];
    return ChartEntry(
      visible: visible is bool ? visible : true,
      order: order is int ? order : fallbackOrder,
      period: _periodFromString(value['period'] is String ? value['period'] as String : null),
      customFrom: customFrom is String ? DateTime.tryParse(customFrom) : null,
      customTo: customTo is String ? DateTime.tryParse(customTo) : null,
    );
  }

  /// Κωδικοποιεί μία entry (ISO strings για το custom range).
  static Map<String, dynamic> _entryToJson(ChartEntry entry) => {
        'visible': entry.visible,
        'order': entry.order,
        'period': entry.period.name,
        'customFrom': entry.customFrom?.toIso8601String(),
        'customTo': entry.customTo?.toIso8601String(),
      };
}
