/// Unit tests — `CatalogExportService` (§2.3 · 30-09-2026).
///
/// Pure builders (sync CPU): filename pattern · headers exact · πλήρης
/// διαδρομή · κενά κλαδιά · null-μονάδα · άδειος κατάλογος · unmatched
/// defensive · decode round-trip (pattern `statistics_export_test`).
/// Οντότητες κατευθείαν (const constructors — κανένα DB).
library;

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_strings.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/models/category_tree_node.dart';
import 'package:times/domain/services/catalog_export.dart';

void main() {
  const kilo = Unit(
    id: 1,
    name: 'Κιλό',
    abbreviation: 'κιλ',
    allowsDecimal: true,
  );
  final food = Category(
    id: 1,
    name: 'ΤΡΟΦΙΜΑ',
    normalizedName: 'τροφιμα',
    createdAt: DateTime(2026, 1, 1),
  );
  const dairy = SubCategory(
    id: 1,
    categoryId: 1,
    name: 'Γαλακτοκομικά',
    normalizedName: 'γαλακτοκομικα',
  );
  const fresh = ItemGroup(
    id: 1,
    subCategoryId: 1,
    name: 'Φρέσκα',
    normalizedName: 'φρεσκα',
  );
  const milk = Item(
    id: 1,
    itemGroupId: 1,
    name: 'Γάλα',
    normalizedName: 'γαλα',
    defaultUnitId: 1,
  );

  CategoryTreeNode treeNode({
    Category? category,
    List<SubCategoryTreeNode> subNodes = const [
      (
        subCategory: dairy,
        itemGroups: [fresh],
      ),
    ],
  }) =>
      (category: category ?? food, subNodes: subNodes);

  /// Αποκωδικοποιεί το φύλλο «Κατάλογος» (μοναδικό — όχι κενό Sheet1).
  List<List<Data?>> sheetRows(List<int> bytes) {
    final excel = Excel.decodeBytes(bytes);
    expect(excel.tables.keys.toList(), ['Κατάλογος']);
    return excel.tables['Κατάλογος']!.rows;
  }

  /// Κείμενο κελιού (TextCellValue → plain, αλλιώς fail — pattern stats).
  String textOf(List<List<Data?>> rows, int r, int c) {
    final value = rows[r][c]?.value;
    if (value is TextCellValue) return value.value.toString();
    return fail('όχι κείμενο ($r,$c): $value');
  }

  /// Ολόκληρη γραμμή ως strings.
  List<String> rowOf(List<List<Data?>> rows, int r) =>
      [for (var c = 0; c < 6; c++) textOf(rows, r, c)];

  group('CatalogExportService (§2.3 · 30-09-2026)', () {
    test('buildCatalogFileName — pattern + .xlsx', () {
      expect(
        CatalogExportService.buildCatalogFileName(DateTime(2026, 9, 30, 12, 34, 56)),
        'times_catalog_20260930_123456.xlsx',
      );
    });

    test('headers exact (SPoT)', () {
      final rows = sheetRows(
        CatalogExportService.buildCatalogExcelBytes(
          tree: const [],
          items: const [],
          units: const [],
        ),
      );
      expect(rows, hasLength(1));
      expect(rowOf(rows, 0), [
        AppStrings.fieldCategory,
        AppStrings.fieldSubCategory,
        AppStrings.fieldItemGroup,
        AppStrings.fieldItemName,
        AppStrings.fieldUnit,
        AppStrings.catalogUnitAbbreviation,
      ]);
    });

    test('πλήρης διαδρομή είδους + μονάδα', () {
      final rows = sheetRows(
        CatalogExportService.buildCatalogExcelBytes(
          tree: [treeNode()],
          items: const [milk],
          units: const [kilo],
        ),
      );
      expect(rows, hasLength(2));
      expect(rowOf(rows, 1), [
        'ΤΡΟΦΙΜΑ',
        'Γαλακτοκομικά',
        'Φρέσκα',
        'Γάλα',
        'Κιλό',
        'κιλ',
      ]);
    });

    test('κενά κλαδιά → γραμμές με άδεια κελιά (Q3)', () {
      const emptyGroup = ItemGroup(
        id: 2,
        subCategoryId: 1,
        name: 'Κατεψυγμένα',
        normalizedName: 'κατεψυγμενα',
      );
      final rows = sheetRows(
        CatalogExportService.buildCatalogExcelBytes(
          tree: [
            (
              category: food,
              subNodes: const [
                (subCategory: dairy, itemGroups: [fresh, emptyGroup]),
              ],
            ),
          ],
          items: const [milk],
          units: const [kilo],
        ),
      );
      expect(rows, hasLength(3));
      expect(rowOf(rows, 2).sublist(0, 3),
          ['ΤΡΟΦΙΜΑ', 'Γαλακτοκομικά', 'Κατεψυγμένα']);
      expect(rowOf(rows, 2).sublist(3), ['', '', '']);
    });

    test('κατηγορία χωρίς υποκατηγορίες → μόνο κελί κατηγορίας', () {
      final rows = sheetRows(
        CatalogExportService.buildCatalogExcelBytes(
          tree: [treeNode(subNodes: const [])],
          items: const [],
          units: const [],
        ),
      );
      expect(rows, hasLength(2));
      expect(rowOf(rows, 1), ['ΤΡΟΦΙΜΑ', '', '', '', '', '']);
    });

    test('είδος χωρίς μονάδα → άδεια κελιά μονάδας (όχι crash)', () {
      const noUnit = Item(
        id: 2,
        itemGroupId: 1,
        name: 'Ψωμί',
        normalizedName: 'ψωμι',
      );
      final rows = sheetRows(
        CatalogExportService.buildCatalogExcelBytes(
          tree: [treeNode()],
          items: const [noUnit],
          units: const [kilo],
        ),
      );
      expect(rows, hasLength(2));
      expect(rowOf(rows, 1).sublist(3), ['Ψωμί', '', '']);
    });

    test('άγνωστο defaultUnitId → άδεια κελιά (defensive)', () {
      const ghost = Item(
        id: 3,
        itemGroupId: 1,
        name: 'Φάντασμα',
        normalizedName: 'φαντασμα',
        defaultUnitId: 999,
      );
      final rows = sheetRows(
        CatalogExportService.buildCatalogExcelBytes(
          tree: [treeNode()],
          items: const [ghost],
          units: const [kilo],
        ),
      );
      expect(rowOf(rows, 1).sublist(3), ['Φάντασμα', '', '']);
    });

    test('unmatched itemGroupId → άδειο path (ορατό, όχι χαμένο)', () {
      const orphan = Item(
        id: 4,
        itemGroupId: 999,
        name: 'Ορφανό',
        normalizedName: 'ορφανο',
        defaultUnitId: 1,
      );
      final rows = sheetRows(
        CatalogExportService.buildCatalogExcelBytes(
          tree: [treeNode()],
          items: const [milk, orphan],
          units: const [kilo],
        ),
      );
      expect(rows, hasLength(3));
      expect(rowOf(rows, 2).sublist(0, 3), ['', '', '']);
      expect(rowOf(rows, 2).sublist(3), ['Ορφανό', 'Κιλό', 'κιλ']);
    });
  });
}
