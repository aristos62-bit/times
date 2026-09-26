# Post-closure: όριο fallback πίτας 360→300 (26-09-2026)

> Κατάσταση: **Κλειστό.**
> Report χρήστη: «βλέπω μόνο τα labels με τις τιμές» (πίνακας αντί πίτας).

---

## 1. Αίτιο

Το `pieFallbackMaxWidth = 360` μετρούσε το πλάτος ΜΕΤΑ το οριζόντιο padding
16 της κάρτας: σε κινητό 320–360px μένουν ~304–344 → **πάντα πίνακας, ποτέ
πίτα**. Λάθος υπολογισμός ορίου, όχι bug λογικής (τα tests περνούσαν — το
threshold δεν είχε test σε πραγματικό πλάτος συσκευής).

## 2. Αλλαγές

- `AppConstants.pieFallbackMaxWidth`: 360.0 → 300.0 (+ σχόλιο αιτίου).
- Νέο test: 320px/304 διαθέσιμα → πίτα (όχι πίνακας).
- Fix overflow: value legend σε `Flexible` + ellipsis (320px + scaler 2.0
  ξεχείλιζε 29px — πιάστηκε από το υπάρχον responsive test).

## 3. Tests

- Σουίτα **1137/1137** ✓ (+1) · `flutter analyze` **No issues** ✓.

## 4. Docs

- DESIGN.md: ΚΑΜΙΑ αλλαγή (ίδια αρχιτεκτονική, διόρθωση τιμής SPoT).
- Backup: `backups/2026-09-26_fase5_threshold_fix/` (2 αρχεία πριν).
