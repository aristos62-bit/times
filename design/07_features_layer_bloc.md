
#### 5.1.7 BLoC (Presentation — `features/receipt/presentation/bloc/`)

> SPLIT (12/09/2026): συνέχεια του §5.1.7 από τον οδηγό
> `design/07_features_layer.md` (κανόνας ≤500 γρ.).

> **✅ Υλοποιήθηκε — Phase 3 Step 6 (11/09/2026):** `receipt_bloc.dart` (~340 γρ.) +
> `receipt_event.dart` (7 events) + `receipt_state.dart` (1 state) + 21 tests
> (`receipt_bloc_test.dart` 495 γρ.) → σύνολο **342/342, analyze clean**.
>
> **✅ Υλοποιήθηκε — Phase 3 Step 7 (11/09/2026):** presentation layer —
> `widgets/` (receipt_card, receipt_item_list, receipt_form_lines, receipt_form) +
> `screens/` (list/entry/detail) + 3 edits (AppStrings +22 strings·
> `ReceiptMessageShown` event· bloc fix `message: () => state.message` +
> `_onMessageShown`) + 46 widget/bloc tests → σύνολο **388/388, analyze clean**.
>
> **✅ Phase 3 Fixes (11/09/2026) — Wiring + SPoT:**
> - **Fix-A (SPoT «paymentStatus»):** τα magic strings `'pending'/'partial'/'paid'`
>   αντικαταστάθηκαν παντού με `AppConstants.paymentStatusPending/Partial/Paid`
>   (tables/receipts, daos/receipt_dao, widgets/receipt_card, bloc docstring).
>   Εξαίρεση: τα integration tests ελέγχουν τις αποθηκευμένες DB τιμές.
> - **✅ SPoT Status Pattern (12/09/2026):** νέο `ReceiptPaymentStatus` enum
>   (core/constants/receipt_payment_status.dart ~40 γρ.) — καταναλώνει τα
>   `AppConstants.paymentStatus*` (const, συνεπείς με το `.g.dart` default),
>   έχει αυστηρό `fromDbValue` (fail-fast ArgumentError + AppLogger.error).
>   Boundaries: DAO filter + `_paymentStatus` (Δ4 logic → enum),
>   repository abstract/impl, BLoC event, chip (exhaustive switch, χωρίς `_`).
> - **Fix-B (Wiring — minimal):** το template `main.dart` αντικαταστάθηκε από
>   `main.dart` → `lib/app.dart` (`ExpenseTrackerApp`, constructor injection) →
>   `ReceiptsHomeScreen` + `ReceiptListScreen`. Ο `ReceiptsHomeScreen` κάνει το
>   ΑΡΧΙΚΟ `ReceiptsLoadRequested` (το list-screen είναι Stateless) και είναι ο
>   μόνος τόπος `Navigator.push`. Το `BlocProvider<ReceiptBloc>` τοποθετείται
>   ΠΑΝΩ από το MaterialApp ώστε τα pushed routes να βλέπουν τον bloc.
>   Πλήρης responsive navigation → Phase 9.
> - **Διόρθωση ακούσιας απώλειας** του `uuid` column του `Receipts` table
>   (επαναφορά + build_runner). Σύνολο **389/389 tests, analyze clean**.

**Σύμβαση BLoC (γενικής ισχύος για όλα τα features):**
- `Bloc({required Repository repository})` — **positional named required**, χωρίς
  `??` fallback, χωρίς DI lookup μέσα στο constructor (`ThemeProvider` pattern). Το
  wiring γίνεται στο presentation layer.
- **Bridge pattern για reactive streams:** το `emit` επιτρέπεται ΜΟΝΟ εντός event
  handler (bloc 9 assert). Οι DAO stream subscriptions (`watchAll`, `watchReceiptItems`)
  ΔΕΝ καλούν απευθείας `emit` — καλούν `bloc.add(...)` με **εσωτερικά events**
  (`ReceiptsStreamUpdated`, `ReceiptItemsStreamUpdated`, `ReceiptStreamError`) και οι
  αντίστοιχοι handlers κάνουν `emit`. Έτσι κάθε state change γίνεται εντός handler.
- Oι subscriptions ακυρώνονται στο `close()` με `isClosed` guards.
- **F2 (reactive):** δεν γίνεται χειροκίνητο refetch μετά από mutations — το
  `watchAll` refreshes το state μόνο του. Η delete ενός ανύπαρκτου id είναι κανονική
  ροή (no-op, χωρίς error).
- **F6 (ημερομηνίες LOCAL):** όλες οι ημερομηνίες στα events και στα states είναι
  τοπικές (local). Το `toUtc()` γίνεται μόνο εντός του DAO.
- **F8 (validation):** `validateReceipt` καλείται ΠΡΙΝ το create — αν αποτύχει,
  καμία κλήση repository δεν γίνεται· μηδέν AppStrings νέα (reuse `genericError`,
  `databaseError`, `receiptAdded`, `receiptUpdated`, `receiptDeleted`, `noReceipts`).
- Error handling: try/catch με `AppLogger.error('...: $e', st)` (άρα χωρίς
  `unused_catch_clause`). Debug logs gated από `DebugConfig.showBlocLogs`.
- Δεν χρησιμοποιούνται `// ignore:` (μηδέν ignores στο project) — λύση για
  `prefer_initializing_formals`: `late final` πεδίο + ανάθεση στο σώμα constructor.

**State — `ReceiptsState`:** `ReceiptsStatus` (`initial/loading/loaded/error`) +
`receipts` (+ προσθήκη `isSubmitting`), `message`, `validationErrors` (null sentinel),
`lastCreatedId`, `selectedReceiptId` + παράγωγα `selectedReceipt`/`selectedItems`/
`selectedTotals` (derive από `watchAll` + items stream — F3, χωρίς `getById`).

