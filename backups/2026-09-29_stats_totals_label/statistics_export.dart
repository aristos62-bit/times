/// Domain service εξαγωγής καρτέλας είδους (§2.3 · 28-09-2026 — 1η ανάλυση).
///
/// Καθαροί builders bytes (όχι DAO/repository/picker/context — εκείνα ζουν
/// στον controller, pattern `BackupService`): Excel via `excel` (CellValue
/// API 4.x, native αριθμοί) · PDF via `pdf` (MultiPage A4 landscape,
/// embedded TTF Β2). Χωρίς state/timers (pattern `AppLogger`)· sync CPU
/// (excel) / async CPU (pdf) — FakeAsync-safe, testable (decode round-trip,
/// `%PDF` magic).
///
/// Προβολή κειμένου: ποσά στο Excel είναι native doubles (€ — αθροίσιμα,
/// χωρίς locale-εξάρτηση)· το κείμενο ποσότητας («0,456 κιλ») και τα σύνολα
/// συντίθενται ΕΔΩ με mirror των SPoT formatters (τεκμηριωμένο, καρφωμένο
/// από tests — η εναλλακτική, import presentation helpers στο domain, θα
/// ανέστρεφε το βέλος §2.5).
library;

import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/logging/app_logger.dart';
import '../../data/local/app_database.dart';
import '../../data/models/chart_totals.dart';

/// Μορφή εξαγωγής (επιλογή χρήστη).
enum StatsExportFormat { excel, pdf }

/// PDF μοντέλο προβολής: έτοιμα strings από τον καλούντα (presentation
/// SPoT — το service κάνει μόνο layout, §2.5).
typedef StatsPdfModel = ({
  String title,
  List<String> headers,
  List<List<String>> body,
  String? totalsLine,
});

/// Επέκταση αρχείου ανά μορφή.
extension StatsExportFormatX on StatsExportFormat {
  String get extension => switch (this) {
        StatsExportFormat.excel => 'xlsx',
        StatsExportFormat.pdf => 'pdf',
      };
}

/// Σύνολα καρτέλας (Q4): label + καθαρό άθροισμα + πλήθος.
typedef StatsTotals = ({String label, int totalCents, int count});

/// Σύνολα αγορών (Q4 · 2η ανάλυση): ποσότητες ανά μονάδα + καθαρό + πλήθος.
typedef PurchasesTotals = ({
  Map<int, double> qtyByUnit,
  int netTotalCents,
  int count,
  String label,
});

/// SPoT service εξαγωγής καρτέλας — μόνο static, δεν instantiate.
abstract final class StatisticsExportService {
  /// Χτίζει filename από SPoT pattern + timestamp + προαιρετικό slug +
  /// extension (manual pad, non-localized — mirror
  /// `BackupService.buildBackupFileName`, όχι reuse: άλλο domain, §1.1).
  /// To slug διακρίνει αναλύσεις (`kartela`/`synola` — ίδιο δευτερόλεπτο =
  /// ίδιο όνομα αλλιώς).
  static String buildStatsFileName(
    DateTime now,
    StatsExportFormat format, [
    String slug = '',
  ]) {
    String p2(int v) => v.toString().padLeft(2, '0');
    final name = AppConstants.statsFileNamePattern
        .replaceAll('yyyy', now.year.toString().padLeft(4, '0'))
        .replaceAll('MM', p2(now.month))
        .replaceAll('dd', p2(now.day))
        .replaceAll('HH', p2(now.hour))
        .replaceAll('mm', p2(now.minute))
        .replaceAll('ss', p2(now.second));
    final tagged = slug.isEmpty ? name : '${name}_$slug';
    return '$tagged.${format.extension}';
  }

  /// Φορτώνει τα embedded PDF fonts (Noto Sans OFL, `assets/fonts`).
  /// Αποτυχία → `StatsExportException` (χωρίς font τα ελληνικά σπάνε — Β2).
  static Future<(Uint8List, Uint8List)> loadPdfFonts() async {
    try {
      final regular =
          await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      final bold = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
      return (
        regular.buffer.asUint8List(),
        bold.buffer.asUint8List(),
      );
    } on Object catch (e, s) {
      AppLogger.error(LogTag.stats, 'Αποτυχία φόρτωσης PDF fonts', e, s);
      throw const StatsExportException();
    }
  }

  /// Λεπτά → «ευρώ,δεκαδικά» με κόμμα (mirror
  /// `CurrencyTextField.formatCents` — βλ. doc αρχείου).
  static String formatCents(int cents) {
    final whole = cents ~/ 100;
    final fraction = (cents % 100).toString().padLeft(2, '0');
    return '$whole,$fraction';
  }

  /// Ποσότητα → «2,5»/«2» με κόμμα (mirror
  /// `QuantityTextField.formatQuantity` — βλ. doc αρχείου).
  static String formatQuantity(double quantity) {
    var fixed = quantity.toStringAsFixed(AppConstants.quantityDecimalDigits);
    fixed = fixed.replaceAll(RegExp(r'0+$'), '');
    fixed = fixed.replaceAll(RegExp(r'\.$'), '');
    return fixed.replaceAll('.', ',');
  }

  /// Κείμενο ποσότητας γραμμής («0,456 κιλ» — parity με draft list §2.2).
  static String quantityText(ItemLedgerRow row) =>
      '${formatQuantity(row.quantity)} ${row.unitAbbreviation}';

  /// Καθαρό σύνολο γραμμής (λεπτά) — display mirror DAO (SPoT §3).
  static int netTotalCents(ItemLedgerRow row) =>
      ((row.priceCents - row.discountCents) * row.quantity).round();

  /// Σύνολα καρτέλας (Q4) — μοναδική πηγή για table/excel/pdf (§1.1).
  static StatsTotals totalsOf(List<ItemLedgerRow> rows) {
    var total = 0;
    for (final row in rows) {
      total += netTotalCents(row);
    }
    return (
      label: '${AppStrings.statsTotalsLabel} (${rows.length})',
      totalCents: total,
      count: rows.length,
    );
  }

  /// Χτίζει XLSX bytes (sync CPU). Header bold · ημερομηνία `DateCellValue` ·
  /// αριθμός `Int` · ποσά native doubles (€) · κείμενα `Text` · footer συνόλων.
  /// Κενές γραμμές → header + footer μηδενικών. Αποτυχία → `StatsExportException`.
  static List<int> buildExcelBytes(List<ItemLedgerRow> rows) {
    try {
      final workbook = _newWorkbook('Καρτέλα');
      final sheet = workbook.sheet;
      const headers = [
        AppStrings.statsColumnDate,
        AppStrings.statsColumnReceipt,
        AppStrings.statsColumnSupplier,
        AppStrings.statsColumnQuantity,
        AppStrings.statsColumnPrice,
        AppStrings.statsColumnDiscount,
        AppStrings.statsColumnNet,
      ];
      for (var c = 0; c < headers.length; c++) {
        final cell =
            sheet.cell(CellIndex.indexByString('${_columnLetter(c)}1'));
        cell.value = TextCellValue(headers[c]);
        cell.cellStyle = CellStyle(bold: true);
      }
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        final n = i + 2;
        sheet.cell(CellIndex.indexByString('A$n')).value = DateCellValue(
          year: row.date.year,
          month: row.date.month,
          day: row.date.day,
        );
        sheet.cell(CellIndex.indexByString('B$n')).value =
            IntCellValue(row.receiptId);
        sheet.cell(CellIndex.indexByString('C$n')).value =
            TextCellValue(row.supplierName);
        sheet.cell(CellIndex.indexByString('D$n')).value =
            TextCellValue(quantityText(row));
        sheet.cell(CellIndex.indexByString('E$n')).value =
            DoubleCellValue(row.priceCents / 100.0);
        sheet.cell(CellIndex.indexByString('F$n')).value =
            DoubleCellValue(row.discountCents / 100.0);
        sheet.cell(CellIndex.indexByString('G$n')).value =
            DoubleCellValue(
          (row.priceCents - row.discountCents) / 100.0,
        );
      }
      final totals = totalsOf(rows);
      final t = rows.length + 2;
      sheet.cell(CellIndex.indexByString('A$t')).value =
          TextCellValue(totals.label);
      sheet.cell(CellIndex.indexByString('G$t')).value =
          DoubleCellValue(totals.totalCents / 100.0);
      return _saveWorkbook(workbook.excel, rows.length);
    } on StatsExportException {
      rethrow;
    } on Object catch (e, s) {
      AppLogger.error(LogTag.stats, 'Αποτυχία δημιουργίας XLSX', e, s);
      throw const StatsExportException();
    }
  }

  /// Κοινός πυρήνας workbook (29-09-2026 · 2η ανάλυση): create + διαγραφή
  /// auto-Sheet1 (μοναδικό φύλλο η ανάλυση) — reuse και από τους δύο builders
  /// (αντί αντιγραφής).
  static ({Excel excel, Sheet sheet}) _newWorkbook(String sheetName) {
    final excel = Excel.createExcel();
    final sheet = excel[sheetName];
    excel.delete('Sheet1');
    return (excel: excel, sheet: sheet);
  }

  /// Αποθήκευση workbook σε bytes + log (κοινός πυρήνας — null = throw).
  static List<int> _saveWorkbook(Excel excel, int rowCount) {
    final bytes = excel.save();
    if (bytes == null) throw const StatsExportException();
    AppLogger.info(LogTag.stats, 'XLSX: $rowCount γραμμές');
    return bytes;
  }

  /// Σύνολα αγορών (Q4): ποσότητες ανά μονάδα + καθαρό άθροισμα + πλήθος —
  /// μοναδική πηγή για table/excel/pdf (§1.1). Το καθαρό είναι άθροισμα
  /// ΣΥΝΟΛΩΝ γραμμών (όχι μοναδιαίων — η στήλη δείχνει €/μονάδα).
  static PurchasesTotals purchasesTotalsOf(List<PeriodPurchaseRow> rows) {
    final qty = <int, double>{};
    var net = 0;
    for (final row in rows) {
      qty[row.unitId] = (qty[row.unitId] ?? 0) + row.quantity;
      net += ((row.priceCents - row.discountCents) * row.quantity).round();
    }
    return (
      qtyByUnit: qty,
      netTotalCents: net,
      count: rows.length,
      label: '${AppStrings.statsTotalsLabel} (${rows.length})',
    );
  }

  /// Χτίζει XLSX συγκεντρωτικών αγορών (sync CPU): fixed στήλες +
  /// μία στήλη ποσότητας ανά μονάδα [units] (δυναμικές, Q3) + Τιμή/Έκπτωση/
  /// Καθαρή native doubles + footer (sums/μονάδα + σύνολο). Αποτυχία →
  /// `StatsExportException`.
  static List<int> buildPurchasesExcelBytes({
    required List<PeriodPurchaseRow> rows,
    required List<Unit> units,
  }) {
    try {
      final workbook = _newWorkbook('Σύνολα');
      final sheet = workbook.sheet;
      final headers = [
        AppStrings.statsColumnDate,
        AppStrings.statsColumnReceipt,
        AppStrings.fieldItemName,
        AppStrings.statsColumnCategory,
        AppStrings.statsColumnSupplier,
        for (final unit in units) unit.name,
        AppStrings.statsColumnPrice,
        AppStrings.statsColumnDiscount,
        AppStrings.statsColumnNet,
      ];
      for (var c = 0; c < headers.length; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[c]);
        cell.cellStyle = CellStyle(bold: true);
      }
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        final r = i + 1;
        void set(int c, CellValue value) =>
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
              ..value = value;
        set(0, DateCellValue(
          year: row.date.year,
          month: row.date.month,
          day: row.date.day,
        ));
        set(1, IntCellValue(row.receiptId));
        set(2, TextCellValue(row.itemName));
        set(3, TextCellValue(row.categoryName));
        set(4, TextCellValue(row.supplierName));
        for (var u = 0; u < units.length; u++) {
          set(
            5 + u,
            DoubleCellValue(
              row.unitId == units[u].id ? row.quantity : 0,
            ),
          );
        }
        final priceCol = 5 + units.length;
        set(priceCol, DoubleCellValue(row.priceCents / 100.0));
        set(priceCol + 1, DoubleCellValue(row.discountCents / 100.0));
        set(
          priceCol + 2,
          DoubleCellValue(
            (row.priceCents - row.discountCents) / 100.0,
          ),
        );
      }
      final totals = purchasesTotalsOf(rows);
      final t = rows.length + 1;
      void setFooter(int c, CellValue value) =>
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: t))
            ..value = value;
      setFooter(0, TextCellValue(totals.label));
      for (var u = 0; u < units.length; u++) {
        setFooter(
          5 + u,
          DoubleCellValue(totals.qtyByUnit[units[u].id] ?? 0),
        );
      }
      final priceCol = 5 + units.length;
      setFooter(
        priceCol + 2,
        DoubleCellValue(totals.netTotalCents / 100.0),
      );
      return _saveWorkbook(workbook.excel, rows.length);
    } on Object catch (e, s) {
      AppLogger.error(
        LogTag.stats,
        'Αποτυχία δημιουργίας XLSX αγορών',
        e,
        s,
      );
      throw const StatsExportException();
    }
  }

  /// Χτίζει PDF bytes (async CPU). `headers`/`body`/`totalsLine` έτοιμα
  /// strings από τον καλούντα (presentation SPoT — το service κάνει μόνο
  /// layout). Αποτυχία → `StatsExportException`.
  static Future<Uint8List> buildPdfBytes({
    required String title,
    required List<String> headers,
    required List<List<String>> body,
    required String? totalsLine,
    required Uint8List fontBytes,
    required Uint8List boldFontBytes,
  }) async {
    try {
      final regular = pw.Font.ttf(fontBytes.buffer.asByteData());
      final bold = pw.Font.ttf(boldFontBytes.buffer.asByteData());
      final doc = pw.Document();
      pw.Widget cell(String text, pw.Font font, {bool boldRow = false}) =>
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(
              text,
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                fontWeight:
                    boldRow ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          );
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          header: (_) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text(
              title,
              style: pw.TextStyle(font: bold, fontSize: 14),
            ),
          ),
          footer: (context) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                totalsLine ?? '',
                style: pw.TextStyle(font: bold, fontSize: 10),
              ),
              pw.Text(
                'Σελίδα ${context.pageNumber} / ${context.pagesCount}',
                style: pw.TextStyle(font: regular, fontSize: 9),
              ),
            ],
          ),
          build: (_) => [
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  children: [
                    for (final h in headers) cell(h, bold, boldRow: true),
                  ],
                ),
                for (final row in body)
                  pw.TableRow(
                    children: [for (final c in row) cell(c, regular)],
                  ),
              ],
            ),
          ],
        ),
      );
      final bytes = await doc.save();
      AppLogger.info(LogTag.stats, 'PDF καρτέλας: ${body.length} γραμμές');
      return bytes;
    } on Object catch (e, s) {
      // Object (όχι Exception): οι parsers (ttf/layout) πετούν Errors
      // (π.χ. RangeError σε corrupt font) — foreseeable input failure
      // (asset/bytes απ' έξω), άρα mapped σε μήνυμα, όχι raw crash.
      AppLogger.error(LogTag.stats, 'Αποτυχία δημιουργίας PDF', e, s);
      throw const StatsExportException();
    }
  }

  /// Γράμμα στήλης (0 → A) — 7 στήλες καρτέλας.
  static String _columnLetter(int index) =>
      String.fromCharCode('A'.codeUnitAt(0) + index);
}
