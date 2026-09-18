/// StreamProviders πάνω στα repositories — Φάση 2, Βήμα 3 (DESIGN §4, §2.0.1).
///
/// Εκθέτουν `AsyncValue<List<T>>` στο presentation layer (§2.5): το UI
/// κάνει μόνο `ref.watch(xxxStreamProvider)` και το AsyncValueView (§2.4,
/// Φάση 3) διαχειρίζεται data/loading/error. Τα σφάλματα είναι ήδη
/// `AppException` (repository mapping, Βήμα 2) → εδώ ΔΕΝ προσθέτουμε logging.
///
/// Όλοι NON-autoDispose: τα streams ζουν όσο η εφαρμογή (χωρίς churn).
/// Σύμβαση ονομασίας §2.0.2: `xxxStreamProvider`. Τα δύο παραμετρικά
/// (ανά category / ανά receipt) είναι `.family`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/greek_text_normalizer.dart';
import '../local/app_database.dart';
import 'database_providers.dart';

/// Όλες οι κατηγορίες, αλφαβητικά · `AsyncValue<List<Category>>`.
final categoryStreamProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(categoryRepositoryProvider).watchAll(),
);

/// Όλες οι υποκατηγορίες, αλφαβητικά.
final subCategoriesStreamProvider = StreamProvider<List<SubCategory>>(
  (ref) => ref.watch(subCategoryRepositoryProvider).watchAll(),
);

/// Υποκατηγορίες μιας κατηγορίας — `.family` παραμετροποιημένο ανά [categoryId].
final subCategoriesByCategoryProvider =
    StreamProvider.family<List<SubCategory>, int>(
  (ref, categoryId) =>
      ref.watch(subCategoryRepositoryProvider).watchByCategoryId(categoryId),
);

/// Όλες οι μονάδες μέτρησης, αλφαβητικά.
final unitsStreamProvider = StreamProvider<List<Unit>>(
  (ref) => ref.watch(unitRepositoryProvider).watchAll(),
);

/// Όλα τα είδη, με σειρά normalizedName.
final itemsStreamProvider = StreamProvider<List<Item>>(
  (ref) => ref.watch(itemRepositoryProvider).watchAll(),
);

/// Όλοι οι προμηθευτές, με σειρά normalizedName.
final suppliersStreamProvider = StreamProvider<List<Supplier>>(
  (ref) => ref.watch(supplierRepositoryProvider).watchAll(),
);

/// LIVE αναζήτηση προμηθευτών για το SearchableDropdownField (§2.4 ·
/// Φάση 3 Βήμα 3). `.family` παραμετροποιημένο ανά [query].
///
/// ΣΥΜΒΑΣΗ: το key είναι το RAW (μη-κανονικοποιημένο) κείμενο που
/// πληκτρολόγησε ο χρήστης — η κανονικοποίηση (GreekTextNormalizer) και
/// το trim γίνονται ΕΔΩ εσωτερικά. ΜΗΝ διαβιβάζεις ήδη-κανονικοποιημένο
/// string έξω από τον provider· μόνο το `when` του AsyncValue καταναλώνει.
/// Κενό query → κενή λίστα χωρίς DB access (short-circuit του repository),
/// συνεπές με τον κανόνα «η βάση δεν ανοίγει εκτός user action».
final supplierSearchProvider = StreamProvider.family<List<Supplier>, String>(
  (ref, query) {
    final normalized = GreekTextNormalizer.normalize(query.trim());
    return ref.watch(supplierRepositoryProvider).searchByNormalizedName(
          normalized,
          limit: AppConstants.searchResultsLimit,
        );
  },
);

/// Όλες οι αποδείξεις, νεότερες πρώτα.
final receiptsStreamProvider = StreamProvider<List<Receipt>>(
  (ref) => ref.watch(receiptRepositoryProvider).watchAll(),
);

/// Γραμμές απόδειξης — `.family` παραμετροποιημένο ανά [receiptId].
final receiptLinesStreamProvider =
    StreamProvider.family<List<ReceiptLine>, int>(
  (ref, receiptId) =>
      ref.watch(receiptRepositoryProvider).watchLines(receiptId),
);