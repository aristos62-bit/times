import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'tag_dao.g.dart';

/// SPO: Tag Data Access Object (tags + receipt_tags junction)
@DriftAccessor(tables: [Tags, ReceiptTags])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(super.db);

  /// Watch all tags (reactive)
  Stream<List<Tag>> watchAllTags() {
    return (select(tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  /// Search tags by name (LIKE, reactive)
  Stream<List<Tag>> searchTagsByName(String query) {
    final pattern = '%${query.toLowerCase()}%';
    return (select(tags)
          ..where((t) => t.name.lower().like(pattern))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Get tag by id
  Future<Tag?> getTagById(int id) =>
      (select(tags)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Δημιουργία tag (αν υπάρχει ήδη με το ίδιο name → null / UNIQUE constraint)
  Future<Tag?> createTag(String name, {String? color}) =>
      into(tags).insertReturningOrNull(
        TagsCompanion.insert(
          name: name,
          color: Value(color),
          createdAt: DateTime.now(),
        ),
        mode: InsertMode.insertOrIgnore,
      );

  /// Ενημέρωση tag
  Future<bool> updateTag(TagsCompanion companion) =>
      update(tags).replace(companion);

  /// Διαγραφή tag (αφαιρεί και τις ενώσεις receipt_tags)
  Future<void> deleteTag(int id) async {
    await transaction(() async {
      await (delete(receiptTags)..where((rt) => rt.tagId.equals(id))).go();
      await (delete(tags)..where((t) => t.id.equals(id))).go();
    });
  }

  /// Tags ενός receipt (reactive)
  Stream<List<Tag>> watchTagsByReceiptId(int receiptId) {
    final query = select(receiptTags).join([
      innerJoin(tags, tags.id.equalsExp(receiptTags.tagId)),
    ])
      ..where(receiptTags.receiptId.equals(receiptId))
      ..orderBy([OrderingTerm.asc(tags.name)]);
    return query
        .watch()
        .map((rows) => rows.map((r) => r.readTable(tags)).toList());
  }

  /// Προσθήκη tag σε receipt (idempotent)
  Future<void> addTagToReceipt(int receiptId, int tagId) async {
    await into(receiptTags).insert(
      ReceiptTagsCompanion.insert(receiptId: receiptId, tagId: tagId),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// Αφαίρεση tag από receipt
  Future<void> removeTagFromReceipt(int receiptId, int tagId) async {
    await (delete(receiptTags)
          ..where((rt) =>
              rt.receiptId.equals(receiptId) & rt.tagId.equals(tagId)))
        .go();
  }

  /// Αφαίρεση όλων των tags ενός receipt
  Future<void> removeAllTagsFromReceipt(int receiptId) async {
    await (delete(receiptTags)
          ..where((rt) => rt.receiptId.equals(receiptId)))
        .go();
  }
}
