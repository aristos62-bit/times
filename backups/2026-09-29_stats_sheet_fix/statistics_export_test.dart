/// Unit tests — `StatisticsExportService` (§2.3 · 28-09-2026).
///
/// Pure builders (χωρίς widget/DB): filename pattern · format mirrors ·
/// totals · XLSX decode round-trip (header/τύποι/footer) · PDF `%PDF` magic
/// με real fonts (rootBundle + binding) · mapping σφαλμάτων.
library;

import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/data/models/chart_totals.dart';
import 'package:times/domain/services/statistics_export.dart';

/// Fixture: φέτα 0,456 κιλ, 12,96 − 0,35 (καθαρή 12,61, σύνολο 5,75 €).
ItemLedgerRow fetaRow() => (
      receiptId: 12,
      date: DateTime(2026, 9, 9),
      supplierName: 'Μάρκος',
      quantity: 0.456,
      unitAbbreviation: 'κιλ',
      priceCents: 1296,
      discountCents: 35,
    );

void main() {
  group('StatisticsExportService', () {
    test('buildStatsFileName — pattern + extension', () {
      final when = DateTime(2026, 9, 28, 14, 5, 6);
      expect(
        StatisticsExportService.buildStatsFileName(
          when,
          StatsExportFormat.excel,
        ),
        'times_stats_20260928_140506.xlsx',
      );
      expect(
        StatisticsExportService.buildStatsFileName(
          when,
          StatsExportFormat.pdf,
        ),
        'times_stats_20260928_140506.pdf',
      );
    });

    test('format mirrors — cents/quantity/net (parity UI §2.2)', () {
      expect(StatisticsExportService.formatCents(1261), '12,61');
      expect(StatisticsExportService.formatCents(5), '0,05');
      expect(StatisticsExportService.formatQuantity(0.456), '0,456');
      expect(StatisticsExportService.formatQuantity(2.0), '2');
      expect(StatisticsExportService.quantityText(fetaRow()), '0,456 κιλ');
      // (1296−35) × 0,456 = 575,016 → 575 (5,75 = 5,91 − 0,16 ακριβώς).
      expect(StatisticsExportService.netTotalCents(fetaRow()), 575);
    });

    test('totalsOf — label + άθροισμα + πλήθος (Q4)', () {
      final totals = StatisticsExportService.totalsOf([fetaRow(), fetaRow()]);
      expect(totals.label, 'Σύνολο (2)');
      expect(totals.totalCents, 575 * 2);
      expect(totals.count, 2);
    });

    test('buildExcelBytes — decode round-trip (header/τύποι/footer)', () {
      final bytes = StatisticsExportService.buildExcelBytes([fetaRow()]);
      final excel = Excel.decodeBytes(bytes);
      expect(excel.tables.keys, contains('Καρτέλα'));
      final rows = excel.tables['Καρτέλα']!.rows;
      // Header + 1 γραμμή + footer.
      expect(rows.length, 3);

      /// Κείμενο κελιού (TextCellValue → plain, αλλιώς fail).
      String textOf(int r, int c) {
        final value = rows[r][c]?.value;
        if (value is TextCellValue) return value.value.toString();
        return fail('όχι κείμενο ($r,$c): $value');
      }

      /// Αριθμός κελιού (Double/Int → double, αλλιώς fail).
      double numOf(int r, int c) {
        final value = rows[r][c]?.value;
        if (value is DoubleCellValue) return value.value;
        if (value is IntCellValue) return value.value.toDouble();
        return fail('όχι αριθμός ($r,$c): $value');
      }

      expect(textOf(0, 0), 'Ημερομηνία');
      expect(textOf(0, 6), 'Καθαρή');
      // Ημερομηνία native + αριθμός + κείμενα.
      final dateValue = rows[1][0]?.value;
      expect(dateValue, isA<DateCellValue>());
      final date = dateValue as DateCellValue;
      expect(date.year, 2026);
      expect(date.month, 9);
      expect(date.day, 9);
      expect(numOf(1, 1), 12);
      expect(textOf(1, 2), 'Μάρκος');
      expect(textOf(1, 3), '0,456 κιλ');
      // Ποσά native doubles (€).
      expect(numOf(1, 4), closeTo(12.96, 0.0001));
      expect(numOf(1, 5), closeTo(0.35, 0.0001));
      expect(numOf(1, 6), closeTo(12.61, 0.0001));
      // Footer: label + σύνολο.
      expect(textOf(2, 0), 'Σύνολο (1)');
      expect(numOf(2, 6), closeTo(5.75, 0.0001));
    });

    test('buildExcelBytes — κενές γραμμές → header + footer μηδενικών', () {
      final bytes = StatisticsExportService.buildExcelBytes(const []);
      final excel = Excel.decodeBytes(bytes);
      final rows = excel.tables['Καρτέλα']!.rows;
      expect(rows.length, 2);
    });

    test('buildPdfBytes — `%PDF` με ελληνικά (real fonts)', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final (regular, bold) =
          await StatisticsExportService.loadPdfFonts();
      expect(regular.isNotEmpty, isTrue);
      expect(bold.isNotEmpty, isTrue);
      final bytes = await StatisticsExportService.buildPdfBytes(
        title: 'Γάλα Φέτα Βαρελίσια',
        headers: const ['Ημερομηνία', 'Προμηθευτής', 'Καθαρή'],
        body: const [
          ['09/09/2026', 'Μάρκος', '12,61 €'],
        ],
        totalsLine: 'Σύνολο (1): 5,75 €',
        fontBytes: regular,
        boldFontBytes: bold,
      );
      expect(bytes.lengthInBytes, greaterThan(1000));
      expect(bytes.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]); // %PDF
    });

    test('buildPdfBytes — άκυρα fonts → StatsExportException', () async {
      await expectLater(
        StatisticsExportService.buildPdfBytes(
          title: 't',
          headers: const ['h'],
          body: const [
            ['x'],
          ],
          totalsLine: null,
          fontBytes: Uint8List(0),
          boldFontBytes: Uint8List(0),
        ),
        throwsA(isA<StatsExportException>()),
      );
    });
  });
}
