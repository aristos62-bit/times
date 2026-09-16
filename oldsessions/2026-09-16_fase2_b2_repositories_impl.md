# Φάση 2 — Βήμα 2: Repository Implementations

> Ημερομηνία: 16-09-2026 · Κατάσταση: Κλειστό · Υλοποίηση των 6 concrete
> repositories πάνω στα DAOs + helper escaping + transaction support.

---

## 1. Πεδίο

Υλοποίηση 6 concrete repository classes στο `lib/data/repositories/` που
καλύπτουν τις abstract interfaces του Βήματος 1. Κάθε implementation:
- Δέχεται **μόνο DAO(s)** στον constructor (όχι AppDatabase — `_dao.db` είναι
  `public final`, base_dao.dart:26).
- Χρησιμοποιεί `db.select(...)` για LIKE queries.
- Mapping: `SqliteException` → `DataLoadException` / `SaveReceiptException` (χωρίς
  re-log — το DAO ήδη κάνει log στο guard).
- Κενό search query → `Stream.value(const [])` (όχι `Stream.empty()`).

## 2. Προεργασία / Review

- Διάβασμα ΟΛΩΝ των εμπλεκόμενων αρχείων πριν κάθε υλοποίηση: DAOs (7),
  base_dao, app_database, app_exceptions, app_errors, app_constants, in_memory_db,
  DESIGN.md, interfaces (6), greek_text_normalizer.
- Επιβεβαίωση drift `like()` API: `Expression<bool> like(String regex,
  {String? escapeChar})` — `escapeChar` **υποστηρίζεται**, generates `LIKE ? ESCAPE '\'`
  (drift-2.35.0/lib/src/runtime/query_builder/expressions/text.dart:10).
- Επιβεβαίωση `SqliteException`: `final class SqliteException implements Exception`
  από `package:sqlite3/src/exception.dart`, re-exported via `drift/native.dart`.
- Διόρθωση docstring bug στο `unit_repository.dart` (deleteById): ήταν γραμμένο
  «επιτρέπεται πάντα» αλλά `ReceiptLines.unitId → RESTRICT` (tables.dart:81).

## 3. Εγκεκριμένες αποφάσεις (user OK)

1. **Constructor pattern**: Μόνο DAO(s), όχι AppDatabase — σωστό από B1.
2. **`escapeLike` placement**: Στην `GreekTextNormalizer` ως `static String
   escapeLike(String input)` — `\`→`\\`, `%`→`\%`, `_`→`\_`. Pattern bound
   σαν `Variable` (no SQL injection).
3. **Empty search**: `Stream.value(const [])` — κενό Stream, όχι `Stream.empty()`.
4. **No info log in search**: Ασυνεπές με το pattern «log rare/significant».

## 4. Αρχεία υλοποίησης

| Αρχείο | Γραμμές | Σημειώσεις |
|---|---|---|
| `category_repository_impl.dart` | 52 | CRUD + `watchAll`/`getById`/`getByNormalizedName` |
| `sub_category_repository_impl.dart` | 66 | + `watchByCategoryId` |
| `unit_repository_impl.dart` | 79 | RESTRICT test μέσω `ReceiptLines.unitId` |
| `item_repository_impl.dart` | 118 | LIKE search + `escapeLike` + `searchResultsLimit` |
| `supplier_repository_impl.dart` | 92 | LIKE search + `escapeLike` |
| `receipt_repository_impl.dart` | 88 | `insertReceiptWithLines` σε transaction, rollback test |
| `greek_text_normalizer.dart` | — | +`escapeLike` static method |
| `unit_repository.dart` | — | docstring fix (RESTRICT accuracy) |

### 4.1 Error Mapping (σύμβαση Βήμα 1)

| Λειτουργία | DAO (raw) | Repository (map) |
|---|---|---|
| watchAll / getById / getByNormalizedName | SqliteException | `DataLoadException` |
| search | SqliteException | `DataLoadException` |
| insert / update / delete (κατάλογος) | SqliteException | `DataLoadException` |
| insertReceiptWithLines | SqliteException | `SaveReceiptException` |

DAO guard logs + rethrows raw. Repos do NOT re-log (no double logging).

### 4.2 Stream Error Mapping

`.handleError((Object e, StackTrace s) => Error.throwWithStackTrace(
  const DataLoadException(), s))` — maps any stream error. Raw SqliteException
would leak to AsyncValueView otherwise. Drift's `watch()` on closed DB emits `[]`
then completes (NOT error) — deterministic tests use subclass DAO double.

### 4.3 Transaction (insertReceiptWithLines)

`_receiptDao.db.transaction(() async { insert receipt; for line → _lineDao.insert;
return receiptId; })`. DAO guard logs per-line failures; repo catch is logging-free.

## 5. Escape Testing

| Test | Input | Expected LIKE pattern |
|---|---|---|
| `%` escape | `5%` | `%5\%%` (starts with 5, ends with %) |
| `_` escape | `Test_` | `Test\_%` (starts with Test_, ends with wildcard) |
| Both | `a%_b` | `%a\%\_b%` |

GreekTextNormalizer.escapeLike: 8 unit tests covering `%`, `_`, `\`,
mixed, no special chars.

## 6. Verification

- `flutter analyze` **No issues found** ✓
- `flutter test` **315/315** ✓ (πριν: 229 — +24 normalizer + 62 repo tests)

### Bugs fixed during implementation

1. **`isNull`/`isNotNull` import ambiguity** (item test): `drift/drift.dart` +
   `flutter_test` both export → `hide isNull, isNotNull` + `show Value`.
2. **SQLite BINARY collation sort order** (supplier test): `'μαρκοπουλου'` <
   `'μαρκοσ'` (Unicode code point `π`(0x3C0) < `σ`(0x3C3)). Fixed expected order.

## 7. Backups

| Αρχείο | Backup |
|---|---|
| `unit_repository.dart` | `backups/unit_repository_before_docstring_fix_20260916_185321.dart` |
| `greek_text_normalizer.dart` | `backups/greek_text_normalizer_before_escapeLike_20260916_185334.dart` |
| `greek_text_normalizer_test.dart` | `backups/greek_text_normalizer_test_before_escapeLike_20260916_185334.dart` |

## 8. Επόμενο

- Φάση 2 — Βήμα 3: Riverpod StreamProviders + dependency injection.
