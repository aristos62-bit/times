# Φάση 2 — Βήμα 1: Abstract Repositories (Repository Layer)

> Ημερομηνία: 16-09-2026 · Κατάσταση: Κλειστό · Αποφάσεις + υλοποίηση του πρώτου
> βήματος της Φάσης 2 (DESIGN §4 Φάση 2 — Βήμα 1).

---

## 1. Πεδίο

Ορισμός 6 abstract repository interfaces στο `lib/data/repositories/`:
Category, SubCategory, Item, Unit, Supplier, Receipt — μόνο interfaces, ΚΑΜΙΑ
υλοποίηση (Βήμα 2). Καμία αλλαγή σε υπάρχοντα αρχεία εκτός από το NOTE στο
`app_errors.dart`.

## 2. Προεργασία / Review

- Πλήρης ανάγνωση: DESIGN.md (§4 Φάση 2, §2.0.4, §2.2, §3), 6 παλιά κεφάλαια
  oldsessions, 7 DAOs, base_dao, app_database, app_exceptions, app_errors,
  app_constants, in_memory_db.
- Διαπιστώθηκαν: μηδέν υπάρχοντα repositories, μηδέν Riverpod providers,
  μηδέν Freezed models, dependencies πλήρη (drift, flutter_riverpod ^3.4.3,
  SDK ^3.13.2).

## 3. Εγκεκριμένες αποφάσεις (user OK)

1. **searchByNormalizedName** σε ItemRepository ΚΑΙ SupplierRepository (όχι στα
   DAOs — DESIGN §4 Φάση 2). Κενό query → κενό Stream · escaping `%`/`_` του
   input (helper στην υλοποίηση Βήμα 2 — **δεν αλλάζει το interface**).
   Προαιρετικό `limit` (default `AppConstants.searchResultsLimit`=15).
2. **Repos δέχονται AppDatabase + DAO** στην υλοποίηση (Βήμα 2) — LIKE queries
   μέσω `db.select(...)`, μηδέν query logic εκτός του LIKE.
3. **Καμία Freezed** — τα repos επιστρέφουν drift data classes απευθείας
   (`Category`, `Item`, ... μέσω `import '../local/app_database.dart'`).
4. **Exception mapping (NOTE αντί νέα κλάση)**: reads → `DataLoadException`,
   `insertReceiptWithLines` → `SaveReceiptException`, άλλες writes →
   `DataLoadException` προσωρινά. NOTE στο `app_errors.dart` (loadDataFailed)
   αναφέρει ότι καλύπτει και write-time FK/UNIQUE καταλόγου μέχρι τη Φάση 3/4
   με validators — ίδιο μοτίβο με το NOTE στο app_exceptions.dart. Λογική:
   λεπτό repo layer, το canDeleteCategoryProvider pre-check (§2.3, Φάση 4)
   προλαμβάνει τα FK violations, μη-αναστρέψιμο θα ήταν διπλή δουλειά.

## 4. Αρχεία

| Αρχείο | Interface | Σημειώσεις |
|---|---|---|
| `lib/data/repositories/category_repository.dart` | CategoryRepository | Μirror CategoryDao |
| `lib/data/repositories/sub_category_repository.dart` | SubCategoryRepository | + `watchByCategoryId` |
| `lib/data/repositories/unit_repository.dart` | UnitRepository | φull CRUD |
| `lib/data/repositories/item_repository.dart` | ItemRepository | + `searchByNormalizedName`, `Value<int?>? defaultUnitId` στο updateById |
| `lib/data/repositories/supplier_repository.dart` | SupplierRepository | + `searchByNormalizedName` |
| `lib/data/repositories/receipt_repository.dart` | ReceiptRepository | + `watchLines`, `insertReceiptWithLines`, typedef `ReceiptLineInput` (record) |
| `lib/core/constants/app_errors.dart` | — | μόνο NOTE (5 γραμμές) στο `loadDataFailed` |

**Κρίσιμα τεχνικά σημεία:**
- Τα data classes (`Category`, `Item`, ...) ζουν στο `app_database.g.dart`
  (part). Γι' αυτό τα interfaces importάρουν `../local/app_database.dart` —
  οΧΙ το DAO αρχείο (αρχικό λάθος: unused import + `Category isn't a type`).
- `ReceiptLineInput` = `({int itemId, int unitId, double quantity, int priceCents})`
  (record typedef) — το `lineTotalCents` υπολογίζεται στο DAO (SPoT §3).
- `Value<int?>? defaultUnitId`: `Value(null)`=καθάρισμα, `const Value.absent()`=no-op
  (σύμβαση Βήμα 4 review fix #3).
- Δεν υπάρχει ξεχωριστό ReceiptLineRepository — οι λειτουργίες γραμμών ζουν στο
  ReceiptRepository (DESIGN §4).

## 5. Error mapping (συμβόλαιο Βήμα 1)

| Λειτουργία | DAO (raw) | Repository (map) |
|---|---|---|
| watchAll / getById / getByNormalizedName / search | SqliteException | `DataLoadException` → loadDataFailed |
| insert / update / delete (κατάλογος) | SqliteException | `DataLoadException` (προσωρινά, NOTE) |
| insertReceiptWithLines | SqliteException | `SaveReceiptException` → saveFailed (§2.2) |

Τα DAOs ρίχνουν πάντα raw + log (BaseDao guard) — η γραμμή του mapping είναι
Η ευθύνη του Repository (σύμβαση Φάσης 1 Βήμα 2).

## 6. Verification

- `flutter analyze` **No issues found** ✓ (μετά από διόρθωση imports:
  app_database αντί DAO, drift μόνο όπου χρησιμοποιείται `Value` — item).
- `flutter test` **229/229** ✓ (μηδέν regressions — μόνο interfaces + main
  + test, καμία αλλαγή σε DAOs/tests).

## 7. Backups

| Αρχείο | Backup |
|---|---|
| `lib/core/constants/app_errors.dart` | `backups/app_errors_20260916_*.dart` (πριν το NOTE) |

## 8. Επόμενο

- Φάση 2 — Βήμα 2: υλοποιήσεις των 6 interfaces πάνω στα DAOs (+ helper
  escaping για LIKE, κενό query → κενό Stream, numWrapping σε AppException,
  `insertReceiptWithLines` σε transaction).