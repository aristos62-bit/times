import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'setting_dao.g.dart';

/// SPO: User Settings Data Access Object
///
/// SPoT αποθήκευσης ρυθμίσεων (π.χ. theme). Η UserSettings table είναι
/// η ΜΟΝΗ πηγή αλήθειας — κανένα SharedPreferences για theme.
@DriftAccessor(tables: [UserSettings])
class SettingDao extends DatabaseAccessor<AppDatabase>
    with _$SettingDaoMixin {
  SettingDao(super.db);

  static const themeKey = 'theme_mode';

  /// Διάβασμα ρύθμισης (string, nullable)
  Future<String?> getSetting(String key) async {
    final row = await (select(userSettings)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  /// Εγγραφή ρύθμισης (insertOrReplace)
  Future<void> setSetting(String key, String value,
      {String type = 'string'}) async {
    await into(userSettings).insert(
      UserSettingsCompanion.insert(
        key: key,
        value: Value(value),
        type: Value(type),
        updatedAt: DateTime.now(),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Παρακολούθηση ρύθμισης (reactive)
  Stream<String?> watchSetting(String key) {
    return (select(userSettings)
          ..where((s) => s.key.equals(key)))
        .watchSingleOrNull()
        .map((row) => row?.value);
  }

  // ---------- Theme helpers ----------

  /// Watch theme mode (reactive) — null/άκυρο → system
  Stream<ThemeMode?> watchThemeMode() =>
      watchSetting(themeKey).map(_parseThemeMode);

  /// Φόρτωση theme mode (single-shot για το startup)
  Future<ThemeMode> getThemeMode() async {
    final value = await getSetting(themeKey);
    return _parseThemeMode(value) ?? ThemeMode.system;
  }

  /// Αποθήκευση theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    await setSetting(themeKey, '${mode.index}', type: 'int');
  }

  /// '0'=system, '1'=light, '2'=dark
  ThemeMode? _parseThemeMode(String? value) {
    if (value == null) return null;
    final index = int.tryParse(value);
    if (index == null || index < 0 || index >= ThemeMode.values.length) {
      return null;
    }
    return ThemeMode.values[index];
  }
}
