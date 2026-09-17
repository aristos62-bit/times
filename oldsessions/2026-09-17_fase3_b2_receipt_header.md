# Φάση 3 — Βήμα 2: Auto αριθμός απόδειξης + Date Picker

> Ημερομηνία: 17-09-2026 · Κατάσταση: Κλειστό · PriceEntryPage απέκτησε
> πραγματικό σκελετό φόρμας (`ReceiptHeaderSection` με ημερομηνία μέσω
> `showDatePicker` ελληνικά) + ελληνικό locale παντού (§0). Ο «αυτόματος
> αριθμός απόδειξης» ΔΕΝ απαιτεί κώδικα — είναι το internal AUTOINCREMENT
> id της Receipt (§3), ορατό στη λίστα αποδείξεων από το Βήμα 7.

---

## 1. Πεδίο

DESIGN §4 Φάση 3 Βήμα 2 («Auto αριθμός απόδειξης + date picker») και §2.2:
η `PriceEntryPage` placeholder (Βήμα 1) αποκτά πραγματικό σκελετό φόρμας —
`receipt_header_section.dart` (ημερομηνία + picker). Ο προμηθευτής έρχεται
στο Βήμα 3 (slot μέσα στο ίδιο widget).

### 1.1 Αποφάσεις ελέγχου πριν την υλοποίηση (εγκεκριμένες)

1. **Σενάριο Α — κανένα preview αριθμού στη φόρμα.** Ο αριθμός = εσωτερικό
   `INTEGER PRIMARY KEY AUTOINCREMENT` id (§3:308 — «δεν χρειάζεται
   ξεχωριστό sequence table/counter»). Μετά από διαγραφή της τελευταίας
   απόδειξης η πρόβλεψη `MAX(id)+1` αποκλίνει (το sqlite_sequence κρατάει
   την αύξηση) → κανένα query, κανένα νέο data-layer κώδικα. Το insert
   επιστρέφει το id (`ReceiptRepository.insert` Φάση 2) → εμφάνιση στη
   placeholder λίστα Βήμα 7.
2. **Ελληνικά παντού (§0 ΔΕΣΜΕΥΤΙΚΟ).** Ο `showDatePicker` και το
   `formatMediumDate` χωρίς `flutter_localizations` βγαίνουν ΑΓΓΛΙΚΑ →
   ασυμβίβαστα με §0 «Γλώσσα UI: Ελληνικά, μοναδική γλώσσα».
   Κρίσιμη διαπίστωση: **`flutter_localizations` (SDK) και `intl` ήταν ήδη
   στο `pubspec.lock` ως transitive** (γρ. 385/496) → η δήλωσή τους ως direct
   dependencies ΔΕΝ άλλαξε το dependency tree (0 νέα πακέτα). Επαληθεύτηκε
   με `flutter pub get`: μόνο «transitive → direct» για τα 2.
3. **`Notifier`, όχι AsyncNotifier**: το state είναι σύγχρονο (δεν έρχεται
   από τη βάση) · ο κανόνας §2.0.2 (ασύγχρονα controllers providers) ισχύει
   για data sections. `AsyncValue.when` δεν χρειάζεται εδώ.
4. **State Freezed μόνο με `date`** (YAGNI): supplier/draftLines/isSaving
   μπαίνουν στα Βήματα 3-5 μαζί με τα μοντέλα τους — επέκταση με copyWith.
5. **Format ημερομηνίας**: `MaterialLocalizations.formatMediumDate` —
   locale-aware (el), ΜΗΔΕΝ νέο util (δεν προστέθηκε `app_formatters.dart`).
6. **Provider στον ίδιο αρχείο** με τον controller (μοτίβο `appRouter` στο
   `app_router.dart:75`) — όχι ξεχωριστό αρχείο provider.
7. **`priceEntryComingSoon` → `priceEntryLinesComingSoon`** με νέο κείμενο
   («Οι γραμμές απόδειξης θα είναι διαθέσιμες σύντομα») — το παλιό
   «Η εισαγωγή τιμών θα είναι διαθέσιμη σύντομα» ήταν πλέον ψευδές.

## 2. Αρχεία υλοποίησης

| Αρχείο | Γραμμές | Σημειώσεις |
|---|---|---|
| `presentation/price_entry/state/receipt_form_state.dart` (ντέο) + `.freezed.dart` | ~16 | Freezed `ReceiptFormState{DateTime date}` — equality/copyWith από codegen |
| `presentation/price_entry/controllers/receipt_form_controller.dart` (ντέο) | ~29 | `Notifier` + `receiptFormControllerProvider` (κοινό αρχείο) · build=σήμερα(dateOnly) · setDate: dateOnly + equality gate + log `[UI]` · όχι autoDispose (§2.2:221) · ΧΩΡΙΣ repository → η βάση δεν ανοίγει |
| `presentation/price_entry/widgets/receipt_header_section.dart` (ντέο) | ~39 | `ConsumerWidget` · Card+ListTile · label `AppStrings.fieldDate` + `formatMediumDate` · tap→`showDatePicker` (first/lastDate από SPoT) · `context.mounted` guard · slot προμηθευτή Βήμα 3 |
| `presentation/price_entry/price_entry_page.dart` (update) | ~33 | `Stateless`→`ConsumerWidget` · `SafeArea`+`ListView` (responsive §1.4) · Header + placeholder γραμμών |
| `core/constants/app_constants.dart` (update) | 92 | +`datePickerFirstYear`(2000), +`datePickerLastYear`(2100) |
| `core/constants/app_strings.dart` (update) | 51 | rename `priceEntryComingSoon`→`priceEntryLinesComingSoon` |
| `main.dart` (update) | ~44 | `localizationsDelegates` + `supportedLocales:[el]` + `locale: el` |
| `pubspec.yaml` (update) | 133 | +`flutter_localizations {sdk}` +`intl ^0.20.3` (ήδη transitive, 0 αλλαγές tree) |

### 2.1 Ευρήματα υλοποίησης

- **`build_runner` warning**: `--delete-conflicting-outputs` έχει αφαιρεθεί
  από το recent build_runner (αγνοήθηκε) — δεν χρειάζεται πλέον · έγραψε 140
  outputs (τα drift `.g.dart` ξαναγράφτηκαν, idem τα freezed).
- **Freezed 4.0.1**: η κλάση δηλώνεται `abstract class ... with _$X`. Το
  `DateTime` ΔΕΝ έχει const constructor → σε tests απαγορεύεται
  `const DateTime(...)` (compile error) — χρήση `final`.
- **ListTile**: προσφέρει από μόνο του το semantic label
  (title+subtitle+onTap) §1.6 — καμία επιπλέον `Semantics` ανάγκη.

## 3. Testing

| Test | Σημειώσεις |
|---|---|
| `state/receipt_form_state_test.dart` (ntéo, 4) | date transfer · equality/hashCode · copyWith immutability |
| `controllers/receipt_form_controller_test.dart` (ntéo, 5) | build=σήμερα(dateOnly) · setDate+log `[UI]` (testSink πριν το setDate!) · dateOnly επί ώρας · equality gate (ίδια μέρα→0 re-notify) · νέα εκπομπή |
| `widgets/receipt_header_section_test.dart` (ntéo, 7) | label+formatMediumDate · tap→DatePickerDialog · OK χωρίς αλλαγή → σημερινή · επιλογή άλλης ημέρας→format νέας · responsive 3 μεγέθη |
| `price_entry_page_test.dart` (update, 4) | +ProviderScope (ConsumerWidget) · νέο placeholder · responsive |
| `widget_test.dart` (update, 2) | νέο placeholder κείμενο |
| `app_router_test.dart` (update, 5) | +ProviderScope στο wrap (3 σημεία) — πλέον απαραίτητο |
| `app_strings_test.dart` (update) | νέο κείμενο + `_allStrings` gate |
| `app_constants_test.dart` (+3) | 2000/2100 + invariant first<last |

**Suite: 371/371** ✓ (+19) · `flutter analyze` **No issues** ✓ · μηδέν νέα
πακέτα · κανένα αρχείο >500 γραμμές.

### 3.1 Ευρήματα testing

- **Σήμερα 17-09-2026 == `DateTime(2026,9,17)`** → o αρχικός λεγμένος
  «target = 2026-09-17» στο controller log-test ισούται με την αρχική
  ημερομηνία (equality gate) → κανένα log. Διορθώθηκε με δυναμικό
  «προηγούμενη ημέρα» (πάντα ≠ σήμερα, εντός bounds).
- **`(_, __)` → lint**: Dart 3 wildcards → `(_, _)` (`unnecessary_underscores`).
- **Router tests (Βήμα 1)** κρατούσαν `MaterialApp.router` χωρίς
  `ProviderScope` → μετά το Βήμα 2 (Page=ConsumerWidget) έσπαγαν με
  provider error. Προστέθηκε `ProviderScope` στα 3 σημεία wrap.

## 4. Backups

- `backups/*_before_fase3_b2_20260917_103914.*` (9 αρχεία: main, app_constants,
  app_strings, price_entry_page, pubspec, widget_test, app_strings_test,
  app_constants_test, price_entry_page_test).

## 5. Επόμενο

- Φάση 3, Βήμα 3: Supplier search/autocomplete + inline "+" νέου προμηθευτή
  (DESIGN §4 Φάση 3 Βήμα 3) — slot στο `ReceiptHeaderSection` (§2.2:182).
  Debug: ο Supplier `searchByNormalizedName` + `getByNormalizedName` υπάρχουν
  ήδη στο Repository (Φάση 2) — χρήση, όχι νέα υλοποίηση.