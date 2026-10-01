/// Dumb πίνακας καρτέλας είδους (§2.3 · 28-09-2026 — 1η ανάλυση).
///
/// Έτοιμες γραμμές (§2.0): καμία provider-ανάγνωση — τα σύνολα υπολογίζονται
/// από το SPoT `StatisticsExportService.totalsOf` (μοναδική πηγή, §1.1).
/// 8 στήλες (SPoT headers) σε οριζόντιο scroll (§1.4 — όχι overflow σε
/// κινητά)· numerics δεξιά· footer συνόλων (Q4). Χρώματα από το theme
/// (DataTable default — dark/light δωρεάν, §1.5).
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../data/models/chart_totals.dart';
import '../../../domain/services/statistics_export.dart';
import '../../shared/currency_text_field.dart';

/// Πίνακας γραμμών καρτέλας με footer συνόλων (§2.3 · Q4).
class StatisticsTable extends StatelessWidget {
  const StatisticsTable({super.key, required this.rows});

  /// Οι γραμμές (ordered, capped από τον provider).
  final List<ItemLedgerRow> rows;

  /// Κελί ποσού («12,61 €», maxLines 1 + ellipsis, §1.4).
  static DataCell _money(int cents) => DataCell(
        Text(
          '${CurrencyTextField.formatCents(cents)} '
          '${AppStrings.currencySymbol}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );

  /// Κελί κειμένου (maxLines 1 + ellipsis, §1.4).
  static DataCell _text(String value) => DataCell(
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final totals = StatisticsExportService.totalsOf(rows);
    final localizations = MaterialLocalizations.of(context);
    return Semantics(
      // container + explicitChildNodes (precedent γραφημάτων, §1.6).
      container: true,
      explicitChildNodes: true,
      label: AppStrings.titleStatisticsSection,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text(AppStrings.statsColumnDate)),
            DataColumn(
              label: Text(AppStrings.statsColumnReceipt),
              numeric: true,
            ),
            DataColumn(label: Text(AppStrings.statsColumnSupplier)),
            DataColumn(
              label: Text(AppStrings.statsColumnQuantity),
              numeric: true,
            ),
            DataColumn(
              label: Text(AppStrings.statsColumnPrice),
              numeric: true,
            ),
            DataColumn(
              label: Text(AppStrings.statsColumnDiscount),
              numeric: true,
            ),
            DataColumn(
              label: Text(AppStrings.statsColumnTotal),
              numeric: true,
            ),
            DataColumn(
              label: Text(AppStrings.statsColumnNet),
              numeric: true,
            ),
          ],
          rows: [
            for (final row in rows)
              DataRow(
                cells: [
                  _text(localizations.formatShortDate(row.date)),
                  _text('${row.receiptId}'),
                  _text(row.supplierName),
                  _text(StatisticsExportService.quantityText(row)),
                  _money(row.priceCents),
                  _money(StatisticsExportService.discountTotalCents(row)),
                  _money(StatisticsExportService.grossTotalCents(row)),
                  _money(StatisticsExportService.netTotalCents(row)),
                ],
              ),
            DataRow(
              cells: [
                _text(totals.label),
                DataCell.empty,
                DataCell.empty,
                DataCell.empty,
                DataCell.empty,
                DataCell.empty,
                DataCell.empty,
                _money(totals.totalCents),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
