# DESIGN.md — Εφαρμογή "Times" (Τιμές)

> Έγγραφο αρχιτεκτονικής και σχεδιασμού. Ενημερώνεται μετά από κάθε ουσιαστική αλλαγή στην εφαρμογή. Αντικαθιστά πλήρως κάθε προηγούμενη έκδοση/προδιαγραφή.

---

## 0. Ταυτότητα Εφαρμογής

| Στοιχείο | Τιμή |
|---|---|
| Όνομα εφαρμογής | **Τιμές** (διεθνές/τεχνικό όνομα: `Times`) |
| Σκοπός | Προσωπική καταγραφή αγορών/αποδείξεων, παρακολούθηση τιμών ειδών ανά προμηθευτή, στατιστικά και συγκρίσεις τιμών στον χρόνο |
| Πλατφόρμα | Flutter/Dart — Android, iOS, Windows (desktop), Web (προαιρετικά αργότερα) |
| Γλώσσα UI | Ελληνικά (μοναδική γλώσσα, μέσω SPoT strings — όχι hardcoded) |
| Βάση δεδομένων | SQLite μέσω **Drift** (type-safe ORM, ενεργά συντηρούμενο, αντικαθιστά το εγκαταλελειμμένο Isar) |
| State management | Riverpod (StreamProvider / AsyncNotifier για real-time reactive UI) |
| Πλοήγηση | GoRouter |
| Θέμα | Light / Dark / Auto (system) |
| Λειτουργία | 100% offline-first, τοπική βάση· "online" = προαιρετικός μελλοντικός συγχρονισμός (δεν είναι στο MVP, σχεδιάζεται ως επέκταση) |
| "Real-time" | UI ενημερώνεται αυτόματα και άμεσα σε κάθε αλλαγή δεδομένων μέσω reactive streams — όχι δικτυακός συγχρονισμός |

**Λογότυπο / branding**: Θα οριστεί στη Φάση 1 (βλ. παρακάτω) — παλέτα χρωμάτων, εικονίδιο εφαρμογής, splash screen, όνομα πακέτου (`com.<σου>.times` ή αντίστοιχο). Καμία σελίδα δεν θα κυκλοφορήσει με προεπιλεγμένο Flutter branding, γενικές περιγραφές τύπου "My App" ή placeholder εικόνες.

---

## 1. Αρχιτεκτονικές Αρχές (Δεσμευτικές για όλο το project)

1. **SPoT (Single Point of Truth) παντού**
   - Κείμενα UI → `lib/core/constants/app_strings.dart`
   - Αριθμητικές/στατικές τιμές (paddings, διάρκειες, όρια) → `lib/core/constants/app_constants.dart`
   - Χρώματα/θέματα → `lib/core/theme/app_theme.dart` + `app_colors.dart`
   - Μονάδες μέτρησης, τύποι κατηγοριών → `lib/core/constants/app_enums.dart` (ή πίνακας στη βάση, βλ. §3)
   - Routes → `lib/core/router/app_routes.dart` (ονόματα/paths ως σταθερές, ποτέ raw strings σε `context.go(...)`)
   - **Κανόνας**: αν μια τιμή/κείμενο/χρώμα εμφανίζεται σε 2+ σημεία ή είναι πιθανό να αλλάξει, πάει σε SPoT αρχείο. Καμία εξαίρεση.

2. **Διαχωρισμός επιπέδων (Clean Layering)**
   ```
   lib/
   ├── core/            (constants, theme, router, utils, errors, logging)
   ├── data/
   │   ├── local/       (Drift database, tables, DAOs)
   │   ├── models/      (Freezed data classes / entities)
   │   └── repositories/(abstract + implementation, μοναδικό σημείο πρόσβασης στη βάση)
   ├── domain/
   │   └── services/    (business logic: στατιστικά, συγκρίσεις τιμών, validation rules)
   ├── presentation/
   │   ├── home/        (Κεντρική - Γραφήματα/Στατιστικά)
   │   ├── price_entry/ (Εισαγωγή τιμών)
   │   ├── settings/    (Ρυθμίσεις)
   │   └── shared/      (κοινά widgets: search field, dropdown, dialogs)
   └── main.dart
   ```
   - Το UI **δεν** μιλάει ποτέ απευθείας με τη βάση· περνάει πάντα από Repository → Riverpod Provider → Widget.
   - Κάθε repository εκθέτει `Stream<List<T>>` για ό,τι πρέπει να ενημερώνεται real-time.

3. **Καμία hardcoded τιμή σε UI ή business logic.** Κάθε αριθμός/κείμενο/χρώμα περνάει από SPoT αρχείο (βλ. §1.1).

4. **Responsive & χωρίς overflow παντού**
   - `LayoutBuilder` / `MediaQuery` breakpoints ορισμένα σε `app_constants.dart` (π.χ. `mobileMaxWidth`, `tabletMaxWidth`).
   - Χρήση `Flexible`/`Expanded`/`Wrap`/`SingleChildScrollView` σε κάθε οθόνη — ποτέ σταθερά `SizedBox` ύψη σε λίστες/φόρμες που μπορεί να μεγαλώσουν.
   - Test σε τουλάχιστον 3 μεγέθη οθόνης (μικρό κινητό, tablet, desktop window resize) πριν κλείσει κάθε Phase.

5. **Θέμα**
   - `ThemeMode.system` ως προεπιλογή, με δυνατότητα override από τον χρήστη (Light/Dark/Auto) αποθηκευμένη τοπικά (SharedPreferences).
   - Όλα τα χρώματα από `ColorScheme`, ποτέ raw `Color(0xFF...)` μέσα σε widgets.

6. **Προσβασιμότητα**: `Semantics` labels σε όλα τα interactive στοιχεία (πεδία, κουμπιά, dropdowns), ιδίως στη φόρμα εισαγωγής τιμών.

7. **Logging / Debug**
   - `lib/core/logging/app_logger.dart` — SPoT logger με ομαδοποιημένα tags: `DB`, `UI`, `NAV`, `STATS`, `BACKUP`.
   - Κάθε repository/service καταγράφει: create/update/delete operations, σφάλματα, query results (σε debug mode μόνο).
   - Config αρχείο `lib/core/logging/debug_config.dart` για ενεργοποίηση/απενεργοποίηση ανά κατηγορία log.

8. **Testing**
   - `test/` mirror του `lib/` δέντρου.
   - Unit tests: repositories, services (στατιστικά, price comparison logic), validators.
   - Widget tests: φόρμα εισαγωγής τιμών (πιο κρίσιμη οθόνη), search/autocomplete λογική.
   - Στόχος: **>80% coverage** μέσω `flutter test --coverage`.
   - Κάθε νέο feature σε κάθε Phase συνοδεύεται από αντίστοιχα tests πριν κλείσει η φάση.

9. **Backup/Restore**
   - Export ολόκληρης της SQLite βάσης σε αρχείο `.db` (ή JSON export ως εναλλακτική, ανθρωπίνως αναγνώσιμη) σε επιλεγμένο φάκελο συσκευής.
   - Restore με επιβεβαίωση (προειδοποίηση αντικατάστασης τρεχόντων δεδομένων) και validation του αρχείου πριν την εισαγωγή.

10. **Καμία αλλαγή στο documentation δεν μένει εκκρεμής** — μετά από κάθε Phase/βήμα ενημερώνονται: `DESIGN.md` (αυτό το αρχείο), `AGENTS.md` (κανόνες συνεργασίας), τυχόν `oldsessions.md`.

---

## 2. Δομή Οθονών (σύμφωνα με τις προδιαγραφές σου)

### 2.1 Κεντρική Σελίδα — Γραφήματα & Στατιστικά
- Επισκόπηση: σύνολο δαπανών ανά περίοδο, top ακριβότερα/φθηνότερα είδη, εξέλιξη τιμής συγκεκριμένου είδους στον χρόνο, σύγκριση τιμών μεταξύ προμηθευτών για το ίδιο είδος.
- Φίλτρα περιόδου (μήνας/τρίμηνο/έτος/custom range) και κατηγορίας.
- Γραφήματα μέσω `fl_chart` (ελαφριά, ενεργά συντηρημένη βιβλιοθήκη, καλή υποστήριξη dark mode).

### 2.2 Σελίδα Εισαγωγής Τιμών
Ροή ακριβώς όπως περιγράφηκε:
1. Αυτόματος αύξων αριθμός απόδειξης (το internal AUTOINCREMENT id της βάσης, read-only πεδίο — βλ. απόφαση §3).
2. Ημερομηνία απόδειξης (date picker, προεπιλογή σήμερα).
3. Προμηθευτής: αναζήτηση με autocomplete → αν δεν βρεθεί, "+" για νέο προμηθευτή (inline, χωρίς αλλαγή οθόνης).
4. Αναζήτηση είδους: incremental filtering σε live query στη βάση (debounced, π.χ. 250ms) πάνω σε ολόκληρη την περιγραφή του είδους.
   - Βρέθηκε & επιλέχθηκε → εμφάνιση Κατηγορίας/Υποκατηγορίας (read-only, ενημερωτικά) → μονάδα μέτρησης (dropdown από SPoT πίνακα μονάδων) → ποσότητα → τιμή → αποθήκευση με SnackBar επιβεβαίωσης.
   - Δεν βρέθηκε ή θέλει νέο → "+" → popup: επιλογή Κατηγορίας (dropdown, με "+" για νέα κατηγορία) → Υποκατηγορία (ίδια λογική) → νέο Είδος → συνέχεια στη ροή μονάδα/ποσότητα/τιμή.
5. Μία απόδειξη μπορεί να έχει πολλαπλά είδη (γραμμές) πριν οριστικοποιηθεί — θα αποφασιστεί στη Φάση 3 αν είναι line-by-line save ή "καλάθι" ανά απόδειξη (προτείνω "καλάθι": απόδειξη = header + πολλές γραμμές ειδών, save μαζί στο τέλος για ατομική συνέπεια δεδομένων).

### 2.3 Σελίδα Ρυθμίσεων
- Επιλογή θέματος (Light/Dark/Auto).
- Διαχείριση Κατηγοριών/Υποκατηγοριών: επεξεργασία ονόματος, διαγραφή **μόνο** αν δεν έχουν συνδεδεμένα είδη/εγγραφές (έλεγχος foreign key πριν την επιτρέψει το UI).
- Backup (export) / Restore (import) με επιβεβαιωτικά dialogs.
- Ονομασία αρχείου backup με timestamp: `times_backup_YYYYMMDD_HHmmss.db` (επιτρέπει πολλαπλά backups χωρίς overwrite).
- **Αυτόματο backup πριν από κάθε Restore** (validation του υπάρχοντος backup που θα αντικατασταθεί) — απαίτηση σχεδίασης, υποχρεωτική.
- (Προαιρετικό, βλ. Φάση 6) Διαχείριση μονάδων μέτρησης, προμηθευτών · αυτόματο περιστασιακό backup (weekly) — σημειωμένη μελλοντική επέκταση, όχι MVP.

---

## 3. Σχήμα Βάσης Δεδομένων (Drift)

```
Category        (id, name, createdAt)
SubCategory     (id, categoryId → Category, name)
Item            (id, subCategoryId → SubCategory, name, defaultUnitId → Unit)
Unit            (id, name, abbreviation)             -- π.χ. Τεμάχιο/τεμ, Κιλό/κιλ, Λίτρο/λτ
Supplier        (id, name, createdAt)
Receipt         (id, receiptNumber [auto], date, supplierId → Supplier)
ReceiptLine     (id, receiptId → Receipt, itemId → Item, unitId → Unit, quantity, price, lineTotal)
```
- `receiptNumber`: χρησιμοποιείται το **internal `INTEGER PRIMARY KEY AUTOINCREMENT` id της απόδειξης**. Η εφαρμογή είναι προσωπική και όχι φορολογικό βιβλίο, άρα οι πιθανές "τρύπες" στην αρίθμηση μετά από διαγραφή δεν είναι πρόβλημα. Αυτή την απόφαση την ορίζουμε ρητά στη Φάση 1 (δεν χρειάζεται ξεχωριστό sequence table/counter).
- Όλα τα foreign keys με `ON DELETE RESTRICT` για Category/SubCategory/Item (ώστε να μην διαγράφονται αν έχουν δεδομένα) — υλοποιεί απευθείας τον κανόνα της §2.3.
- Indexes σε `Item.name` (για γρήγορη αναζήτηση) και `ReceiptLine.itemId` (για στατιστικά).

---

## 4. Φάσεις Ανάπτυξης

> Κάθε φάση κλείνει μόνο όταν: (α) ο κώδικας λειτουργεί, (β) τα tests της φάσης περνάνε, (γ) το DESIGN.md ενημερώνεται, (δ) έχεις δώσει ρητό OK.

### Φάση 0 — Θεμελίωση Project
1. Δημιουργία Flutter project, ρύθμιση `pubspec.yaml` (Drift, Riverpod, GoRouter, fl_chart, shared_preferences, file_picker για backup).
2. Ορισμός branding: όνομα app, package id, εικονίδιο, splash screen, χρωματική παλέτα.
3. Δημιουργία δομής φακέλων (§1.2) με κενά αρχεία-σκελετούς.
4. `app_strings.dart`, `app_constants.dart`, `app_colors.dart` — αρχικό SPoT σκελετό.
5. `app_logger.dart` + `debug_config.dart`.
6. `AGENTS.md` με τους κανόνες συνεργασίας μας (βήμα-βήμα, backups, confirmations).

### Φάση 1 — Βάση Δεδομένων & Domain Models
1. Ορισμός Drift tables (§3).
2. DAOs με βασικά CRUD + streams.
3. Seed δεδομένων για μονάδες μέτρησης (Τεμάχιο, Κιλό, Γραμμάριο, Λίτρο, Χιλιοστόλιτρο κ.λπ.) ως SPoT seed, όχι hardcoded στο UI.
4. Unit tests στα DAOs.

### Φάση 2 — Repository Layer
1. Abstract repositories (Category, SubCategory, Item, Unit, Supplier, Receipt).
2. Υλοποιήσεις πάνω στα DAOs, με `Stream` methods για real-time.
3. Riverpod providers (`StreamProvider`) πάνω στα repositories.
4. Unit tests repositories (mocked DB ή in-memory Drift).

### Φάση 3 — Σελίδα Εισαγωγής Τιμών (πυρήνας εφαρμογής)
1. UI σκελετός οθόνης, responsive layout.
2. Auto αριθμός απόδειξης + date picker.
3. Supplier search/autocomplete + inline "+" δημιουργία.
4. Item search/autocomplete με incremental filtering (debounce) + "+" popup ροή (Κατηγορία→Υποκατηγορία→Είδος).
5. Unit dropdown, ποσότητα, τιμή, save flow ("καλάθι" απόδειξης — βλ. §2.2.5).
6. Validation (π.χ. τιμή > 0, υποχρεωτικά πεδία) μέσω SPoT validators.
7. **Placeholder λίστα αποδείξεων** (read-only `ListView` με τις τελευταίες αποδείξεις: αριθμός, ημερομηνία, προμηθευτής, ένδειξη αριθμού γραμμών/συνόλου) — όχι επεξεργάσιμη, ως "vertical slice" για οπτική επιβεβαίωση ότι η ροή δεδομένων δουλεύει πριν τη Φάση 5.
8. Widget tests στη φόρμα.

### Φάση 4 — Ρυθμίσεις
1. Theme switcher (Light/Dark/Auto) με persistence.
2. CRUD Κατηγοριών/Υποκατηγοριών με έλεγχο δυνατότητας διαγραφής.
3. Backup export (.db/JSON) και Restore import με validation.
4. Tests.

### Φάση 5 — Κεντρική Σελίδα (Στατιστικά & Γραφήματα)
1. Domain service για υπολογισμούς (μέση τιμή ανά περίοδο, εξέλιξη τιμής είδους, σύγκριση προμηθευτών).
2. UI φίλτρων περιόδου/κατηγορίας.
3. Γραφήματα με `fl_chart`, responsive σε όλα τα μεγέθη οθόνης, dark-mode συμβατά χρώματα. **Ρητή απαίτηση**: τα γραφήματα πρέπει να δίνουν ρητά constraints ώστε να μην κόβονται legends/labels σε πολύ στενά ή πολύ φαρδιά containers· όπου το γράφημα δεν χωράει στο διαθέσιμο χώρο, χρησιμοποιείται **fallback σε πίνακα/λίστα** (safety net) αντί για overflow ή μη-αναγνώσιμο γράφημα.
4. Unit tests στο domain service (η πιο κρίσιμη λογική για coverage).

### Φάση 6 — Στίλβωση & Επεκτάσεις
1. Πλήρης έλεγχος responsive/overflow σε real συσκευές/μεγέθη.
2. Accessibility pass (Semantics σε όλη την εφαρμογή).
3. Έλεγχος συνολικού test coverage (>80%) και συμπλήρωση κενών.
4. Προαιρετικά (μόνο αν το ζητήσεις): διαχείριση προμηθευτών/μονάδων από Ρυθμίσεις, cloud sync ως μελλοντική επέκταση, **αυτόματο περιστασιακό backup (weekly)** — σημειωμένο ως επέκταση που απαιτεί background scheduling (WorkManager/permissions), όχι απαίτηση MVP.

---

## 5. Επόμενο Βήμα

Ξεκινάμε από τη **Φάση 0, Βήμα 1** μόνο όταν μου δώσεις ρητή εντολή. Μέχρι τότε δεν δημιουργώ κανένα αρχείο κώδικα.
