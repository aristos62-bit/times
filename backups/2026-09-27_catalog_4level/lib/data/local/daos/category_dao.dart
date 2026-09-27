/// DAO για τον πίνακα `categories` — Φάση 1, Βήμα 2 (§3, §4.1 DESIGN).
///
/// Καθαρό CRUD + streams + counts/cascade (Φάση 4, Βήμα 2 · §2.3).
/// Δεν υπάρχουν υπολογισμένα πεδία (normalizedName
/// είναι μόνο σε Item/Supplier). Όλα τα σφάλματα: log (tag DB) + raw rethrow
/// μέσω BaseDao — το mapping σε AppException γίνεται στο Repository (Φάση 2).
library;

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../base_dao.dart';

/// CRUD + streams για τις κατηγορίες ειδών.
class CategoryDao extends BaseDao {
  CategoryDao(super.db);

  /// Παρακολουθεί όλες τις κατηγορίες, αλφαβητικά (name).
  Stream<List<Category>> watchAll() => guardStream(
        'Ανάγνωση κατηγοριών',
        () => (db.select(db.categories)..orderBy([(t) => OrderingTerm.asc(t.name)]))
            .watch(),
      );

  /// Διαβάζει μία κατηγορία ή null αν δεν υπάρχει.
  Future<Category?> getById(int id) => guard(
        'Ανάγνωση κατηγορίας',
        () => (db.select(db.categories)..where((t) => t.id.equals(id)))
            .getSingleOrNull(),
      );

  /// Εισάγει κατηγορία· επιστρέφει το νέο id.
  Future<int> insert({required String name}) => guard(
        'Εισαγωγή κατηγορίας',
        () => db.into(db.categories).insert(CategoriesCompanion.insert(name: name)),
      );

  /// Ενημερώνει το όνομα. Επιστρέφει true αν άλλαξε 1 γραμμή.
  Future<bool> updateById(int id, {required String name}) => guard(
        'Ενημέρωση κατηγορίας',
        () async {
          final rows = await (db.update(db.categories)..where((t) => t.id.equals(id)))
              .write(CategoriesCompanion(name: Value(name)));
          return rows > 0;
        },
      );

  /// Διαγραφή. RESTRICT (FK): αποτυγχάνει αν υπάρχουν υποκατηγορίες.
  Future<bool> deleteById(int id) => guard(
        'Διαγραφή κατηγορίας',
        () async {
          final rows = await (db.delete(db.categories)..where((t) => t.id.equals(id))).go();
          return rows > 0;
        },
      );

  /// Μετράει τα είδη της κατηγορίας — Φάση 4, Βήμα 2 (§2.3).
  ///
  /// Χρήση (Βήμα 4): ο αριθμός στο confirm του cascade («θα σβηστούν Ν είδη»)
  /// και στο tooltip όταν η διαγραφή είναι μπλοκαρισμένη. Άθροιση στο SQL
  /// (§2.1) με typed drift API (selectOnly + join + count — τα ονόματα
  /// πινάκων/στηλών ελέγχονται στο compile time).
  /// Σημ.: το `items.sub_category_id` δεν έχει index (οι FK στήλες δεν
  /// παίρνουν αυτόματα στο SQLite) — αμελητέο για τον όγκο καταλόγου
  /// (53 υποκατηγορίες / 535 είδη), χωρίς migration.
  Future<int> countItemsByCategoryId(int categoryId) => guard(
        'Μέτρηση ειδών κατηγορίας',
        () async {
          final countExp = db.items.id.count();
          final query = db.selectOnly(db.items)
            ..addColumns([countExp])
            ..join([
              innerJoin(
                db.subCategories,
                db.subCategories.id.equalsExp(db.items.subCategoryId),
              ),
            ])
            ..where(db.subCategories.categoryId.equals(categoryId));
          final row = await query.getSingle();
          return row.read(countExp) ?? 0;
        },
      );

  /// Μετράει τα είδη της κατηγορίας με τουλάχιστον μία γραμμή απόδειξης —
  /// Φάση 4, Βήμα 2 (§2.3, εύρημα Α2).
  ///
  /// Χρήση (Βήμα 3/4): πύλη διαγραφής — `0` = καθαρή (επιτρέπεται cascade),
  /// `>0` = μπλοκαρισμένη (greyed-out + tooltip «Χ είδη έχουν καταχωρημένες
  /// τιμές»). COUNT(DISTINCT items.id) πάνω σε join με τις γραμμές, ώστε
  /// ένα είδος με πολλές γραμμές να μετριέται μία φορά.
  Future<int> countItemsInUseByCategoryId(int categoryId) => guard(
        'Μέτρηση χρησιμοποιούμενων ειδών κατηγορίας',
        () async {
          final countExp = db.items.id.count(distinct: true);
          final query = db.selectOnly(db.items)
            ..addColumns([countExp])
            ..join([
              innerJoin(
                db.receiptLines,
                db.receiptLines.itemId.equalsExp(db.items.id),
              ),
              innerJoin(
                db.subCategories,
                db.subCategories.id.equalsExp(db.items.subCategoryId),
              ),
            ])
            ..where(db.subCategories.categoryId.equals(categoryId));
          final row = await query.getSingle();
          return row.read(countExp) ?? 0;
        },
      );

  /// Διαγράφει την κατηγορία με όλο το περιεχόμενό της (υποκατηγορίες +
  /// ορφανά είδη) — Φάση 4, Βήμα 2 (§2.3, αποφάσεις Α/Γ).
  ///
  /// Καλείται ΜΟΝΟ όταν `countItemsInUseByCategoryId == 0` (καθαρή) — ο
  /// έλεγχος γίνεται στον provider (Βήμα 3), όχι εδώ. Αν παρόλα αυτά
  /// υπάρχουν γραμμές, το RESTRICT ρίχνει raw σφάλμα και το transaction
  /// κάνει rollback (τίποτα δεν σβήνεται). Σειρά: είδη → υποκατηγορίες →
  /// κατηγορία, όλα σε ΕΝΑ transaction (είτε όλα είτε τίποτα). Το subquery
  /// (`isInQuery`) αποφεύγει branch άδειας λίστας και race read→delete.
  /// Επιστρέφει true αν έσβησε η κατηγορία, false αν δεν υπήρχε.
  Future<bool> deleteWithContents(int categoryId) => guard(
        'Διαγραφή κατηγορίας με περιεχόμενα',
        () => db.transaction(() async {
          final subIdsQuery = db.selectOnly(db.subCategories)
            ..addColumns([db.subCategories.id])
            ..where(db.subCategories.categoryId.equals(categoryId));
          await (db.delete(db.items)
                ..where((t) => t.subCategoryId.isInQuery(subIdsQuery)))
              .go();
          await (db.delete(db.subCategories)
                ..where((t) => t.categoryId.equals(categoryId)))
              .go();
          final rows = await (db.delete(db.categories)
                ..where((t) => t.id.equals(categoryId)))
              .go();
          return rows > 0;
        }),
      );
}