// lib/injection/dependency_injection.dart
import '../core/database/app_database.dart' as core_db;
import '../core/database/daos/daos.dart';
import '../core/debug/app_logger.dart';
import '../core/theme/theme_provider.dart';
import '../features/budget/data/repositories/budget_repository_impl.dart';
import '../features/budget/domain/repositories/budget_repository.dart';
import '../features/category/data/repositories/category_repository_impl.dart';
import '../features/category/domain/repositories/category_repository.dart';
import '../features/item/data/repositories/item_repository_impl.dart';
import '../features/item/domain/repositories/item_repository.dart';
import '../features/supplier/data/repositories/supplier_repository_impl.dart';
import '../features/supplier/domain/repositories/supplier_repository.dart';

/// SPO: Service locator — κεντρική εγγραφή/επίλυση του object graph.
///
/// Εγγράφει ΜΟΝΟ intances που παράγονται από την υπάρχουσα constructor
/// injection (Route A-Συνεπές): `AppDatabase` → 6 DAOs → 4 repositories →
/// `ThemeProvider`. Κανένα widget δεν διαβάζει απευθείας από εδώ (χρησιμοποιεί
/// constructor injection όπως τώρα) — η lookup γίνεται στο app startup (`main()`)
/// και στα tests.
///
/// Χωρίς εξωτερικό DI framework (δεν υπάρχει στο pubspec) — μικρό registry
/// `<Type, instance>`. Guard flag έναντι duplicate `configure()`, `reset()` για
/// test isolation (κλείνει και την DB — reuse `AppDatabase.close()`).
class DependencyInjection {
  DependencyInjection._(); // coverage:ignore-line

  static core_db.AppDatabase? _db;
  static bool _configured = false;
  static final _singletons = <Type, dynamic>{};

  /// App startup / test setup. Καλείται ΜΟΝΟ μια φορά ανά εφαρμογή.
  ///
  /// `database`: αν παραλειφθεί, εγγράφεται το global `database` (reuse —
  /// κανένα νέο `AppDatabase()`). Τα tests περνούν `AppDatabase.test()`.
  /// Δεν γίνεται κανένα ασύγχρονο DB-read εδώ (το `ThemeProvider.initialize()`
  /// το καλεί ο consumer). Λάθος: double `configure()` → no-op + log.
  static Future<void> configure({core_db.AppDatabase? database}) async {
    if (_configured) {
      AppLogger.error('DependencyInjection.configure: already configured');
      return;
    }
    final db = database ?? core_db.database;
    await _register(db);
    _db = db;
    _configured = true;
    AppLogger.info('DI configured: ${db.runtimeType}');
  }

  /// Εγγράφει όλους τους singletons (ένα graph, μία βάση).
  static Future<void> _register(core_db.AppDatabase db) async {
    // APP
    _singletons[core_db.AppDatabase] = db;

    // DATA (DAOs — όλα από την ίδια db instance)
    _singletons[SettingDao] = SettingDao(db);
    _singletons[CategoryDao] = CategoryDao(db);
    _singletons[SupplierDao] = SupplierDao(db);
    _singletons[ItemDao] = ItemDao(db);
    _singletons[TagDao] = TagDao(db);
    _singletons[BudgetDao] = BudgetDao(db);

    // REPOSITORIES (pure delegates — Route A-Συνεπές)
    _singletons[ItemRepository] =
        ItemRepositoryImpl(_singletons[ItemDao] as ItemDao);
    _singletons[CategoryRepository] =
        CategoryRepositoryImpl(_singletons[CategoryDao] as CategoryDao);
    _singletons[SupplierRepository] =
        SupplierRepositoryImpl(_singletons[SupplierDao] as SupplierDao);
    _singletons[BudgetRepository] =
        BudgetRepositoryImpl(_singletons[BudgetDao] as BudgetDao);

    // PRESENTATION-SUPPORT (ThemeProvider — reuse υπάρχοντα constructor)
    _singletons[ThemeProvider] = ThemeProvider(
      settingsDao: _singletons[SettingDao] as SettingDao,
    );
  }

  /// Επίλυση εξάρτησης. Αποτυχία (μη εγγεγραμμένος ή πριν το configure):
  /// `StateError` + log — fast-fail στα tests.
  static T get<T>() {
    final instance = _singletons[T];
    if (instance == null) {
      AppLogger.error('DependencyInjection.get<$T>: not registered');
      throw StateError('Η εξάρτηση $T δεν έχει καταχωρηθεί (configure πρώτα).');
    }
    return instance as T;
  }

  /// Test isolation: κλείνει την DB (reuse `AppDatabase.close()`) και
  /// καθαρίζει όλα τα singletons. Επόμενο `configure()` ξεκινά καθαρό graph.
  static Future<void> reset() async {
    await _db?.close();
    _singletons.clear();
    _db = null;
    _configured = false;
    AppLogger.info('DI reset');
  }

  /// True αν έχει τρέξει επιτυχώς ένα `configure()`.
  static bool get isConfigured => _configured;
}