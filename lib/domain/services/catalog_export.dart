/// Domain service εξαγωγής καταλόγου (§2.3 · 30-09-2026).
///
/// Καθαροί builders bytes (όχι DAO/repository/picker/context — εκείνα ζουν
/// στον controller, pattern `BackupService`/`StatisticsExportService`):
/// Excel via `excel` (CellValue API 4.x, όλα κείμενα — τίποτα αθροίσιμο).
/// Χωρίς state/timers· sync CPU — FakeAsync-safe, testable (decode
/// round-trip). Δικό του αρχείο (όχι στο `statistics_export.dart` — εκείνο
/// είναι ήδη 520 γρ., κανόνας 7· precedent σκόπιμης μη-reuse μικρών
/// templates άλλου domain, §1.1).
library;

import 'package:excel/excel.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/logging/app_logger.dart';
import '../../data/local/app_database.dart';
import '../../data/models/category_tree_node.dart';

/// SPoT service εξαγωγής καταλόγου — μόνο static, δεν instantiate.
abstract final class CatalogExportService {
  /// Χτίζει filename από SPoT pattern + timestamp (manual pad,
  /// non-localized — mirror `buildStatsFileName`/`buildBackupFileName`,
  /// δικό του builder: άλλο domain, §1.1 · χωρίς slug: μία εξαγωγή).
  static String buildCatalogFileName(DateTime now) {
    String p2(int v) => v.toString().padLeft(2, '0');
    final name = AppConstants.catalogFileNamePattern
        .replaceAll('yyyy', now.year.toString().padLeft(4, '0'))
        .replaceAll('MM', p2(now.month))
        .replaceAll('dd', p2(now.day))
        .replaceAll('HH', p2(now.hour))
        .replaceAll('mm', p2(now.minute))
        .replaceAll('ss', p2(now.second));
    return '$name.xlsx';
  }

  /// Χτίζει XLSX bytes (sync CPU): 1 γραμμή ανά είδος με πλήρη διαδρομή
  /// + κενά κλαδιά με άδεια κελιά (Q3) + headers. Σειρά encounter δέντρου
  /// (αλφαβητικά) × normalizedName ειδών (το stream είναι ταξινομημένο —
  /// ντετερμινιστικό χωρίς extra sort). Άδειος κατάλογος → headers only.
  /// Αποτυχία → `CatalogExportException`.
  static List<int> buildCatalogExcelBytes({
    required List<CategoryTreeNode> tree,
    required List<Item> items,
    required List<Unit> units,
  }) {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Κατάλογος'];
      excel.delete('Sheet1');
      const headers = [
        AppStrings.fieldCategory,
        AppStrings.fieldSubCategory,
        AppStrings.fieldItemGroup,
        AppStrings.fieldItemName,
        AppStrings.fieldUnit,
        AppStrings.catalogUnitAbbreviation,
      ];
      for (var c = 0; c < headers.length; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[c]);
        cell.cellStyle = CellStyle(bold: true);
      }
      final unitsById = {for (final u in units) u.id: u};
      final itemsByGroup = <int, List<Item>>{};
      for (final item in items) {
        (itemsByGroup[item.itemGroupId] ??= []).add(item);
      }
      final seenGroups = <int>{};
      var r = 1;
      void set(int c, CellValue value) =>
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
            ..value = value;
      void row(
        String category,
        String subCategory,
        String group,
        String item,
        String unit,
        String abbreviation,
      ) {
        set(0, TextCellValue(category));
        set(1, TextCellValue(subCategory));
        set(2, TextCellValue(group));
        set(3, TextCellValue(item));
        set(4, TextCellValue(unit));
        set(5, TextCellValue(abbreviation));
        r++;
      }

      void itemRow(String category, String subCategory, String group, Item item) {
        final unit = item.defaultUnitId == null
            ? null
            : unitsById[item.defaultUnitId];
        row(
          category,
          subCategory,
          group,
          item.name,
          unit?.name ?? '',
          unit?.abbreviation ?? '',
        );
      }

      for (final catNode in tree) {
        final catName = catNode.category.name;
        if (catNode.subNodes.isEmpty) {
          row(catName, '', '', '', '', '');
          continue;
        }
        for (final subNode in catNode.subNodes) {
          final subName = subNode.subCategory.name;
          if (subNode.itemGroups.isEmpty) {
            row(catName, subName, '', '', '', '');
            continue;
          }
          for (final group in subNode.itemGroups) {
            seenGroups.add(group.id);
            final groupItems = itemsByGroup[group.id] ?? const <Item>[];
            if (groupItems.isEmpty) {
              row(catName, subName, group.name, '', '', '');
              continue;
            }
            for (final item in groupItems) {
              itemRow(catName, subName, group.name, item);
            }
          }
        }
      }
      // Defensive: είδη με άγνωστο τμήμα (αδύνατο via RESTRICT/cascade —
      // ορατά με άδειο path, ποτέ χαμένα).
      for (final entry in itemsByGroup.entries) {
        if (seenGroups.contains(entry.key)) continue;
        for (final item in entry.value) {
          itemRow('', '', '', item);
        }
      }
      final bytes = excel.save();
      if (bytes == null) throw const CatalogExportException();
      AppLogger.info(LogTag.backup, 'XLSX καταλόγου: ${r - 1} γραμμές');
      return bytes;
    } on CatalogExportException {
      rethrow;
    } on Object catch (e, s) {
      AppLogger.error(
        LogTag.backup,
        'Αποτυχία δημιουργίας XLSX καταλόγου',
        e,
        s,
      );
      throw const CatalogExportException();
    }
  }
}
