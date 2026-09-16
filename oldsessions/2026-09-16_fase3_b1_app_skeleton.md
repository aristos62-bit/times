# Φάση 3 — Βήμα 1: App Skeleton & Navigation

> Ημερομηνία: 16-09-2026 · Κατάσταση: Κλειστό · GoRouter shell
> (StatefulShellRoute + NavigationBar) με 3 placeholder σελίδες +
> NAV logging. Ξεκινά την Presentation Layer (Φάση 3).

---

## 1. Πεδίο

Εκκίνηση της **Φάσης 3 (Presentation Layer)** με το App UI skeleton.
Αντικαθιστά το `MaterialApp(home:)` με `MaterialApp.router` (GoRouter §1.2:
GoRouter config ξεχωριστό αρχείο `router/`, §1.2:42). Κάθε σελίδα είναι
placeholder (ΚΑΝΕΝΑ provider watch) — η βάση **δεν ανοίγει στο launch**.

### 1.1 Αριθμητική (CORRECTION)

Το παλιό label «Φάση 2 Βήμα 4» στη γραμμή όγδοη του `oldsessions.md`
(«Επόμενο») ήταν λάθος: το Φάση 2 Βήμα 4 (unit tests repositories) **ήδη
καλύφθηκε** μέσα στο Βήμα 2. Άρα:
- Η **Φάση 2 κλείνει ως Ολοκληρωμένη** μετά το Βήμα 3 (providers).
- Το Router/Πλοήγηση ανήκει στο **Presentation layer** (§1.2) → όχι
  «Φάση 2 Βήμα 5». Το σωστό label είναι **Φάση 3, Βήμα 1** (UI σκελετός).
- Το DESIGN §4 λέει «unit tests repositories» στο Βήμα 4 Φάση 2 — ουδέποτε
  «router» στη Φάση 2. Επομένως νέο Βήμα 5 δεν προστέθηκε.

## 2. Αρχεία υλοποίησης

| Αρχείο | Γραμμές | Σημειώσεις |
|---|---|---|
| `core/router/app_router.dart` | ~100 | `buildAppRouter()` + `appRouter` + `AppShell` |
| `core/router/nav_log_observer.dart` | ~33 | `NavigatorObserver`, tag `NAV` |
| `presentation/home/home_page.dart` | ~28 | placeholder στατιστικών §2.1 |
| `presentation/price_entry/price_entry_page.dart` | ~28 | placeholder εισαγωγής §2.2 |
| `presentation/settings/settings_page.dart` | ~28 | placeholder ρυθμίσεων §2.3 |
| `main.dart` | ~30 | `MaterialApp.router` + `routerConfig` |

## 3. Σχεδιαστικές αποφάσεις (εγκεκριμένες)

1. **`StatefulShellRoute.indexedStack`**: κάθε branch κρατά δικό της state
   (αλλαγή tab ΔΕΝ ξαναχτίζει τη σελίδα — προστατεύει draft δεδομένα
   φόρμας §2.2:222). `initialLocation = '/'` (Home §2.1).
2. **`NavLogObserver` ως ξεχωριστό αρχείο**: «route definitions» (§1.2:42),
   ίδιο μοτίβο `base_dao.dart` vs `daos/*.dart` (infrastructure χωριστά από
   domain-specific). Μπαίνει **πάντα** στους observers — τα tests προσθέτουν
   πάνω από αυτόν. Καταγράφει `→/←/↻/✗` με `LogTag.nav` (§1.7).
3. **`buildAppRouter({observers})`** επιστρέφει νέο GoRouter ανά κλήση —
   τα widget tests αποφεύγουν shared router state.
4. **SPoT strings**: 8 νέα (navHome/navPriceEntry/navSettings/statsComingSoon/
   titlePriceEntry/priceEntryComingSoon/titleSettings/settingsComingSoon) στο
   `app_strings.dart` + exact tests + `_allStrings` gate (μηδέν hardcoded
   κείμενο στο NavigationBar).
5. **Μηδέν νέα dependencies**: `go_router ^18.0.1` ήδη στο pubspec.

## 4. Δοκιμές

| Test | Σημειώσεις |
|---|---|
| `app_router_test.dart` (5) | `initialLocation`, 3 branches via paths, NavigationBar 3 destinations, tab-switch + state preservation (`skipOffstage:false`), NAV log capture |
| `home_page_test.dart` (4) | placeholder + responsive 3 μεγέθη (mobile 320 / tablet 800 / desktop 1200 → `tester.view.physicalSize`) |
| `price_entry_page_test.dart` (4) | placeholder + responsive 3 μεγέθη |
| `settings_page_test.dart` (4) | placeholder + responsive 3 μεγέθη |
| `widget_test.dart` (2) | AppBar «Τιμές» + NavigationBar 3 tabs + tab change → «Εισαγωγή Τιμών» |

Σύνολο suite: **352/352** ✓ (από 329) · `flutter analyze` **No issues** ✓.

### 4.1 Ευρήματα

- `tester.view.physicalSize` + `addTearDown(resetPhysicalSize/resetDevicePixelRatio)`
  για responsive (pattern app_feedback_test).
- Μετά από tab-switch το Home μένει **offstage** στο IndexedStack → ο
  `find.text` (skipOffstage:true) δεν το βρίσκει. Επιβεβαιώνεται με
  `skipOffstage:false` (state preservation §2.2:222).
- `addTearDown` εκτός test → `Bad state` (flutter_test). Σε `main()` επίπεδο
  χρησιμοποιείται `setUp`/`tearDown`, όχι `addTearDown` (το `addTearDown`
  μόνο μέσα σε test body).

## 5. Backups

- `backups/*_before_fase3_b1_20260916_220516.*` (6 αρχεία: main, app_strings,
  widget_test, app_strings_test, DESIGN, oldsessions).

## 6. Επόμενο

- Φάση 3, Βήμα 2: Auto αριθμός απόδειξης + date picker (DESIGN §4 Φάση 3
  Βήμα 2) — η PriceEntryPage placeholder να αποκτήσει πραγματικό σκελετό
  φόρμας (receipt_header_section §2.2). Τα shared widgets (§2.4) που
  χρειάζονται πρώτο καταναλωτή (π.χ. AsyncValueView για την placeholder
  λίστα αποδείξεων Βήμα 7) παραμένουν εκτός μέχρι να εμφανιστεί χρήση.