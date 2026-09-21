# Φάση 3 — Βήμα 7: Λίστα πρόσφατων αποδείξεων (read-only)

> Ημερομηνία έναρξης: 21-09-2026 · Κατάσταση: Κλειστό
> Read-only λίστα των τελευταίων αποδείξεων στο κάτω μέρος της PriceEntry
> (αριθμός, ημερομηνία, προμηθευτής, πλήθος γραμμών, σύνολο €) με αυτόματη
> ανανέωση μετά το save. Υλοποιήθηκε σε Υποβήματα 1–9, ένα-ένα με backup,
> tests και ρητό «επόμενο».

---

## 1. Υποβήματα

| Υποβήμα | Περιεχόμενο | Tests (σύνολο) |
|---|---|---|
| 1 — Backup | 15 `.bak` στο `backups/2026-09-21_fase3_b7_receipts_list/` (εμπλεκόμενα lib + test αρχεία) | — |
| 2 — Projection + DAO | `receipt_summary.dart` (record `{id, date, supplierName, lineCount, lineTotalCentsSum}`) · `ReceiptDao.watchRecentSummaries` (`customSelect` + `readsFrom` + `.watch()`, drag το drift 2.35: τα `customSelectStream`/`customSelectQuery` είναι deprecated) | +7 |
| 3 — Repository | `watchRecentSummaries` στο interface + impl + error mapping (Reads → `DataLoadException`) | +3 |
| 4 — Provider | `recentReceiptsStreamProvider` (StreamProvider, `autoDispose: false`, `AppConstants.recentReceiptsLimit` = 20) — σύνοψη, κενή, live auto-refresh | +3 |
| 5 — SPoT κείμενα | `AppStrings.recentReceiptsTitle` («Πρόσφατες αποδείξεις») · `recentReceiptsEmpty` · `AppMessages.receiptNumber(id)` · `receiptLinesLabel(count)` | +4 |
| 6 — Widget | `recent_receipts_list.dart` (~135 γρ.): `AsyncValue.when` — loading (spinner), error (`AppErrors.loadDataFailed` + «Επανάληψη» → `ref.invalidate`), empty, data (Card + ListTile, subtitle `προμηθευτής · ημερομηνία · #γραμμές`, trailing `formatCents` €) | +6 |
| 7 — Ενσωμάτωση | `RecentReceiptsList` στην `price_entry_page.dart` κάτω από το save (`recentBlock`) · overrides κενής λίστας σε `price_entry_page_test`, `app_router_test`, `widget_test` + assertions | 11/11 |
| 8 — Full verify | `flutter analyze` (project) + `flutter test` (πλήρες) · **fix**: 5 compile errors σε fakes `implements ReceiptRepository` (χωρίς `watchRecentSummaries`) σε 3 test files — backups 3 `.bak` · **699/699** ✓ | +22 |
| 9 — Τεκμηρίωση | DESIGN §2.2 / §4 (Φάση 3 Βήμα 1 «Α1» + Βήμα 7) / §5 · oldsessions root (TOC) + αυτό το κεφάλαιο | — |

## 2. Αποφάσεις (εγκρίθηκαν από τον χρήστη πριν την υλοποίηση)

1. **Α1 — Η λίστα είναι πάντα ορατή** στην PriceEntry → με το `IndexedStack`
   (AppShell, Φάση 3 Βήμα 1) η σελίδα φορτώνει στο launch και **η βάση
   ανοίγει στο launch**. Συνέπεια: κάθε widget test που pump-άρει
   `PriceEntryPage`/`TimesApp` κάνει override `recentReceiptsStreamProvider`
   (κενή λίστα) — αυτό κλείδωσε και τα 3 test files που επηρεάστηκαν.
2. **Β1 — `(priceCents * quantity).round() == 0`** (π.χ. 0,01 € × 0,004)
   είναι **έγκυρη** γραμμή με σύνολο **0,00 €**· το SUM γίνεται στο SQL πάνω
   σε **stored** `lineTotalCents` (SPoT του `ReceiptLineDao`, §3) — κανένας
   διπλός υπολογισμός στο Dart.
3. **Γ1 —** Η λίστα χρησιμοποιεί απλό `ref.watch().when()` (το `AsyncValueView`
   ως shared widget μένει εκτός Βήματος).
4. **formatShortDate** (Βήμα 6): το `formatMediumDate` σε αυτή την έκδοση
   Flutter βγάζει «Πέμ, Ιαν 1» χωρίς έτος (verified στις
   `material_localizations.dart:878`), το `formatShortDate` δίνει «Ιαν 1,
   2026». Στα tests (en_US DefaultMaterialLocalizations) = «Jan 1, 2026» →
   assert `textContaining('2026')`.

## 3. Ευρήματα / περιστατικά

1. **Riverpod 3.4.3**: το `Override` (sealed) ΔΕΝ εξάγεται από το
   `package:flutter_riverpod` → τα overrides γράφονται πάντα inline literals
   (context inference), ποτέ μεταβλητές.
2. **Drift 2.35**: `customSelect(query, {variables, readsFrom}).watch()`
   (τα `customSelectStream`/`customSelectQuery` είναι deprecated) ·
   `row.read<DateTime>('date')` auto-mapping unix seconds · στα DAO/repo
   tests πάντα `.first` (lint `await_only_futures`).
3. **Πλήρες `flutter analyze` έπιασε 5 compile errors** που το στοχευμένο
   analyze των υποβημάτων δεν έβλεπε: τα fakes `_FailingReceiptRepo`,
   `_BlockingReceiptRepo` (σε `receipt_form_controller_test` και
   `save_receipt_button_test`) και `_NeverInsertReceiptRepo`
   (`receipt_form_controller_validation_test`) υλοποιούν `implements
   ReceiptRepository` → όφειλαν τη νέα μέθοδο `watchRecentSummaries`.
   Fix: +3 imports `receipt_summary.dart` + 5 υλοποιήσεις κατ' αναλογία του
   pattern κάθε fake (`throw const DataLoadException()` / `throw
   UnimplementedError()` / `inner.watchRecentSummaries(limit: limit)`).
4. **Provider tests**: pattern `waitForValue` (Completer + predicate), γιατί
   το `.future` του StreamProvider δεν πιάνει την πρώτη εκπομπή.

## 4. Αρχεία (γραμμές μετά το Βήμα 7)

| Αρχείο | Σημειώσεις |
|---|---|
| `data/models/receipt_summary.dart` (νέο) | projection record |
| `data/local/daos/receipt_dao.dart` | +`watchRecentSummaries` (watch query) |
| `data/repositories/receipt_repository.dart` · `_impl.dart` | +`watchRecentSummaries` + error mapping |
| `data/providers/stream_providers.dart` | +`recentReceiptsStreamProvider` (non-autoDispose) |
| `presentation/price_entry/widgets/recent_receipts_list.dart` (νέο, ~135) | read-only λίστα |
| `presentation/price_entry/price_entry_page.dart` | +`RecentReceiptsList` κάτω από το save |
| `core/constants/app_strings.dart` · `app_messages.dart` | +2 strings · +2 μέθοδοι |
| Tests (νέο) | `recent_receipts_list_test` (6) |
| Tests (αλλαγές) | `receipt_dao_test` · `receipt_repository_test` · `stream_providers_test` · `app_strings_test` · `app_messages_test` · `price_entry_page_test` · `app_router_test` · `widget_test` |
| Tests (fix) | `receipt_form_controller_test` · `receipt_form_controller_validation_test` · `save_receipt_button_test` (+fakes `watchRecentSummaries`) |

Backups: `backups/2026-09-21_fase3_b7_receipts_list/` (20 αρχεία: 15 αρχικά +
3 test files του fix + DESIGN.md + oldsessions.md).

## 5. Verification

`flutter test` **699/699** ✓ (677 → 699, +22) · `flutter analyze`
**No issues** ✓ · κανένα νέο ή τροποποιημένο `.dart` >500 γρ.

## 6. Ανοιχτά (δεν υλοποιήθηκαν σε αυτό το Βήμα)

- **Φάση 3 Βήμα 8 — Widget tests στη φόρμα**: τα ανά-υποβήμα widget tests
  υπάρχουν ήδη (Bήματα 3–7) — έλεγχος κενών/ενοποίηση πριν το κλείσιμο της
  Φάσης 3.
- **Housekeeping** (ξεχωριστό βήμα): split των test αρχείων >500 γρ.
  (`receipt_form_controller_test.dart`, `searchable_dropdown_field_test.dart`)
  — παραβίαση κανόνα 7 του AGENTS· ενοποίηση του διπλού κεφαλαίου 14.
- **Έξοδος με μη αποθηκευμένες γραμμές** (§2.2 «Ημιτελής καταχώρηση»,
  `ConfirmDialog` + `PopScope`) → «Βήμα 7β».
- **Προαιρετικό `onChanged` στο `SearchableDropdownField`**: τα inline
  μηνύματα του «+» δεν σβήνουν κατά την πληκτρολόγηση.

## 7. Επόμενο

Φάση 3, Βήμα 8 (Widget tests στη φόρμα) → Φάση 4 (Ρυθμίσεις). Ο έλεγχος
βρίσκεται σε κάθε Βήμα: κλείνει μόνο με ρητό OK, tests + analyze πράσινα και
ενημέρωση τεκμηρίωσης.