/// Drift πίνακες της βάσης (§3 DESIGN.md) — Φάση 1, Βήμα 1.
///
/// 7 πίνακες: Categories, SubCategories, Units, Items, Suppliers,
/// Receipts, ReceiptLines. Foreign keys με `ON DELETE RESTRICT` μόνο για
/// Category/SubCategory/Item/Supplier/Unit (προστασία καταλόγου §2.3).
/// Η Receipt→ReceiptLine είναι σχέση κυριότητας: `ReceiptLines.receiptId`
/// κάνει `CASCADE` (η διαγραφή απόδειξης σβήνει και τις γραμμές της — §3).
/// Το προαιρετικό `Items.defaultUnitId` είναι `SET NULL` (null = χωρίς πρόταση).
/// Το μοναδικό ρητό index είναι στο `ReceiptLine.itemId` (για στατιστικά)·
/// τα `UNIQUE` σε Item/Supplier.normalizedName φέρνουν index αυτόματα.
///
/// Καμία στήλη με length/check constraint: `maxItemNameLength` είναι
/// validation του domain layer (Φάση 3), όχι σχήματος — §3 DESIGN.
library;

import 'package:drift/drift.dart';

/// Κατηγορίες ειδών (π.χ. ΤΡΟΦΙΜΑ) — ένα Item ανήκει πάντα σε μία.
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Υποκατηγορίες κάτω από μία κατηγορία.
class SubCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.restrict)();
  TextColumn get name => text()();
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
  IntColumn get subCategoryId => integer()
      .references(SubCategories, #id, onDelete: KeyAction.restrict)();
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
  /// SPoT καθαρού συνόλου: `lineTotalCents = ((priceCents - discountCents)
  /// * quantity).round()` στο ReceiptLineDao.
  IntColumn get discountCents =>
      integer().withDefault(const Constant(0))();
  IntColumn get lineTotalCents => integer()();
}