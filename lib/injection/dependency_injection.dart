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
import '../features/receipt/data/repositories/receipt_repository_impl.dart';
import '../features/receipt/domain/repositories/receipt_repository.dart';
import '../features/supplier/data/repositories/supplier_repository_impl.dart';
import '../features/supplier/domain/repositories/supplier_repository.dart';

/// SPO: Service locator — κεντρική εγγραφή/επίλυση του object graph.
///
/// Εγγράφει ΜΟΝΟ intances που παράγονται από την υπάρχουσα constructor
/// injection (Route A-Συνεπές): `AppDatabase` → 7 DAOs → 5 repositories →
/// `ThemeProvider`. Κανένα widget δεν διαβάζει απευθείας από εδώ (χρησιμοποιεί
/// constructor injection όπως τώρα) — η lookup γίνεται στο app startup (`main()`)
/// και στα tests.
///
/// Χωρίς εξωτερικό DI framework (δεν υπάρχει στο pubspec). Κάθε εξάρτηση έχει
/// το δικό της nullable static πεδίο + ρητό typed getter (αντί για γενικό
/// `Map<Type, dynamic>` + `get<T>()`) — έτσι ένα ξεχασμένο registration
/// πιάνεται από τον compiler (non-nullable return type) αντί να σκάει runtime
/// βαθιά μέσα σε ένα bloc. Guard flag έναντι duplicate `configure()`,
/// `reset()` για test isolation (κλείνει και την DB — reuse
/// `AppDatabase.close()`).
class DependencyInjection {
  DependencyInjection._(); // coverage:ignore-line

  static core_db.AppDatabase? _db;
  static bool _configured = false;

  static SettingDao? _settingDao;
  static CategoryDao? _categoryDao;
  static SupplierDao? _supplierDao;
  static ItemDao? _itemDao;
  static TagDao? _tagDao;
  static BudgetDao? _budgetDao;
  static ReceiptDao? _receiptDao;

  static ItemRepository? _itemRepository;
  static CategoryRepository? _categoryRepository;
  static SupplierRepository? _supplierRepository;
  static BudgetRepository? _budgetRepository;
  static ReceiptRepository? _receiptRepository;

  static ThemeProvider? _themeProvider;

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

  /// Εγγράφει όλους τους singletons (ένα graph, μία βάση). Η σειρά είναι
  /// η ίδια εξαρτησιακή σειρά με πριν: DAOs → repositories → ThemeProvider.
  static Future<void> _register(core_db.AppDatabase db) async {
    // DATA (DAOs — όλα από την ίδια db instance)
    _settingDao = SettingDao(db);
    _categoryDao = CategoryDao(db);
    _supplierDao = SupplierDao(db);
    _itemDao = ItemDao(db);
    _tagDao = TagDao(db);
    _budgetDao = BudgetDao(db);
    _receiptDao = ReceiptDao(
      db,
      settingDao: _settingDao!,
      itemDao: _itemDao!,
      tagDao: _tagDao!,
    );

    // REPOSITORIES (pure delegates — Route A-Συνεπές)
    _itemRepository = ItemRepositoryImpl(_itemDao!);
    _categoryRepository = CategoryRepositoryImpl(_categoryDao!);
    _supplierRepository = SupplierRepositoryImpl(_supplierDao!);
    _budgetRepository = BudgetRepositoryImpl(_budgetDao!);
    _receiptRepository = ReceiptRepositoryImpl(_receiptDao!);

    // PRESENTATION-SUPPORT (ThemeProvider — reuse υπάρχοντα constructor)
    _themeProvider = ThemeProvider(settingsDao: _settingDao!);
  }

  /// Κοινός βοηθός: throw `StateError` + log αν δεν έχει γίνει `configure()`.
  /// Χρησιμοποιείται από όλα τα typed getters παρακάτω (SPoT για το error).
  static T _require<T>(T? value, String name) {
    if (value == null) {
      AppLogger.error('DependencyInjection.$name: not registered');
      throw StateError('Η εξάρτηση $name δεν έχει καταχωρηθεί (configure πρώτα).');
    }
    return value;
  }

  // ---------- Typed getters (αντικαθιστούν το γενικό get<T>()) ----------

  static core_db.AppDatabase get database => _require(_db, 'AppDatabase');

  static SettingDao get settingDao => _require(_settingDao, 'SettingDao');
  static CategoryDao get categoryDao => _require(_categoryDao, 'CategoryDao');
  static SupplierDao get supplierDao => _require(_supplierDao, 'SupplierDao');
  static ItemDao get itemDao => _require(_itemDao, 'ItemDao');
  static TagDao get tagDao => _require(_tagDao, 'TagDao');
  static BudgetDao get budgetDao => _require(_budgetDao, 'BudgetDao');
  static ReceiptDao get receiptDao => _require(_receiptDao, 'ReceiptDao');

  static ItemRepository get itemRepository =>
      _require(_itemRepository, 'ItemRepository');
  static CategoryRepository get categoryRepository =>
      _require(_categoryRepository, 'CategoryRepository');
  static SupplierRepository get supplierRepository =>
      _require(_supplierRepository, 'SupplierRepository');
  static BudgetRepository get budgetRepository =>
      _require(_budgetRepository, 'BudgetRepository');
  static ReceiptRepository get receiptRepository =>
      _require(_receiptRepository, 'ReceiptRepository');

  static ThemeProvider get themeProvider =>
      _require(_themeProvider, 'ThemeProvider');

  /// Test isolation: κλείνει την DB (reuse `AppDatabase.close()`) και
  /// καθαρίζει όλα τα singletons. Επόμενο `configure()` ξεκινά καθαρό graph.
  static Future<void> reset() async {
    await _db?.close();
    _db = null;
    _settingDao = null;
    _categoryDao = null;
    _supplierDao = null;
    _itemDao = null;
    _tagDao = null;
    _budgetDao = null;
    _receiptDao = null;
    _itemRepository = null;
    _categoryRepository = null;
    _supplierRepository = null;
    _budgetRepository = null;
    _receiptRepository = null;
    _themeProvider = null;
    _configured = false;
    AppLogger.info('DI reset');
  }

  /// True αν έχει τρέξει επιτυχώς ένα `configure()`.
  static bool get isConfigured => _configured;
}