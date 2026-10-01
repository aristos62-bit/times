# DESIGN.md — Εφαρμογή "Times" (Τιμές)

> Έγγραφο αρχιτεκτονικής και σχεδιασμού. Ενημερώνεται μετά από κάθε ουσιαστική αλλαγή στην εφαρμογή. Αντικαθιστά πλήρως κάθε προηγούμενη έκδοση/προδιαγραφή.

---

## 0. Ταυτότητα Εφαρμογής

| Στοιχείο | Τιμή |
|---|---|
| Όνομα εφαρμογής | **Τιμές** (διεθνές/τεχνικό όνομα: `Times`) |
| Σκοπός | Προσωπική καταγραφή αγορών/αποδείξεων, παρακολούθηση τιμών ειδών ανά προμηθευτή, στατιστικά και συγκρίσεις τιμών στον χρόνο |
| Πλατφόρμα | Flutter/Dart — Android, iOS, Windows (desktop), Web (προαιρετικά αργότερα) |
| Γλώσσα UI | Ελληνικά (μοναδική γλώσσα, μέσω SPoT strings — όχι hardcoded) |
| Βάση δεδομένων | SQLite μέσω **Drift** (type-safe ORM, ενεργά συντηρούμενο, αντικαθιστά το εγκαταλελειμμένο Isar) |
| State management | Riverpod · **StreamProvider / AsyncNotifier όταν το state εξαρτάται από async πηγή (DB/stream)** — ό,τι χρειάζεται real-time · **plain Notifier όταν το state είναι καθαρά τοπικό/σύγχρονο**, με τα async actions σημειωμένα μέσα στο state (π.χ. `isSaving` flag) |
| Πλοήγηση | GoRouter |
| Θέμα | Light / Dark / Auto (system) |
| Λειτουργία | 100% offline-first, τοπική βάση· "online" = προαιρετικός μελλοντικός συγχρονισμός (δεν είναι στο MVP, σχεδιάζεται ως επέκταση) |
| "Real-time" | UI ενημερώνεται αυτόματα και άμεσα σε κάθε αλλαγή δεδομένων μέσω reactive streams — όχι δικτυακός συγχρονισμός |

**Λογότυπο / branding**: παλέτα (teal seed `#00897B`), εικονίδιο εφαρμογής & splash (`assets/icons/Times.png`), εμφανιζόμενο όνομα «Τιμές», package id `com.app.times`. Καμία σελίδα δεν κυκλοφορεί με προεπιλεγμένο Flutter branding, γενικές περιγραφές τύπου "My App" ή placeholder εικόνες.

---

## 1. Αρχιτεκτονικές Αρχές (Δεσμευτικές για όλο το project)

1. **SPoT (Single Point of Truth) παντού**
   - Κείμενα UI → `lib/core/constants/app_strings.dart`
   - Αριθμητικές/στατικές τιμές (paddings, διάρκειες, όρια) → `lib/core/constants/app_constants.dart`
   - Χρώματα/θέματα → `lib/core/theme/app_theme.dart` + `app_colors.dart`
   - Μονάδες μέτρησης, τύποι κατηγοριών → `lib/core/constants/app_enums.dart` (ή πίνακας στη βάση, βλ. §3)
   - Routes → `lib/core/router/app_routes.dart` (ονόματα/paths ως σταθερές, ποτέ raw strings σε `context.go(...)`)
   - **Κανόνας**: αν μια τιμή/κείμενο/χρώμα εμφανίζεται σε 2+ σημεία ή είναι πιθανό να αλλάξει, πάει σε SPoT αρχείο. Καμία εξαίρεση.

2. **Διαχωρισμός επιπέδων (Clean Layering)**
   ```
   lib/
   ├── core/
   │   ├── constants/   (SPoT: app_constants, app_strings, app_messages, app_errors, app_enums)
   │   ├── theme/       (app_theme, app_colors)
   │   ├── router/      (app_routes, app_router [route definitions + GoRouter], nav_log_observer)
   │   ├── utils/       (debouncer, greek_text_normalizer, app_feedback, dates, line_total)
   │   ├── errors/      (app_exceptions)
   │   ├── logging/     (app_logger)
   │   └── debug/       (debug_config)
   ├── data/
   │   ├── local/       (Drift database, tables, DAOs)
   │   ├── models/      (records: receipt_summary, chart_totals, category_tree_node · καμία Freezed: τα repos επιστρέφουν Drift data classes / records απευθείας)
   │   ├── repositories/(abstract + implementation, μοναδικό σημείο πρόσβασης στη βάση)
   │   └── providers/   (Riverpod DI δέντρο + StreamProviders — η γέφυρα repos → UI)
   ├── domain/
   │   ├── services/    (business logic: στατιστικά, συγκρίσεις τιμών)
   │   └── validators/  (SPoT validators: receipt_validator, name_validator)
   ├── presentation/
   │   ├── home/        (Κεντρική: home_page, controllers/, state/, widgets/) — §2.1
   │   ├── price_entry/ (Εισαγωγή τιμών: price_entry_page, controllers/, state/, widgets/) — §2.2
   │   ├── settings/    (Ρυθμίσεις: settings_page, controllers/, state/, widgets/) — §2.3
   │   └── shared/      (κοινά widgets: SearchableDropdownField, ConfirmDialog, DeleteGateButton, controller_op_runner, ...) — §2.4
   └── main.dart
   ```
   - Το UI **δεν** μιλάει ποτέ απευθείας με τη βάση· περνάει πάντα από Repository → Riverpod Provider → Widget.
   - Κάθε repository εκθέτει `Stream<List<T>>` για ό,τι πρέπει να ενημερώνεται real-time.

3. **Καμία hardcoded τιμή σε UI ή business logic.** Κάθε αριθμός/κείμενο/χρώμα περνάει από SPoT αρχείο (βλ. §1.1).

4. **Responsive & χωρίς overflow παντού**
   - `LayoutBuilder` / `MediaQuery` breakpoints ορισμένα σε `app_constants.dart` (π.χ. `mobileMaxWidth`, `tabletMaxWidth`).
   - Χρήση `Flexible`/`Expanded`/`Wrap`/`SingleChildScrollView` σε κάθε οθόνη — ποτέ σταθερά `SizedBox` ύψη σε λίστες/φόρμες που μπορεί να μεγαλώσουν.
   - Test σε τουλάχιστον 3 μεγέθη οθόνης (μικρό κινητό, tablet, desktop window resize) πριν κλείσει κάθε Phase.

5. **Θέμα**
   - `ThemeMode.system` ως προεπιλογή, με δυνατότητα override από τον χρήστη (Light/Dark/Auto) αποθηκευμένη τοπικά (SharedPreferences).
   - Όλα τα χρώματα από `ColorScheme`, ποτέ raw `Color(0xFF...)` μέσα σε widgets.

6. **Προσβασιμότητα**: `Semantics` labels σε όλα τα interactive στοιχεία (πεδία, κουμπιά, dropdowns), ιδίως στη φόρμα εισαγωγής τιμών.

7. **Logging / Debug**
   - `lib/core/logging/app_logger.dart` — SPoT logger με ομαδοποιημένα tags: `DB`, `UI`, `NAV`, `STATS`, `BACKUP`.
   - Κάθε repository/service καταγράφει: create/update/delete operations, σφάλματα, query results (σε debug mode μόνο).
   - Config αρχείο `lib/core/debug/debug_config.dart` για ενεργοποίηση/απενεργοποίηση ανά κατηγορία log.
  - Global handlers (`main.dart`): `FlutterError.onError` + `PlatformDispatcher.onError` → log + present — hook για μελλοντικό crash reporting (release: σιωπή by design).

8. **Testing**
   - `test/` mirror του `lib/` δέντρου.
   - Unit tests: repositories, services (στατιστικά, price comparison logic), validators.
   - Widget tests: φόρμα εισαγωγής τιμών (πιο κρίσιμη οθόνη), search/autocomplete λογική.
   - Στόχος: **>80% coverage** μέσω `flutter test --coverage`.
   - Κάθε νέο feature σε κάθε Phase συνοδεύεται από αντίστοιχα tests πριν κλείσει η φάση.

9. **Backup/Restore**
   - Export ολόκληρης της SQLite βάσης σε αρχείο `.db` (ή JSON export ως εναλλακτική, ανθρωπίνως αναγνώσιμη) σε επιλεγμένο φάκελο συσκευής.
   - Restore με επιβεβαίωση (προειδοποίηση αντικατάστασης τρεχόντων δεδομένων) και validation του αρχείου πριν την εισαγωγή.

10. **Καμία αλλαγή στο documentation δεν μένει εκκρεμής** — μετά από κάθε Phase/βήμα ενημερώνονται: `DESIGN.md` (αυτό το αρχείο), `AGENTS.md` (κανόνες συνεργασίας), τυχόν `oldsessions.md`.

---

## 2. Αρχιτεκτονική Οθονών (Λεπτομερής)

### 2.0 Κοινό Πρότυπο ανά Οθόνη (δεσμευτικό για όλες τις σελίδες)

Κάθε σελίδα ακολουθεί **την ίδια** εσωτερική δομή, ώστε να μην αποφασίζουμε ξανά αρχιτεκτονική σε κάθε Phase:

```
presentation/<screen>/
├── <screen>_page.dart          -- ConsumerWidget, ΜΟΝΟ layout/σύνθεση, καθόλου business logic
├── controllers/
│   └── <screen>_controller.dart -- Notifier/AsyncNotifier, όλη η λογική & state (επιλογή βάσει κανόνα, §2.0)
├── state/
│   └── <screen>_state.dart      -- Freezed immutable state class
└── widgets/
    └── ...                       -- μικρά, "χαζά" (dumb) widgets· παίρνουν δεδομένα από το page, δεν διαβάζουν providers μόνα τους (εκτός αν είναι self-contained, π.χ. search field)
```

**Κανόνες που ισχύουν παντού (αποτρέπουν τα πιο συνηθισμένα λάθη):**

1. **Ένα state, τέσσερις καταστάσεις.** Κάθε οθόνη/section με δεδομένα από τη βάση περνάει πάντα από `AsyncValue<T>.when(data:, loading:, error:)` — ποτέ χειροκίνητο `isLoading` bool flag ξεχωριστά από `AsyncValue`. Έτσι loading/empty/error αντιμετωπίζονται ομοιόμορφα παντού.
2. **Naming convention providers** (SPoT και στα ονόματα, όχι μόνο στις τιμές):
   - `xxxRepositoryProvider` → το repository (Provider, singleton)
   - `xxxStreamProvider` → ζωντανή λίστα από repository (StreamProvider)
   - `xxxControllerProvider` → φόρμες/actions · **AsyncNotifierProvider** όταν το state προέρχεται από async πηγή (DB/stream), **plain NotifierProvider** όταν το state είναι καθαρά τοπικό/σύγχρονο με async actions σημειωμένα μέσα στο state (π.χ. `isSaving` flag) — βλ. παράδειγμα `receipt_form_controller` (§2.2)
   - `selectedXxxProvider` → απλή επιλογή UI state (StateProvider), π.χ. φίλτρο
3. **Debounce σε ΚΑΘΕ text input που πυροδοτεί query** (όχι μόνο στην αναζήτηση ειδών) — χρήση κοινού `Debouncer` util στο `core/utils/debouncer.dart`, με τιμή από `AppConstants.searchDebounceMillis`. Κάθε νέο keystroke **ακυρώνει** το προηγούμενο pending query (αποφυγή race condition: παλιό αργό αποτέλεσμα να "προσπεράσει" νεότερο).
4. **Ελληνικό normalization στην αναζήτηση**: η αναζήτηση ειδών/προμηθευτών/κατηγοριών πρέπει να δουλεύει ανεξαρτήτως τόνων/κεφαλαίων (π.χ. "γαλα" να βρίσκει "Γάλα") και τελικού σίγμα (αδιάφορο σ/ς). SPoT utility `core/utils/greek_text_normalizer.dart` → εφαρμόζεται και στο SQL query (αποθηκευμένη normalized στήλη `normalizedName`, §3) και στο UI input πριν το query φύγει.
5. **Καμία οθόνη δεν διαβάζει repository απευθείας** — πάντα μέσω controller/provider (ισχύει ήδη στο §1.2, το επαναλαμβάνω εδώ γιατί είναι το σημείο που παραβιάζεται πιο εύκολα μέσα σε popup/dialog widgets που "βολεύει" να πάρουν shortcut).
6. **Snackbars/Toasts μόνο μέσω SPoT wrapper** `core/utils/app_feedback.dart` (`AppFeedback.showSuccess(context, msg)` / `showError(...)`) — χρησιμοποιεί `AppConstants.snackBarDurationSeconds`, ώστε να μην ξαναγραφτεί `ScaffoldMessenger.of(context).showSnackBar(...)` σκόρπιο σε 10 σημεία.

---

### 2.1 Κεντρική Σελίδα — Γραφήματα & Στατιστικά

**Σκοπός**: σύνολα δαπανών (καθαρά, μετά έκπτωση §3) ανά περίοδο σε 5 πίτες
με 3D-εφέ + πορεία τιμής είδους (γραμμή) + «Προσαρμογή Οθόνης»
από τον χρήστη (τελευταία γραμμή).

**Γραφήματα (όλα pie, σύνολα €, καθαρά §3)**
1. Ανά προμηθευτή · 2. Ανά κατηγορία · 3. Ανά υποκατηγορία · 4. Ανά τμήμα · 5. Top-10 είδη (κατά σύνολο € · +dropdown μετρικής €/Τεμ/Κιλ/Λτ, persisted — € αμετάβλητο, ποσότητες σε `QtyPieChart` με reuse painter).
6. Πορεία τιμής είδους (γραμμή, καθαρή €/μονάδα §3, όχι πίτα):
επιλογή είδους (search, χωρίς «+») + περίοδος κάρτας· 1 point = 1 γραμμή
(καμία συγχώνευση §2.2:291)· φίλτρο κλειδωμένης μονάδας
(ξένες γραμμές μετριούνται, δεν σχεδιάζονται)· Χ ομοιόμορφα ανά index
(ίδιες ημέρες δεν επικαλύπτονται)· cap 200 νεότερα (Q4).
- 3D = εφέ βάθους (tilt + πάχος φέτας, custom painter `Pie3dPainter`,
  0 νέα packages). Labels ΠΑΝΤΑ δεξιά της πίτας (custom
  legend-στήλη, όχι overlay — αποφυγή κοψίματος §1.4). Ο painter δέχεται
  fractions — αγνωστικός €/ποσότητας.
- Άθροιση στο SQL (`SUM(lineTotalCents) GROUP BY`, top-10 με
  `ORDER BY SUM DESC LIMIT 10`) — ποτέ φόρτωμα γραμμών σε Dart·
  streams (όχι futures) → auto-refresh μετά από save.
  Το DAO επιστρέφει την πλήρη ordered λίστα (χωρίς LIMIT — οι ομάδες
  είναι λίγες, προσωπική χρήση) και το slice top-N + «Λοιπά» γίνεται
  στον provider· το `limit` του `ChartQuery` εφαρμόζεται εκεί
  (SPoT `pieMaxSlices`/`topItemsLimit`).

**Περίοδος ανά γράφημα (Ημέρα/Εβδομάδα/Μήνας/Έτος/Προσαρμοσμένο)**
- Κάθε κάρτα έχει δικό της selector (date-range picker στο Προσαρμοσμένο)·
  default Μήνας (τρέχων). Global φίλτρο ΔΕΝ υπάρχει.
- `PeriodType` (app_enums): day/week/month/year/custom (+
  `DateTimeRange?` για custom, validation from≤to).

**Προσαρμογή Οθόνης (τελευταία γραμμή, collapsible — pattern Ρυθμίσεων)**
- Ανά γράφημα: ορατότητα (switch), περίοδος, σειρά (βέλη πάνω/κάτω).
- Persisted σε SharedPreferences (SPoT keys, pattern theme)·
  default: και τα 6 ορατά, Μήνας, σειρά 1-2-3-4-5-6· corrupt → defaults.

**Δομή αρχείων**
```
presentation/home/
├── home_page.dart                     -- ConsumerWidget, ΜΟΝΟ layout/σύνθεση
├── controllers/
│   └── home_chart_config_controller.dart -- plain Notifier, persisted config
├── state/
│   └── home_chart_config.dart         -- Freezed: ανά γράφημα {visible, order, period} (6 entries)
└── widgets/
    ├── pie_3d_chart.dart              -- generic πίτα 3D-εφέ + legend δεξιά + auto-size
    ├── home_chart_card.dart           -- τίτλος + period selector + AsyncValue states
    ├── chart_state_views.dart         -- shared skeleton/error
    ├── qty_pie_chart.dart             -- πίτα ποσοτήτων + legend (reuse painter)
    ├── top_items_card.dart            -- Top-10 + metric selector
    ├── item_trend_card.dart           -- 6η κάρτα: επιλογή είδους + locked banner + γραμμή + states
    ├── item_trend_chart.dart          -- custom line painter + άξονες + auto-size
    ├── item_trend_fallback_list.dart  -- στενό container safety net, χωρίς σύνολο
    ├── home_customization_section.dart -- «Προσαρμογή Οθόνης» (visibility/period/order)
    └── chart_fallback_table.dart      -- στενό container safety net
```
- Trend-line + bar σύγκρισης + global `period_filter_bar`/`category_filter_chip` → **εκτός scope** (ρητό).

**Providers / ροή δεδομένων**
- `homeChartConfigProvider` (plain Notifier, persisted SharedPreferences — read στο build, save async όπως theme · equality gate).
- `todayProvider` (plain `Notifier<DateTime>`, SPoT τρέχουσα ημέρα dayOnly — `Timer.periodic` SPoT `clockCheckSeconds` + day-gate, rebuild Κεντρικής ΜΟΝΟ σε αλλαγή ημέρας · λύνει stale `now` τα μεσάνυχτα).
- 5 streams ( `supplierTotalsStreamProvider` / `categoryTotalsStreamProvider` / `subCategoryTotalsStreamProvider` / `itemGroupTotalsStreamProvider` / `topItemsStreamProvider`, `.family` ανά `ChartQuery{from,to,limit}`) → repo passthrough (error-mapping μόνο) → DAO aggregations (§3).
- Μετρικές Top-10: `topItemsMetricProvider` (plain `Notifier<TopItemsMetric>`, persisted `topItemsMetricKey`) + `topItemsByUnitProvider` (`autoDispose.family` ανά `TopItemsQtyQuery{from,to,unitId}` → top-10 + «Λοιπά» in-provider) → repo passthrough → `ReceiptDao.watchTopItemsByUnit` (SUM/GROUP, §3).
- Πορεία: `selectedTrendItemProvider` (plain `Notifier<int?>`, persisted `trendSelectedItemKey`) + `itemTrendSearchProvider` (family, LIKE) + `itemTrendProvider` (`autoDispose.family` ανά `ItemTrendQuery{itemId,unitId,from,to}` → split κλειδωμένης μονάδας + cap `trendMaxPoints` in-provider) → repo passthrough → `ReceiptLineDao.watchItemHistory` (§3).
- **Κρίσιμο**: άθροιση στο SQL · totals/τιμές καθαρά (μετά έκπτωση §3) · `formatCents` SPoT προβολή.

**Καταστάσεις κάρτας**
- `loading` → skeleton (όχι κενή κάρτα) · `data` κενό → `noPricesForPeriod` (SPoT) · `error` → `loadDataFailed` + «Επανάληψη» (`ref.invalidate` του family instance).

**Προβλέψεις/παγίδες που αποφεύγουμε ρητά**
- Jank: τοπικό `Consumer` ανά κάρτα (όχι rebuild σελίδας σε αλλαγή φίλτρου — §2.1Perf).
- Πλήθος φετών: top-N + «Λοιπά» (όρια SPoT: pieMaxSlices — suppliers/κατηγορίες/υποκατηγορίες/τμήματα top 8+Λοιπά, είδη top 10+Λοιπά)· χρώματα από `ColorScheme` palette (dark-safe, §1.5).
- Στενό container → fallback πίνακας (όχι overflow/μικροσκοπική πίτα — §1.4 + §4).
- Custom range: from≤to + SPoT όρια (`datePickerFirstYear/LastYear`)· άδειο/άκυρο → empty msg, όχι crash.

---

### 2.2 Σελίδα Εισαγωγής Τιμών (ο πυρήνας της εφαρμογής)

Αυτή είναι η πιο πολύπλοκη οθόνη (πολλαπλά εμφωλευμένα "+" flows) — περιγράφεται ως **state machine**, όχι απλή λίστα βημάτων, ώστε να μην υπάρχει αμφισημία στην υλοποίηση.

**Δομή αρχείων**
```
presentation/price_entry/
├── price_entry_page.dart
├── controllers/
│   ├── receipt_form_controller.dart   -- header (ημερομηνία, προμηθευτής) + λίστα draft γραμμών + save · **plain Notifier** (τοπικό/σύγχρονο state `ReceiptFormState{date, supplier, draftLines[], isSaving}`, async save σημειωμένο με `isSaving`)
│   └── item_search_controller.dart    -- αναζήτηση/επιλογή είδους, ξεχωριστό γιατί έχει δικό του lifecycle (debounce, cancel) · **AsyncNotifier** (αποτελέσματα από DB/stream)
├── state/
│   ├── receipt_form_state.dart        -- Freezed: date, supplier, draftLines[], isSaving
│   └── item_search_state.dart         -- Freezed: query, results[], selectedItem, status(idle/searching/found/notFound)
└── widgets/
    ├── receipt_header_section.dart    -- ημερομηνία + προμηθευτής (με inline "+" νέου προμηθευτή)
    ├── item_search_field.dart         -- το search box με live αποτελέσματα από κάτω
    ├── new_item_flow_dialog.dart      -- popup Κατηγορία→Υποκατηγορία→Τμήμα→Είδος+Μονάδα (βλ. state machine)
    ├── unit_quantity_price_section.dart
    ├── discount_field.dart               -- dumb πεδίο «Έκπτωση» (€/μονάδα, §2.2)
    ├── unit_section_checks.dart          -- part: helpers ανάγνωσης πεδίων (κανόνας 7)
    ├── draft_lines_list.dart          -- οι γραμμές που έχουν προστεθεί στο "καλάθι" της τρέχουσας απόδειξης · αφαίρεση ανά γραμμή με destructive confirm (§2.4)
    ├── save_receipt_button.dart       -- «Αποθήκευση Απόδειξης» (disabled-OR: κενό καλάθι ∨ χωρίς προμηθευτή ∨ isSaving) + feedback
    └── recent_receipts_list.dart      -- λίστα αποδείξεων περιόδου με actions (επεξεργασία + φίλτρο Η/Ε/Μ): #, ημερομηνία, προμηθευτής, #γραμμές, σύνολο € + μολύβι/κάδος · auto-refresh μέσω stream
```

**State machine εισαγωγής γραμμής (item_search_controller)**

```
IDLE  ──(πληκτρολόγηση ≥ searchMinChars)──▶  SEARCHING
SEARCHING ──(βρέθηκαν 1+ αποτελέσματα, ≤ searchResultsLimit)──▶ RESULTS_FOUND
SEARCHING ──(0 αποτελέσματα)──▶ NOT_FOUND
RESULTS_FOUND ──(χρήστης επιλέγει είδος)──▶ ITEM_SELECTED
RESULTS_FOUND ──(χρήστης πατά "+")──▶ NEW_ITEM_FLOW
NOT_FOUND ──(αυτόματα εμφανίζεται "+")──▶ NEW_ITEM_FLOW
NEW_ITEM_FLOW: επιλογή Κατηγορίας [υπάρχουσα ▸ ή "+" νέα] 
             → επιλογή Υποκατηγορίας [υπάρχουσα ▸ ή "+" νέα]
             → επιλογή Τμήματος [υπάρχον ▸ ή "+" νέο]
             → εισαγωγή ονόματος νέου Είδους + ΥΠΟΧΡΕΩΤΙΚΗ μονάδα
             → (save Category/SubCategory/ItemGroup/Item αν χρειάζεται) ──▶ ITEM_SELECTED
ITEM_SELECTED ──▶ κλειδωμένη μονάδα είδους (`Item.defaultUnitId`,
              locked banner, όπως προμηθευτής/είδος §2.4· αλλαγή
              ΜΟΝΟ από Ρυθμίσεις → Είδη· χωρίς `defaultUnitId` το «Προσθήκη»
              μένει ανενεργό με `unitRequired`)
             → Ποσότητα (input τύπου ανάλογα με Unit.allowsDecimal)
             → Τιμή (μοναδιαία — ή ΣΥΝΟΛΟ ποσότητας με τον διακόπτη
               «Συνολική τιμή»: η μοναδιαία παράγεται
               `(total/quantity).round()`, ισχύει για όλες τις μονάδες)
              → Έκπτωση (προαιρετική — ανά μονάδα σε unit-mode, έκπτωση
                ΣΥΝΟΛΟΥ σε total-mode (`discUnit=(D/Q).round()`, guard `0≤disc≤gross`)· τελικό γραμμής `(τιμή−έκπτωση)×ποσότητα`)
             → "Προσθήκη γραμμής" ──▶ γραμμή μπαίνει στο draftLines[] της απόδειξης, το search field καθαρίζει και επιστρέφει σε IDLE (έτοιμο για επόμενο είδος)
             → Prefill (§2.2): είδος με ιστορικό → τιμή+έκπτωση από την
               τελευταία γραμμή (ίδια μονάδα, κενά πεδία, χωρίς typing)
```

**Ροή αποθήκευσης ολόκληρης απόδειξης**
1. Ο χρήστης προσθέτει 1+ γραμμές στο "καλάθι" (`draftLines`) — καμία εγγραφή στη βάση ακόμα.
2. Πατώντας "Αποθήκευση Απόδειξης": validation (§ παρακάτω) → `receipt_form_controller` καλεί repository σε **μία transaction**: insert `Receipt` + όλες οι `ReceiptLine` μαζί (atomicity — είτε όλα είτε τίποτα).
3. Επιτυχία → `AppFeedback.showSuccess` + καθαρισμός φόρμας + refresh του `recent_receipts_list` (αυτόματο, μέσω stream).
4. Αποτυχία (π.χ. σφάλμα βάσης) → `AppFeedback.showError`, τα draft δεδομένα **παραμένουν** στη φόρμα (δεν χάνει ό,τι έγραψε ο χρήστης).

**Λίστα πρόσφατων αποδείξεων (κάτω από το save)**
- Δεδομένα: `ReceiptSummary` projection (record `{id, date, supplierName, lineCount, lineTotalCentsSum}`) από `ReceiptDao.watchSummariesByDay` (ημέρα) / `watchSummariesBetween` (εβδομάδα/μήνας, όρια `resolvePeriodRange`) — ίδιο watch query (`customSelect` + `readsFrom`) πάνω σε **stored** `lineTotalCents` (SPoT §3). Το `(priceCents * quantity).round() == 0` (π.χ. 0,01 € × 0,004) είναι **έγκυρη** γραμμή με σύνολο **0,00 €** — δεν απορρίπτεται.
- Ενημέρωση: `recentReceiptsStreamProvider` (StreamProvider, `autoDispose: false`, όριο `AppConstants.recentReceiptsLimit` = 20, φίλτρο `recentPeriodFilterProvider` Η/Ε/Μ default ημέρα + `todayProvider` για μεσάνυχτα). Επειδή η λίστα παρακολουθεί το stream, **ανανεώνεται αυτόματα μετά από κάθε save** (βήμα 3 παραπάνω).
- Εμφάνιση: `recent_receipts_list.dart` — `SegmentedButton` Η/Ε/Μ (labels `periodDay/Week/Month`) + `AsyncValue.when`: loading (spinner), error (`AppErrors.loadDataFailed` + «Επανάληψη» → `ref.invalidate`), empty (ημέρα → `noReceiptsForDay`, εβδομάδα/μήνας → `noPricesForPeriod`), data (Card + ListTile ανά απόδειξη: subtitle `προμηθευτής · ημερομηνία · #γραμμές`, trailing `formatCents` €). Responsive 3 μεγέθη + dark/light.
- SPoT κείμενα: `AppStrings.recentReceiptsTitle` · `AppMessages.receiptNumber(id)` / `receiptLinesLabel(count)` · κενά: `noReceiptsForDay` (ημέρα) / `noPricesForPeriod` (εβδομάδα/μήνας).
- **Επεξεργασία + διαγραφή**: κάθε γραμμή έχει μολύβι (`editAction` → `loadReceiptForEdit`, φόρτωση date/supplier/drafts στη φόρμα με `editingId`· γεμάτα drafts → confirm `editDiscardDraftsConfirm`) + κόκκινο κάδο (`deleteAction`, `colorScheme.error` → `showConfirmDialog(isDestructive)` + `deleteReceipt`, CASCADE §3). Save σε edit mode → `updateReceiptWithLines` (update κεφαλίδας + αντικατάσταση γραμμών, μία transaction· τα line-ids αλλάζουν, SUM §3) + `receiptUpdated`· banner `receiptNumber(editingId)` + «Ακύρωση» (`cancelEdit`).
- **Συνέπεια (Α1)**: η λίστα είναι **πάντα ορατή** στην PriceEntry → με το `IndexedStack` η σελίδα φορτώνει στο launch και **η βάση ανοίγει στο launch** — κάθε widget test που pump-άρει `PriceEntryPage`/`TimesApp` κάνει override του `recentReceiptsStreamProvider`.

**Validation πριν την αποθήκευση (SPoT validators, `domain/validators/receipt_validator.dart`)**
- Τουλάχιστον 1 γραμμή, όχι πάνω από `maxReceiptLines`.
- `price > validationMinPrice`, `quantity > validationMinQuantity` — σε λειτουργία
  «Συνολικής τιμής» ελέγχεται το πληκτρολογημένο σύνολο με τους
  ίδιους κανόνες ΚΑΙ η παραγόμενη μοναδιαία `(total/quantity).round()` (guard
  0/overflow, ίδια μηνύματα — π.χ. 99999,99 € / 0,001 → `priceTooLarge`).
  Έκπτωση συνόλου: `0≤D≤T` (ίδια μηνύματα — `discountTooLarge`
  όταν D>T) + guard παραγόμενης `discUnit` (στρογγυλοποίηση).
- Αν `Unit.allowsDecimal == false` → `quantity` πρέπει να είναι ακέραιος (απόρριψη 2.5 τεμάχια).
- Όνομα νέας Κατηγορίας/Υποκατηγορίας/Τμήματος/Είδους: όχι κενό, ≤ `maxItemNameLength`, **global UNIQUE `normalizedName`** (καμία επανάληψη ονόματος πουθενά, §3) — `domain/validators/name_validator.dart`.
- **Υλοποίηση**: ο `ReceiptValidator` είναι καθαρός (static, χωρίς UI/DB/logging, εξαρτάται μόνο από `core/constants`, δουλεύει με primitives) και όπως ο `NameValidator` επιστρέφει `String?` — `null` = ΟΚ, αλλιώς SPoT μήνυμα (`AppErrors` ή `AppMessages.receiptLinesLimitReached`)· ΚΑΝΕΝΑ exception (δεν ορίστηκε `ValidationException`). API: `validateUnit` · `validatePriceCents` (σε ΛΕΠΤΑ, §3) · `validateDiscountCents(discount, price)` (`0≤d≤p`, §2.2) · `validateQuantity(q, allowsDecimal:)` · `validateLine` (ποσότητα → τιμή → έκπτωση) · `validateLineCount` · `validateReceipt(hasSupplier, lineCount)` (γραμμές → προμηθευτής) · `isIncompleteNumber(text)` (τελικός διαχωριστής → κανένα σφάλμα «υπό πληκτρολόγηση»). Δεν υπολογίζει `lineTotalCents` — SPoT του `ReceiptLineDao` (§3).
- **Ένας κανόνας, τρεις καταναλωτές**: (1) `unit_quantity_price_section` — inline σφάλμα (`errorText` στα `CurrencyTextField`/`QuantityTextField`, `AppConstants.fieldErrorMaxLines`) ΜΟΝΟ σε μη κενή, ολοκληρωμένη είσοδο + hint μονάδας· (2) `save_receipt_button` — `canSave` από `validateReceipt` + hint `supplierRequired` όταν υπάρχουν γραμμές αλλά όχι προμηθευτής· (3) `receipt_form_controller` — safety-net: το `addDraftLine` αγνοεί άκυρη γραμμή και το `saveReceipt` απορρίπτει ΠΡΙΝ το `isSaving`, και στις δύο περιπτώσεις με log `[UI][ERROR]` και (στο save) `SaveReceiptException` — ο λόγος μένει στο log, το ειδικό μήνυμα φαίνεται inline. Το `DraftReceiptLine.unitAllowsDecimal` (snapshot του `Unit.allowsDecimal`, default `true`) τροφοδοτεί τον κανόνα ακεραιότητας.
- **Ονόματα στο «+»**: προμηθευτής (`receipt_header_section`) → `AppFeedback.showError(nameRequired/nameTooLong)` πριν το DB· Κατηγορία/Υποκατηγορία/Τμήμα στο `new_item_flow_dialog` → inline μήνυμα κάτω από το πεδίο (`nameRequired`/`nameTooLong`/`nameExists`) — ΟΧΙ snackbar μέσα στο dialog (ScaffoldMessenger caveat, §2.4).

**Προβλέψεις/παγίδες που αποφεύγουμε ρητά**
- **Double-tap στο "+" προμηθευτή/είδους**: τοπικός busy-flag στο widget
  (`_isCreating`) + guard στον controller — μια μόνο δημιουργία ανά tap
  (§2.4.1).
- **Διπλότυπος προμηθευτής από το «+»**: ο `createSupplier` του
  `receipt_form_controller` τρέχει exact-match έλεγχο στο `normalizedName`
  (getByNormalizedName §2.0.4) ΠΡΙΝ το insert και — αντί για exception —
  επιστρέφει **record `({Supplier? supplier, bool created})`**: `created=false`
  σημαίνει «υπάρχει ήδη» → ο καλών εμφανίζει το σωστό snackbar
  (`supplierAdded` ή `supplierExists` via `AppFeedback`), χωρίς soft-fail στο
  UNIQUE constraint της βάσης. Το UNIQUE παραμένει το safety-net (αν περάσει,
  `DataLoadException`).
- **Ημιτελής καταχώρηση κατά την έξοδο**: αν ο χρήστης πιέσει system back (Android/iOS) με μη αποθηκευμένες `draftLines`, το `PopScope` της PriceEntryPage μπλοκάρει το pop και εμφανίζει το generic `ConfirmDialog` (§2.4) με *"Έχετε μη αποθηκευμένες γραμμές. Έξοδος χωρίς αποθήκευση;"*. «Ναι» → καθαρισμός φόρμας (`resetForm` + `clearSelection` — ο χρήστης βρίσκει ΚΑΘΑΡΗ φόρμα αν γυρίσει) + άδεια εξόδου· το **επόμενο** system-back ολοκληρώνει την έξοδο — **ΚΑΝΕΝΑ ρητό `pop`**: η σελίδα είναι η μοναδική route της branch (ρητό pop θα έσπαγε το go_router shell). «Ακύρωση»/dismiss → παραμονή, τα drafts μένουν. **Αλλαγή tab ΔΕΝ ενεργοποιεί τον έλεγχο** (IndexedStack κρατά τα drafts σκόπιμα, §2.2:222). Η «άδεια εξόδου» σβήνει ξανά σε νέο draft (`ref.listen`). **Όρια**: κλείσιμο παραθύρου desktop (X/Alt+F4) και browser-close εκτός ελέγχου Flutter (native listener εκτός MVP)· web back = προαιρετικά αργότερα. Το state του controller έχει `autoDispose: false`, ώστε προσωρινή αλλαγή tab να μην σβήσει drafts.
- **Race condition αναζήτησης**: κάθε νέο keystroke ακυρώνει το προηγούμενο pending search (§2.0.3) — αλλιώς ένα αργό query για "γ" μπορεί να εμφανιστεί *μετά* το γρήγορο query για "γάλα" και να δείξει λάθος αποτελέσματα.
- **Διπλή δημιουργία είδους σε γρήγορο double-tap** στο "+": το κουμπί απενεργοποιείται (`isSaving` flag) μέχρι να ολοκληρωθεί το insert.
- **Κλειδωμένη μονάδα είδους**: η μονάδα γραμμής προκύπτει
  ΑΠΟΚΛΕΙΣΤΙΚΑ από το `Item.defaultUnitId` και εμφανίζεται σε locked banner
  (pattern προμηθευτή/είδους §2.4) — καμία χειροκίνητη επιλογή στη φόρμα· η
  αλλαγή γίνεται ΜΟΝΟ από Ρυθμίσεις → Είδη (`ItemEditDialog`), ρητά.
  Το `defaultUnitId` ορίζεται ΥΠΟΧΡΕΩΤΙΚΑ στη δημιουργία
  (dialog «+», §2.4) — είδη χωρίς μονάδα υπάρχουν μόνο από edit-καθάρισμα
  (Ρυθμίσεις) και δεν δέχονται γραμμές (`unitRequired`) μέχρι να οριστεί.
- **Πολλαπλές γραμμές ίδιου είδους στην ίδια απόδειξη** (π.χ. 2 διαφορετικές τιμές/συσκευασίες γάλακτος): επιτρέπεται — δεν κάνουμε merge, κάθε γραμμή είναι ανεξάρτητη.

---

### 2.3 Σελίδα Ρυθμίσεων

**Δομή αρχείων**
```
presentation/settings/
├── settings_page.dart
├── controllers/
│   ├── category_management_controller.dart
│   ├── item_management_controller.dart           (CRUD ειδών)
│   ├── supplier_management_controller.dart   (CRUD προμηθευτών)
│   ├── backup_restore_controller.dart
│   └── statistics_controller.dart            (export αναλύσεων)
├── state/settings_state.dart
└── widgets/
    ├── theme_mode_selector.dart
    ├── app_lock_section.dart                 (dumb switch κλειδώματος, §2.3)
    ├── app_lock_overlay.dart                 (fullscreen overlay + πύλη, §2.3 · +`AppLockBackground` semantics/focus trap)
    ├── app_lock_watcher.dart                 (lifecycle paused/resumed + χάρη, §2.3 · +hide/show desktop)
    ├── statistics_section.dart               (μενού 3 αναλύσεων · split σε parts, κανόνας 7)
    │   ├── statistics_analysis_shared.dart   (part: labels/headers/rows/dropdowns/`_groupDisplay`/`_LedgerError`)
    │   ├── ledger_analysis.dart              (part: 1η ανάλυση καρτέλας + banner + body)
    │   ├── purchases_analysis.dart           (part: 2η ανάλυση αγορών + body)
    │   └── grouped_analysis.dart             (part: 3η ομαδοποιημένη + body)
    ├── catalog_filter.dart                   (dumb φίλτρο καταλόγου 3 επιπέδων, §2.3)
    ├── statistics_table.dart                 (dumb DataTable καρτέλας)
    ├── purchases_table.dart                  (dumb DataTable αγορών, δυναμικές στήλες)
    ├── report_preview_dialog.dart            (preview ομαδοποιημένης + export actions)
    ├── category_tree_editor.dart      -- δέντρο Κατηγορία▸Υποκατηγορία▸Τμήμα με edit/delete εικονίδια
    ├── item_list_editor.dart            -- λίστα Ειδών με αναζήτηση + edit/delete εικονίδια (CRUD ειδών)
    ├── item_edit_dialog.dart            -- dialog επεξεργασίας είδους (όνομα/τμήμα/μονάδα)
    ├── supplier_list_editor.dart      -- λίστα Προμηθευτών με edit/delete εικονίδια
    ├── receipts_management_editor.dart  -- διαχείριση Αποδείξεων (Φάση Β): φίλτρο ημέρας + edit/delete
    └── backup_restore_section.dart
```

**Θέμα** — `data/providers/settings_providers.dart`
(`themeModeProvider` + `settingsRepositoryProvider` + `sharedPreferencesProvider`):
σύγχρονο read, αληθινό zero flash.

**Providers / λογική**
- `themeModeProvider` (Notifier, persisted μέσω `SettingsRepository` πάνω σε SharedPreferences) — read στο `main.dart` (`ConsumerWidget`) για `MaterialApp.router.themeMode`. SPoT: key `AppConstants.themeModeKey`, default `AppTheme.defaultMode` (system), labels `AppStrings` (τίτλος/Φωτεινό/Σκοτεινό/Αυτόματο).
- **Κλείδωμα εφαρμογής**: κάρτα «Ασφάλεια» κάτω από το Θέμα (πάντα ορατή — κρυφή εσωτερικά όταν δεν υποστηρίζεται) + dumb `AppLockSection` (SwitchListTile, ακριβές σχήμα customization §2.1) + fullscreen `AppLockOverlay` (`PopScope` no-back, busy guard §2.4 · timeout SPoT `appLockAuthTimeoutSeconds`=60 σε hang-native → ορατό σφάλμα + retry) + `AppLockBackground` (φόντο εκτός semantics/focus όταν locked) + `AppLockWatcher` (`AppLifecycleListener` pause/resume + hide/show desktop, ΜΟΝΟ κλειδώνει, χάρη `appLockGraceSeconds`) + πύλη στο `builder` του `MaterialApp.router` (σκεπάζει NavigationBar + dialogs). Data: `AppLockController` (plain Notifier, record `{enabled,locked}`, sync read persisted bool + zero-flash locked, auth ΠΡΙΝ persist, επιστρέφει record για `runControllerOp`) + `BiometricGate` wrapper (`local_auth`, fallback PIN, `persistAcrossBackgrounding`, `getAvailableBiometrics` ποτέ· σφάλματα πλατφόρμας → `LocalAuthException` → ορατό `appLockFailed`, ακύρωση → σιωπή) σε ξεχωριστό `app_lock_providers.dart` (κανόνας 7). SPoT +2/+5/+1 error/+2 messages/+3 consts (0 χρώματα/tags). Android: `MainActivity : FlutterFragmentActivity` (απαίτηση `local_auth_android`, αλλιώς `uiUnavailable`).
- `categoryTreeStreamProvider` (StreamProvider) → live δέντρο Κατηγορία ▸ Υποκατηγορία ▸ Τμήματα.
- `suppliersStreamProvider` (StreamProvider) → live λίστα Προμηθευτών για τον supplier editor (reuse — κανένα νέο query).
- Sections «Κατηγορίες»/«Προμηθευτές» collapsible: `ExpansionTile` κλειστά by default — καθαρή είσοδος· tap δείχνει τον editor (ίδια widgets, §2.4).
- `canDeleteCategoryProvider` / `canDeleteSubCategoryProvider` / `canDeleteItemGroupProvider` (`FutureProvider.family<bool, int>`) → **προ-έλεγχος** (μετράει συνδεδεμένα Items/ReceiptLines) πριν καν εμφανιστεί ενεργό το εικονίδιο διαγραφής.
- `canDeleteSupplierProvider` / `receiptCountSupplierProvider` (`FutureProvider.family`) → προ-έλεγχος προμηθευτή (`countBySupplierId == 0`, RESTRICT §3).
- Scope CRUD: **Κατηγορίες/Υποκατηγορίες/Τμήματα + Προμηθευτές + Είδη** — το cascade καθαρίζει orphan Items σε transaction ως side-effect. Τα είδη έχουν δικό τους editor (αναζήτηση forked §2.4 + full edit + πύλη `countLinesByItemId`)· η μετακίνηση είδους ανανεώνει τις πύλες παλιάς/νέας κατηγορίας. Οι προμηθευτές ΔΕΝ έχουν cascade (RESTRICT §3 — μόνο καθαροί διαγράφονται)· η μετονομασία τους φαίνεται αυτόματα στις αποδείξεις (join). Το FK `RESTRICT` του §3 παραμένει· οι count/cascade queries ζουν στα **DAOs** (repos = error-mapping μόνο).
- **Διαχείριση αποδείξεων (Φάση Β)**: section «Αποδείξεις» (collapsible Card) — φίλτρο ημέρας (`selectedReceiptDayProvider`, null = όλες· `receiptsByDayStreamProvider`) + λίστα συνόψεων (shared `ReceiptSummaryTile`) + μολύβι (load + `goNamed` Εισαγωγή, reuse controller Φάσης Α) + κάδος (confirm + CASCADE). Data: `ReceiptDao.watchSummariesByDay` (WHERE ημέρας) + `manageReceiptsLimit` (100)· SPoT +3/+1.
- **Στατιστικά**: section «Στατιστικά» (collapsible Card, Θέμα → Στατιστικά → Είδη) — μενού αναλύσεων + detail (όχι στοίβα — κλιμακώνεται· 1η ανάλυση «Ιστορικό αγορών είδους»): είδος (search, τοπικό state, όχι persist) + περίοδος (`PeriodType`/`ChartPeriodSelector`/`resolvePeriodRange`, reuse Home) + dumb `StatisticsTable` (8 στήλες, footer Σύνολο) + export XLSX/PDF (`StatisticsController` + `StatisticsExportService` + `BackupFilePicker.saveBytes`, deps `excel`/`pdf`, fonts `assets/fonts`). Data: `ReceiptLineDao.watchItemLedger` (joins receipts+suppliers+units) + `itemLedgerProvider` (cap `statsTableMaxRows`)· SPoT consts/strings/messages +1 error (`statsExportFailed` → `StatsExportException`, tag `stats`).
- **Συνολικές αγορές (2η ανάλυση)**: γραμμές-αγορές περιόδου (όλα τα είδη) + ταξινόμηση (`PurchasesSort`: Ημ/νία↑↓/Προμηθευτής/Κατηγορία + tiebreak, στο SQL) + dumb `PurchasesTable` (δυναμικές στήλες μονάδων από ΒΔ + Τιμή/Έκπτωση/Σύνολο/Καθαρή + footer sums/μονάδα + σύνολο) + export (ίδιος controller/service — κοινός πυρήνας workbook, filename slug `_synola`). Data: `watchPeriodPurchases` (8-table join) + `periodPurchasesProvider` ({rows,truncated}). **Φίλτρο καταλόγου**: dumb `CatalogFilterField` (Κατηγορία→Υποκατηγορία→Τμήμα, `SearchableDropdownField` show-all + `onCleared`, κενό = Όλα, αλλαγή γονέα μηδενίζει παιδιά, παιδί disabled με hint χωρίς γονέα, τοπικό state όχι persist) — shared 2η/3η ανάλυση · 3 nullable ids στο `PeriodPurchasesQuery` → προαιρετικά SQL WHERE (`c/sc/ig`, null = Όλα) · ισχύει σε οθόνη + export.
- **Ομαδοποιημένη αναφορά (3η ανάλυση)**: μενού + detail (period/sort/group + «Προεπισκόπηση») + preview dialog (grand banner + sections [header + `PurchasesTable`/ομάδα] + Excel/PDF/Κλείσιμο, contract enum/null) + grouped export (extensions builders, όχι νέα). Ομαδοποίηση client-side (`groupPurchases` + labels, Κατηγορία/Προμηθευτής/Ημέρα/Μήνας — sort πρώτα στη SQL, encounter-order τεκμηριωμένο) πάνω στις φιλτραρισμένες γραμμές (ίδιο `CatalogFilterField`, Q-συνέπεια οθόνης/export).

**Προβλέψεις/παγίδες που αποφεύγουμε ρητά**
- Το κουμπί διαγραφής **δεν** εμφανίζεται απλά "με error μετά το tap" — είναι **greyed-out με tooltip** (`AppMessages.itemsInUseTooltip(count)` / `supplierReceiptsTooltip(count)`) όταν `canDelete == false` (§1.4).
- Edit ονόματος Κατηγορίας/Υποκατηγορίας/Τμήματος/Προμηθευτή περνάει από τον **ίδιο** global UNIQUE duplicate-check (exact-match `getByNormalizedName`, §3) με τη Φάση 3 (κοινό `domain/validators/name_validator.dart` — SPoT, όχι διπλή υλοποίηση)· recase στον εαυτό επιτρέπεται (write), clash με άλλον → `nameExists`.
- `inUseCount*`/`receiptCount*` (int siblings για tooltip) + refresh ορατών πυλών (one-shot families, IndexedStack) — σκόπιμα one-shot αντί live watches· auto-refresh από save/delete (`_refreshAffectedGuards` — μόνο επηρεαζόμενα ids, swallow σε failure).

**Backup/Restore — αναλυτική ροή**
1. **Export**: tap → snapshot μέσω `VACUUM INTO` temp αρχείου (WAL-safe) → bytes → `file_picker` save dialog (`saveFile(fileName, bytes)`, προτεινόμενο filename από `AppConstants.backupFileNamePattern` + timestamp) → `AppFeedback.showSuccess`. ΠΟΤΕ γραφή στο `backups/` του project (μόνο αρχεία βημάτων).
2. **Εξαγωγή καταλόγου**: 3ο κουμπί στο `Wrap` (`OutlinedButton`, ίδιο `isWorking` guard) → `BackupRestoreController.exportCatalog()` (one-shot `.first` reads 5 repos + pure `buildCategoryTreeNodes` SPoT + `CatalogExportService.buildCatalogExcelBytes`, 1 γραμμή/είδος με πλήρη διαδρομή + κενά κλαδιά) → save dialog (`times_catalog_*` + timestamp) → `AppMessages.catalogExported`. Ακύρωση → no-op· σφάλμα → `CatalogExportException` (`LogTag.backup`).
3. **Restore**: tap → επιλογή αρχείου → **validation ΠΡΙΝ από οτιδήποτε** (SQLite header magic + `user_version` == schema §3 (strict) + αναμενόμενοι πίνακες + στήλες ανά πίνακα (`expectedColumns`) + πλήρες `integrity_check`) → αν άκυρο, error χωρίς αλλαγή.
4. Αν έγκυρο → **confirm dialog** με ρητή προειδοποίηση αντικατάστασης → OK → **υποχρεωτικό auto-backup** τρέχουσας βάσης (safety net · retention: μετά από επιτυχημένο restore κρατιούνται τα `autoBackupRetentionCount`=5 νεότερα, τα παλιότερα σβήνονται) → `closeSafely()` (idempotent) → αντικατάσταση αρχείου (copy σε temp ίδιου dir + rename, όχι copy — crash δεν αφήνει μισό αρχείο · καθαρισμός stale sidecars `-wal`/`-shm`/`-journal`, best-effort, μετά το rename) → με αποτυχία: best-effort rollback από το auto-backup + rethrow → ΠΑΝΤΑ **restart providers** (`ref.invalidate(appDatabaseProvider)`) + reset φορμών, ώστε όλο το UI να διαβάσει τα νέα δεδομένα και η εφαρμογή να μην μένει ποτέ με κλειστή βάση.
5. **Android Auto Backup ΑΠΕΝΕΡΓΟΠΟΙΗΜΕΝΟ** (`android:allowBackup="false"` στο manifest): το cloud restore θα επανέφερε ασύμβατη παλιά βάση μετά από reinstall — το μόνο αντίγραφο είναι το in-app export.

---

### 2.4 Κοινά (Shared) Widgets — χτίζονται μία φορά, χρησιμοποιούνται παντού

| Widget | Ρόλος | Χρησιμοποιείται σε |
|---|---|---|
| `SearchableDropdownField` | Γενικό dropdown με αναζήτηση + slot για "+" νέο | Προμηθευτής, Κατηγορία, Υποκατηγορία, Τμήμα (η μονάδα γραμμής κλειδώθηκε — banner, §2.2) |
| `ConfirmDialog` | Γενικό επιβεβαιωτικό: `showConfirmDialog` → `Future<bool?>` (true/false/`null`=dismiss)· SPoT defaults («Επιβεβαίωση», «Ναι»/«Ακύρωση»)· `isDestructive` (error styling) για διαγραφές· responsive §1.4 | Διαγραφή, Restore, έξοδος με unsaved data |
| `DeleteGateButton` | Κουμπί πύλης διαγραφής (§2.3:275): ενεργό/greyed+tooltip/retry — dumb, ο γονέας περνά `AsyncValue`s | Tree editor, supplier editor |
| `runControllerOp` | Helper controller-op → feedback (ok/success, error/snackbar, DB/`userMessage`) — SPoT του pattern (§2.3 editors) | Tree editor, supplier editor |
| `CurrencyTextField` | Input formatter με `priceDecimalDigits`, εμφανίζει €, μετατρέπει σε cents στο submit · προαιρετικό `errorText` | Τιμή στη Φάση 3 |
| `QuantityTextField` | Input formatter με `quantityDecimalDigits` + δέχεται flag `allowsDecimal` · προαιρετικό `errorText` | Ποσότητα στη Φάση 3 |
| `AppFeedback` | SPoT snackbar/toast wrapper (§2.0.6) | Παντού |

### 2.4.1 `SearchableDropdownField` — υλοποίηση

Υλοποιήθηκε ως `ConsumerStatefulWidget` πάνω στο native `RawAutocomplete`
(keyboard/accessibility δωρεάν) + `Debouncer` + **gated watch**. Ρητές
αποφάσεις υλοποίησης (δεσμευτικές για το ίδιο widget και στα Βήματα 4/6):

- **Gated watch (§2.0.1)**: `ref.watch` ΜΟΝΟ όταν `query.length >= minChars`·
  ο `optionsBuilder` είναι **σύγχρονος** (επιστρέφει ήδη-υπολογισμένη λίστα,
  ΚΑΝΕΝΑ provider read μέσα του) + controlled refresh σε άφιξη δεδομένων.
- **«+» πάντα στο τέλος** όταν `createLabel != null` (ορατό και με 0 results).
  INVARIANT: `createLabel`/`onCreate` δίνονται μαζί ή κανένα.
- **Double-tap guard**: τοπικό busy-flag `_isCreating` (χωρίς feedback —
  snackbar στον καλούντα μέσω `AppFeedback`) · κλειστό overlay μετά επιλογή
  (`_selectedLabel` guard) · ρητό `displayStringForOption` (όχι `toString()`).
- Προαιρετικά: `prefixIcon`/`resultLeadingIcon` · `showAllWhenEmpty` +
  `allOptionsProvider` · `initialValue` (μόνο εμφάνιση) · `onCleared`
  (fire-once) · `onChanged` (μόνο πληκτρολόγηση, όχι programmatic).
- **Κλειδώματα (§2.2/§2.4)**: επιλεγμένος προμηθευτής/μονάδα → locked banner
  + «Αλλαγή» (reuse `AppStrings.changeItem`)· καθαρισμός φόρμας ξεκλειδώνει.

---

---

### 2.5 Σύνοψη Ροής Δεδομένων (ισχύει σε όλες τις οθόνες)

```
SQLite (Drift) 
   ↓ Stream<List<T>>
Repository (data/repositories) 
   ↓ (business rules, aggregation) 
Domain Service (μόνο όπου χρειάζεται υπολογισμό, π.χ. StatisticsService, ReceiptValidator)
   ↓
Riverpod Provider (xxxStreamProvider / xxxControllerProvider)
   ↓ ref.watch
<screen>_page.dart (σύνθεση layout, ΚΑΝΕΝΑ business logic εδώ)
   ↓
widgets/ (dumb components, παίρνουν έτοιμα δεδομένα ως παραμέτρους)
```
Αυτή η κατεύθυνση **δεν αντιστρέφεται ποτέ** — ένα widget δεν καλεί ποτέ repository, ένα repository δεν ξέρει τίποτα για Riverpod ή Widgets.

---

## 3. Σχήμα Βάσης Δεδομένων (Drift)

```
Category        (id, name, normalizedName [UNIQUE], createdAt)
SubCategory     (id, categoryId → Category, name, normalizedName [UNIQUE])
ItemGroup       (id, subCategoryId → SubCategory, name, normalizedName [UNIQUE])  -- Τμήμα
Item            (id, itemGroupId → ItemGroup, name, normalizedName [UNIQUE], defaultUnitId → Unit)
Unit            (id, name, abbreviation, allowsDecimal)  -- π.χ. Τεμάχιο/τεμ (allowsDecimal=false), Κιλό/κιλ (true), Λίτρο/λτ (true)
Supplier        (id, name, normalizedName [UNIQUE], createdAt)
Receipt         (id, receiptNumber [auto], date, supplierId → Supplier)
ReceiptLine     (id, receiptId → Receipt [CASCADE], itemId → Item, unitId → Unit,
                 quantity [REAL], priceCents [INTEGER], discountCents [INTEGER],
                 lineTotalCents [INTEGER])
```
- `receiptNumber`: χρησιμοποιείται το **internal `INTEGER PRIMARY KEY AUTOINCREMENT` id της απόδειξης**. Η εφαρμογή είναι προσωπική και όχι φορολογικό βιβλίο, άρα οι πιθανές "τρύπες" στην αρίθμηση μετά από διαγραφή δεν είναι πρόβλημα. Αυτή την απόφαση την ορίζουμε ρητά στη Φάση 1 (δεν χρειάζεται ξεχωριστό sequence table/counter).
- **`priceCents`**: ακέραιος σε λεπτά (μέγεθος ×100, π.χ. 2,50€ → 250). Το χρήμα αποθηκεύεται **ποτέ** ως float — όλα τα αθροίσματα/στατιστικά γίνονται σε ακέραιους χωρίς floating-point σφάλματα. Σε γραμμές «Συνολικής τιμής» η μοναδιαία **παράγεται** `(totalCents/quantity).round()` στη φόρμα — η βάση δέχεται πάντα μοναδιαία (καμία migration, τα στατιστικά €/μονάδα δουλεύουν).
- **`quantity`**: REAL — φυσικό μέγεθος (κιλά/λίτρα/τεμάχια), δεν εμφανίζεται ποτέ μόνο του σε λογιστικό άθροισμα.
- **`lineTotalCents`**: INTEGER, υπολογισμένο **μία φορά** κατά το insert μέσω SPoT `lineTotalCents()` (`core/utils/line_total.dart` — η μόνη υλοποίηση του τύπου για stored writes ΚΑΙ display mirrors) — **όχι** Drift generated column (παραμένει ελεγχόμενο, testable, ανεξάρτητο από SQLite float handling). Κάθε επόμενος υπολογισμός (μέσος όρος, σύνολο μήνα, σύγκριση προμηθευτών) δουλεύει **μόνο** σε `SUM(lineTotalCents)` (καθαρά, μετά έκπτωση).
- **`discountCents`** (§2.2): έκπτωση μονάδας σε λεπτά (`0` = καμία · `0≤d≤p`, αλλιώς απόρριψη) — writer ο `ReceiptLineDao` (τύπος στο SPoT `core/utils/line_total.dart`).
- **Κανόνας Δ-stat (δεσμευτικός για Φάση 5)**: κάθε στατιστικό μοναδιαίας τιμής (trend είδους, σύγκριση προμηθευτών €/μονάδα) χρησιμοποιεί **πάντα την καθαρή** `priceCents − discountCents` (ισοδύναμα `SUM(lineTotalCents)/SUM(quantity)`) — **ποτέ** σκέτο `priceCents` (θα έβγαζε τη χονδρική). Το πληκτρολογημένο σύνολο φυλάσσεται ως `DraftReceiptLine.enteredTotalCents` snapshot (display-only στο draft list — εξαίρεση Δ2 μόνο για αυτές τις γραμμές)· το stored σύνολο μπορεί να διαφέρει ±1 λεπτό (στρογγυλοποίηση παραγόμενης).
- **`Unit.allowsDecimal`**: flag που ορίζει αν μια μονάδα δέχεται κλασματική ποσότητα (π.χ. Τεμάχιο=false, Κιλό=true). Χρησιμοποιείται από τη φόρμα εισαγωγής (Φάση 3) για απόρριψη τιμών όπως «2.5 τεμάχια».
- **Foreign key policy** (απόφαση, Φάση 1):
  - `ON DELETE RESTRICT` για Category/SubCategory/ItemGroup/Item/Supplier/Unit (ώστε να μην διαγράφονται αν έχουν δεδομένα — υλοποιεί απευθείας τον κανόνα της §2.3).
  - `ReceiptLine.receiptId → ON DELETE CASCADE`: η γραμμή χωρίς κεφαλίδα είναι άχρηστη (σχέση κυριότητας) — η διαγραφή απόδειξης σβήνει και τις γραμμές της. Εξαιρείται ρητά από τον RESTRICT κανόνα της §2.3.
  - `Item.defaultUnitId → ON DELETE SET NULL`: η προτεινόμενη μονάδα είναι προαιρετική — αν σβηστεί η μονάδα, το είδος απλώς μένει χωρίς πρόταση (null).
- **`normalizedName`** (Category & SubCategory & ItemGroup & Item & Supplier): καθαρή `GreekTextNormalizer.normalize(name)` (lowercase + αφαίρεση τόνων + ς→σ) που υπολογίζεται στο Dart κατά insert/update — όχι DB-generated column, ελεγχόμενο/testable, ίδιο μοτίβο με το `lineTotalCents`. Η αναζήτηση ειδών/προμηθευτών γίνεται πάντα με `WHERE normalizedName LIKE '%' || :normalizedQuery || '%'` (§2.0.4). Κατηγορία/Υποκατηγορία/Τμήμα επιλέγονται από μικρές ήδη-φορτωμένες λίστες (SearchableDropdownField §2.4) — φιλτράρισμα in-memory πάνω στο stream, χωρίς DB query. Ο ίδιος `normalizedName` χρησιμοποιείται και στον global duplicate-check του §2.2 (exact match, όχι LIKE) — μία μόνο υλοποίηση normalization, καμία διπλή λογική.
- **`UNIQUE` στο `normalizedName`** (global constraint σε Category/SubCategory/ItemGroup/Item/Supplier): η απαγόρευση διπλότυπων ονομάτων εγγυάται σε επίπεδο βάσης μέσω exact-match στο `normalizedName` (πεζά/άτονα/ς→σ, §2.2). Δεν επαρκεί `UNIQUE` στο raw `name`, γιατί το SQLite string match δεν είναι case/tone-insensitive («Γάλα»≠«γάλα» ως strings).
- Σημ.: τα `UNIQUE` σε `normalizedName` δημιουργούν αυτόματα δικό τους index — **δεν** προστίθενται ξεχωριστά indexes σ' αυτά τα columns. Ρητά indexes βάσει σχήματος (v5): `ReceiptLine.itemId` (στατιστικά) + `ReceiptLine.receiptId` (λίστα γραμμών/CASCADE) + `Receipt.date` (period queries) + `Receipt.supplierId` (joins/GROUP BY). Ως εκ τούτου δεν χρησιμοποιείται `@TableIndex` σε κατάλογο/προμηθευτές. Το substring `LIKE '%...%'` του §3 παραμένει full scan στο SQLite χωρίς FTS5 — αμελητέο για τον όγκο δεδομένων προσωπικής χρήσης.
- **Κανόνας migration** (επαληθευμένος στην πράξη): κάθε bump = version step + test (tripwire) — ποτέ wipe, ποτέ επανεγκατάσταση. Σημ.: παλιά backups απορρίπτονται (strict validation) — fresh export μετά το update.

---

## 4. Φάσεις Ανάπτυξης

> Κάθε φάση κλείνει μόνο όταν: (α) ο κώδικας λειτουργεί, (β) τα tests της φάσης περνάνε, (γ) το DESIGN.md ενημερώνεται, (δ) έχεις δώσει ρητό OK.

### Φάση 0 — Θεμελίωση Project
1. Δημιουργία Flutter project, ρύθμιση `pubspec.yaml` (Drift, Riverpod, GoRouter, shared_preferences, file_picker + path_provider + sqlite3 για backup, `excel`/`pdf` για export στατιστικών, `local_auth` για κλείδωμα εφαρμογής).
2. Ορισμός branding: όνομα app, package id, εικονίδιο, splash screen, χρωματική παλέτα.
3. Δημιουργία δομής φακέλων (§1.2) με κενά αρχεία-σκελετούς.
4. SPoT σκελετοί (`lib/core/`): `app_constants.dart`, `app_strings.dart`, `app_messages.dart`, `app_errors.dart`, `app_enums.dart`, `app_theme.dart`, `app_colors.dart`, `app_routes.dart`, `app_exceptions.dart`.
5. `app_logger.dart` + `debug_config.dart`.
6. SPoT utilities στο `lib/core/utils/`: `debouncer.dart` (common debounce με cancel — §2.0.3), `greek_text_normalizer.dart` (αφαίρεση τόνων/κεφαλαίων — §2.0.4), `app_feedback.dart` (SPoT snackbar wrapper — §2.0.6).
7. `AGENTS.md` με τους κανόνες συνεργασίας μας (βήμα-βήμα, backups, confirmations).

### Φάση 1 — Βάση Δεδομένων & Domain Models

> Baseline παραγωγής: schema v5 — κάθε αλλαγή σχήματος θέλει migration step + test. Ισχύει μόνο το παρακάτω.

1. Ορισμός Drift tables (§3 — 8 πίνακες, schema v5).
2. DAOs με βασικά CRUD + streams (+counts/cascade §2.3).
3. **Seed δεδομένων** — bootstrap **μία φορά** στο Drift `onCreate` (νέο DB file), μέσα σε **ένα transaction**· όχι σε κάθε launch.
    - **Μονάδες μέτρησης** (Τεμάχιο/τεμ `allowsDecimal=false`, Κιλό/κιλ `true`, Λίτρο/λτ `true`) ως Dart seed constants.
    - **Κατηγορίες / Υποκατηγορίες / Τμήματα**: πηγή το `supermarket_categories_v3.md` (root repo, 6 κατηγορίες / 28 υποκατηγορίες / 183 τμήματα, 0 είδη). Τα δεδομένα μεταγράφονται σε Dart seed constants στο `lib/data/local/seed/` (`seed_categories.dart` · `seed_sub_categories.dart` · `seed_item_groups.dart`)· καμία runtime ανάγνωση του .md.
    - Κάθε εγγραφή με `normalizedName` (UNIQUE §3, global — καμία επανάληψη ονόματος) + fail-fast διπλότυπου στο runner· κάθε Category με `createdAt`· logging tag `DB`.
    - **Καμία seed για Είδη/Suppliers** — δημιουργούνται από το UI.
4. Unit tests στα DAOs — **συμπεριλαμβάνουν seed-import tests**: μονάδες 3, άδειος κατάλογος default, `normalizedName` exact, **κανένα διπλότυπο (global UNIQUE §3)**, ατομικότητα, `onCreate` μία φορά.

### Φάση 2 — Repository Layer
1. Abstract repositories (Category, SubCategory, ItemGroup, Item, Unit, Supplier, Receipt).
2. Υλοποιήσεις πάνω στα DAOs, με `Stream` methods για real-time.
3. Riverpod providers (`StreamProvider`) πάνω στα repositories.
4. Unit tests repositories (mocked DB ή in-memory Drift).
   - **Αναζήτηση Item/Supplier**: ορίζεται στα **Repositories** (ΟΧΙ στα DAOs της Φάσης 1) η μέθοδος `searchByNormalizedName(String query, {int? limit})` — `WHERE normalizedName LIKE '%' || :normalizedQuery || '%'`, με το input ήδη κανονικοποιημένο (§2.0.4/§3). Προαιρετικό `limit` με default από `searchResultsLimit` (§2.0). Κατηγορία/Υποκατηγορία/Unit μένουν in-memory φιλτράρισμα πάνω στο stream (μικρές λίστες, §3).

### Φάση 3 — Σελίδα Εισαγωγής Τιμών (πυρήνας εφαρμογής)
1. **App UI σκελετός** (ξεκινά τη Φάση 3): `GoRouter` με `StatefulShellRoute.indexedStack` + `NavigationBar` (3 branches: Home/PriceEntry/Settings, paths από `AppRoutes`) + placeholder σελίδες ανά οθόνη (καθαρά `Scaffold`, ΚΑΝΕΝΑ provider watch → η βάση δεν ανοίγει στο launch) + `NavLogObserver` (σημείο καταγραφής `LogTag.nav`). Responsive layout από εδώ (§1.4). **Απόφαση Α1 (Βήμα 7, §2.2)**: η λίστα πρόσφατων αποδείξεων είναι πάντα ορατή στην PriceEntry → η βάση **ανοίγει στο launch** (ο κανόνας «ΚΑΝΕΝΑ provider watch» ισχύει μόνο μέχρι το Βήμα 7 — από εκεί και μετά κάθε widget test που pump-άρει `PriceEntryPage`/`TimesApp` κάνει override του `recentReceiptsStreamProvider`).
2. Auto αριθμός απόδειξης + date picker.
3. Supplier search/autocomplete + inline "+" δημιουργία.
4. Item search/autocomplete με incremental filtering (debounce) + "+" popup ροή (Κατηγορία→Υποκατηγορία→Τμήμα→Είδος).
5. Κλειδωμένη μονάδα, ποσότητα, τιμή, save flow ("καλάθι" απόδειξης — βλ. state machine §2.2).
6. Validation (π.χ. τιμή > 0, υποχρεωτικά πεδία) μέσω SPoT validators.
7. **Λίστα πρόσφατων αποδείξεων (read-only).** `ReceiptSummary` projection + `ReceiptDao.watchSummariesByDay` / `watchSummariesBetween` (watch queries πάνω σε stored `lineTotalCents`, φίλτρο Η/Ε/Μ §2.2) · `recentReceiptsStreamProvider` (μη autoDispose, όριο `AppConstants.recentReceiptsLimit` = 20) → **auto-refresh μετά το save** · `recent_receipts_list.dart` (`AsyncValue.when`: loading/error+Επανάληψη/empty, Card+ListTile, responsive + dark/light) · SPoT strings/messages · έγκυρη γραμμή 0,00 € όταν `(priceCents*quantity).round()==0` (§2.2).
8. Widget tests στη φόρμα: flow F1/F2 + dark gap-fill + semantics §1.6 + housekeeping splits (κανένα test αρχείο >500 γρ.).
9. **Exit-confirm §2.2.** `ConfirmDialog` (shared §2.4) + `PopScope` στην PriceEntryPage (βλ. §2.2:244).

### Φάση 4 — Ρυθμίσεις

**Βήμα-βήμα (6) — σειρά υλοποίησης**:

1. **Theme persistence** (Light/Dark/Auto): `themeModeProvider` → **Notifier** πάνω σε `SettingsRepository` (SharedPreferences, SPoT keys §2.3) · `main.dart` γίνεται `ConsumerWidget` με `ref.watch(themeModeProvider)` → `MaterialApp.router.themeMode` (§2.3).
2. **DAO counts + cascade guards** (Βήμα 2): `countItemsByCategoryId`/`countItemsInUseByCategoryId` (+`...BySubCategoryId`) και `deleteWithContents` στα **DAOs** (§2.0.5), όχι στα Repositories (repos = error-mapping μόνο, μοναδική εξαίρεση search). `countItems*` = πλήθος ειδών (confirm cascade) · `countItemsInUse*` = COUNT(DISTINCT items.id) με ≥1 γραμμή (πύλη: `0` = καθαρή). Typed drift API (selectOnly+join+count, compile-time ονόματα) · cascade με subquery `isInQuery` σε ένα transaction · RESTRICT παραμένει.
3. **Providers ελέγχου**: `canDeleteCategoryProvider`/`canDeleteSubCategoryProvider` (`FutureProvider.family<bool,int>`, §2.3:272) — προ-έλεγχος πριν ενεργό delete icon, tooltip «περιέχει X είδη» όταν blocked (§2.3:275).
4. **SettingsPage + category tree editor** (Βήμα 4): CRUD Κατηγοριών/Υποκατηγοριών (§2.3 · cascade-delete Items side-effect) · reuse ConfirmDialog (isDestructive) + NameValidator + AppFeedback + shared widgets (§2.4). **CRUD προμηθευτών** — section + controller + editor (§2.3, RESTRICT, πύλη). **Seed 3 μονάδες** — Τεμάχιο/Κιλό/Λίτρο. **Editor fixes** — exact-match rename, keys/βέλος, 2 shared, dialog label, docs-cleanup.
5. **BackupService + UI** (Βήμα 5): Export = snapshot `VACUUM INTO` temp + `saveFile` bytes (§2.3) · Restore = validate (magic + πίνακες, read-only sqlite3 probe) → **confirm → auto-backup** → `closeSafely()` (idempotent, §2.3) → replace → **restart providers** (`ref.invalidate(appDatabaseProvider)` + reset φορμών, §2.3).
6. **Housekeeping** (Βήμα 6): splits >500 γρ. (κανόνας 7) · oldsessions.md update (1 κεφάλαιο) · backups recap · `flutter analyze` + full tests.

### Φάση 5 — Κεντρική Σελίδα (5 πίτες 3D-εφέ + πορεία + στατιστικά)
1. DAO aggregations (`SUM(lineTotalCents) GROUP BY` + TOP 10, §3) → repos (error-mapping) → 5 stream families (auto-refresh).
2. 5 pie cards (supplier/category/subCategory/itemGroup/top-10) με per-chart περίοδο (Η/Ε/Μ/Ε/προσαρμοσμένο, default Μήνας) + custom 3D-εφέ painter (0 νέα packages) + labels δεξιά + auto-size (`LayoutBuilder`) + fallback πίνακα σε στενά (§1.4).
3. «Προσαρμογή Οθόνης» τελευταία γραμμή (ορατότητα/περίοδος/σειρά ανά γράφημα, persisted SharedPreferences, defaults 6-ορατά/Μήνας/1-2-3-4-5-6).
4. Unit tests (aggregations, config controller, validators ορίων) + widget tests (states/responsive 3 μεγέθη/dark/semantics)· 0 golden tests (brittle cross-platform).
5. 6η κάρτα «Πορεία τιμής» (γραμμή §2.1): `ReceiptLineDao.watchItemHistory` + repo passthrough + `itemTrendProvider` (autoDispose family, split μονάδας + cap) + `selectedTrendItemProvider` (persisted) + custom line painter (0 packages) + Προσαρμογή (6η γραμμή αυτόματα).
6. Ενότητα «Στατιστικά» (§2.3): καρτέλα είδους + export Excel/PDF (deps `excel`/`pdf` + Noto fonts, `BackupFilePicker` reuse, tag `stats`).

### Φάση 6 — Στίλβωση & Επεκτάσεις
1. Πλήρης έλεγχος responsive/overflow σε real συσκευές/μεγέθη.
2. Accessibility pass (Semantics σε όλη την εφαρμογή).
3. Έλεγχος συνολικού test coverage (>80%) και συμπλήρωση κενών.
4. Προαιρετικά (μόνο αν το ζητήσεις): διαχείριση κατηγοριών/υποκατηγοριών/προμηθευτών/μονάδων από Ρυθμίσεις, cloud sync ως μελλοντική επέκταση, **αυτόματο περιστασιακό backup (weekly)** — σημειωμένο ως επέκταση που απαιτεί background scheduling (WorkManager/permissions), όχι απαίτηση MVP.

---


## 5. Επόμενο Βήμα

> Ιστορικό: `oldsessions.md`. Τρέχουσα εικόνα — χωρίς πλήθη tests (ισχύει το τελευταίο full run στη σύνοψη του `oldsessions.md`).

**Παραγωγή**: schema v5 · release signing (AAB/APK) · αντίγραφα: in-app export (παλιά backups απορρίπτονται — strict validation, fresh export μετά το update).

**Ποιότητα**: `flutter analyze` καθαρό · σουίτα πράσινη (τελευταίο full run βλ. `oldsessions.md`) · κανένα `.dart` >500 γρ. στο `lib/` (splits: parts + SPoT utils) · backups ανά βήμα στο `backups/`.

**Επόμενο**: Φάση 6 — Στίλβωση & Επεκτάσεις (§4), ένα βήμα τη φορά (AGENTS.md).
