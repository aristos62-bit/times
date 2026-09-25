# Post-closure: auto-refresh πυλών διαγραφής από save/delete (25-09-2026)

> Κατάσταση: **Κλειστό**. Backup `backups/2026-09-25_guard_invalidation/`
> (controller + oldsessions + DESIGN πριν το fix).
> Βάση εκκίνησης: 1024/1024 (row #37: Φάση 4 Βήμα 5).

---

## 1. Εύρημα

Τα `canDelete*/inUseCount*` families είναι one-shot (`FutureProvider.family`)
και δεν ξανατρέχουν όταν η «Εισαγωγή Τιμών» προσθέτει/σβήνει γραμμές
(IndexedStack, άλλο tab). Μόνη ανανέωση ήταν το χειροκίνητο «↻»
(`refreshGuards`). Όχι bug ακεραιότητας (defense-in-depth στα deletes),
αλλά UX gap: φαινομενικά ενεργό delete → σφάλμα, ή stale greyed-out.

## 2. Υλοποίηση (μόνο `receipt_form_controller.dart`, 371→~416 γρ.)

- Νέο private `_refreshAffectedGuards({supplierId, itemIds})`: invalidate
  supplier pair + ανά distinct item → `itemRepo.getById` → `subRepo.getById`
  → invalidate sub pair + category pair · `ref.mounted` guards · `on
  Exception` → log + swallow (save/delete έχει πετύχει· stale = πριν).
- `saveReceipt` (insert + update): κλήση μετά το `resetForm()` (ids ήδη
  στη μνήμη — 0 reads προμηθευτή, 2 PK-reads/είδος).
- `deleteReceipt`: pre-read (`getById` + `getLines`) ΠΡΙΝ το delete (μετά
  χάνεται) · κλήση σε επιτυχία.
- Ρητά εκτός: `loadReceiptForEdit`/`resetForm`/new-item flows (read-only ή
  χωρίς γραμμές) · δέντρο (stream-driven) · «↻» μένει ως δίχτυ.
- Reuse: families + `ref.invalidate(id)` (precedent category controller) ·
  `getById/getLines` (precedent `loadReceiptForEdit`) · 0 νέα
  providers/state/strings · import `settings_providers` ακίνδυνο (0 κύκλος).

## 3. Tests (1024 → 1028, +4)

- ΝΕΟ `receipt_form_guard_invalidation_test` (listen-based, precedent Βήμα 3
  Ε1): supplier rebuild true→false · category/sub rebuild · throwing
  itemRepo → save πράσινο + stale (swallow) · delete rebuild false→true.
- Υπάρχοντα save/delete tests άθικτα (real item/sub repos — τα throwing
  fakes ζουν μόνο σε item_search tests).
- `flutter analyze` No issues ✓ · `flutter test --timeout 60s` **1028/1028** ✓.
