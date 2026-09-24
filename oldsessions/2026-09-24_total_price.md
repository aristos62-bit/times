# Κεφάλαιο 28 — Φάση 3 post-closure: συνολική τιμή ανά γραμμή (όλες οι μονάδες)

**Ημερομηνία έναρξης:** 24-09-2026 · **Κατάσταση:** Κλειστό

## Αίτημα χρήστη

«Αν θέλω να εισάγω συνολική τιμή των 350 γραμμαρίων = 12 €, πώς το φτιάχνουμε
— για όλες τις μονάδες;» Το μοντέλο ήταν μοναδιαία τιμή (`lineTotal =
price×qty`), οπότε 350 + γρ + 12 € υπολόγιζε 4.200 € (12 €/γραμμάριο).

## Απόφαση (εγκεκριμένη — τελική πρόταση 24-09)

Διακόπτης «Συνολική τιμή» ανά γραμμή στο `unit_quantity_price_section`
(default OFF = σημερινή συμπεριφορά): ΟΝ = το πεδίο Τιμή είναι το σύνολο της
ποσότητας και η μοναδιαία παράγεται `(total/quantity).round()` — π.χ. 0,350
κιλ + 12 € → 3429 (34,29 €/κιλ) → stored σύνολο 1200. Χωρίς αλλαγή βάσης
(η μοναδιαία αποθηκεύεται, ο τύπος DAO και τα στατιστικά άθικτα)· ισχύει για
όλες τις μονάδες με τον ίδιο τρόπο.

## Επανέλεγχος reuse (τελικός)

- Reuse: `_quantityCheck`/`_priceCheck`, `ReceiptValidator` + ίδια errors,
  `DraftReceiptLine`/DAO/providers/controller/save/recent/stats (άθικτα),
  `ValueKey(item.id)` lifecycle, `formatCents`, `SwitchListTile`,
  test helpers (`fieldByLabel/enter/addEnabled/seed/wrap`).
- Διορθώσεις: guard παραγόμενης 0/overflow με ίδια errors (είχε διαφύγει) ·
  εξαίρεση Δ2 ΜΟΝΟ για total-mode γραμμές (stored `enteredTotalCents`
  snapshot, χωρίς επαν-υπολογισμό — SPoT μαθηματικών το DAO) · 2 νέα SPoT
  strings (`priceTotalMode`, `lineTotalLabel`) — κανένα νέο error/validator ·
  απόρριψη schema-change (θα έσπαγε Φάση 5 + migration + 800 tests).

## Αλλαγές

- **`app_strings.dart`** (+2 SPoT): `priceTotalMode='Συνολική τιμή'`,
  `lineTotalLabel='σύνολο'`.
- **`receipt_form_state.dart`**: `DraftReceiptLine.enteredTotalCents` (nullable,
  default null — υπάρχοντες καλούντες/tests άθικτοι) + ==/hashCode.
- **`unit_quantity_price_section.dart`**: `_isTotal` + `SwitchListTile` +
  παραγόμενη μοναδιαία με guards σε `canAdd` και `_addLine` (safety-net).
- **`draft_lines_list.dart`**: subtitle με σύνολο ΜΟΝΟ όταν
  `enteredTotalCents != null` (stored snapshot).
- **Tests**: `app_strings_test` (+1 exact + `_allStrings`) ·
  `validation_test` T1–T4 (μετατροπή 12/0,35→3429 · OFF regression ·
  overflow→`priceTooLarge` · zero→`priceMustBePositive`) ·
  `draft_lines_list_test` (+2: total subtitle · Δ2 preserved για μοναδιαίας).
- **DESIGN.md**: §2.2 (state machine + validation + Δ2 εξαίρεση) · §3
  (`priceCents` παραγόμενη + `enteredTotalCents` display-only).

## Tests

- Στοχευμένα: strings/draft/state + T1–T4 → pass (1 δικό μου assertion
  διορθώθηκε: UI-finder συνόλου μεταφέρθηκε στο draft test — το section tree
  δεν περιέχει draft list).
- Full suite: **862/862** ✓ (+7: +1 strings +4 T1–T4 +2 draft) · `--timeout 60s`
  (αποφυγή hangs) · `flutter analyze` **No issues** ✓ · κανένα `.dart` >500 γρ. ✓.

## Backup

- `backups/2026-09-24_total_price/` — section + draft list + state + strings +
  2 test αρχεία + DESIGN.md + oldsessions.md (πριν τις αλλαγές).
