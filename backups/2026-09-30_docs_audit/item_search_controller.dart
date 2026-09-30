/// SPoT controller — Αναζήτηση είδους (§2.4 DESIGN / Φάση 3 Βήμα 4).
///
/// `AsyncNotifier` (όχι Notifier): η αναζήτηση γίνεται ΑΣΥΓΧΡΟΝΑ στη βάση —
/// το AsyncValue αποδίδει φυσικά τις καταστάσεις data/loading/error που
/// χρειάζεται το inline panel. Όχι autoDispose: το IndexedStack κρατά ζωντανή
/// τη σελίδα σε αλλαγή tab — ο επιλεγμένος σταθμός επιβιώνει (§2.2:221).
///
/// ΡΟΗ (§2.0.3, §2.0.1):
///   * `build()` → idle ΧΩΡΙΣ repo reads → η βάση ΔΕΝ ανοίγει όσο κανείς
///     δεν πληκτρολογεί (κανόνας DESIGN §2.0.1).
///   * `onQueryChanged` → trim + gating (below `searchMinChars` → idle):
///     κάτω από το όριο ΑΚΥΡΩΝΕΙ τον pending Debouncer (no search) και
///     σβήνει τα αποτελέσματα. Από το όριο → `_debouncer.run` (μόνο η
///     ΤΕΛΕΥΤΑΙΑ πληκτρολόγηση τρέχει, §2.0.3).
///   * `_search` → token race-guard (ακυρώνει παλιά searches): normalize
///     query → `searchByNormalizedName(...  limit: searchResultsLimit).first`
///     → found (results) / notFound (κενή λίστα) / AsyncError
///     (DataLoadException → retry).
///   * `selectItem`/`clearSelection` → ITEM_SELECTED banner / επιστροφή.
///   * `createCategory`/`createSubCategory`/`createItemGroup`/`createItem` →
///     record `{ entity, created }` (soft dup-check §2.0.4 + `NameValidator`).
///     Το `createItem` απαιτεί `defaultUnitId` (προτεινόμενη μονάδα §2.2 —
///     προεπιλέγεται στο entry μέσω `_applyDefaultUnit`).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/debouncer.dart';
import '../../../core/utils/greek_text_normalizer.dart';
import '../../../data/local/app_database.dart';
import '../../../data/providers/database_providers.dart';
import '../../../domain/validators/name_validator.dart';
import '../state/item_search_state.dart';

/// SPoT provider — μη autoDispose (§2.2:221, βλ. doc του class).
final itemSearchControllerProvider =
    AsyncNotifierProvider<ItemSearchController, ItemSearchState>(
  ItemSearchController.new,
);

/// Controller της αναζήτησης είδους στο inline panel.
class ItemSearchController extends AsyncNotifier<ItemSearchState> {
  /// Debouncer για την πληκτρολόγηση (§2.0.3) — release με `ref.onDispose`
  /// (Riverpod 3: το AsyncNotifier δεν έχει δικό του dispose override).
  final Debouncer _debouncer = Debouncer(
    delay: Duration(milliseconds: AppConstants.searchDebounceMillis),
  );

  /// Race-guard: κάθε νέα αναζήτηση ακυρώνει τις παλιές in-flight.
  int _searchToken = 0;

  /// Τελευταίο query που «έτρεξε» — για το retry μετά από σφάλμα.
  String _lastQuery = '';

  @override
  Future<ItemSearchState> build() async {
    ref.onDispose(_debouncer.dispose); // ακύρωση pending timer — edge case §2.2
    return const ItemSearchState();
  }

  /// Συντομογραφία θέσεως state 🡒 `AsyncData(next)`.
  void _apply(ItemSearchState next) => state = AsyncData(next);

  /// Σελιδoποίηση για το retry — ξανα-τρέχει την τελευταία αναζήτηση.
  void retry() {
    final query = _lastQuery;
    if (query.trim().isEmpty) return;
    _search(query);
  }

  /// Αλλαγή κειμένου του πεδίου αναζήτησης (§2.0.3): trim + gating.
  /// Κάτω από `searchMinChars` → idle (καμία αναζήτηση, ακύρωση debounce).
  void onQueryChanged(String raw) {
    final query = raw.trim();
    _lastQuery = query;
    if (query.length < AppConstants.searchMinChars) {
      _debouncer.cancel();
      _searchToken++; // ακυρώνει τυχόν in-flight search
      _apply(const ItemSearchState());
      return;
    }
    _debouncer.run(() {
      if (ref.mounted) _search(query);
    });
  }

  /// Πραγματική αναζήτηση: searching → found/notFound/error.
  Future<void> _search(String query) async {
    final token = ++_searchToken;
    _lastQuery = query;
    _apply(ItemSearchState(query: query, status: ItemSearchStatus.searching));

    try {
      final normalized = GreekTextNormalizer.normalize(query);
      final results = await ref
          .read(itemRepositoryProvider)
          .searchByNormalizedName(
            normalized,
            limit: AppConstants.searchResultsLimit,
          )
          .first;
      if (!ref.mounted) return; // disposed ενώ τρέχει το search → παράλειψη ενημέρωσης
      if (token != _searchToken) return; // παρακάμφθηκε από νέο search
      if (results.isEmpty) {
        _apply(
          ItemSearchState(
            query: query,
            status: ItemSearchStatus.notFound,
          ),
        );
      } else {
        _apply(
          ItemSearchState(
            query: query,
            status: ItemSearchStatus.found,
            results: results,
          ),
        );
      }
      AppLogger.info(LogTag.db, 'Αναζήτηση είδους "$normalized": ${results.length}');
    } catch (e, s) {
      if (!ref.mounted) return; // disposed ενώ τρέχει το search → παράλειψη
      if (token != _searchToken) return;
      AppLogger.error(LogTag.db, 'Αποτυχία αναζήτησης είδους', e, s);
      state = AsyncValue.error(const DataLoadException(), s);
    }
  }

  /// Επιλογή είδους → ITEM_SELECTED §2.4 (banner «Αλλαγή»). Equality gate
  /// κατά `id` → no re-notify αν ήδη επιλεγμένο.
  void selectItem(Item item) {
    if (state.value?.selectedItem?.id == item.id) return;
    _apply(
      (state.value ?? const ItemSearchState()).copyWith(
        selectedItem: item,
        status: ItemSearchStatus.idle,
      ),
    );
    AppLogger.info(LogTag.ui, 'Επιλογή είδους: ${item.name}');
  }

  /// Αποεπιλογή (κουμπί «Αλλαγή» στο banner) → πίσω σε idle αναζήτηση.
  void clearSelection() {
    final current = state.value;
    if (current?.selectedItem == null) return;
    _apply(
      current!.copyWith(selectedItem: null, status: ItemSearchStatus.idle),
    );
    AppLogger.info(LogTag.ui, 'Αλλαγή επιλεγμένου είδους');
  }

  /// Δημιουργία κατηγορίας από το «+» του dialog (§2.4). Soft dup-check:
  /// exact-match `getByNormalizedName` (UNIQUE §3, 27-09-2026). Κενό/άκυρο
  /// όνομα → `(null, false)` χωρίς DB access.
  Future<({Category? category, bool created})> createCategory(
    String name,
  ) async {
    final trimmed = name.trim();
    final error = NameValidator.validate(trimmed);
    if (error != null) return (category: null, created: false);

    final repo = ref.read(categoryRepositoryProvider);
    final existing = await repo.getByNormalizedName(
      GreekTextNormalizer.normalize(trimmed),
    );
    if (existing != null) return (category: null, created: false);

    final id = await repo.insert(name: trimmed);
    final created = await repo.getById(id);
    return (category: created, created: true);
  }

  /// Δημιουργία υποκατηγορίας στο dialog (§2.4). Soft dup-check exact-match
  /// (UNIQUE §3, 27-09-2026 — όχι πλέον in-memory scan). Κενό/άκυρο →
  /// `(null, false)`.
  Future<({SubCategory? subCategory, bool created})> createSubCategory({
    required int categoryId,
    required String name,
  }) async {
    final trimmed = name.trim();
    final error = NameValidator.validate(trimmed);
    if (error != null) return (subCategory: null, created: false);

    final repo = ref.read(subCategoryRepositoryProvider);
    final existing = await repo.getByNormalizedName(
      GreekTextNormalizer.normalize(trimmed),
    );
    if (existing != null) return (subCategory: null, created: false);

    final id = await repo.insert(categoryId: categoryId, name: trimmed);
    final created = await repo.getById(id);
    return (subCategory: created, created: true);
  }

  /// Δημιουργία τμήματος στο dialog (§2.4 · 27-09-2026). Soft dup-check
  /// exact-match (UNIQUE §3). Κενό/άκυρο → `(null, false)`.
  Future<({ItemGroup? itemGroup, bool created})> createItemGroup({
    required int subCategoryId,
    required String name,
  }) async {
    final trimmed = name.trim();
    final error = NameValidator.validate(trimmed);
    if (error != null) return (itemGroup: null, created: false);

    final repo = ref.read(itemGroupRepositoryProvider);
    final existing = await repo.getByNormalizedName(
      GreekTextNormalizer.normalize(trimmed),
    );
    if (existing != null) return (itemGroup: null, created: false);

    final id = await repo.insert(subCategoryId: subCategoryId, name: trimmed);
    final created = await repo.getById(id);
    return (itemGroup: created, created: true);
  }

  /// Δημιουργία είδους (§2.4 · με defaultUnitId 27-09-2026).
  /// Soft dup-check exact-match `getByNormalizedName` (§2.0.4). Κενό/άκυρο
  /// όνομα Ή null μονάδα → `(null, false)` χωρίς DB access (safety-net —
  /// το dialog απενεργοποιεί το «Προσθήκη», εδώ guard για programmatic).
  Future<({Item? item, bool created})> createItem({
    required int itemGroupId,
    required String name,
    int? defaultUnitId,
  }) async {
    final trimmed = name.trim();
    final error = NameValidator.validate(trimmed);
    if (error != null || defaultUnitId == null) {
      return (item: null, created: false);
    }

    final repo = ref.read(itemRepositoryProvider);
    final existing = await repo.getByNormalizedName(
      GreekTextNormalizer.normalize(trimmed),
    );
    if (existing != null) return (item: existing, created: false);

    final id = await repo.insert(
      itemGroupId: itemGroupId,
      name: trimmed,
      defaultUnitId: defaultUnitId,
    );
    final created = await repo.getById(id);
    if (created != null) {
      AppLogger.info(
        LogTag.db,
        'Δημιουργία είδους: ${created.name} (#$id, μονάδα #$defaultUnitId)',
      );
    }
    return (item: created, created: created != null);
  }
}