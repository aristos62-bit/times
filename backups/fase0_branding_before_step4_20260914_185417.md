# Κεφάλαιο 1 — Φάση 0: Θεμελίωση Project & Branding

> Στατική αναφορά. Δεν ξαναγράφεται. Ημερομηνία έναρξης: 13-09-2026 · Κατάσταση: **Κλειστό**.

---

## 1. Απόφαση δομής Old Sessions

- Συμφωνήθηκε προτεινόμενη δομή: root = πλοήγηση/σύνοψη, κεφάλαια = λεπτομέρειες σε `oldsessions/`.
- Ενσωματώθηκαν 2 προτάσεις:
  1. Διόρθωση ιστορικού μέσω εγγραφών `CORRECTION` (ποτέ ξαναγράψιμο παλιού αρχείου).
  2. TOC με ημερομηνία έναρξης + κατάσταση («ανοιχτό/κλειστό») ανά κεφάλαιο.

---

## 2. Επανεξέταση DESIGN.md (review βελτιώσεις)

Ο χρήστης ζήτησε ειλικρινή αξιολόγηση του σχεδίου · εφαρμόστηκαν οι εξής αλλαγές στο `DESIGN.md` (αρχείο στο root του project):

1. **Φάση 5, βήμα 3** — Ρητή απαίτηση: ρητά constraints σε fl_chart (legends/labels να μην κόβονται σε στενά/φαρδιά containers) + **fallback σε πίνακα/λίστα** όταν το γράφημα δεν χωράει.
2. **Φάση 3, βήμα 7** — Placeholder read-only λίστα αποδείξεων (vertical slice) πριν τη Φάση 5 · τα widget tests μετακινήθηκαν στο βήμα 8.
3. **§2.3 Backup/Restore** — Naming με timestamp `times_backup_YYYYMMDD_HHmmss.db` + **υποχρεωτικό auto-backup πριν από κάθε Restore**. Weekly backup → σημειωμένη μελλοντική επέκταση (Φάση 6), όχι MVP.
4. **§3 receiptNumber** — Απόφαση: χρήση του internal `INTEGER PRIMARY KEY AUTOINCREMENT` id (προσωπική εφαρμογή, τρύπες στην αρίθμηση δεν είναι πρόβλημα). Δεν χρειάζεται sequence table/counter. Ενημερώθηκε και η ορολογία της §2.2.
5. **§2.2** — Ενημέρωση ορολογίας αυτόματου αριθμού απόδειξης για συνέπεια με την απόφαση του §3.

---

## 3. Φάση 0 · Βήμα 1 — Ρύθμιση pubspec.yaml

Εξετάστηκε αναλυτικά το πλάνο · έγκριση χρήστη για **πλήρες σύνολο**.

**Runtime dependencies** (φέρθηκαν στις τελευταίες εκδόσεις εκείνη τη στιγμή):
`drift ^2.35.0`, `drift_flutter ^0.3.1`, `flutter_riverpod ^3.4.3`, `go_router ^18.0.1`, `fl_chart ^1.2.0`, `shared_preferences ^2.5.5`, `file_picker ^12.3.0`, `freezed_annotation ^3.1.0`, `json_annotation ^4.12.0`.

**Dev dependencies:**
`drift_dev ^2.35.0`, `build_runner ^2.16.1`, `freezed ^4.0.1`, `json_serializable ^6.14.1`.

**Αναβάθμιση στο maximum** — `flutter pub upgrade` έφερε τις μεταβατικές `code_assets 2.0.0`, `hooks 2.2.0`, `meta 1.19.0`, `native_toolchain_c 0.19.4`, `objective_c 9.6.0`, `record_use 1.1.1`, `process 5.0.6`.

**Κλειδωμένα στην παλαιότερη έκδοση (μη αναβαθμίσιμα):**
- `material_color_utilities`, `test_api` — κλειδωμένα από Flutter SDK / `flutter_test`.
- `cli_util` — αρχικά κλειδώθηκε από build_runner chain · αργότερα υποβαθμίστηκε σε 0.4.2 από constraint του `flutter_native_splash`.

> **Παραδοχή**: οι άμεσες εξαρτήσεις ήταν ήδη τελευταίες · η "αναβάθμιση όλων" αφορούσε κυρίως μεταβατικές.

---

## 4. Φάση 0 · Βήμα 2 — Branding

### 4.1 Αποφάσεις χρήστη
- **Όνομα**: «Τιμές» παντού (UI label Android/iOS/Web/Windows) · «Times» παραμένει μόνο ως τεχνικό package name.
- **Description**: Αγγλικό — *"Personal expense & receipt tracking with price history and store comparisons."*
- **Package ID**: `com.app.times` (εφαρμόστηκε σε όλες τις πλατφόρμες).
- **Χρωματική κατεύθυνση**: Teal seed (`#00897B`) — για απόσταση από τα trend colors (πράσινο=πτώση, κόκκινο=άνοδος). Surfaces από ColorScheme, όχι custom greys.
- **Λογότυπο**: υπάρχον αρχείο `assets/icons/Times.png` (1254×1254).

### 4.2 Αλλαγές ανά πλατφόρμα
- `pubspec.yaml`: description + config `flutter_launcher_icons` (android, ios, web, windows, macos, linux) + `flutter_native_splash` (teal #00897B). Εργαλεία: `flutter_launcher_icons 0.14.4`, `flutter_native_splash 2.4.8`.
- **Android**: `namespace` & `applicationId` → `com.app.times` · `android:label="Τιμές"` · `MainActivity.kt` μετακινήθηκε σε `kotlin/com/app/times/` + `package com.app.times`.
- **iOS**: `CFBundleDisplayName`/`CFBundleName` = «Τιμές» · `PRODUCT_BUNDLE_IDENTIFIER` → `com.app.times` (6 σημεία στο pbxproj, συμπ. RunnerTests).
- **macOS**: `PRODUCT_BUNDLE_IDENTIFIER` → `com.app.times` + `PRODUCT_COPYRIGHT` → «Τιμές» · `Info.plist` + `CFBundleDisplayName` «Τιμές» · pbxproj RunnerTests → `com.app.times`· `APPLICATION_ID` → τόσο στο CMakeLists.txt του linux όσο και στα σχετικά αρχεία.
- **Web**: `manifest.json` name/short_name «Τιμές», colors → `#00897B`, description EN · `index.html` title/meta/description «Τιμές» + splash εισήχθη αυτόματα από flutter_native_splash.
- **Windows**: `main.cpp` window title «Τιμές» · `Runner.rc` CompanyName/FileDescription/ProductName/LegalCopyright «Τιμές».
- **Linux**: `APPLICATION_ID` → `com.app.times`.
- `README.md`: τίτλος «Τιμές (Times)» + περιγραφή EN/EL.

### 4.3 Εκτελέσεις
- `dart run flutter_launcher_icons` ✅ (Android, iOS, Web, Windows, macOS).
- `dart run flutter_native_splash:create` ✅ (Android styles v31/night, iOS, Web).
- `flutter analyze` ✅ No issues.

### 4.4 Εκκρεμές
- Τελικό `flutter build apk --debug` **διακόπηκε** (αργό πρώτο Gradle build · native plugins drift/sqlite κάνουν C/C++ compilation). Πρέπει να ολοκληρωθεί για verification.

> **CORRECTION 13-09-2026:** Το build πραγματοποιήθηκε εκ νέου και **ολοκληρώθηκε επιτυχώς** — `flutter build apk --debug` ✓ (18.3s, `build\app\outputs\flutter-apk\app-debug.apk`). Οι WARNING του Gradle (`java.lang.System::load`, native access) είναι αναμενόμενες κατά τον κατ' εκτίμηση συμβατές JDK/Gradle daemon και δεν επηρεάζουν το artifact. Το κρύο Gradle cache έφτιαξε, επόμενα builds θα είναι ταχύτερα.

---

## 5. Σημειώσεις / Προσθήκες για μελλοντικά sessions

- Το `DESIGN.md` είναι στο **root του project** (`C:\Users\Vaggelis\Flutter Projects\times\DESIGN.md`), όχι στο Desktop.
- Ελέγξτε αν το `flutter build apk --debug` ολοκληρώνεται (η κρύα Gradle cache δεν υπάρχει ακόμα · θα φτιάξει μετά το πρώτο build).
- Το `cli_util` υποβαθμίστηκε λόγω `flutter_native_splash` — δεν είναι πρόβλημα, σημειώνεται για ιστορικό.

---

## 6. Φάση 0 · Βήμα 6 (ολοκλήρωση) — `app_feedback.dart`

> Ημερομηνία: 14-09-2026. Append στο κεφάλαιο (η φάση 0 παραμένει ένα κεφάλαιο).

- Υλοποιήθηκε το SPoT wrapper `lib/core/utils/app_feedback.dart` (DESIGN §2.0.6 / §2.4) — μόνο `showSuccess(context, msg)` και `showError(context, msg)`, ό,τι ορίζει ρητά το DESIGN, με μοναδική private `_show`.
- **Συμπεριφορά**: διάρκεια από `AppConstants.snackBarDurationSeconds` · `context.mounted` + `ScaffoldMessenger.maybeOf` guards (no-op χωρίς scaffold/unmounted — κανένα crash) · error → `colorScheme.errorContainer`/`onErrorContainer` + `clearSnackBars()` (άμεση εμφάνιση, όχι ουρά) · success → Material default χρώματα, χωρίς clear (μπαίνει στην ουρά) · `SnackBarBehavior.floating` (responsive, §1.4) · `maxLines` safety net (§1.4).
- **Προστέθηκαν 1 SPoT σταθερά** στο `app_constants.dart`: `maxFeedbackLines = 3` (αριθμητική σταθερά μόνο — όχι αλλαγή αρχιτεκτονικής → DESIGN.md **δεν** άλλαξε, κανόνας 8).
- **Debug — Επιλογή Α**: το util υλοποιήθηκε χωρίς logging (app_logger κενό, Βήμα 5 εκκρεμεί). Στο Βήμα 5 θα προστεθεί 1–2 γραμμές `AppLogger` (tag `UI`) στη `_show`.
- **Tests**: `test/core/utils/app_feedback_test.dart` με **8 widget tests** — success/error εμφάνιση, error colors από ColorScheme, no-op χωρίς messenger, clear στο error, queue στο success, auto-dismiss μετά το SPoT duration, overflow-safe σε στενή οθόνη 320×480, κλήση μετά από unmount. Suite συνολικά **31/31** ✓ · `flutter analyze` **No issues** ✓.
- **Τεχνικό**: τα timing-tests του SnackBar χρειάζονται 2 ξεχωριστά `pump` — το entry animation ολοκληρώνεται πριν ξεκινήσει ο auto-hide timer (helper `_elapseSnackBarLife`).
- **Διόρθωση naming**: το backup `.dart` του app_constants μετονομάστηκε σε lower_case (`maxfeedbacklines`) για συμμόρφωση με τον `file_names` lint.

---

## 7. Φάση 0 · Βήμα 5 — `app_logger.dart` + `debug_config.dart`

> Ημερομηνία: 14-09-2026. Append στο κεφάλαιο (η φάση 0 παραμένει ένα κεφάλαιο).

- Υλοποιήθηκε το SPoT config `lib/core/debug/debug_config.dart` (DESIGN §1.7):
  - `enum LogTag { db, ui, nav, stats, backup }` — ορίζεται στο **config**, όχι στον logger, ώστε η εξάρτηση να είναι μονοκατεύθυνση `logging → debug` (καμία circular dependency) και τα exceptions (Βήμα 4, TODO "logging tag") να παίρνουν το tag από εδώ χωρίς «import μόνο για ένα enum».
  - `isEnabled = kDebugMode && !_forceDisabled` — release build: κανένα log, compile-time tree-shaking.
  - `enabledTags` (const set με τα 5 tags) — ενεργοποίηση/απενεργοποίηση ανά κατηγορία μέσω edit της σταθεράς.
  - `isTagEnabled(tag)` + `@visibleForTesting forceDisable()/reset()`.
  - Tests: `test/core/debug/debug_config_test.dart` — 4 cases.
- Υλοποιήθηκε ο SPoT logger `lib/core/logging/app_logger.dart`:
  - `info(LogTag, String)` → `[TAG] μήνυμα` · `error(LogTag, String, [error, stack])` → `[TAG][ERROR] μήνυμα | error` + stack.
  - `_shouldLog` = non-empty && `DebugConfig.isTagEnabled` → ποτέ exception, μόνο no-op.
  - Έξοδος `(_testSink ?? debugPrint)(line)` · `testSink` `@visibleForTesting` (String sink) · `resetTestSink()`.
  - `export .. show LogTag` — ένα import για logger+tag σε όλους τους καταναλωτές.
  - `debugPrint` (όχι `print`· lint `avoid_print`), τεμαχίζει μεγάλα μηνύματα/stack.
  - Tests: `test/core/logging/app_logger_test.dart` — 7 cases (info, error±error-object, κενό message, forceDisable, formatting 5 tags, ποτέ throw με 10k chars).
- **Hook στο `app_feedback._show`** (απόφαση Επιλογή Α, §6): error→`AppLogger.error(LogTag.ui, ...)`, success→`AppLogger.info(LogTag.ui, ...)`, μετά τους guards (log μόνο όταν πραγματικά εμφανίζεται). Regression widget test: snackbar εμφανίζεται ΚΑΙ sink λαμβάνει `[UI][ERROR] Snackbar σφάλματος εμφανίστηκε`.
- **Διορθώσεις κατά την υλοποίηση**:
  - `analysis_options.yaml`: προστέθηκε `backups/**` στο `analyzer.exclude` — τα backup `.dart` αρχεία (με relative imports) προκαλούσαν errors στον analyzer.
  - `AppLogger.testSink` δέχεται `String` (όχι `Object?`) — η έξοδος είναι πάντα String.
- **DESIGN.md doc-fix** (εγκεκριμένο): γραμμή 80 `logging/debug_config.dart` → `debug/debug_config.dart` (η δομή §1.2 δείχνει `debug/`, το αρχείο υπήρχε ήδη εκεί). Καμία αρχιτεκτονική αλλαγή.
- **Σύνολο suite**: **43/43** tests ✓ (31 + 4 debug_config + 7 app_logger + 1 regression) · `flutter analyze` **No issues** ✓.
- **Backups** (`backups/`): `app_logger_before_step5_20260914_135833.dart`, `debug_config_before_step5_20260914_135833.dart`, `app_feedback_before_step5_20260914_135833.dart`, `app_feedback_test_before_step5_20260914_135833.dart`, `DESIGN_before_step5_20260914_135833.md`, `oldsessions_before_step5_20260914_135833.md`, `fase0_branding_before_step5_20260914_135833.md`.

---

## 8. Φάση 0 · Βήμα 4 SPoT — `app_strings.dart`

> Ημερομηνία: 14-09-2026. Append στο κεφάλαιο (η φάση 0 παραμένει ένα κεφάλαιο).

- **Γέμισμα `lib/core/constants/app_strings.dart`** (DESIGN §0, §2.1, §2.2) — 11 SPoT strings σε `abstract final class` (pattern AppConstants):
  - §0: `appTitle = 'Τιμές'` — branding (MaterialApp.title + AppBar).
  - §2.1: `noPricesForPeriod`, `retryButton` — empty/error states.
  - §2.2: `saveReceipt`, `addReceiptLine`, `fieldDate`, `fieldSupplier`, `fieldQuantity`, `fieldPrice` — φόρμα εισαγωγής.
  - Template (προσωρινό, αφαιρείται στη Φάση 3): `counterInstruction`, `counterIncrementTooltip`.
  - Οι 4 field labels (Ημερομηνία/Προμηθευτής/Ποσότητα/Τιμή) είναι συναγωγή από τη ροή/state machine §2.2, όχι ρητά σε εισαγωγικά στο DESIGN — χαμηλού ρίσκου, τεκμηριωμένη απόφαση.
  - Δεν δημιουργήθηκε `fieldUnit` («Μονάδα») — το DESIGN δεν ορίζει ρητό label.
  - Τα `noPricesForPeriod`, `retryButton`, `saveReceipt`, `addReceiptLine`, `appTitle` επαληθεύτηκαν λέξη-προς-λέξη με DESIGN.
- **`lib/main.dart` swap** — 4 hardcoded strings αντικαταστάθηκαν:
  - `'Flutter Demo'` → `AppStrings.appTitle`
  - `'Flutter Demo Home Page'` → `AppStrings.appTitle`
  - `'You have pushed the button this many times:'` → `AppStrings.counterInstruction`
  - `'Increment'` → `AppStrings.counterIncrementTooltip`
  - Προστέθηκε init log: `AppLogger.info(LogTag.ui, 'Εφαρμογή «Τιμές» ξεκίνησε')` (dev-facing, tag UI, ίδιο pattern με app_feedback hook).
- **Regression lock** στο `test/widget_test.dart`: `expect(find.text(AppStrings.appTitle), findsOneWidget)` — κλειδώνει το swap (η AppBar δείχνει το appTitle).
- **`test/core/constants/app_strings_test.dart`** — 8 unit tests (plain `test()`, χωρίς widget pump):
  1. `appTitle == 'Τιμές'`
  2. `noPricesForPeriod` ακριβές κείμενο
  3. `retryButton == 'Επανάληψη'`
  4. `saveReceipt == 'Αποθήκευση Απόδειξης'`
  5. `addReceiptLine == 'Προσθήκη γραμμής'`
  6. Field labels (4)
  7. Καθολικός έλεγχος: μη-κενά, χωρίς whitespace στα άκρα, χωρίς `\n` (loop πάνω σε `_allStrings` list — χειροκίνητα maintained)
  8. Template counter strings — ελληνικά (όχι default Flutter)
- **Σύνολο suite:** **51/51** ✓ (31 + 4 debug_config + 7 app_logger + 1 regression-widget + 8 app_strings) · `flutter analyze` **No issues** ✓.
- **Δεν άλλαξε DESIGN.md** — καμία αρχιτεκτονική αλλαγή (κανόνας 8): το §1.1 ήδη ορίζει app_strings, το content είναι υλοποίηση σχεδιασμού, όχι νέα απόφαση.
- **Backups** (`backups/*_before_step4_20260914_145925.*`): `app_strings`, `main`, `widget_test`, `oldsessions.md`, `fase0_branding.md`.

---

## 9. Φάση 0 · Βήμα 4 SPoT — `app_messages.dart`

> Ημερομηνία: 14-09-2026. Append στο κεφάλαιο (η φάση 0 παραμένει ένα κεφάλαιο).

- **Γέμισμα `lib/core/constants/app_messages.dart`** (DESIGN §2.2, §2.3, §2.4) — 6 SPoT const + 1 method, σε `abstract final class` (pattern AppConstants):
  - SnackBar success: `savedReceipt = 'Αποθήκευση επιτυχής'` (§2.2, αναφέρεται ήδη στο app_feedback.dart docstring γραμμή 5), `restoreSuccess = 'Η επαναφορά ολοκληρώθηκε'` (§2.3).
  - Confirm dialog defaults (§2.4 «ConfirmDialog — τίτλος/μήνυμα/actions από παραμέτρους, SPoT strings»): `confirmDialogTitle = 'Επιβεβαίωση'`, `confirmDialogConfirm = 'Ναι'`, `confirmDialogCancel = 'Ακύρωση'`.
  - Confirm message: `exitUnsavedConfirm = 'Έχετε μη αποθηκευμένες γραμμές. Έξοδος χωρίς αποθήκευση;'` (§2.2.221, PopScope/onExit φόρμας).
  - **Dynamic tooltip (η μόνη method, όχι const)**: `static String itemCountTooltip(int count)` → `'Δεν μπορεί να διαγραφεί: περιέχει $count είδη'` (§2.3.252). Σκόπιμη παραβίαση του `static const String` pattern για δυναμικό περιεχόμενο — τεκμηριωμένη σε doc comment.
- **Δεν συμπεριλήφθηκαν** (ελέγχθηκαν & απορρίφθηκαν):
  - `noPricesForPeriod`, `retryButton`, `saveReceipt` (κουμπί), `addReceiptLine` — ήδη στο `AppStrings` (static labels).
  - `saveFailed`, `dbError`, `backupFailed`, `restoreFailed` — ανήκουν στο `app_errors.dart` (error flow, επόμενο).
- **`test/core/constants/app_messages_test.dart`** — 10 unit tests (plain `test()`, χωρίς widget pump):
  1. `savedReceipt == 'Αποθήκευση επιτυχής'`
  2. `restoreSuccess == 'Η επαναφορά ολοκληρώθηκε'`
  3. `confirmDialogTitle == 'Επιβεβαίωση'`
  4. `confirmDialogConfirm == 'Ναι'`
  5. `confirmDialogCancel == 'Ακύρωση'`
  6. `exitUnsavedConfirm` ακριβές κείμενο (§2.2.221)
  7. `itemCountTooltip(0)` edge case
  8. `itemCountTooltip(5)` typical
  9. pattern check — επιστρέφει String (method, όχι const)
  10. Καθολικός έλεγχος: μη-κενά, χωρίς whitespace στα άκρα, χωρίς `\n` (loop πάνω σε `_allConstStrings`)
- **Σύνολο suite:** **61/61** ✓ (51 + 10 app_messages) · `flutter analyze` **No issues** ✓.
- **Δεν άλλαξε DESIGN.md** — καμία αρχιτεκτονική αλλαγή (κανόνας 8).
- **Backups** (`backups/*_before_step4_20260914_180047.*`): `app_messages`, `oldsessions.md`, `fase0_branding.md`.

---

## 10. Φάση 0 · Βήμα 4 SPoT — `app_errors.dart`

> Ημερομηνία: 14-09-2026. Append στο κεφάλαιο (η φάση 0 παραμένει ένα κεφάλαιο).

- **Γέμισμα `lib/core/constants/app_errors.dart`** (DESIGN §2.1, §2.2, §2.3, §2.4) — 5 SPoT const, σε `abstract final class` (pattern AppConstants). Σαρώθηκε ολόκληρο το lib/test πριν την υλοποίηση (μόνο πραγματικά γειωμένα σημεία, μηδέν υποθέσεις):
  - `saveFailed = 'Σφάλμα κατά την αποθήκευση'` (§2.2, αποτυχία αποθήκευσης απόδειξης) — **ενεργοποίησε το placeholder** `AppErrors.saveFailed` στο app_feedback.dart:6 docstring.
  - `loadDataFailed = 'Σφάλμα κατά τη φόρτωση δεδομένων'` (§2.1 error state + §2.4 AsyncValueView generic error — 2+ σημεία → SPoT §1.1).
  - `backupFailed = 'Σφάλμα κατά τη δημιουργία αντιγράφου'` (§2.3 Βήμα 1 Export) — **1 const, 2 σημεία χρήσης**: και Βήμα 3 υποχρεωτικό auto-backup πριν την αντικατάσταση (αποτυχία → ακύρωση restore).
  - `invalidBackupFile = 'Το αρχείο δεν είναι έγκυρο αντίγραφο της βάσης'` (§2.3 Βήμα 2 file validation — SQLite header + πίνακες, καμία αλλαγή στη βάση). Μετονομασία από `restoreInvalidFile` (ακριβέστερο· ορολογία backup).
  - `restoreFailed = 'Σφάλμα κατά την επαναφορά αντιγράφου'` (§2.3 Βήμα 4 αντικατάσταση βάσης).
- **NOTE(Φάση0-Βήμα4)** αντί του TODO σκελετού: validation messages (§2.2:214-218 — ≥1 γραμμή, ≤maxReceiptLines, price/quantity όρια, ακέραια ποσότητα, όνομα/διπλότυπο) **αναβλήθηκαν στη Φάση 3** μαζί με τους validators — μηδέν καταναλωτές τώρα (domain/validators = .gitkeep), κείμενα χωρίς γείωση στο DESIGN (μόνο κανόνες), ρίσκο επαναδιατύπωσης (π.χ. μονάδα ποσότητας). Το NOTE δεσμεύει ρητά το scope.
- **Αποκλείστηκαν & τεκμηριώθηκαν** (ολική σάρωση):
  - Dev-log strings `app_feedback.dart:49,54` ('Snackbar σφάλματος εμφανίστηκε' κλπ.) — dev-facing, pattern §1.3/logger → **δεν** είναι UI SPoT.
  - `deleteFailed` / `searchFailed` — προλαμβάνονται από tooltip+pre-check (§2.3.252) / NOT_FOUND είναι state (§2.2), όχι snackbar.
  - Drift raw exceptions — δουλειά repositories/exceptions (Φάση 1-2).
  - `app_feedback_test.dart` raw strings ('Αποτυχία αποθήκευσης'/'Σφάλμα'/'Αποθηκεύτηκε') — test-data της δοκιμής wrapper, όχι coupling → **δεν άλλαξαν**.
- **Συμμετρία με AppMessages:** `savedReceipt`↔`saveFailed` · `restoreSuccess`↔`restoreFailed`+`invalidBackupFile` · γλωσσικό pattern «Σφάλμα κατά τη/την …».
- **`test/core/constants/app_errors_test.dart`** — 6 unit tests (plain `test()`, pattern app_messages_test):
  1. `saveFailed` == 'Σφάλμα κατά την αποθήκευση'
  2. `loadDataFailed` == 'Σφάλμα κατά τη φόρτωση δεδομένων'
  3. `backupFailed` == 'Σφάλμα κατά τη δημιουργία αντιγράφου'
  4. `invalidBackupFile` == 'Το αρχείο δεν είναι έγκυρο αντίγραφο της βάσης'
  5. `restoreFailed` == 'Σφάλμα κατά την επαναφορά αντιγράφου'
  6. Καθολικός έλεγχος ποιότητας: μη-κενά/χωρίς whitespace/χωρίς `\n` (loop `_allConstStrings`)
- **Σύνολο suite:** **67/67** ✓ (61 + 6 app_errors) · `flutter analyze` **No issues** ✓.
- **Δεν άλλαξε DESIGN.md** — καμία αρχιτεκτονική αλλαγή (κανόνας 8).
- **Backups** (`backups/*_before_step4_20260914_183723.*`): `app_errors`, `oldsessions.md`, `fase0_branding.md`.