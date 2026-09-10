import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'category_dao.g.dart';

/// SPO: Category Data Access Object
@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  /// Watch all active categories (reactive)
  Stream<List<Category>> watchAllCategories() {
    return (select(categories)
          ..where((c) => c.isActive.equals(true))
          ..orderBy([
            (c) => OrderingTerm.asc(c.level),
            (c) => OrderingTerm.asc(c.sortOrder),
          ]))
        .watch();
  }

  /// Get category by id
  Future<Category?> getCategoryById(int id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  /// Watch full category tree — parent/child ομαδοποίηση (reactive)
  Stream<List<Category>> watchCategoryTree() {
    return (select(categories)
          ..orderBy([
            (c) => OrderingTerm.asc(c.level),
            (c) => OrderingTerm.asc(c.parentId),
            (c) => OrderingTerm.asc(c.sortOrder),
          ]))
        .watch();
  }

  /// Watch μία κατηγορία μαζί με όλα τα έμμεσα παιδιά της (recursive CTE)
  Stream<List<Category>> watchCategoryWithChildrenRecursively(int rootId) {
    final query = customSelect(
      'WITH RECURSIVE tree AS ('
      'SELECT * FROM categories WHERE id = ? '
      'UNION ALL '
      'SELECT c.* FROM categories c '
      'JOIN tree t ON c.parent_id = t.id'
      ') SELECT * FROM tree ORDER BY level, sort_order, name',
      variables: [Variable.withInt(rootId)],
      readsFrom: {categories},
    );
    return query.watch().map(
      (rows) => rows
          .map(
            (r) => Category(
              id: r.read<int>('id'),
              uuid: r.read<String>('uuid'),
              name: r.read<String>('name'),
              description: r.readNullable<String>('description'),
              icon: r.readNullable<String>('icon'),
              color: r.readNullable<String>('color'),
              parentId: r.readNullable<int>('parent_id'),
              level: r.read<int>('level'),
              sortOrder: r.read<int>('sort_order'),
              isActive: r.read<bool>('is_active'),
              createdBy: r.readNullable<String>('created_by'),
              createdAt: r.read<DateTime>('created_at').toLocal(),
              updatedAt: r.read<DateTime>('updated_at').toLocal(),
            ),
          )
          .toList(),
    );
  }

  /// Δημιουργία κατηγορίας
  Future<int> createCategory(CategoriesCompanion companion) =>
      into(categories).insert(companion);

  /// Ενημέρωση κατηγορίας
  Future<bool> updateCategory(CategoriesCompanion companion) =>
      update(categories).replace(companion);

  /// Soft delete (isActive = false).
  /// Επιστρέφει false αν υπάρχουν ενεργά παιδιά (αποτροπή ορφανισμού δέντρου).
  Future<bool> softDeleteCategory(int id) async {
    final activeChildren = await (select(categories)
          ..where((c) => c.parentId.equals(id) & c.isActive.equals(true)))
        .get();

    if (activeChildren.isNotEmpty) {
      return false;
    }

    await (update(categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return true;
  }
}
