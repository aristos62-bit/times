/// Unit tests για το DI δέντρο (database_providers.dart) — Φάση 2, Βήμα 3.
///
/// Επαληθεύει: (a) τύπο επιστροφής κάθε `xxxRepositoryProvider`, (b) ότι
/// η ίδια instance επιστρέφεται σε επαναλαμβανόμενες αναγνώσεις (singleton,
/// NON-autoDispose).
///
/// Χρήση `ProviderContainer.test()` — το container διατίθεται ΑΥΤΟΜΑΤΑ
/// (Riverpod 3.x). Το `appDatabaseProvider.overrideWithValue(...)` προσπερνά
/// το εσωτερικό `ref.onDispose(db.close)` → χειροκίνητο `addTearDown(db.close)`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/repositories/category_repository.dart';
import 'package:times/data/repositories/category_repository_impl.dart';
import 'package:times/data/repositories/item_repository.dart';
import 'package:times/data/repositories/item_repository_impl.dart';
import 'package:times/data/repositories/receipt_repository.dart';
import 'package:times/data/repositories/receipt_repository_impl.dart';
import 'package:times/data/repositories/sub_category_repository.dart';
import 'package:times/data/repositories/sub_category_repository_impl.dart';
import 'package:times/data/repositories/supplier_repository.dart';
import 'package:times/data/repositories/supplier_repository_impl.dart';
import 'package:times/data/repositories/unit_repository.dart';
import 'package:times/data/repositories/unit_repository_impl.dart';

import '../local/helpers/in_memory_db.dart';

void main() {
  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// Container με in-memory βάση · `dispose()` αυτόματο από ProviderContainer.test.
  /// Το κλείσιμο της βάσης χειροκίνητο (overrideWithValue προσπερνά onDispose).
  ProviderContainer containerWithDb() {
    final db = inMemoryDb();
    addTearDown(db.close);
    return ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  }

  // ─── DI structure + singleton tests ────────────────────────────────────────

  group('DI δέντρο — σωστός τύπος και singleton behavior', () {
    test('categoryRepositoryProvider', () {
      final container = containerWithDb();
      final repo = container.read(categoryRepositoryProvider);
      expect(repo, isA<CategoryRepository>());
      expect(repo, isA<CategoryRepositoryImpl>());
      expect(container.read(categoryRepositoryProvider), same(repo));
    });

    test('subCategoryRepositoryProvider', () {
      final container = containerWithDb();
      final repo = container.read(subCategoryRepositoryProvider);
      expect(repo, isA<SubCategoryRepository>());
      expect(repo, isA<SubCategoryRepositoryImpl>());
      expect(container.read(subCategoryRepositoryProvider), same(repo));
    });

    test('unitRepositoryProvider', () {
      final container = containerWithDb();
      final repo = container.read(unitRepositoryProvider);
      expect(repo, isA<UnitRepository>());
      expect(repo, isA<UnitRepositoryImpl>());
      expect(container.read(unitRepositoryProvider), same(repo));
    });

    test('itemRepositoryProvider', () {
      final container = containerWithDb();
      final repo = container.read(itemRepositoryProvider);
      expect(repo, isA<ItemRepository>());
      expect(repo, isA<ItemRepositoryImpl>());
      expect(container.read(itemRepositoryProvider), same(repo));
    });

    test('supplierRepositoryProvider', () {
      final container = containerWithDb();
      final repo = container.read(supplierRepositoryProvider);
      expect(repo, isA<SupplierRepository>());
      expect(repo, isA<SupplierRepositoryImpl>());
      expect(container.read(supplierRepositoryProvider), same(repo));
    });

    test('receiptRepositoryProvider (2 DAOs)', () {
      final container = containerWithDb();
      final repo = container.read(receiptRepositoryProvider);
      expect(repo, isA<ReceiptRepository>());
      expect(repo, isA<ReceiptRepositoryImpl>());
      expect(container.read(receiptRepositoryProvider), same(repo));
    });
  });
}