# Post-closure: έκπτωση συνόλου σε total-mode (25-09-2026)

> Κατάσταση: **Κλειστό**. Backup `backups/2026-09-25_total_discount/`
> (section + draft list + DESIGN πριν το feature).

---

## 1. Αίτημα

Total-mode μηδένιζε την έκπτωση («το σύνολο ΕΙΝΑΙ το τελικό») — σκόπιμο,
αλλά αδύνατη η καταχώριση «μικτό σύνολο + έκπτωση συνόλου» (π.χ. φέτα
0,634 κιλ · μικτά 6,91 € · έκπτωση 1,08 € → πληρωμή 5,83 €). Κλειδώθηκε:
σε total-mode η Έκπτωση = έκπτωση ΣΥΝΟΛΟΥ (εφάπαξ).

## 2. Υλοποίηση

- `unit_quantity_price_section.dart`: DiscountField πάντα ορατό ·
  `0≤D≤T` (reuse `validateDiscountCents`, 0 νέα strings) + guard
  παραγόμενης `discUnit=(D/Q).round()` (μονοτονία round ⇒ πλεονασμός,
  safety-net) · `_addLine`: `discountCents=discUnit`, `enteredTotal=T`.
  Toggle επανερμηνεύει κείμενα (όπως η Τιμή).
- `draft_lines_list.dart` (+4): με έκπτωση + snapshot δείχνει ΜΟΝΟ το
  καθαρό (όχι διπλό «σύνολο»).
- Αμετάβλητα: validator, DAO, controller, prefill (unit-only), stats
  (βλέπουν μικτά/έκπτωση/καθαρά αυτόματα), label πεδίου.
- DESIGN §2.2 (state machine + validation).

## 3. Tests (+5: T5–T8 section · 1 draft)

- T5 feta full-flow (1090/170/691 → stored 583) · T6 D>T →
  `discountTooLarge` · T7 κενό→0 · T8 toggle κρατά κείμενο · draft
  single-net (`5,83`, όχι `6,91`) · P4 prefill ενημερώθηκε (πεδίο ορατό,
  prefill άδειο).
- `flutter analyze` No issues ✓ · σουίτα **1033/1033** ✓ (+5).
