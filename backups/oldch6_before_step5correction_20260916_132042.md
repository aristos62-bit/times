# Φάση 1 — Code review fixes μετά τον έλεγχο του χρήστη

> Ημερομηνία: 16-09-2026 · Follow-up του Βήματος 4 μετά από εκτενή manual έλεγχο του χρήστη.

## Τι ελέγχθηκε

Ο χρήστης έκανε διεξοδικό review των Βημάτων 1-4 (μηχανικές επαληθεύσεις: seed counts 9/53/535, 0 duplicate normalizedName, όλες οι αναφορές έγκυρες, καμία ορφανή υποκατηγορία, max name 40/100, κανόνας ≤500 γρ., SPoT τηρείται) και εντόπισε **7 ευρήματα** (+ μικρότερα). Διορθώθηκαν όλα εγκεκριμένα.

## Διορθώσεις (με σειρά προτεραιότητας)

### 🔴 1. CASCADE στη διαγραφή απόδειξης → γραμμές
- **Πρόβλημα**: `ReceiptLines.receiptId` είχε `ON DELETE RESTRICT` → η διαγραφή απόδειξης με γραμμές ήταν ΑΔΥΝΑΤΗ. Το §3 DESIGN ζητάει RESTRICT μόνο για Category/SubCategory/Item. Η Receipt→ReceiptLine είναι σχέση **κυριότητας** (γραμμή χωρίς κεφαλίδα = άχρηστη).
- **Απόφαση χρήστη**: (α) `KeyAction.cascade` στο receiptId — μία γραμμή, δομικά ασφαλές. `unitId`/`itemId` παραμένουν RESTRICT.
- Ενημερώθηκε: `tables.dart` + docstring, σχόλιο `ReceiptDao.deleteById`, νέο test «CASCADE: διαγραφή απόδειξης σβήνει και τις γραμμές της» (receipt_dao_test.dart).
- **Σημείωση**: αλλαγή σχήματος → τοπικό db file πρέπει να σβηστεί (dev, μηδέν χρήστες).

### 🔴 2. `runSeed` τυλίγεται σε ρητό transaction
- **Πρόβλημα**: το §4.1.3 ζητάει seed «μέσα σε ένα transaction», αλλά το production path (onCreate) το κάλεσε χωρίς ρητό wrapper. Το παλιό μου συμπέρασμα «deadlock στο onCreate» ήταν **λάθος**: στη drift 2.33 ο `_BeforeOpeningExecutor.ensureOpen` (engines.dart:640-643) επιστρέφει αμέσως — το `db.transaction()` στο onCreate δουλεύει κανονικά.
- **Fix**: `Future<void> runSeed(AppDatabase db) => db.transaction(() async {...})` — ολόκληρο το σώμα είναι πλέον ρητά ατομικό.
- **Test**: το atomicity test αφαίρεσε το εξωτερικό `db.transaction(() => runSeed(db))` wrapper και καλεί **απλώς** `runSeed(db)` — ελέγχει πλέον ακριβώς την production διαδρομή.

### 🟠 3. `ItemDao.updateById` μπορεί πλέον να καθαρίζει το defaultUnitId
- **Πρόβλημα**: `null` σήμαινε «μην το πειράξεις» → αδύνατο να γυρίσει ένα είδος σε «χωρίς προτεινόμενη μονάδα» (θα σκόνταφτε Φάση 4).
- **Fix**: παράμετρος `Value<int?>? defaultUnitId` (drift pattern): `Value(null)` = καθάρισμα, `Value(id)` = θέση, `const Value.absent()` = no-op.
- **Test**: νέο — «Value(null) καθαρίζει, Value.absent() δεν το πειράζει». Value.absent() επιστρέφει `isFalse` (0 rows changed = no-op, σημασιολογικά σωστό).

### 🟠 4. LIKE αναζήτηση — δηλωμένη για Φάση 2
- Δεν προστέθηκε κώδικας. Ρητή απόφαση: `searchByNormalizedName(query, {limit})` με `searchResultsLimit` μπαίνει στα **Item/Supplier Repositories στη Φάση 2** (§2.0.4 / §3), όχι στα DAOs της Φάσης 2 β/2. Η Φάση 3 απλώς την καλεί.

### 🟠 5. Fail-fast στο seed για ομώνυμες υποκατηγορίες
- **Πρόβλημα**: το `subCategoryIds[s.name]` θα σκέπαζε σιωπηλά μια 2η ομώνυμη υποκατηγορία → είδη σε λάθος κλάδο χωρίς exception.
- **Fix**: `if (subCategoryIds.containsKey(s.name)) throw StateError(...)` — fail-fast, χωρίς αλλαγή στα seed files.

### 🟡 6. Batch insert για τα 535 items (ταχύ πρώτο άνοιγμα)
- Units/categories/subcategories χρειάζονται ids πίσω → σειριακά. Τα **items δε** χρειάζονται ids → `db.batch((b) => b.insertAll(db.items, itemCompanions))` — μία ατομική ομάδα χωρίς 535 round-trips. Το batch τρέχει μέσα στο transaction του #2.

### 🟡 7. `guardStream` κρατάει το αρχικό stack trace
- **Fix**: `Error.throwWithStackTrace(e, s)` αντί `throw e;` (το `throw e;` έκανε restart του stack στον handler → άχρηστο για debugs Φάσης 3).

### ⚪ Μικρότερα
- **CI**: `flutter test --coverage` + upload artifact lcov (μετριέται πλέον το coverage — αναφορά §1.8/Φάση 6).
- **Dead code `Value.absent()`**: κρατιέται ως πρόβλεψη με σχόλιο (το defaultUnitId είναι nullable §3) — ΟΧΙ αφαίρεση.
- **Κενά RESTRICT tests**: προστέθηκε το cascade test (#1). Το «item με γραμμή → raw error» υπήρχε ήδη (receipt_line_dao_test.dart:190).
- **FK ανενεργά κατά το seed**: σωστή επισήμανση — το PRAGMA FK μπαίνει στο beforeOpen (μετά το seed). Προστασία = οι StateError έλεγχοι του runner. Δεν απαιτεί αλλαγή.

## Verification

- `dart run build_runner build` ✓ (ξανά-γενιά μετά το CASCADE)
- `flutter analyze` → **No issues found**
- `flutter test` → **229/229** ✓ (227 + 2 νέα tests: cascade delete, defaultUnitId Value pattern)

## Backups (8 αρχεία, Φάση 1 fixes)

- `backups/{tables,seed_runner,item_dao,base_dao,seed_database_test,receipt_dao_test,item_dao_test}_before_fixes_20260916_130637.dart`
- `backups/flutter_ci_before_fixes_20260916_130637.yml`

## Σημείωση DESIGN.md

- ΚΑΜΙΑ αλλαγή: όλα τα fixes εντός του ήδη-σχεδιασμένου §3/§4.1.3/§4.1.34.