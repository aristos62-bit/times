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
import '../../core/utils/line_total.dart' as line_total;
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

/// PDF section ομαδοποιημένης αναφοράς (§2.3 · 3η ανάλυση): τίτλος +
/// γραμμές + γραμμή υποσυνόλου (έτοιμα strings, όπως `StatsPdfModel`).
typedef PdfSection = ({String title, List<List<String>> rows, String subtotal});

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
      final regular = await rootBundle.load(
        'assets/fonts/NotoSans-Regular.ttf',
      );
      final bold = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
      return (regular.buffer.asUint8List(), bold.buffer.asUint8List());
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

  /// Καθαρό σύνολο γραμμής (λεπτά) — display mirror μέσω SPoT
  /// `lineTotalCents()` (§3, `core/utils/line_total.dart`).
  static int netTotalCents(ItemLedgerRow row) => line_total.lineTotalCents(
    priceCents: row.priceCents,
    discountCents: row.discountCents,
    quantity: row.quantity,
  );

  /// Μικτό σύνολο γραμμής — στήλη «Σύνολο» (01-10, SPoT fn).
  static int grossTotalCents(ItemLedgerRow row) =>
      line_total.grossTotalCents(
        priceCents: row.priceCents,
        quantity: row.quantity,
      );

  /// Συνολική έκπτωση γραμμής — στήλη «Έκπτωση» (01-10, SPoT fn).
  static int discountTotalCents(ItemLedgerRow row) =>
      line_total.discountTotalCents(
        discountCents: row.discountCents,
        quantity: row.quantity,
      );

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

  /// Ομαδοποιεί γραμμές κατά [group] (§2.3 · 3η ανάλυση — pure, testable).
  ///
  /// Keys RAW (όχι προβολή): ονόματα ως έχουν · ημέρα `yyyy-MM-dd` · μήνας
  /// `yyyy-MM` (το mapping σε προβολή το κάνει ο καλούντος — το service δεν
  /// έχει locale). Διατηρεί τη σειρά encounter (το sort προηγήθηκε στη SQL,
  /// τεκμηριωμένο)· κενές ομάδες αδύνατες (προκύπτουν από γραμμές).
  static List<PurchaseGroup> groupPurchases(
    List<PeriodPurchaseRow> rows,
    PurchasesGroup group,
  ) {
    final order = <String>[];
    final buckets = <String, List<PeriodPurchaseRow>>{};
    String keyOf(PeriodPurchaseRow row) => switch (group) {
      PurchasesGroup.category => row.categoryName,
      PurchasesGroup.supplier => row.supplierName,
      PurchasesGroup.day =>
        '${row.date.year}-${row.date.month.toString().padLeft(2, '0')}-'
            '${row.date.day.toString().padLeft(2, '0')}',
      PurchasesGroup.month =>
        '${row.date.year}-${row.date.month.toString().padLeft(2, '0')}',
    };
    for (final row in rows) {
      final key = keyOf(row);
      if (!buckets.containsKey(key)) {
        buckets[key] = [];
        order.add(key);
      }
      buckets[key]!.add(row);
    }
    return [for (final key in order) (key: key, rows: buckets[key]!)];
  }

  /// Label γραμμής υποσυνόλου («ΤΡΟΦΙΜΑ · Σύνολο: (Κιλ: 2)» — §1.1).
  static String groupSubtotalLabel(
    String displayName,
    PurchasesTotals totals,
  ) => '$displayName · ${totals.label}';

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
        AppStrings.statsColumnTotal,
        AppStrings.statsColumnNet,
      ];
      for (var c = 0; c < headers.length; c++) {
        final cell = sheet.cell(
          CellIndex.indexByString('${_columnLetter(c)}1'),
        );
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
        sheet.cell(CellIndex.indexByString('B$n')).value = IntCellValue(
          row.receiptId,
        );
        sheet.cell(CellIndex.indexByString('C$n')).value = TextCellValue(
          row.supplierName,
        );
        sheet.cell(CellIndex.indexByString('D$n')).value = TextCellValue(
          quantityText(row),
        );
        sheet.cell(CellIndex.indexByString('E$n')).value = DoubleCellValue(
          row.priceCents / 100.0,
        );
        sheet.cell(CellIndex.indexByString('F$n')).value = DoubleCellValue(
          discountTotalCents(row) / 100.0,
        );
        sheet.cell(CellIndex.indexByString('G$n')).value = DoubleCellValue(
          grossTotalCents(row) / 100.0,
        );
        sheet.cell(CellIndex.indexByString('H$n')).value = DoubleCellValue(
          netTotalCents(row) / 100.0,
        );
      }
      final totals = totalsOf(rows);
      final t = rows.length + 2;
      sheet.cell(CellIndex.indexByString('A$t')).value = TextCellValue(
        totals.label,
      );
      sheet.cell(CellIndex.indexByString('H$t')).value = DoubleCellValue(
        totals.totalCents / 100.0,
      );
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

  /// Σύνολα αγορών (Q4 · 2η ανάλυση + 29-09 σπάσιμο): ποσότητες ανά μονάδα +
  /// καθαρό άθροισμα + πλήθος — μοναδική πηγή για table/excel/pdf (§1.1).
  /// Το label σπάει ανά μονάδα («Σύνολο: (Τεμ: 10 / Κιλ: 1,35)» — μόνο
  /// μονάδες με κίνηση, σειρά [units])· άδειο → «Σύνολο (0)». Το καθαρό
  /// είναι άθροισμα ΣΥΝΟΛΩΝ γραμμών (όχι μοναδιαίων — η στήλη δείχνει
  /// €/μονάδα).
  static PurchasesTotals purchasesTotalsOf(
    List<PeriodPurchaseRow> rows,
    List<Unit> units,
  ) {
    final qty = <int, double>{};
    var net = 0;
    for (final row in rows) {
      qty[row.unitId] = (qty[row.unitId] ?? 0) + row.quantity;
      net += line_total.lineTotalCents(
        priceCents: row.priceCents,
        discountCents: row.discountCents,
        quantity: row.quantity,
      );
    }
    final parts = [
      for (final unit in units)
        if ((qty[unit.id] ?? 0) > 0)
          '${_capitalized(unit.abbreviation)}: ${formatQuantity(qty[unit.id]!)}',
    ];
    return (
      qtyByUnit: qty,
      netTotalCents: net,
      count: rows.length,
      label: parts.isEmpty ? 'Σύνολο (0)' : 'Σύνολο: (${parts.join(' / ')})',
    );
  }

  /// Κεφαλαιοποιεί συντομογραφία («κιλ» → «Κιλ») για το label συνόλων.
  static String _capitalized(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

  /// Χτίζει XLSX συγκεντρωτικών αγορών (sync CPU): fixed στήλες +
  /// μία στήλη ποσότητας ανά μονάδα [units] (δυναμικές, Q3) + Τιμή/Έκπτωση/
  /// Σύνολο/Καθαρή native doubles + footer (sums/μονάδα + σύνολο). Με [groups]
  /// (3η ανάλυση): blocks τίτλου + υποσύνολο + grand footer — χωρίς groups
  /// η flat συμπεριφορά (backward compatible). Αποτυχία →
  /// `StatsExportException`.
  static List<int> buildPurchasesExcelBytes({
    required List<PeriodPurchaseRow> rows,
    required List<Unit> units,
    List<PurchaseGroup>? groups,
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
        AppStrings.statsColumnTotal,
        AppStrings.statsColumnNet,
      ];
      for (var c = 0; c < headers.length; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[c]);
        cell.cellStyle = CellStyle(bold: true);
      }
      // Γραμμές: flat ή blocks ομάδων (με τίτλο + υποσύνολο ανά block).
      // Τα display names των groups τα δίνει ο καλών (έχει locale).
      final blocks = groups ?? [(key: '', rows: rows)];
      var r = 1;
      void set(int c, CellValue value) =>
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
            ..value = value;
      for (final block in blocks) {
        if (groups != null) {
          set(0, TextCellValue(block.key));
          r++;
        }
        for (final row in block.rows) {
          set(
            0,
            DateCellValue(
              year: row.date.year,
              month: row.date.month,
              day: row.date.day,
            ),
          );
          set(1, IntCellValue(row.receiptId));
          set(2, TextCellValue(row.itemName));
          set(3, TextCellValue(row.categoryName));
          set(4, TextCellValue(row.supplierName));
          for (var u = 0; u < units.length; u++) {
            set(
              5 + u,
              DoubleCellValue(row.unitId == units[u].id ? row.quantity : 0),
            );
          }
          final priceCol = 5 + units.length;
          set(priceCol, DoubleCellValue(row.priceCents / 100.0));
          set(
            priceCol + 1,
            DoubleCellValue(
              line_total.discountTotalCents(
                    discountCents: row.discountCents,
                    quantity: row.quantity,
                  ) /
                  100.0,
            ),
          );
          set(
            priceCol + 2,
            DoubleCellValue(
              line_total.grossTotalCents(
                    priceCents: row.priceCents,
                    quantity: row.quantity,
                  ) /
                  100.0,
            ),
          );
          set(
            priceCol + 3,
            DoubleCellValue(
              line_total.lineTotalCents(
                    priceCents: row.priceCents,
                    discountCents: row.discountCents,
                    quantity: row.quantity,
                  ) /
                  100.0,
            ),
          );
          r++;
        }
        if (groups != null) {
          final sub = purchasesTotalsOf(block.rows, units);
          setFooterRow(
            sheet,
            r,
            units,
            groupSubtotalLabel(block.key, sub),
            sub,
          );
          r++;
        }
      }
      if (groups == null) {
        final totals = purchasesTotalsOf(rows, units);
        setFooterRow(sheet, r, units, totals.label, totals);
      } else {
        final totals = purchasesTotalsOf(rows, units);
        setFooterRow(
          sheet,
          r,
          units,
          '${AppStrings.statsGrandTotal} ${totals.label}',
          totals,
        );
      }
      return _saveWorkbook(workbook.excel, rows.length);
    } on Object catch (e, s) {
      AppLogger.error(LogTag.stats, 'Αποτυχία δημιουργίας XLSX αγορών', e, s);
      throw const StatsExportException();
    }
  }

  /// Γραμμή footer (label + sums/μονάδα + σύνολο) στη γραμμή [r].
  static void setFooterRow(
    Sheet sheet,
    int r,
    List<Unit> units,
    String label,
    PurchasesTotals totals,
  ) {
    void set(int c, CellValue value) =>
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
          ..value = value;
    set(0, TextCellValue(label));
    for (var u = 0; u < units.length; u++) {
      set(5 + u, DoubleCellValue(totals.qtyByUnit[units[u].id] ?? 0));
    }
    final priceCol = 5 + units.length;
    set(priceCol + 3, DoubleCellValue(totals.netTotalCents / 100.0));
  }

  /// Χτίζει PDF bytes (async CPU). `headers`/`body`/`totalsLine` έτοιμα
  /// strings από τον καλούντα (presentation SPoT — το service κάνει μόνο
  /// layout). Με [sections] (3η ανάλυση): blocks τίτλου + πίνακα + υποσυνόλου
  /// + grand footer — χωρίς sections η flat συμπεριφορά (backward
  /// compatible). Αποτυχία → `StatsExportException`.
  static Future<Uint8List> buildPdfBytes({
    required String title,
    required List<String> headers,
    required List<List<String>> body,
    required String? totalsLine,
    required Uint8List fontBytes,
    required Uint8List boldFontBytes,
    List<PdfSection>? sections,
  }) async {
    try {
      final regular = pw.Font.ttf(fontBytes.buffer.asByteData());
      final bold = pw.Font.ttf(boldFontBytes.buffer.asByteData());
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          header: (_) => pw.Padding(
            padding: const pw.EdgeInsets.only(
              bottom: AppConstants.pdfHeaderPaddingBottom,
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(font: bold, fontSize: AppConstants.pdfTitleFontSize),
            ),
          ),
          footer: (context) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                totalsLine ?? '',
                style: pw.TextStyle(font: bold, fontSize: AppConstants.pdfBodyFontSize),
              ),
              pw.Text(
                'Σελίδα ${context.pageNumber} / ${context.pagesCount}',
                style: pw.TextStyle(font: regular, fontSize: AppConstants.pdfPageNoFontSize),
              ),
            ],
          ),
          build: (_) => [
            if (sections == null)
              _pdfTable(
                headers: headers,
                rows: body,
                regular: regular,
                bold: bold,
              )
            else
              for (final section in sections) ...[
                pw.Padding(
                  padding: const pw.EdgeInsets.only(
                    top: AppConstants.pdfSectionPaddingTop,
                    bottom: AppConstants.pdfSectionPaddingBottom,
                  ),
                  child: pw.Text(
                    section.title,
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: AppConstants.pdfSectionFontSize,
                    ),
                  ),
                ),
                _pdfTable(
                  headers: headers,
                  rows: section.rows,
                  regular: regular,
                  bold: bold,
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(
                    top: AppConstants.pdfSubtotalPaddingTop,
                    bottom: AppConstants.pdfSubtotalPaddingBottom,
                  ),
                  child: pw.Text(
                    section.subtotal,
                    style: pw.TextStyle(font: bold, fontSize: AppConstants.pdfBodyFontSize),
                  ),
                ),
              ],
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

  /// Πίνακας PDF (κοινός flat + sections — ίδια όψη: padding 4, plain
  /// header, border all · `TableHelper.fromTextArray`, 29-09-2026).
  static pw.Widget _pdfTable({
    required List<String> headers,
    required List<List<String>> rows,
    required pw.Font regular,
    required pw.Font bold,
  }) {
    pw.TextStyle cellStyle(bool header) => pw.TextStyle(
      font: header ? bold : regular,
      fontSize: AppConstants.pdfBodyFontSize,
      fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: cellStyle(true),
      cellStyle: cellStyle(false),
      cellPadding: const pw.EdgeInsets.all(AppConstants.pdfCellPadding),
      border: pw.TableBorder.all(),
    );
  }

  /// Γράμμα στήλης (0 → A) — 8 στήλες καρτέλας.
  static String _columnLetter(int index) =>
      String.fromCharCode('A'.codeUnitAt(0) + index);
}
