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
import '../models/receipt_summary.dart';
import 'database_providers.dart';

/// Όλες οι κατηγορίες, αλφαβητικά · `AsyncValue<List<Category>>`.
final categoryStreamProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(categoryRepositoryProvider).watchAll(),
);

/// LIVE αναζήτηση κατηγοριών για το new-item dialog (§2.4 · Φάση 3 Βήμα 4).
/// `.family` παραμετροποιημένο ανά [query]. In-memory filter πάνω στο
/// `watchAll()` του repository — ΚΑΝΕΝΑ νέο DB query (το upstream stream
/// είναι ήδη φορτωμένο). Κενό query → `[]` (Stream.value: εκπέμπει άμεσα
/// το empty χωρίς DB access — όχι Stream.empty, θα έμενε loading για πάντα).
/// Non-autoDispose.
final categorySearchProvider = StreamProvider.family<List<Category>, String>(
  (ref, query) {
    final normalized = GreekTextNormalizer.normalize(query.trim());
    if (normalized.isEmpty) return Stream.value(const []);
    return ref.watch(categoryRepositoryProvider).watchAll().map(
          (categories) => categories
              .where(
                (c) =>
                    GreekTextNormalizer.normalize(c.name).contains(normalized),
              )
              .toList(),
        );
  },
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

/// LIVE αναζήτηση υποκατηγοριών για το new-item dialog (§2.4 · Φάση 3 Βήμα 4).
/// `.family` παραμετροποιημένο ανά `({int categoryId, String query})`.
/// In-memory filter πάνω σε `watchByCategoryId` — χωρίς νέα DB query.
/// Κενό query → `[]` (Stream.value: εκπέμπει άμεσα — όχι Stream.empty).
/// Non-autoDispose.
final subCategorySearchProvider =
    StreamProvider.family<List<SubCategory>, ({int categoryId, String query})>(
  (ref, params) {
    final normalized = GreekTextNormalizer.normalize(params.query.trim());
    if (normalized.isEmpty) return Stream.value(const []);
    return ref
        .watch(subCategoryRepositoryProvider)
        .watchByCategoryId(params.categoryId)
        .map(
          (subs) => subs
              .where(
                (s) =>
                    GreekTextNormalizer.normalize(s.name).contains(normalized),
              )
              .toList(),
        );
  },
);

/// Όλες οι μονάδες μέτρησης, αλφαβητικά.
final unitsStreamProvider = StreamProvider<List<Unit>>(
  (ref) => ref.watch(unitRepositoryProvider).watchAll(),
);

/// LIVE αναζήτηση μονάδων για το Unit dropdown (Φάση 3 Βήμα 5). `.family`
/// παραμετροποιημένο ανά [query]. Match (κανονικοποιημένο, `contains`) στο
/// ΟΝΟΜΑ Ή στη ΣΥΝΤΟΜΟΓΡΑΦΙΑ της μονάδας (Β5ε-3: π.χ. «λτ» → Λίτρο).
/// In-memory filter πάνω στο
/// `watchAll()` — ίδιο idiom με το `categorySearchProvider` (μικρή
/// ήδη-φορτωμένη λίστα, DESIGN §3). Κενό query → `[]` (Stream.value, όχι
/// Stream.empty — θα έμενε σε loading). Το show-all-στο-focus (Δ1, Β5β) ΔΕΝ
/// περνάει από εδώ: η φόρμα χρησιμοποιεί το `unitsStreamProvider` ως πηγή
/// «όλων» μέσα στο SearchableDropdownField (allOptionsProvider).
final unitSearchProvider = StreamProvider.family<List<Unit>, String>(
  (ref, query) {
    final normalized = GreekTextNormalizer.normalize(query.trim());
    if (normalized.isEmpty) return Stream.value(const []);
    return ref.watch(unitRepositoryProvider).watchAll().map(
          (units) => units
          .where(
            (u) =>
        GreekTextNormalizer.normalize(u.name).contains(normalized) ||
            GreekTextNormalizer.normalize(u.abbreviation)
                .contains(normalized),
      )
          .toList(),
    );
  },
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

/// Οι τελευταίες [AppConstants.recentReceiptsLimit] αποδείξεις με σύνοψη
/// (ReceiptSummary: αριθμός, ημερομηνία, προμηθευτής, γραμμές, σύνολο €)
/// για τη read-only λίστα (§2.2 Βήμα 7). NON-autoDispose (ίδιο idiom με
/// όλα τα stream providers): το stream ζει όσο η εφαρμογή — η λίστα
/// ανανεώνεται μόνη της μετά το save (re-emit του customSelectStream).
final recentReceiptsStreamProvider = StreamProvider<List<ReceiptSummary>>(
  (ref) => ref
      .watch(receiptRepositoryProvider)
      .watchRecentSummaries(limit: AppConstants.recentReceiptsLimit),
);

/// Γραμμές απόδειξης — `.family` παραμετροποιημένο ανά [receiptId].
final receiptLinesStreamProvider =
    StreamProvider.family<List<ReceiptLine>, int>(
  (ref, receiptId) =>
      ref.watch(receiptRepositoryProvider).watchLines(receiptId),
);