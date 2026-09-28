/// Dumb dialog προεπισκόπησης ομαδοποιημένης αναφοράς (§2.3 · 3η ανάλυση).
///
/// Grand banner + sections (header + `PurchasesTable`/ομάδα — footer =
/// υποσύνολο) + actions Excel/PDF/Κλείσιμο (pattern reference 29-09-2026,
/// προσαρμοσμένο στις συμβάσεις: ColorScheme αντί hardcoded, SPoT strings,
/// AppFeedback εκτός). Επιστρέφει την επιλεγμένη εξαγωγή (`null` = dismiss
/// ή Κλείσιμο — ο καλών δεν κάνει τίποτα). Καμία provider-ανάγνωση (§2.0.1 —
/// δεδομένα ως παράμετροι, §2.0 dumb).
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_messages.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/local/app_database.dart';
import '../../../data/models/chart_totals.dart';
import '../../../domain/services/statistics_export.dart';
import '../../shared/currency_text_field.dart';
import 'purchases_table.dart';

/// Επιλεγμένη εξαγωγή από την προεπισκόπηση (null = dismiss/Κλείσιμο).
enum ReportPreviewAction { excel, pdf }

/// Section προεπισκόπησης: εμφανιζόμενο όνομα + γραμμές.
typedef PreviewSection = ({String display, List<PeriodPurchaseRow> rows});

/// Ανοίγει την προεπισκόπηση αναφοράς.
Future<ReportPreviewAction?> showReportPreview(
  BuildContext context, {
  required String title,
  required PurchasesTotals grandTotals,
  required List<Unit> units,
  required List<PreviewSection> sections,
}) {
  return showDialog<ReportPreviewAction>(
    context: context,
    builder: (_) => ReportPreviewDialog(
      title: title,
      grandTotals: grandTotals,
      units: units,
      sections: sections,
    ),
  );
}

/// Dialog προεπισκόπησης — «χαζό» (§2.0): όλα από παραμέτρους.
class ReportPreviewDialog extends StatelessWidget {
  const ReportPreviewDialog({
    super.key,
    required this.title,
    required this.grandTotals,
    required this.units,
    required this.sections,
  });

  final String title;
  final PurchasesTotals grandTotals;
  final List<Unit> units;
  final List<PreviewSection> sections;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(title),
      // Responsive (§1.4): max-width + scroll (pattern ConfirmDialog).
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppConstants.dialogMaxWidth,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusS),
                ),
                child: Semantics(
                  label:
                      '${AppStrings.chartTotalLabel} ${CurrencyTextField.formatCents(grandTotals.netTotalCents)}',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.chartTotalLabel.toUpperCase(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${CurrencyTextField.formatCents(grandTotals.netTotalCents)} '
                        '${AppStrings.currencySymbol}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              for (final section in sections) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        section.display,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      '${CurrencyTextField.formatCents(StatisticsExportService.purchasesTotalsOf(section.rows, units).netTotalCents)} '
                      '${AppStrings.currencySymbol}',
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingS),
                PurchasesTable(
                  rows: section.rows,
                  units: units,
                  totals: StatisticsExportService.purchasesTotalsOf(
                    section.rows,
                    units,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () =>
              Navigator.of(context).pop(ReportPreviewAction.excel),
          icon: const Icon(Icons.table_chart_outlined),
          label: const Text(AppStrings.statsExportExcelAction),
        ),
        TextButton.icon(
          onPressed: () =>
              Navigator.of(context).pop(ReportPreviewAction.pdf),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text(AppStrings.statsExportPdfAction),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppMessages.confirmDialogCancel),
        ),
      ],
    );
  }
}
