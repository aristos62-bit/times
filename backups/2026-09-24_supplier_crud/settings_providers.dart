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

import '../../core/logging/app_logger.dart';
import '../../core/theme/app_theme.dart';
import '../models/category_tree_node.dart';
import '../repositories/settings_repository.dart';
import '../repositories/settings_repository_impl.dart';
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

/// Ζωντανό δέντρο «Κατηγορία ▸ Υποκατηγορίες» για τον tree editor (Βήμα 4).
///
/// Σύνθεση in-memory πάνω στα ήδη-φορτωμένα `categoryStreamProvider` +
/// `subCategoriesStreamProvider` — ΚΑΝΕΝΑ νέο DB query (§3: μικρές λίστες).
/// Κάθε εκπομπή upstream ξανατρέχει το body και δίνει νέο single-value
/// stream (`Stream.value` — precedent `categorySearchProvider`): τα δεδομένα
/// ανανεώνονται χωρίς νέο subscription. Όσο κάποιο upstream φορτώνει,
/// επιστρέφεται `Stream.empty()` (μένει σε loading — σκόπιμα, όχι `[]` που
/// θα έδειχνε ψευδώς άδειο δέντρο).
///
/// Προτεραιότητα σφάλματος (εύρημα Βήματος 3 — Riverpod 3 retry): σε
/// αποτυχία το upstream μένει `AsyncLoading` με συνημμένο σφάλμα (το
/// Riverpod ξαναπροσπαθεί αυτόματα) και το σκέτο `.when` θα έπαιρνε το
/// `loading` branch → `Stream.empty()` → το δέντρο θα έμενε loading ΓΙΑ
/// ΠΑΝΤΑ σε μόνιμη βλάβη. Γι' αυτό το `hasError` (χωρίς τιμή) προηγείται
/// με `Stream.error` (ήδη-mapαρισμένο `DataLoadException` — προβολή στο
/// Βήμα 4 με `AsyncValue.when`: `AppErrors.loadDataFailed` + Επανάληψη).
/// Χωρίς logging εδώ (τα σφάλματα λογκάρονται μία φορά στον DAO guard).
/// NON-autoDispose (σύμβαση DI δέντρου).
final categoryTreeStreamProvider = StreamProvider<List<CategoryTreeNode>>(
  (ref) {
    final categories = ref.watch(categoryStreamProvider);
    final subs = ref.watch(subCategoriesStreamProvider);
    if (categories.hasError && !categories.hasValue) {
      return Stream.error(categories.error!, categories.stackTrace);
    }
    if (subs.hasError && !subs.hasValue) {
      return Stream.error(subs.error!, subs.stackTrace);
    }
    return categories.when(
      data: (cats) => subs.when(
        data: (subList) => Stream.value([
          for (final cat in cats)
            (
              category: cat,
              subCategories: [
                for (final sub in subList)
                  if (sub.categoryId == cat.id) sub,
              ],
            ),
        ]),
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
