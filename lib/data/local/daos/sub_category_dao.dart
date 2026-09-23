/// DAO για τον πίνακα `sub_categories` — Φάση 1, Βήμα 2 (§3, §4.1 DESIGN).
///
/// Ομαδοποιημένες ανά category (watchByCategoryId) + πλήρης λίστα
/// αλφαβητικά + counts/cascade (Φάση 4, Βήμα 2 · §2.3). Όλα τα σφάλματα:
/// log (tag DB) + raw rethrow (BaseDao);
/// mapping σε AppException στο Repository (Φάση 2).
library;

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../base_dao.dart';

/// CRUD + streams για τις υποκατηγορίες.
class SubCategoryDao extends BaseDao {
  SubCategoryDao(super.db);

  /// Παρακολουθεί όλες τις υποκατηγορίες, αλφαβητικά (name).
  Stream<List<SubCategory>> watchAll() => guardStream(
        'Ανάγνωση υποκατηγοριών',
        () => (db.select(db.subCategories)
              ..orderBy([(t) => OrderingTerm.asc(t.name)]))
            .watch(),
      );

  /// Παρακολουθεί τις υποκατηγορίες μιας κατηγορίας, αλφαβητικά.
  Stream<List<SubCategory>> watchByCategoryId(int categoryId) => guardStream(
        'Ανάγνωση υποκατηγοριών κατηγορίας',
        () => (db.select(db.subCategories)
              ..where((t) => t.categoryId.equals(categoryId))
              ..orderBy([(t) => OrderingTerm.asc(t.name)]))
            .watch(),
      );

  /// Διαβάζει μία υποκατηγορία ή null αν δεν υπάρχει.
  Future<SubCategory?> getById(int id) => guard(
        'Ανάγνωση υποκατηγορίας',
        () => (db.select(db.subCategories)..where((t) => t.id.equals(id)))
            .getSingleOrNull(),
      );

  /// Εισάγει υποκατηγορία σε [categoryId]· επιστρέφει το νέο id.
  Future<int> insert({required int categoryId, required String name}) => guard(
        'Εισαγωγή υποκατηγορίας',
        () => db.into(db.subCategories).insert(
              SubCategoriesCompanion.insert(categoryId: categoryId, name: name),
            ),
      );

  /// Ενημερώνει category ή/και name (όσα δεν είναι null). True αν υπήρξε αλλαγή.
  Future<bool> updateById(int id, {int? categoryId, String? name}) => guard(
        'Ενημέρωση υποκατηγορίας',
        () async {
          var companion = const SubCategoriesCompanion();
          if (categoryId != null) {
            companion = companion.copyWith(categoryId: Value(categoryId));
          }
          if (name != null) {
            companion = companion.copyWith(name: Value(name));
          }
          final rows = await (db.update(db.subCategories)
                ..where((t) => t.id.equals(id)))
              .write(companion);
          return rows > 0;
        },
      );

  /// Διαγραφή. RESTRICT (FK): αποτυγχάνει αν υπάρχουν items σε αυτή.
  Future<bool> deleteById(int id) => guard(
        'Διαγραφή υποκατηγορίας',
        () async {
          final rows = await (db.delete(db.subCategories)
                ..where((t) => t.id.equals(id)))
              .go();
          return rows > 0;
        },
      );

  /// Μετράει τα είδη της υποκατηγορίας — Φάση 4, Βήμα 2 (§2.3).
  ///
  /// Χρήση (Βήμα 4): ο αριθμός στο confirm του cascade («θα σβηστούν Ν είδη»)
  /// και στο tooltip όταν η διαγραφή είναι μπλοκαρισμένη. Άθροιση στο SQL
  /// (§2.1) με typed drift API (τα ονόματα ελέγχονται στο compile time).
  /// Σημ.: το `items.sub_category_id` δεν έχει index (οι FK στήλες δεν
  /// παίρνουν αυτόματα στο SQLite) — αμελητέο για τον όγκο καταλόγου,
  /// χωρίς migration.
  Future<int> countItemsBySubCategoryId(int subCategoryId) => guard(
        'Μέτρηση ειδών υποκατηγορίας',
        () async {
          final countExp = db.items.id.count();
          final query = db.selectOnly(db.items)
            ..addColumns([countExp])
            ..where(db.items.subCategoryId.equals(subCategoryId));
          final row = await query.getSingle();
          return row.read(countExp) ?? 0;
        },
      );

  /// Μετράει τα είδη της υποκατηγορίας με τουλάχιστον μία γραμμή απόδειξης —
  /// Φάση 4, Βήμα 2 (§2.3, εύρημα Α2).
  ///
  /// Χρήση (Βήμα 3/4): πύλη διαγραφής — `0` = καθαρή (επιτρέπεται cascade),
  /// `>0` = μπλοκαρισμένη (greyed-out + tooltip «Χ είδη έχουν καταχωρημένες
  /// τιμές»). COUNT(DISTINCT items.id) πάνω σε join με τις γραμμές, ώστε
  /// ένα είδος με πολλές γραμμές να μετριέται μία φορά.
  Future<int> countItemsInUseBySubCategoryId(int subCategoryId) => guard(
        'Μέτρηση χρησιμοποιούμενων ειδών υποκατηγορίας',
        () async {
          final countExp = db.items.id.count(distinct: true);
          final query = db.selectOnly(db.items)
            ..addColumns([countExp])
            ..join([
              innerJoin(
                db.receiptLines,
                db.receiptLines.itemId.equalsExp(db.items.id),
              ),
            ])
            ..where(db.items.subCategoryId.equals(subCategoryId));
          final row = await query.getSingle();
          return row.read(countExp) ?? 0;
        },
      );

  /// Διαγράφει την υποκατηγορία με τα ορφανά είδη της — Φάση 4, Βήμα 2
  /// (§2.3, αποφάσεις Α/Γ).
  ///
  /// Καλείται ΜΟΝΟ όταν `countItemsInUseBySubCategoryId == 0` (καθαρή) — ο
  /// έλεγχος γίνεται στον provider (Βήμα 3), όχι εδώ. Αν παρόλα αυτά
  /// υπάρχουν γραμμές, το RESTRICT ρίχνει raw σφάλμα και το transaction
  /// κάνει rollback (τίποτα δεν σβήνεται). Σειρά: είδη → υποκατηγορία, όλα
  /// σε ΕΝΑ transaction. Επιστρέφει true αν έσβησε, false αν δεν υπήρχε.
  Future<bool> deleteWithContents(int subCategoryId) => guard(
        'Διαγραφή υποκατηγορίας με περιεχόμενα',
        () => db.transaction(() async {
          await (db.delete(db.items)
                ..where((t) => t.subCategoryId.equals(subCategoryId)))
              .go();
          final rows = await (db.delete(db.subCategories)
                ..where((t) => t.id.equals(subCategoryId)))
              .go();
          return rows > 0;
        }),
      );
}