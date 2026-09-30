/// Drift πίνακες της βάσης (§3 DESIGN.md) — Refactor 4 επιπέδων 27-09-2026.
///
/// 8 πίνακες: Categories, SubCategories, ItemGroups, Units, Items,
/// Suppliers, Receipts, ReceiptLines. Ιεραρχία καταλόγου:
/// Category (Τρόφιμα) ▸ SubCategory (Γαλακτοκομικά) ▸ ItemGroup
/// (Τμήμα, π.χ. Φέτα) ▸ Item (π.χ. Φέτα Βαρέλι Μυτιλήνης).
/// Foreign keys με `ON DELETE RESTRICT` σε όλο τον κατάλογο
/// (Category/SubCategory/ItemGroup/Item/Supplier/Unit — προστασία §2.3).
/// Η Receipt→ReceiptLine είναι σχέση κυριότητας: `ReceiptLines.receiptId`
/// κάνει `CASCADE` (η διαγραφή απόδειξης σβήνει και τις γραμμές της — §3).
/// Το προαιρετικό `Items.defaultUnitId` είναι `SET NULL` (null = χωρίς πρόταση).
/// `normalizedName` global UNIQUE σε Category/SubCategory/ItemGroup/Item/
/// Supplier (πεζά/άτονα/ς→σ, §2.2 — καμία επανάληψη ονόματος πουθενά).
/// Το μοναδικό ρητό index είναι στο `ReceiptLine.itemId` (για στατιστικά)·
/// τα `UNIQUE` φέρνουν index αυτόματα.
///
/// Καμία στήλη με length/check constraint: `maxItemNameLength` είναι
/// validation του domain layer, όχι σχήματος — §3 DESIGN.
library;

import 'package:drift/drift.dart';

/// Κατηγορίες ειδών (π.χ. Τρόφιμα) — ένα Item ανήκει πάντα σε μία,
/// μέσω Υποκατηγορίας ▸ Τμήματος.
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get normalizedName => text().unique()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Υποκατηγορίες κάτω από μία κατηγορία (π.χ. Γαλακτοκομικά).
class SubCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.restrict)();
  TextColumn get name => text()();
  TextColumn get normalizedName => text().unique()();
}

/// Τμήματα κάτω από μία υποκατηγορία (π.χ. Φέτα) — 27-09-2026.
///
/// Το «Τμήμα» είναι το 3ο επίπεδο καταλόγου (ορατό όνομα UI: «Τμήμα»).
/// Το είδος ανήκει πάντα σε ένα τμήμα (`Items.itemGroupId`).
class ItemGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subCategoryId =>
      integer().references(SubCategories, #id, onDelete: KeyAction.restrict)();
  TextColumn get name => text()();
  TextColumn get normalizedName => text().unique()();
}

/// Μονάδες μέτρησης (Τεμάχιο/τεμ, Κιλό/κιλ, ...) — §3.
class Units extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get abbreviation => text()();
  BoolColumn get allowsDecimal =>
      boolean().withDefault(const Constant(false))();
}

/// Είδη — το `normalizedName` είναι global UNIQUE (πεζά/άτονα/ς→σ),
/// ώστε η βάση να απορρίπτει διπλότυπα (π.χ. «Γάλα» vs «γαλα»).
class Items extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemGroupId => integer()
      .references(ItemGroups, #id, onDelete: KeyAction.restrict)();
  TextColumn get name => text()();
  TextColumn get normalizedName => text().unique()();
  IntColumn get defaultUnitId =>
      integer().nullable().references(Units, #id, onDelete: KeyAction.setNull)();
}

/// Προμηθευτές — το `normalizedName` είναι global UNIQUE (όπως Items).
class Suppliers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get normalizedName => text().unique()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Αποδείξεις — το `id` (AUTOINCREMENT) χρησιμεύει ως αριθμός απόδειξης
/// (απόφαση §3: δεν χρειάζεται ξεχωριστός sequence counter).
class Receipts extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get supplierId =>
      integer().references(Suppliers, #id, onDelete: KeyAction.restrict)();
}

/// Γραμμές αποδείξεων — `lineTotalCents` υπολογισμένο μία φορά στο insert
/// (`((priceCents − discountCents) × quantity).round()`, §3: ποτέ DB
/// generated column).
@TableIndex(name: 'idx_receipt_lines_item_id', columns: {#itemId})
class ReceiptLines extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get receiptId =>
      integer().references(Receipts, #id, onDelete: KeyAction.cascade)();
  IntColumn get itemId =>
      integer().references(Items, #id, onDelete: KeyAction.restrict)();
  IntColumn get unitId =>
      integer().references(Units, #id, onDelete: KeyAction.restrict)();
  RealColumn get quantity => real()();
  IntColumn get priceCents => integer()();

  /// Έκπτωση μονάδας σε λεπτά (0 = καμία · ≤ priceCents, §2.2).
  /// SPoT καθαρού συνόλου: `lineTotalCents()` (`core/utils/line_total.dart`)
  /// — writer ο ReceiptLineDao.
  IntColumn get discountCents =>
      integer().withDefault(const Constant(0))();
  IntColumn get lineTotalCents => integer()();
}
