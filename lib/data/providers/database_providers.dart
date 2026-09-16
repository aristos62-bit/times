/// Riverpod DI δέντρο της εφαρμογής — Φάση 2, Βήμα 3 (DESIGN §4, §2.5).
///
/// Αλυσίδα: `AppDatabase → DAOs → Repositories`. Οι controllers/pages
/// (Φάση 3+) καταναλώνουν repositories ΜΟΝΟ μέσω αυτών των providers —
/// κανένα UI δεν καλεί DAO απευθείας (DESIGN §1.2).
///
/// Όλοι οι providers είναι NON-autoDispose (singletons, ζωή εφαρμογής):
/// η βάση κλείνει μόνο μία φορά, μέσω `ref.onDispose` στο
/// [appDatabaseProvider]. Σε override στα tests (overrideWithValue) το
/// `onDispose` προσπερνάται εσκεμμένα — το κλείσιμο ανατίθεται στο test.
///
/// Σύμβαση ονομασίας §2.0.2: `xxxRepositoryProvider`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/app_database.dart';
import '../local/daos/category_dao.dart';
import '../local/daos/item_dao.dart';
import '../local/daos/receipt_dao.dart';
import '../local/daos/receipt_line_dao.dart';
import '../local/daos/sub_category_dao.dart';
import '../local/daos/supplier_dao.dart';
import '../local/daos/unit_dao.dart';
import '../repositories/category_repository.dart';
import '../repositories/category_repository_impl.dart';
import '../repositories/item_repository.dart';
import '../repositories/item_repository_impl.dart';
import '../repositories/receipt_repository.dart';
import '../repositories/receipt_repository_impl.dart';
import '../repositories/sub_category_repository.dart';
import '../repositories/sub_category_repository_impl.dart';
import '../repositories/supplier_repository.dart';
import '../repositories/supplier_repository_impl.dart';
import '../repositories/unit_repository.dart';
import '../repositories/unit_repository_impl.dart';

/// Το `AppDatabase` (η μία βάση της εφαρμογής) — Drift SPoT σύνδεσης (§3).
/// Zει όσο η εφαρμογή· το `onDispose(db.close)` κλείνει τη βάση στο τέλος.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Singleton `CategoryRepository` (§2.5 data flow).
final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepositoryImpl(CategoryDao(ref.watch(appDatabaseProvider))),
);

/// Singleton `SubCategoryRepository`.
final subCategoryRepositoryProvider = Provider<SubCategoryRepository>(
  (ref) =>
      SubCategoryRepositoryImpl(SubCategoryDao(ref.watch(appDatabaseProvider))),
);

/// Singleton `UnitRepository`.
final unitRepositoryProvider = Provider<UnitRepository>(
  (ref) => UnitRepositoryImpl(UnitDao(ref.watch(appDatabaseProvider))),
);

/// Singleton `ItemRepository`.
final itemRepositoryProvider = Provider<ItemRepository>(
  (ref) => ItemRepositoryImpl(ItemDao(ref.watch(appDatabaseProvider))),
);

/// Singleton `SupplierRepository`.
final supplierRepositoryProvider = Provider<SupplierRepository>(
  (ref) => SupplierRepositoryImpl(SupplierDao(ref.watch(appDatabaseProvider))),
);

/// Singleton `ReceiptRepository` — χρειάζεται 2 DAOs (κεφαλίδα + γραμμές),
/// ακριβώς όπως το `ReceiptRepositoryImpl` (DESIGN §4).
final receiptRepositoryProvider = Provider<ReceiptRepository>(
  (ref) => ReceiptRepositoryImpl(
    ReceiptDao(ref.watch(appDatabaseProvider)),
    ReceiptLineDao(ref.watch(appDatabaseProvider)),
  ),
);