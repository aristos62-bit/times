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

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/logging/app_logger.dart';
import '../../core/utils/greek_text_normalizer.dart';
import '../../domain/services/chart_helpers.dart';
import '../local/app_database.dart';
import '../models/chart_totals.dart';
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

/// Όλα τα τμήματα, αλφαβητικά (27-09-2026).
final itemGroupsStreamProvider = StreamProvider<List<ItemGroup>>(
  (ref) => ref.watch(itemGroupRepositoryProvider).watchAll(),
);

/// Τμήματα μιας υποκατηγορίας — `.family` ανά [subCategoryId].
final itemGroupsBySubCategoryProvider =
    StreamProvider.family<List<ItemGroup>, int>(
  (ref, subCategoryId) => ref
      .watch(itemGroupRepositoryProvider)
      .watchBySubCategoryId(subCategoryId),
);

/// LIVE αναζήτηση τμημάτων για το new-item dialog (27-09-2026).
/// `.family` ανά `({int subCategoryId, String query})`.
/// In-memory filter πάνω σε `watchBySubCategoryId` — χωρίς νέα DB query.
/// Κενό query → `[]` (Stream.value). Non-autoDispose.
final itemGroupSearchProvider =
    StreamProvider.family<List<ItemGroup>, ({int subCategoryId, String query})>(
  (ref, params) {
    final normalized = GreekTextNormalizer.normalize(params.query.trim());
    if (normalized.isEmpty) return Stream.value(const []);
    return ref
        .watch(itemGroupRepositoryProvider)
        .watchBySubCategoryId(params.subCategoryId)
        .map(
          (groups) => groups
              .where(
                (g) =>
                    GreekTextNormalizer.normalize(g.name).contains(normalized),
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

// ─── Φάση 5 — Chart streams (§2.1 · Βήμα 3) ─────────────────────────────────
//
// 5 families παραμετροποιημένες ανά [ChartQuery] (`{from, to}` — το `limit`
// εφαρμόζεται στο slice, Q1 Βήματος 2). Slice top-N + «Λοιπά» in-memory
// (precedent `categoryTreeStreamProvider`): η SQL επιστρέφει την πλήρη
// ordered λίστα (ΧΩΡΙΣ LIMIT) και ο `toChartSlices` κρατά top-N + exact
// υπόλοιπο. Σφάλματα ήδη `DataLoadException` (repo mapping) — εδώ ΔΕΝ
// προσθέτουμε logging. Όλα NON-autoDispose (σύμβαση DI δέντρου).

/// Φέτες «Ανά προμηθευτή» — top `pieMaxSlices` + «Λοιπά».
final supplierTotalsProvider =
    StreamProvider.family<List<ChartSlice>, ChartQuery>(
  (ref, query) => ref
      .watch(receiptRepositoryProvider)
      .watchTotalsBySupplier(from: query.from, to: query.to)
      .map(
        (rows) => toChartSlices(
          rows,
          labelOf: (row) => row.supplierName,
          totalOf: (row) => row.totalCents,
          limit: AppConstants.pieMaxSlices,
          othersLabel: AppStrings.othersSliceLabel,
        ),
      ),
);

/// Φέτες «Ανά κατηγορία» — top `pieMaxSlices` + «Λοιπά».
final categoryTotalsProvider =
    StreamProvider.family<List<ChartSlice>, ChartQuery>(
  (ref, query) => ref
      .watch(receiptRepositoryProvider)
      .watchTotalsByCategory(from: query.from, to: query.to)
      .map(
        (rows) => toChartSlices(
          rows,
          labelOf: (row) => row.categoryName,
          totalOf: (row) => row.totalCents,
          limit: AppConstants.pieMaxSlices,
          othersLabel: AppStrings.othersSliceLabel,
        ),
      ),
);

/// Φέτες «Ανά υποκατηγορία» — top `pieMaxSlices` + «Λοιπά».
final subCategoryTotalsProvider =
    StreamProvider.family<List<ChartSlice>, ChartQuery>(
  (ref, query) => ref
      .watch(receiptRepositoryProvider)
      .watchTotalsBySubCategory(from: query.from, to: query.to)
      .map(
        (rows) => toChartSlices(
          rows,
          labelOf: (row) => row.subCategoryName,
          totalOf: (row) => row.totalCents,
          limit: AppConstants.pieMaxSlices,
          othersLabel: AppStrings.othersSliceLabel,
        ),
      ),
);

/// Φέτες «Ανά τμήμα» — top `pieMaxSlices` + «Λοιπά».
final itemGroupTotalsProvider =
    StreamProvider.family<List<ChartSlice>, ChartQuery>(
  (ref, query) => ref
      .watch(receiptRepositoryProvider)
      .watchTotalsByItemGroup(from: query.from, to: query.to)
      .map(
        (rows) => toChartSlices(
          rows,
          labelOf: (row) => row.itemGroupName,
          totalOf: (row) => row.totalCents,
          limit: AppConstants.pieMaxSlices,
          othersLabel: AppStrings.othersSliceLabel,
        ),
      ),
);

/// Φέτες Top-10 ειδών — top `topItemsLimit` + «Λοιπά».
final topItemsTotalsProvider =
    StreamProvider.family<List<ChartSlice>, ChartQuery>(
  (ref, query) => ref
      .watch(receiptRepositoryProvider)
      .watchTopItems(from: query.from, to: query.to)
      .map(
        (rows) => toChartSlices(
          rows,
          labelOf: (row) => row.itemName,
          totalOf: (row) => row.totalCents,
          limit: AppConstants.topItemsLimit,
          othersLabel: AppStrings.othersSliceLabel,
        ),
      ),
);

/// Τελευταία γραμμή είδους για prefill τιμής/έκπτωσης (§2.2) — `.family`
/// παραμετροποιημένο ανά [itemId]. One-shot FutureProvider (όχι stream — η
/// τιμή διαβάζεται μία φορά στην επιλογή είδους, precedent `canDelete*`
/// §2.3). `null` = το είδος δεν έχει κινηθεί. Σφάλμα → `DataLoadException`
/// (repository mapping)· το section το αγνοεί σιωπηλά (no-prefill — η φόρμα
/// δεν μπλοκάρεται ποτέ από αποτυχία prefill).
/// NON-autoDispose (σύμβαση DI δέντρου).
final latestReceiptLineProvider = FutureProvider.family<ReceiptLine?, int>(
  (ref, itemId) =>
      ref.watch(receiptRepositoryProvider).getLatestByItemId(itemId),
);

/// Επιλεγμένη ημέρα φίλτρου «Διαχείρισης αποδείξεων» (§2.3 · Φάση Β).
/// `null` = όλες (οι τελευταίες `AppConstants.manageReceiptsLimit`).
/// Plain `Notifier` (όχι `StateProvider` — αφαιρέθηκε στο Riverpod 3·
/// pattern `ThemeModeController`): σύγχρονο nullable state, `select`/`clear`.
/// Σύμβαση ονομασίας §2.0.2: `selectedXxxProvider`. NON-autoDispose.
final selectedReceiptDayProvider =
    NotifierProvider<SelectedReceiptDay, DateTime?>(
  SelectedReceiptDay.new,
);

/// Controller φίλτρου ημέρας — plain Notifier (βλ. `selectedReceiptDayProvider`).
class SelectedReceiptDay extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  /// Ορίζει την ημέρα φίλτρου (date-picker, ήδη dateOnly).
  void select(DateTime day) {
    if (state == day) return;
    state = day;
  }

  /// Καθαρισμός → όλες.
  void clear() => state = null;
}

/// Αποδείξεις με σύνοψη για τη διαχείριση (§2.3 · Φάση Β): της επιλεγμένης
/// ημέρας ή (χωρίς φίλτρο) οι τελευταίες `manageReceiptsLimit`. Live stream
/// (ίδιο `readsFrom` με το recent) — save/update/delete ανανεώνουν αυτόματα.
/// NON-autoDispose (σύμβαση DI δέντρου).
final receiptsByDayStreamProvider = StreamProvider<List<ReceiptSummary>>(
  (ref) {
    final day = ref.watch(selectedReceiptDayProvider);
    final repo = ref.watch(receiptRepositoryProvider);
    if (day == null) {
      return repo.watchRecentSummaries(
        limit: AppConstants.manageReceiptsLimit,
      );
    }
    return repo.watchSummariesByDay(
      day: day,
      limit: AppConstants.manageReceiptsLimit,
    );
  },
);

// ─── Τρέχουσα ημέρα — SPoT χρόνου Κεντρικής (§2.1 · 27-09-2026) ──────────────
//
// Plain `Notifier<DateTime>` (όχι Stream — εκπέμπει ΜΟΝΟ σε αλλαγή ημέρας,
// day-gate, μηδέν churn στα chart families): λύνει το stale `now` του
// `HomePage.build` σε ανοικτή σελίδα πάνω στα μεσάνυχτα (day/week/month/year
// ξανα-επιλύονται, custom άθικτο). Καθαρό Dart day-truncation (όχι flutter
// `DateUtils`: το data layer δεν εξαρτάται από το UI, precedent
// `watchSummariesByDay`). Αποδέσμευση του `Timer` με `ref.onDispose`
// (precedent `ItemSearchController`).
// Σημ.: τα παλιά chart family instances μένουν (NON-autoDispose σύμβαση) —
// 4/ημέρα, αμελητέο για προσωπική χρήση (follow-up: autoDispose families).
// NON-autoDispose (σύμβαση DI δέντρου).
final todayProvider = NotifierProvider<TodayController, DateTime>(
  TodayController.new,
);

/// Controller τρέχουσας ημέρας — βλ. `todayProvider`.
class TodayController extends Notifier<DateTime> {
  /// Κανονικοποιεί σε μέρα (καθαρό Dart — όχι `DateUtils`, βλ. πάνω).
  static DateTime dayOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  DateTime build() {
    final timer = Timer.periodic(
      Duration(seconds: AppConstants.clockCheckSeconds),
      (_) => checkNow(DateTime.now()),
    );
    ref.onDispose(timer.cancel);
    return dayOnly(DateTime.now());
  }

  /// Ελέγχει αν άλλαξε η ημέρα — ΜΟΝΟ τότε ειδοποιεί (day-gate).
  /// Καλείται από το `Timer`· δημόσια και ως test-hook (hermetic
  /// midnight-test χωρίς αναμονή, pattern `resolvePeriodRange(now:)`).
  void checkNow(DateTime now) {
    final day = dayOnly(now);
    if (day == state) return;
    state = day;
    AppLogger.info(LogTag.ui, 'Αλλαγή ημέρας: ${day.toIso8601String()}');
  }
}