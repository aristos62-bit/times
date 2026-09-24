# Φάση 3 — post-closure: Διαχείριση αποδείξεων (Φάση Β · 24-09-2026)

> Κατάσταση: **ΟΛΟΚΛΗΡΩΘΗΚΕ** 24-09-2026. Section «Αποδείξεις» στις Ρυθμίσεις:
> φίλτρο ημέρας + λίστα + edit (άλμα Εισαγωγή) + delete. Reuse Φάσης Α πλήρες.

---

## 1. Αλλαγές

| Αρχείο | Αλλαγή |
|---|---|
| SPoT (`app_strings` +3, `app_constants` +1) | `titleReceiptsSection`/`clearReceiptFilter`/`noReceiptsForDay` + `manageReceiptsLimit`=100 |
| `receipt_dao.dart` (+~40) | +`watchSummariesByDay` (κλώνος recent + WHERE ημέρας, dateOnly όρια) |
| `receipt_repository(.impl)` | passthrough + error-mapping (Βήμα 2) |
| `stream_providers.dart` (+~30) | `selectedReceiptDayProvider` (Notifier — StateProvider αφαιρέθηκε στο Riverpod 3) + `receiptsByDayStreamProvider` (null→recent-100) |
| `shared/receipt_summary_tile.dart` (νέο, ~100) | SPoT tile· υιοθετήθηκε από `RecentReceiptsList` (ίδια pixels) |
| `settings/.../receipts_management_editor.dart` (νέο, ~290) | Φίλτρο (picker + «Όλες») + λίστα + edit-and-go + delete (pattern supplier-editor) |
| `settings_page.dart` | 4ο collapsible Card «Αποδείξεις» |
| tests | 6 fakes +`watchSummariesByDay`· SPoT +2· νέο DAO (6)· νέο widget (10)· settings_page +1 |

## 2. Ευρήματα

- **Ε1 — StateProvider ανύπαρκτο (Riverpod 3)** → Notifier+select/clear (pattern ThemeModeController).
- **Ε2 — διπλό `getLines` σε 2 fakes** (copy-paste) → διαγραφή αντιγράφου.
- **Ε3 — δικό μου test-λάθος** («Όλες» ×2 ενώ το subtitle δείχνει ημερομηνία) → findsOneWidget.
- **Ε4 — off-screen tap** στο real-router test (section χαμηλά) → `ensureVisible`.
- Επιβεβαιώθηκε: watch-`.first` πουθενά σε widget paths (Ε3 Φάσης Α)· goNamed ασφαλές (log `[NAV] → priceEntry`).

## 3. Verification

- `flutter analyze` No issues · **945/945** (+19) · μεγέθη <500 ·
  backup `backups/2026-09-24_faseB_receipts_mgmt/` (12) · DESIGN §2.3.
