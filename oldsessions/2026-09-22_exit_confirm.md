# Κεφάλαιο 20 — Φάση 3 post-closure: Exit-confirm (έξοδος με μη αποθηκευμένες γραμμές)

**Ημερομηνία έναρξης:** 22-09-2026 · **Κατάσταση:** Κλειστό

## Πρόβλημα (ανοιχτό από §2.2:244)

Η προδιαγραφή «Ημιτελής καταχώρηση κατά την έξοδο» ήταν η μόνη ανοιχτή
λειτουργία της Φάσης 3: με μη αποθηκευμένες `draftLines`, το system back
(Android/iOS) έπρεπε να ρωτήσει *«Έχετε μη αποθηκευμένες γραμμές. Έξοδος χωρίς
αποθήκευση;»*. Υλοποιήθηκε με `PopScope` + generic `ConfirmDialog` (§2.4).

## Απόφαση (εγκεκριμένη)

- **`PopScope` μόνο** (όχι `GoRoute.onExit`): καλύπτει Android/iOS system back
  μέσα από τον router (v18: `popRoute` → `maybePop` → σέβεται `popDisposition`).
  Web = προαιρετικά αργότερα. Windows X/Alt+F4 εκτός ελέγχου Flutter
  (τεκμηριωμένο όριο, §2.2:244).
- **«Ναι» → καθαρή φόρμα** που βρίσκει ο χρήστης αν γυρίσει (`resetForm` +
  `clearSelection`, ίδιο μοτίβο με το αποτέλεσμα save §2.2:212).
- **`ConfirmDialog` generic** shared widget (§2.4) με SPoT defaults
  (`confirmDialogTitle`/`confirmDialogConfirm`/`confirmDialogCancel`) και
  `isDestructive` (error styling, έτοιμο για διαγραφές Φάσης 4).

## Κρίσιμο εύρημα (go_router 18.0.1)

- `GoRouterDelegate.popRoute()` δοκιμάζει `maybePop()` στο branch navigator
  ΠΡΩΤΑ (via `_findCurrentNavigators().reversed`) → το `PopScope` της σελίδας
  πυροδοτείται κανονικά στην παραγωγή (όχι μόνο στα tests).
- Το shell route στο root navigator είναι `isFirst` → `bubble` → ΔΕΝ
  ποπάρεται κάτω από το dialog (κανένα «σπάσιμο»).
- **Απαγόρευση ρητού `Navigator.pop()`**: η PriceEntryPage είναι η ΜΟΝΑΔΙΚΗ
  route της branch· ρητό pop → `_handlePopPageWithRouteMatch` →
  `_completeRouteMatch` → assert «You have popped the last page off of the
  stack» (debug crash + σπασμένο config). Αφαιρέθηκε και από το
  `onPopInvokedWithResult` και από το `_confirmExit`.
- **Τελική συμπεριφορά**: «Ναι» → καθαρισμός + `_allowPop=true` (χωρίς pop)·
  το **επόμενο** system-back με `canPop=true` ολοκληρώνει την έξοδο (root pop
  / app-exit Android) ή απλώς τίποτα (desktop — η φόρμα είναι ήδη καθαρή).
- `stale-flag` edge (desktop no-op pop): `ref.listen` σβήνει το `_allowPop`
  σε νέο draft → το back ρωτάει ΞΑΝΑ (tested).

## Αλλαγές

- **`lib/presentation/shared/confirm_dialog.dart`** (νέο, ~100 γρ.):
  `showConfirmDialog` → `Future<bool?>` (true/false/`null`=dismiss)· SPoT
  defaults, `isDestructive` (error+onError foreground), responsive
  `ConstrainedBox(dialogMaxWidth)` + `SingleChildScrollView` (ίδιο pattern με
  το `NewItemFlowDialog`). «Χαζό» widget — καμία business logic (§2.0).
- **`lib/presentation/price_entry/price_entry_page.dart`** (ConsumerWidget →
  ConsumerStatefulWidget, +~40 γρ.): `PopScope` με
  `canPop = _allowPop || !hasDrafts` (`hasDrafts` από
  `receiptFormControllerProvider.draftLines` — μόνοι προμηθευτής/ημερομηνία
  ΔΕΝ μπλοκάρουν)· `onPopInvokedWithResult`: `didPop`→return, `_allowPop`→
  return (κανένα pop), αλλιώς `_confirmExit()`· flags `_allowPop` + `_dialogOpen`
  (double-tap guard)· `ref.listen` reset του `_allowPop`· layout άθικτο.
- **DESIGN.md**: §2.2:244 (υλοποίηση + όρια), §2.4 πίνακας (ConfirmDialog),
  §4 Φάση 3 steps 8-9, §5 Επόμενο Βήμα.

## Tests (κανόνας 4)

- **`test/presentation/shared/confirm_dialog_test.dart`** (νέο, 8 tests):
  SPoT defaults · custom labels · «Ναι»→true κλείσιμο · «Ακύρωση»→false ·
  dismiss→null (barrier tap) · isDestructive styling (style non-null) ·
  μη-destructive (style null) · responsive στενή οθόνη χωρίς overflow.
- **`test/presentation/price_entry/price_entry_page_test.dart`** (νέο group,
  5 tests — με τον **πραγματικό router** `buildAppRouter()`, όχι περιληπτικό
  wrap, ώστε το branch-root pop να είναι no-op όπως σε desktop):
  1. back χωρίς drafts → κανένα dialog/exception
  2. back με draft → εμφανίζεται το μήνυμα (§2.2:244)
  3. «Ακύρωση» → dialog κλείνει, drafts μένουν (hasLength(1))
  4. «Ναι» → φόρμα ΚΑΘΑΡΗ (draftLines empty + supplier null) + σελίδα παραμένει
  5. stale-flag: «Ναι» + νέο draft → το back ρωτάει ΞΑΝΑ (ref.listen reset)
  - `systemBack` helper = `tester.binding.handlePopRoute()` (περνά από τον
    router delegate — όχι `WidgetsAppState`, που είναι private).

## Verification

- `flutter analyze` → **No issues found** ✓
- `flutter test` → **724/724** ✓ (711 + 13 νέα: 8 confirm_dialog + 5 exit)
- Κανένα `.dart` > 500 γρ. ✓ (confirm_dialog ~100, page ~215)

## Backup

- `backups/2026-09-22_exit_confirm/` — `price_entry_page.dart`,
  `price_entry_page_test.dart`, `DESIGN.md`, `oldsessions.md` (πριν τις
  αλλαγές).

## Commit

- Commit + push `origin/main` (περιγραφή: exit-confirm PopScope + ConfirmDialog).