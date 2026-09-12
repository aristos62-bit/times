## 3.11 Theme System (`core/theme/app_theme.dart`)

```dart
/// SPO: Theme definitions - single source of truth
/// Τα χρώματα έρχονται από το AppColors (§7.1) — δεν ορίζονται ξανά εδώ.
class AppTheme {
  AppTheme._();
  
  // Colors — SPoT: AppColors (core/theme/app_colors.dart)
  static const Color primaryColor = AppColors.primaryLight;
  static const Color secondaryColor = AppColors.secondaryLight;
  static const Color errorColor = AppColors.error;
  static const Color warningColor = AppColors.warning;
  
  // Light Theme
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: AppColors.surfaceLight,
      foregroundColor: AppColors.textPrimaryLight,
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      color: AppColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
  
  // Dark Theme
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: AppColors.textPrimaryDark,
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}
```

### 3.12 Theme Provider (`core/theme/theme_provider.dart`)

> **SPoT απόφαση (2026-09-09):** Η πηγή αλήθειας για το theme είναι η
> **UserSettings table** (Drift) — ΟΧΙ SharedPreferences. Το ThemeProvider
> κάνει subscribe σε Stream, οπότε η αλλαγή theme είναι reactive/live
> και δουλεύει παντού (multi-window desktop) χωρίς διπλό STORAGE.
> Το `shared_preferences` ΔΕΝ χρησιμοποιείται από το theme feature.
>
> **Υλοποίηση (2026-09-10, Phase 2 Step 4.1):** Συνδέθηκε με `SettingDao`
> (persistence στο user_settings table). Constructor injection: DI με
> `AppDatabase.test()` για testing, default `SettingDao(database)`.

```dart
/// SPO: Theme state management — persistence στο UserSettings table (Drift),
/// reactive μέσω Stream. Δεν χρησιμοποιεί SharedPreferences.
///
/// DI: SettingDao περνιέται από το constructor (για testing με AppDatabase.test()).
/// Default: SettingDao(database) — το global singleton DB.
class ThemeProvider extends ChangeNotifier {
  final SettingDao _settingsDao;
  StreamSubscription<ThemeMode?>? _sub;
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeProvider({SettingDao? settingsDao})
      : _settingsDao = settingsDao ?? SettingDao(database);
  
  ThemeMode get themeMode => _themeMode;
  Stream<ThemeMode> get themeStream => _streamController.stream;
  
  Future<void> initialize() async {
    _themeMode = await _settingsDao.getThemeMode();
    notifyListeners();
    _sub ??= _settingsDao.watchThemeMode().listen(_onDbThemeChanged);
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    await _settingsDao.setThemeMode(mode);
    _applyThemeMode(mode);
  }
  
  void _onDbThemeChanged(ThemeMode? mode) {
    if (mode == null) return;
    _applyThemeMode(mode);
  }
  
  void _applyThemeMode(ThemeMode mode) {
    final changed = mode != _themeMode;
    _themeMode = mode;
    if (changed) { _streamController.add(mode); notifyListeners(); }
  }
  
  @override
  void dispose() { _sub?.cancel(); _streamController.close(); super.dispose(); }
}
```

**SPoT Theme settings:** Η αποθήκευση/ανάγνωση γίνεται μόνο μέσω του `SettingDao`
(§4.3), στο table `user_settings`, key `'theme_mode'`, value = string με τον
δείκτη του `ThemeMode` (`'0'`=system, `'1'`=light, `'2'`=dark), type `'int'`.

> **Υλοποίηση (2026-09-10):** Πλήρως **SettingDao-backed** — το `ThemeProvider`
> διαβάζει `getThemeMode()` στο `initialize()` και γίνεται reactive μέσω
> `watchThemeMode()`. Το προηγούμενο in-memory stub (Phase 1) καταργήθηκε.

### 3.13 Extensions (`core/utils/extensions.dart`)

```dart
/// SPO: Dart extensions - reusable extensions
extension StringExtensions on String {
  /// Capitalize first letter
  String get capitalize => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  
  /// Check if string is numeric
  bool get isNumeric => double.tryParse(this) != null;
  
  /// Remove extra whitespace
  String get removeExtraWhitespace => replaceAll(RegExp(r'\s+'), ' ').trim();
}

extension DateTimeExtensions on DateTime {
  /// Check if same day
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
  
  /// Check if today
  bool get isToday => isSameDay(DateTime.now());
  
  /// Check if yesterday
  bool get isYesterday => isSameDay(DateTime.now().subtract(const Duration(days: 1)));
  
  /// Get start of day
  DateTime get startOfDay => DateTime(year, month, day);
  
  /// Get end of day
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
  
  /// Get start of month
  DateTime get startOfMonth => DateTime(year, month, 1);
  
  /// Get end of month
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59);
}

extension DoubleExtensions on double {
  /// Format as currency
  String toCurrency() => CurrencyFormatter.format(this);
  
  /// Format with 2 decimal places
  String toFixed2() => toStringAsFixed(2);
  
  /// Check if approximately equal
  bool approximates(double other, {double epsilon = 0.001}) =>
      (this - other).abs() < epsilon;
}
```

---

> **Σημείωση (12/09/2026):** Το `03_core_layer.md` χωρίστηκε σε 3 αρχεία
> (κανόνας ≤500 γρ.): `03_core_layer.md` (§3.1–3.7),
> `03_utilities_widgets.md` (§3.8–3.10), `03_theme_extensions.md` (§3.11–3.13).