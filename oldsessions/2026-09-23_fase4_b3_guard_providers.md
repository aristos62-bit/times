# Φάση 4 — Βήμα 3: Providers ελέγχου (23-09-2026)

> Κατάσταση: **Κλειστό**. Backup `backups/2026-09-23_fase4_b3_guards/`
> (4 repo files + settings_providers + DESIGN + oldsessions πριν το βήμα).

---

## 1. Σκοπός

Οι providers του DESIGN §2.3:274-275 / §4:463 — προ-έλεγχος διαγραφής και
ζωντανό δέντρο για τον tree editor του Βήματος 4. Κανένα UI, κανένα schema
change, κανένα νέο string/const/log-tag (Α1 «βάση μόνο μέσω PriceEntry»
παραμένει — κανένα `watch` στη SettingsPage).

## 2. Υλοποίηση

- `CategoryRepository`/`SubCategoryRepository` (+ impl): `countItemsInUse`
  — passthrough των DAO `countItemsInUseBy*` (Βήμα 2) με `_guard` →
  `DataLoadException` (Q3 του Βήματος 2· repos = error-mapping μόνο, §2.3:276).
  Το `countItems` (confirm cascade) μένει για το Βήμα 4 (YAGNI).
- ΝΕΟ `lib/data/models/category_tree_node.dart`: `CategoryTreeNode`
  record typedef (pattern `ReceiptSummary`, όχι Freezed).
- `settings_providers.dart` (91→179 γρ.): `categoryTreeStreamProvider`
  (in-memory σύνθεση των 2 catalog streams, `Stream.value` + `Stream.empty`
  — ΚΑΝΕΝΑ νέο DB query) + `canDeleteCategoryProvider` /
  `canDeleteSubCategoryProvider` (`FutureProvider.family<bool,int>`, οι
  πρώτοι `FutureProvider` της εφαρμογής). Χωρίς logging (κανόνας
  stream_providers). NON-autoDispose.

## 3. Ευρήματα (εκτέλεση, όχι θεωρία)

- **Ε1 — `.future`+throwsA δεν δουλεύει σε error-paths (Riverpod 3 retry).**
  Πρώτο run: 38/41 — τα 3 error tests hangάρισαν μέχρι timeout ενώ τα
  repo-level mapping tests περνούσαν. Διάγνωση με προσωρινό test (σβήστηκε):
  το repo ρίχνει σωστά `DataLoadException`, αλλά το Riverpod 3 ξαναπροσπαθεί
  αυτόματα τα αποτυχημένα futures (`AsyncLoading ... retrying`, 4 εκπομπές
  σε 2s) και το `.future` δεν ολοκληρώνεται ποτέ. Fix: error-path tests με
  listen+completer (`hasError`) — νέο precedent κώδικα, τεκμηριωμένο στο
  docstring του `canDeleteCategoryProvider`.
- **Ε2 — το tree κατάπινε σφάλματα (πραγματικό bug παραγωγής).** Στο retry
  το upstream μένει `AsyncLoading` με συνημμένο σφάλμα και το σκέτο `.when`
  παίρνει το `loading` branch → `Stream.empty()` → infinite loading σε
  μόνιμη βλάβη (διαγνώστηκε: tree έμεινε γυμνό `AsyncLoading` χωρίς error).
  Fix: προτεραιότητα `hasError && !hasValue` → `Stream.error` (με τιμή
  κρατά τη σύμβαση loading της εφαρμογής).
- **Ε3 — `AsyncValueView` δεν υπάρχει** (μόνο docstring-αναφορές)· το Βήμα 4
  θα δείξει σφάλματα με `AsyncValue.when` (§2.2:219). `ConfirmDialog`
  υπάρχει — reuse Βήματος 4 ισχύει.

## 4. Tests (782 → 805, +23)

- Repo groups (+4/+4): 0 / N / απομόνωση / ανύπαρκτο→0 / `Future.error`-double
  → `DataLoadException` (όχι κλειστή-βάση — εύθραυστο).
- ΝΕΟ `test/data/providers/category_guard_providers_test.dart` (15):
  canDelete×2 (καθαρό→true· είδη χωρίς γραμμές→true· με γραμμές→false·
  απομόνωση· άγνωστο→true· failing-override→DataLoadException) + tree
  ([]· nesting+αλφαβητικά· node με []· live re-emit· failing-override→
  DataLoadException). `flutter analyze` No issues ✓ · `flutter test`
  **805/805** ✓ · BOM=False · κανένα αρχείο >500 γρ.

## 5. Συμβόλαια για Βήμα 4

- `ref.invalidate(canDelete*(id))` μετά από CRUD σε είδη/γραμμές
  (stale one-shot bool, IndexedStack).
- Tree rebuild → στιγμιαίο loading-with-value → UI με `skipLoadingOnReload`.
- Ανοιχτό: σύγκρουση tooltip (κλειδωμένη Α2-1 «νέο string» vs §2.3:279
  `itemCountTooltip`).

## 6. Επόμενο

Βήμα 4 — SettingsPage + category tree editor (μόνο με ρητό OK).
