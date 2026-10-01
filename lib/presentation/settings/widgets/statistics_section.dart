/// Section «Στατιστικά» (§2.3 · 28-09-2026).
///
/// Μενού αναλύσεων + detail ανά ανάλυση (όχι στοίβα — κλιμακώνεται σε Ν
/// αναλύσεις: νέα = νέα γραμμή στο `_entries` + νέο part αρχείο).
/// Αναλύσεις σε parts (κανόνας 7, <500 γρ. έκαστο): ledger (1η: καρτέλα) ·
/// purchases (2η: αγορές) · grouped (3η: ομαδοποιημένη) · shared (κοινά).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/constants/app_errors.dart';
import '../../../core/constants/app_messages.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/line_total.dart';
import '../../../data/local/app_database.dart';
import '../../../data/models/chart_totals.dart';
import '../../../data/providers/stream_providers.dart';
import '../../../domain/services/chart_helpers.dart';
import '../../../domain/services/statistics_export.dart';
import '../../home/widgets/home_chart_card.dart';
import '../../shared/currency_text_field.dart';
import '../../shared/quantity_text_field.dart';
import '../../shared/searchable_dropdown_field.dart';
import '../../shared/controller_op_runner.dart';
import '../controllers/statistics_controller.dart';
import 'catalog_filter.dart';
import 'purchases_table.dart';
import 'report_preview_dialog.dart';
import 'statistics_table.dart';

part 'statistics_analysis_shared.dart';
part 'ledger_analysis.dart';
part 'purchases_analysis.dart';
part 'grouped_analysis.dart';

/// Καταχώρηση μενού (τίτλος + περιγραφή · νέα ανάλυση = νέα γραμμή).
typedef _StatsEntry = ({String title, String description});

/// Section «Στατιστικά» — μενού αναλύσεων (§2.3).
class StatisticsSection extends ConsumerStatefulWidget {
  const StatisticsSection({super.key});

  @override
  ConsumerState<StatisticsSection> createState() => _StatisticsSectionState();
}

class _StatisticsSectionState extends ConsumerState<StatisticsSection> {
  /// Ανοιχτή ανάλυση (null = μενού) — τοπικό, όχι persist (Q5).
  int? _openIndex;

  /// Μενού (κλιμακώνεται — 29-09-2026: 3 γραμμές).
  static const _entries = <_StatsEntry>[
    (
      title: AppStrings.statsLedgerTitle,
      description: AppStrings.statsLedgerDescription,
    ),
    (
      title: AppStrings.statsPurchasesTitle,
      description: AppStrings.statsPurchasesDescription,
    ),
    (
      title: AppStrings.statsGroupedTitle,
      description: AppStrings.statsGroupedDescription,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final open = _openIndex;
    if (open == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _entries.length; i++)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                _entries[i].title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                _entries[i].description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.arrow_forward_outlined),
              onTap: () {
                setState(() => _openIndex = i);
                AppLogger.info(
                  LogTag.ui,
                  'Άνοιγμα ανάλυσης: ${_entries[i].title}',
                );
              },
            ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_outlined),
              tooltip: AppStrings.statsBackAction,
              onPressed: () => setState(() => _openIndex = null),
            ),
            Expanded(
              child: Text(
                _entries[open].title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingS),
        if (open == 0)
          const _LedgerAnalysis()
        else if (open == 1)
          const _PurchasesAnalysis()
        else
          const _GroupedAnalysis(),
      ],
    );
  }
}
