/// Riverpod providers των ρυθμίσεων — Φάση 4, Βήματα 1+3 (DESIGN §2.3).
///
/// Αλυσίδες:
///   * `SharedPreferences → SettingsRepository → themeModeProvider` (Βήμα 1).
///   * `AppDatabase → Category/SubCategoryRepository → categoryTreeStreamProvider`
///     + `canDelete*Provider` (Βήμα 3 · §2.3:274-275): προ-έλεγχος διαγραφής
///     και ζωντανό δένδρο για τον tree editor του Βήματος 4.
/// Όλα NON-autoDispose (singletons, ζωή εφαρμογής — πρότυπο database_providers).
///
/// Το `SharedPreferences` ΔΙΝΕΤΑΙ ΠΑΝΤΑ με override:
///   * `main()` → `await SharedPreferences.getInstance()` ΠΡΙΝ το `runApp`
///     (Q4: μηδέν flash — το θέμα είναι γνωστό πριν το πρώτο frame) και
///     `sharedPreferencesProvider.overrideWithValue(prefs)`.
///   * tests → `SharedPreferences.setMockInitialValues({})` + `getInstance()`
///     στο setUp, ώστε ο provider να είναι πάντα injected (pattern
///     `appDatabaseProvider.overrideWithValue(db)` στα database tests).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_strings.dart';
import '../../core/logging/app_logger.dart';
import '../../core/theme/app_theme.dart';
import '../models/category_tree_node.dart';
import '../models/chart_totals.dart';
import '../repositories/settings_repository.dart';
import '../repositories/settings_repository_impl.dart';
import '../../domain/services/backup_service.dart';
import 'backup_file_picker.dart';
import 'database_providers.dart';
import 'stream_providers.dart';

/// Το προφορτωμένο `SharedPreferences` — σύγχρονο (όχι FutureProvider):
/// ο `settingsRepositoryProvider` μένει `Provider` singleton (§2.0.2
/// «xxxRepositoryProvider») και τα prefs είναι ήδη στη μνήμη. Χωρίς override
/// ρίχνει σκόπιμα UnimplementedError (μην ξεχαστεί injection σε test/main).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'Δώσε sharedPreferencesProvider με overrideWithValue (main ή test)',
  ),
);

/// Singleton `SettingsRepository` (DESIGN §2.5 data flow).
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.watch(sharedPreferencesProvider)),
);

/// Το επιλεγμένο `ThemeMode` (DESIGN §2.3:270) — read στο main.dart
/// (`MaterialApp.router.themeMode`) και στον selector της SettingsPage.
/// Μη autoDispose: με το IndexedStack η σελίδα χτίζεται στο launch → το
/// persisted mode φορτώνεται ΜΙΑ φορά (καμία επαναφόρτωση σε tab switch).
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// Controller του θέματος — **plain Notifier** (§2.0.1· κλειδωμένη απόφαση Β0):
/// το state είναι σύγχρονο (`ThemeMode` επιστρέφεται άμεσα, κανένα loading
/// flash)· το read είναι memory-read (Q4) → το persisted mode είναι ορατό στο
/// ΠΡΩΤΟ frame (review fix 23-09: το προηγούμενο async load άφηνε 1 frame με
/// default). Μόνο το save είναι async (unawaited, δική του μεταχείριση
/// σφαλμάτων). Equality gate + logging (πρότυπο `ReceiptFormController`).
class ThemeModeController extends Notifier<ThemeMode> {
  /// Σύγχρονο read (Q3 αναθεωρήθηκε με ΟΚ χρήστη 23-09): τα prefs είναι
  /// προφορτωμένα στη μνήμη (Q4) → το persisted mode επιστρέφεται άμεσα,
  /// ορατό στο πρώτο frame (αληθινό zero flash — χωρίς async κενό δεν
  /// υπάρχει race, ο `_userChanged` guard δεν χρειάζεται πια). Σφάλμα →
  /// default + log (κανένα crash). Default = `AppTheme.defaultMode`
  /// (system, SPoT §1.5).
  @override
  ThemeMode build() {
    try {
      return ref.read(settingsRepositoryProvider).readThemeMode();
    } catch (e, s) {
      AppLogger.error(LogTag.ui, 'Ανάγνωση θέματος απέτυχε — χρήση default', e, s);
      return AppTheme.defaultMode;
    }
  }

  /// Ορίζει το θέμα από τον χρήστη (selector). Equality gate: ίδιο mode →
  /// χωρίς re-notify και χωρίς περιττό save. Save αποτυχία → το state μένει
  /// στη μνήμη (η επιλογή ισχύει στην τρέχουσα συνεδρία· μόνο log — κανένα
  /// snackbar, κανένα νέο AppErrors· απόφαση Β1).
  void setMode(ThemeMode mode) {
    if (mode == state) return;
    state = mode;
    AppLogger.info(LogTag.ui, 'Θέμα: ${mode.name}');
    unawaited(_save(mode));
  }

  Future<void> _save(ThemeMode mode) async {
    if (!ref.mounted) return;
    try {
      await ref.read(settingsRepositoryProvider).saveThemeMode(mode);
    } catch (e, s) {
      AppLogger.error(LogTag.ui, 'Αποθήκευση θέματος απέτυχε', e, s);
    }
  }
}

// ─── Βήμα 3 — Providers ελέγχου (DESIGN §2.3:274-275 · §4:463) ───────────────

/// Ζωντανό δέντρο «Κατηγορία ▸ Υποκατηγορία ▸ Τμήματα» (27-09-2026).
///
/// Σύνθεση in-memory πάνω στα ήδη-φορτωμένα `categoryStreamProvider` +
/// `subCategoriesStreamProvider` + `itemGroupsStreamProvider` — ΚΑΝΕΝΑ νέο
/// DB query (§3: μικρές λίστες). Προτεραιότητα σφάλματος (Riverpod 3 retry):
/// `hasError` χωρίς τιμή → `Stream.error` (όχι αιώνιο loading).
/// NON-autoDispose (σύμβαση DI δέντρου).
final categoryTreeStreamProvider = StreamProvider<List<CategoryTreeNode>>(
  (ref) {
    final categories = ref.watch(categoryStreamProvider);
    final subs = ref.watch(subCategoriesStreamProvider);
    final groups = ref.watch(itemGroupsStreamProvider);
    for (final upstream in [categories, subs, groups]) {
      if (upstream.hasError && !upstream.hasValue) {
        return Stream.error(upstream.error!, upstream.stackTrace);
      }
    }
    return categories.when(
      data: (cats) => subs.when(
        data: (subList) => groups.when(
          data: (groupList) => Stream.value([
            for (final cat in cats)
              (
                category: cat,
                subNodes: [
                  for (final sub in subList)
                    if (sub.categoryId == cat.id)
                      (
                        subCategory: sub,
                        itemGroups: [
                          for (final g in groupList)
                            if (g.subCategoryId == sub.id) g,
                        ],
                      ),
                ],
              ),
          ]),
          loading: () => const Stream.empty(),
          error: (e, s) => Stream.error(e, s),
        ),
        loading: () => const Stream.empty(),
        error: (e, s) => Stream.error(e, s),
      ),
      loading: () => const Stream.empty(),
      error: (e, s) => Stream.error(e, s),
    );
  },
);

/// Προ-έλεγχος διαγραφής κατηγορίας (DESIGN §2.3:275 · §4:463).
///
/// `true` = καθαρή (`countItemsInUse == 0`, επιτρέπεται cascade) ·
/// `false` = μπλοκαρισμένη (greyed-out + tooltip στο Βήμα 4). Πρώτοι
/// `FutureProvider` της εφαρμογής — καμία νέα dependency, `.family`
/// ανάλογο των `StreamProvider.family`. Σφάλμα → `DataLoadException`
/// (repository mapping). Προσοχή (lifecycle): one-shot τιμή ανά id — μετά
/// από CRUD που αγγίζει είδη/γραμμές, το Βήμα 4 κάνει
/// `ref.invalidate(canDeleteCategoryProvider(id))` (συμβόλαιο Βήματος 4).
/// Σημ. tests (εύρημα Βήματος 3): το Riverpod 3 ξαναπροσπαθεί αυτόματα τα
/// αποτυχημένα futures (retry) — τα error-path tests ακούν με
/// listen+completer (`hasError`), ποτέ `.future`+throwsA (δεν ολοκληρώνεται).
/// NON-autoDispose (σύμβαση DI δέντρου — τα ids είναι λίγα).
final canDeleteCategoryProvider = FutureProvider.family<bool, int>(
  (ref, categoryId) async =>
      await ref.watch(categoryRepositoryProvider).countItemsInUse(categoryId) ==
      0,
);

/// Πλήθος ειδών της κατηγορίας με ≥1 γραμμή απόδειξης — Φάση 4, Βήμα 4
/// (§2.3): αριθμός στο blocked tooltip (`AppMessages.itemsInUseTooltip`).
/// Sibling του `canDeleteCategoryProvider` (ίδιο repo call, `int` αντί
/// `bool`) — το bool δεν φτάνει για tooltip με πλήθος. Invalidate μαζί με
/// το canDelete (κουμπί ανανέωσης του tree editor + μετά από delete).
/// NON-autoDispose.
final inUseCountCategoryProvider = FutureProvider.family<int, int>(
  (ref, categoryId) =>
      ref.watch(categoryRepositoryProvider).countItemsInUse(categoryId),
);

/// Προ-έλεγχος διαγραφής υποκατηγορίας — συμμετρικό με το κατηγορίας.
/// Καταναλώνει το `SubCategoryRepository.countItemsInUse` (Βήμα 3).
final canDeleteSubCategoryProvider = FutureProvider.family<bool, int>(
  (ref, subCategoryId) async =>
      await ref.watch(subCategoryRepositoryProvider).countItemsInUse(
            subCategoryId,
          ) ==
      0,
);

/// Πλήθος ειδών της υποκατηγορίας με ≥1 γραμμή απόδειξης — Φάση 4,
/// Βήμα 4 (§2.3): αριθμός στο blocked tooltip. Sibling του
/// `canDeleteSubCategoryProvider`, συμμετρικό με το κατηγορίας.
/// NON-autoDispose.
final inUseCountSubCategoryProvider = FutureProvider.family<int, int>(
  (ref, subCategoryId) =>
      ref.watch(subCategoryRepositoryProvider).countItemsInUse(subCategoryId),
);

// ─── Τμήματα — πύλη διαγραφής (§2.3 · 27-09-2026) ──────────────────────────

/// Προ-έλεγχος διαγραφής τμήματος — συμμετρικό με κατηγορίας/υποκατηγορίας.
/// `true` = καθαρό (`countItemsInUse == 0`, επιτρέπεται cascade).
final canDeleteItemGroupProvider = FutureProvider.family<bool, int>(
  (ref, itemGroupId) async =>
      await ref.watch(itemGroupRepositoryProvider).countItemsInUse(
            itemGroupId,
          ) ==
      0,
);

/// Πλήθος ειδών του τμήματος με ≥1 γραμμή — sibling για το tooltip.
final inUseCountItemGroupProvider = FutureProvider.family<int, int>(
  (ref, itemGroupId) =>
      ref.watch(itemGroupRepositoryProvider).countItemsInUse(itemGroupId),
);

// ─── CRUD προμηθευτών — πύλη διαγραφής (§2.3 · 24-09-2026) ─────────────────

/// Προ-έλεγχος διαγραφής προμηθευτή.
///
/// `true` = καθαρός (`countBySupplierId == 0`, RESTRICT δεν εμποδίζει) ·
/// `false` = μπλοκαρισμένος (greyed-out + tooltip με πλήθος αποδείξεων).
/// Family one-shot ανά id + invalidate μετά από delete (πατρόν Βήματος 4).
/// NON-autoDispose.
final canDeleteSupplierProvider = FutureProvider.family<bool, int>(
  (ref, supplierId) async =>
      await ref.watch(receiptRepositoryProvider).countBySupplierId(supplierId) ==
      0,
);

/// Πλήθος αποδείξεων του προμηθευτή — sibling του `canDeleteSupplierProvider`
/// (`int` για το blocked tooltip `supplierReceiptsTooltip`). Invalidate μαζί
/// με το canDelete (κουμπί ανανέωσης + μετά από delete). NON-autoDispose.
final receiptCountSupplierProvider = FutureProvider.family<int, int>(
  (ref, supplierId) =>
      ref.watch(receiptRepositoryProvider).countBySupplierId(supplierId),
);

// ─── CRUD ειδών — πύλη διαγραφής (§2.3 · ενότητα Ειδών) ─────────────────────

/// Προ-έλεγχος διαγραφής είδους.
///
/// `true` = καθαρό (`countLinesByItemId == 0`, RESTRICT δεν εμποδίζει) ·
/// `false` = μπλοκαρισμένο (greyed-out + tooltip με πλήθος γραμμών).
/// Family one-shot ανά id + invalidate μετά από delete/μετακίνηση (πατρόν
/// Βήματος 4 — η μετακίνηση αλλάζει τα `inUse` πυλών κατηγοριών).
/// NON-autoDispose.
final canDeleteItemProvider = FutureProvider.family<bool, int>(
  (ref, itemId) async =>
      await ref.watch(receiptRepositoryProvider).countLinesByItemId(itemId) ==
      0,
);

/// Πλήθος γραμμών του είδους — sibling του `canDeleteItemProvider`
/// (`int` για το blocked tooltip `itemLinesTooltip`). Invalidate μαζί
/// με το canDelete. NON-autoDispose.
final itemLinesCountProvider = FutureProvider.family<int, int>(
  (ref, itemId) =>
      ref.watch(receiptRepositoryProvider).countLinesByItemId(itemId),
);

// ─── Backup / Restore — service + picker (§2.3 · Φάση 4 Βήμα 5) ─────────────

/// SPoT `BackupService` πάνω στην ανοιχτή βάση. Cascade invalidation: το
/// `ref.invalidate(appDatabaseProvider)` ξαναχτίζει service + repos + streams
/// (όλα κάνουν watch το DB provider) — το UI διαβάζει τα νέα δεδομένα.
/// NON-autoDispose (σύμβαση DI δέντρου).
final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(appDatabaseProvider)),
);

/// SPoT picker αντιγράφων — production impl εδώ, override με fake στα tests
/// (pattern `sharedPreferencesProvider`/`appDatabaseProvider.overrideWithValue`).
/// NON-autoDispose.
final backupFilePickerProvider = Provider<BackupFilePicker>(
  (ref) => FilePickerBackupPicker(),
);

// ─── Επιλεγμένο είδος πορείας (§2.1 · 28-09-2026, Q5) ────────────────────────

/// Επιλεγμένο είδος κάρτας πορείας (itemId) — `null` = κανένα (idle hint).
/// Plain `Notifier` (pattern `SelectedReceiptDay`/`ThemeModeController`):
/// σύγχρονο nullable state + persist `trendSelectedItemKey` μέσω
/// `SettingsRepository` (sync read, async save με δική του μεταχείριση).
/// Ζει εδώ (όχι στο stream_providers — το repository είναι ορατό μόνο από
/// αυτό το αρχείο, αλλιώς κυκλικό import). NON-autoDispose.
final selectedTrendItemProvider = NotifierProvider<SelectedTrendItem, int?>(
  SelectedTrendItem.new,
);

/// Controller επιλογής είδους πορείας — βλ. `selectedTrendItemProvider`.
class SelectedTrendItem extends Notifier<int?> {
  /// Σύγχρονο read (pattern theme Βήματος 1): memory-read, ορατό στο πρώτο
  /// frame· σφάλμα → null (idle, κανένα crash).
  @override
  int? build() {
    try {
      return ref.read(settingsRepositoryProvider).readTrendItemId();
    } catch (e, s) {
      AppLogger.error(
        LogTag.ui,
        'Ανάγνωση επιλεγμένου είδους πορείας απέτυχε',
        e,
        s,
      );
      return null;
    }
  }

  /// Επιλογή είδους. Equality gate: ίδιο id → no-op (χωρίς re-notify/save).
  void select(int id) {
    if (state == id) return;
    state = id;
    AppLogger.info(LogTag.ui, 'Επιλογή είδους πορείας: #$id');
    unawaited(_save(id));
  }

  /// Αποεπιλογή → idle hint. Ήδη null → no-op.
  void clear() {
    if (state == null) return;
    state = null;
    AppLogger.info(LogTag.ui, 'Αποεπιλογή είδους πορείας');
    unawaited(_save(null));
  }

  Future<void> _save(int? id) async {
    if (!ref.mounted) return;
    try {
      await ref.read(settingsRepositoryProvider).saveTrendItemId(id);
    } catch (e, s) {
      AppLogger.error(
        LogTag.ui,
        'Αποθήκευση είδους πορείας απέτυχε',
        e,
        s,
      );
    }
  }
}

// ─── Μετρική Top-10 (§2.1 · 29-09-2026, Q2) ─────────────────────────────────

/// Μετρική κάρτας Top-10 — SPoT (`AppStrings`, §1.1).
String topItemsMetricLabel(TopItemsMetric metric) => switch (metric) {
      TopItemsMetric.euros => AppStrings.currencySymbol,
      TopItemsMetric.pieces => AppStrings.topItemsMetricPieces,
      TopItemsMetric.kilos => AppStrings.topItemsMetricKilos,
      TopItemsMetric.liters => AppStrings.topItemsMetricLiters,
    };

/// Συντομογραφία μονάδας ανά μετρική (lookup στο `unitsStreamProvider` —
/// stable seeds, §3 · miss → null = empty, όχι crash).
String? topItemsMetricAbbreviation(TopItemsMetric metric) => switch (metric) {
      TopItemsMetric.euros => null,
      TopItemsMetric.pieces => 'τεμ',
      TopItemsMetric.kilos => 'κιλ',
      TopItemsMetric.liters => 'λτ',
    };

/// Επιλεγμένη μετρική Top-10. Plain `Notifier` (pattern `SelectedTrendItem`):
/// σύγχρονο state + persist `topItemsMetricKey` (sync read, async save).
/// NON-autoDispose (σύμβαση DI δέντρου).
final topItemsMetricProvider = NotifierProvider<TopItemsMetricController, TopItemsMetric>(
  TopItemsMetricController.new,
);

/// Controller μετρικής Top-10 — βλ. `topItemsMetricProvider`.
class TopItemsMetricController extends Notifier<TopItemsMetric> {
  /// Σύγχρονο read (pattern theme): memory-read · σφάλμα → euros (default).
  @override
  TopItemsMetric build() {
    try {
      return ref.read(settingsRepositoryProvider).readTopItemsMetric();
    } catch (e, s) {
      AppLogger.error(
        LogTag.ui,
        'Ανάγνωση μετρικής Top-10 απέτυχε — χρήση default',
        e,
        s,
      );
      return TopItemsMetric.euros;
    }
  }

  /// Ορίζει τη μετρική. Equality gate: ίδια → no-op.
  void setMetric(TopItemsMetric metric) {
    if (state == metric) return;
    state = metric;
    AppLogger.info(LogTag.stats, 'Μετρική Top-10: ${metric.name}');
    unawaited(_save(metric));
  }

  Future<void> _save(TopItemsMetric metric) async {
    if (!ref.mounted) return;
    try {
      await ref.read(settingsRepositoryProvider).saveTopItemsMetric(metric);
    } catch (e, s) {
      AppLogger.error(
        LogTag.ui,
        'Αποθήκευση μετρικής Top-10 απέτυχε',
        e,
        s,
      );
    }
  }
}
