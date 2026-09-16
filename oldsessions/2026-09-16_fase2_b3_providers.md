# Φάση 2 — Βήμα 3: Riverpod DI Tree & StreamProviders

> Ημερομηνία: 16-09-2026 · Κατάσταση: Κλειστό · Υλοποίηση του Riverpod
> dependency-injection δέντρου (AppDatabase → Repositories → StreamProviders),
> rewrite του `main.dart` (ProviderScope + branded placeholder) και αφαίρεση
> του counter template (branding §0).

---

## 1. Πεδίο

Φάση 2, Βήμα 3 (§1.2) — η γέφυρα ανάμεσα στα repositories και το UI:

- `lib/data/providers/database_providers.dart` — `appDatabaseProvider` +
  6 repository providers (Provider, singleton, app-lifetime).
- `lib/data/providers/stream_providers.dart` — 8 StreamProviders (6 plain +
  2 `.family`) πάνω στα repositories.
- `lib/main.dart` — rewrite: `ProviderScope` γυρω από το app + branded
  placeholder (MaterialApp με `AppTheme`), καθάρισμα του counter template.
- `lib/core/constants/app_strings.dart` — αφαίρεση 2 counter strings.
- Tests: DI structure, stream emissions, widget smoke, app_strings cleanup.

## 2. Προεργασία / Review

- Διαβάστηκαν ΟΛΑ τα εμπλεκόμενα αρχεία πριν από κάθε υλοποίηση:
  main.dart, app_strings.dart, widget_test.dart, app_strings_test.dart,
  app_theme.dart, app_colors.dart, debug_config.dart, app_logger.dart,
  app_routes.dart, DESIGN.md §0/§1.2/§2.0.2, repositories (6 interfaces +
  6 impl), DAOs (7), app_database.dart, helpers/in_memory_db.dart.
- Επαληθεύτηκαν τα constructor signatures: `CategoryRepositoryImpl(this._dao)`
  κ.ο.κ., `ReceiptRepositoryImpl(this._receiptDao, this._lineDao)`, DAOs με
  `super.db`, `AppDatabase({QueryExecutor? executor, this.skipSeed = false})`.

## 3. Εγκεκριμένες αποφάσεις (user OK)

1. **Startup log στο `main()` ΚΡΑΤΑΕΙ** — `AppLogger.info(LogTag.ui, 'Εφαρμογή «Τιμές» ξεκίνησε')` (DESIGN §1.7, main.dart:9). Δεν αφαιρείται.
2. **`ThemeMode` μέσω SPoT**: χρήση `AppTheme.defaultMode` (app_theme.dart:14), όχι literal `ThemeMode.system`.
3. **`watchLines(int receiptId)`** (receipt_repository.dart:43) — όχι `watchReceiptLines`. Αντιστοιχία με `ReceiptLineDao.watchByReceiptId`.
4. **Provider `onDispose` στο `appDatabaseProvider`**: `ref.onDispose(db.close)` — μόνο για αυθεντική δημιουργία DB (τιμή). `overrideWithValue` σε tests το προσπερνά.
5. **Όλα τα providers NON-autoDispose** (singleton, app-lifetime).
6. **Naming** (§2.0.2): `xxxRepositoryProvider`, `xxxStreamProvider`; families `subCategoriesByCategoryProvider(catId)` + `receiptLinesStreamProvider(receiptId)`.

## 4. Αρχεία υλοποίησης

| Αρχείο | Γραμμές | Σημειώσεις |
|---|---|---|
| `lib/data/providers/database_providers.dart` | ~45 | `appDatabaseProvider` (onDispose→close) + 6 repo providers |
| `lib/data/providers/stream_providers.dart` | ~90 | 8 providers: 6 plain + 2 `.family` |
| `lib/main.dart` | ~70 | ProviderScope + TimesApp + `_BrandedPlaceholder` |
| `lib/core/constants/app_strings.dart` | — | −2 counter strings (counter section) |
| `test/widget_test.dart` | — | rewrite: smoke branding test |
| `test/core/constants/app_strings_test.dart` | — | −counter block, −2 `_allStrings` |
| `test/data/providers/database_providers_test.dart` | — | DI structure + singleton checks (6 tests) |
| `test/data/providers/stream_providers_test.dart` | — | stream emission tests (9 tests) |

Placeholder: MaterialApp με `AppTheme.light/dark/defaultMode`, `AppBar` +
Center με `AppStrings.appTitle`. **Δεν** κάνει watch data providers → το
widget_test δεν χρειάζεται DB override.

## 5. Ευρήματα Riverpod 3.4.3 (empirικά — κρίσιμα για το μέλλον)

1. **`.future` του StreamProvider ΔΕΝ πιάνει την πρώτη εκπομπή** των drift
   stream queries. `container.read(provider.future)` κρέμεται μέχρι timeout,
   ενώ το repository stream `.first` δουλεύει κανονικά, και
   `container.listen` + `Completer` δουλεύει. Συμπέρασμα: **στα tests χρήση
   `container.listen` + `Completer` πάντα**.
2. **`ProviderListenable` είναι internal** — ορατό μόνο μέσα στο πακέτο
   (annotation `@publicInMisc`, riverpod-3.4.3 `lib/src/core/foundation.dart`).
   Δεν μπορεί να χρησιμοποιηθεί σαν public type σε helpers tests. → Ο helper
   δέχεται το provider μέσω subscribe-callback.
3. **Generic inference limitation**: helper `waitForValue<T>(subscribe,
   predicate)` με T κατά Inference ΔΕΝ δουλεύει — το κλείσιμο subscribe
   περιέχει `container.listen(provider, listen)` (κυκλική inference → T=Never).
   Διόρθωση: **ρητό type argument σε κάθε κλήση** (`waitForValue<List<T>>`).
4. **`ProviderContainer.test()` auto-disposes** το container (Riverpod 3.x) →
   `addTearDown(db.close)` μόνο (το `overrideWithValue` προσπερνά το onDispose).

## 6. Διάγνωση του test hang (αφαιρέθηκε το tmp_debug_test)

- debug1: repository stream `.first` → OK.
- debug2: `provider.future` → `TimeoutException` στα 5s (hang).
- debug3: `container.listen` + `Completer` → OK.
- Επιβεβαιώθηκε ότι **δεν φταίνε τα repositories** — το πρόβλημα είναι το
  `.future` API του StreamProvider (riverpod-3.4.3).

## 7. Verification

- `flutter test` **329/329** ✓ (πριν: 315 — +6 DI +9 streams −1 counter block
  αναδιοργάνωση, count τελικό 329).
- `flutter analyze` **No issues found** ✓.

## 8. Backups

| Αρχείο | Backup |
|---|---|
| `lib/main.dart` | `backups/2026-09-16_fase2_b3/main.dart.bak` |
| `lib/core/constants/app_strings.dart` | `backups/2026-09-16_fase2_b3/app_strings.dart.bak` |
| `test/widget_test.dart` | `backups/2026-09-16_fase2_b3/widget_test.dart.bak` |
| `test/core/constants/app_strings_test.dart` | `backups/2026-09-16_fase2_b3/app_strings_test.dart.bak` |

## 9. Επόμενο

- Φάση 2 — Βήμα 4: Controllers / AsyncNotifiers για τις οθόνες (ή ό,τι
  επόμενο ορίσει ο χρήστης).