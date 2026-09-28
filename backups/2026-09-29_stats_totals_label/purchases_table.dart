/// Dumb πίνακας συγκεντρωτικών αγορών (§2.3 · 2η ανάλυση «Συνολικές αγορές»).
///
/// Έτοιμες γραμμές + μονάδες + σύνολα (§2.0): καμία provider-ανάγνωση.
/// Στήλες ποσότητας δυναμικές — μία ανά μονάδα [units] (σειρά λίστας, Q3) —
/// ώστε τεμάχια/κιλά/λίτρα να μη συγχέονται στα σύνολα. Οριζόντιο scroll
/// (§1.4 — 8+Ν στήλες)· numerics δεξιά· footer (sums/μονάδα + σύνολο, Q4).
/// Χρώματα από το theme (DataTable default — dark/light δωρεάν, §1.5).
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../data/local/app_database.dart';
import '../../../data/models/chart_totals.dart';
import '../../../domain/services/statistics_export.dart';
import '../../shared/currency_text_field.dart';
import '../../shared/quantity_text_field.dart';

/// Πίνακας αγορών με footer συνόλων (§2.3 · Q4).
class PurchasesTable extends StatelessWidget {
  const PurchasesTable({
    super.key,
    required this.rows,
    required this.units,
    required this.totals,
  });

  /// Οι γραμμές (ordered κατά sort, capped από τον provider).
  final List<PeriodPurchaseRow> rows;

  /// Οι μονάδες-στήλες (σειρά προβολής, από `unitsStreamProvider`).
  final List<Unit> units;

  /// Τα σύνολα (μοναδική πηγή `purchasesTotalsOf`, §1.1).
  final PurchasesTotals totals;

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
    final localizations = MaterialLocalizations.of(context);
    return Semantics(
      // container + explicitChildNodes (precedent γραφημάτων, §1.6).
      container: true,
      explicitChildNodes: true,
      label: AppStrings.statsPurchasesTitle,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            const DataColumn(label: Text(AppStrings.statsColumnDate)),
            const DataColumn(
              label: Text(AppStrings.statsColumnReceipt),
              numeric: true,
            ),
            const DataColumn(label: Text(AppStrings.fieldItemName)),
            const DataColumn(label: Text(AppStrings.statsColumnCategory)),
            const DataColumn(label: Text(AppStrings.statsColumnSupplier)),
            for (final unit in units)
              DataColumn(label: Text(unit.name), numeric: true),
            const DataColumn(
              label: Text(AppStrings.statsColumnPrice),
              numeric: true,
            ),
            const DataColumn(
              label: Text(AppStrings.statsColumnDiscount),
              numeric: true,
            ),
            const DataColumn(
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
                  _text(row.itemName),
                  _text(row.categoryName),
                  _text(row.supplierName),
                  for (final unit in units)
                    if (row.unitId == unit.id)
                      _text(
                        QuantityTextField.formatQuantity(row.quantity),
                      )
                    else
                      DataCell.empty,
                  _money(row.priceCents),
                  _money(row.discountCents),
                  _money(row.priceCents - row.discountCents),
                ],
              ),
            DataRow(
              cells: [
                _text(totals.label),
                DataCell.empty,
                DataCell.empty,
                DataCell.empty,
                DataCell.empty,
                for (final unit in units)
                  _text(
                    QuantityTextField.formatQuantity(
                      totals.qtyByUnit[unit.id] ?? 0,
                    ),
                  ),
                DataCell.empty,
                DataCell.empty,
                _money(totals.netTotalCents),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
