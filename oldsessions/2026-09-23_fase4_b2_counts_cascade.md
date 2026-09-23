# Φάση 4 — Βήμα 2: DAO counts + cascade guards (23-09-2026)

> Κατάσταση: **Κλειστό**. Backup `backups/2026-09-23_fase4_b2_counts_cascade/`
> (category/sub_category DAO + DESIGN + oldsessions πριν το βήμα).

---

## 1. Σκοπός

Counts + cascade-delete στα **DAOs** (DESIGN §2.3:273 — repos = error-mapping
μόνο): προ-έλεγχος διαγραφής Κατηγορίας/Υποκατηγορίας και καθάρισμα orphan
Items σε transaction ως side-effect. Καμία UI αλλαγή — providers (Βήμα 3) και
tree editor (Βήμα 4) έπονται. Το FK `RESTRICT` του §3 παραμένει στο schema.

## 2. Κλειδωμένες διορθώσεις Α2 (αξιολόγηση χρήστη, ένα ΟΚ)

- **Α2-1 — Tooltip που λέει αλήθεια**: `countItems*` (πλήθος ειδών — confirm
  cascade Βήματος 4) + `countItemsInUse*` = COUNT(DISTINCT items.id) με ≥1
  γραμμή (πύλη: `0` = καθαρή). Το μήνυμα «Χ είδη έχουν καταχωρημένες τιμές»
  είναι νέο string Βήματος 4 — το υπάρχον `itemCountTooltip` («περιέχει»)
  δεν επαναχρησιμοποιείται λάθος.
- **Α2-2 — Typed drift API**: `selectOnly().join()` + `count()` /
  `count(distinct: true)` αντί `customSelect` (compile-time ονόματα — το
  `customSelect` μένει μόνο στο σύνθετο `watchRecentSummaries`).
- **Α2-3 — Απλούστερο cascade**: subquery `isInQuery` μέσα στο transaction
  (χωρίς branch άδειας λίστας, χωρίς όριο μεταβλητών, χωρίς race read→delete).
- **Α2-4 — Διαδικασία + test ατομικότητας**: backups πριν κάθε edit ·
  συγχρονισμός ονομάτων DESIGN §4:459 · test με 2 subs όπου η 2η έχει γραμμές
  → throw + πλήρες rollback. Σημείωση: το `items.sub_category_id` δεν έχει
  index (αμελητέο σε 53/535, χωρίς migration).
- **Q1**: δύο counts όπως παραπάνω · **Q2**: `deleteWithContents` ·
  **Q3**: όχι repo passthrough τώρα (Βήμα 3).

## 3. Υλοποίηση

- `lib/data/local/daos/category_dao.dart` (55→~150 γρ.): `countItemsByCategoryId`
  (join items→sub_categories) · `countItemsInUseByCategoryId` (join
  items→receipt_lines→sub_categories, DISTINCT) · `deleteWithContents`
  (transaction: είδη via subquery → υποκατηγορίες → κατηγορία). Υπάρχον
  `deleteById` (RESTRICT) άθικτο.
- `lib/data/local/daos/sub_category_dao.dart` (77→~165 γρ.): αντίστοιχα σε
  ένα επίπεδο (είδη → υποκατηγορία, `equals` αντί subquery).
- Όλα σε `guard` (log tag `DB`, raw rethrow) — κανένα νέο `AppLogger`,
  κανένα νέο SPoT string/const, κανένα schema change. Units άθικτες
  (SET NULL) · PriceEntry/dialog/search providers ανεπηρέαστα (auto re-emit
  των `watch` streams).

## 4. Tests (762 → 782, +20)

- Νέα: `category_counts_cascade_test` (10) · `sub_category_counts_cascade_test`
  (10): counts 0/N/DISTINCT/απομόνωση · cascade άδειας/με-περιεχόμενα/
  ανύπαρκτου → `false` · μπλοκαρισμένη → raw `SqliteException` (όχι
  `AppException`) + rollback (όλα ανέγγιχτα, γραμμές παρούσες).
- Βάση 762 (επαληθευμένη με προσωρινή μετακίνηση των νέων αρχείων — το
  DESIGN §5 έγραφε ήδη 762/762· η σύνοψη root έγραφε 760/760, διορθώνεται).
- `flutter analyze` No issues ✓ (typed API compile με την πρώτη) ·
  `flutter test` **782/782** ✓.

## 5. Ευρήματα/fixes του βήματος

- Κανένα fix — υλοποίηση + tests πέρασαν με την πρώτη. Τα `[DB][ERROR]`
  logs στα blocked tests είναι σκόπιμα (guard λογκάρει πριν το rethrow).
- `flutter analyze` No issues ✓ · `flutter test` **782/782** ✓.

## 6. Επόμενο

Βήμα 3 — Providers ελέγχου (`canDeleteCategoryProvider` /
`canDeleteSubCategoryProvider` + `categoryTreeStreamProvider`).
