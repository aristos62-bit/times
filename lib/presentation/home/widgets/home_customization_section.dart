/// «Προσαρμογή Οθόνης» — τελευταία γραμμή Κεντρικής (§2.1 · Φάση 5 Βήμα 5).
///
/// Collapsible section (pattern Ρυθμίσεων `settings_page.dart` — κλειστή εξ
/// αρχής): ανά γράφημα ορατότητα (switch) + περίοδος (label) + σειρά (βέλη).
/// Η περίοδος αλλάζει από τις κάρτες (picker εκεί)· εδώ φαίνεται ως info.
/// Watches: `homeChartConfigProvider` (prefs, όχι βάση). Χωρίς busy-flag
/// (sync ops όπως το theme — όχι CRUD).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../controllers/home_chart_config_controller.dart';
import '../home_page.dart';
import '../state/home_chart_config.dart';
import 'home_chart_card.dart';

/// Section προσαρμογής γραφημάτων (§2.1).
class HomeCustomizationSection extends ConsumerWidget {
  const HomeCustomizationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(homeChartConfigProvider);
    final ids = List.of(ChartId.values)
      ..sort((a, b) {
        final orderCompare =
            config.entryOf(a).order.compareTo(config.entryOf(b).order);
        if (orderCompare != 0) return orderCompare;
        return a.index.compareTo(b.index);
      });
    return Card(
      // Collapsible section (pattern Ρυθμίσεων): κλειστή εξ αρχής —
      // tap δείχνει τις γραμμές (ίδια widgets, §2.4).
      child: ExpansionTile(
        title: Text(
          AppStrings.homeCustomizationTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppConstants.spacingL,
          0,
          AppConstants.spacingL,
          AppConstants.spacingL,
        ),
        children: [
          for (final id in ids)
            _ChartRow(
              id: id,
              entry: config.entryOf(id),
              isFirst: id == ids.first,
              isLast: id == ids.last,
            ),
        ],
      ),
    );
  }
}

/// Γραμμή ενός γραφήματος: switch ορατότητας + period label + βέλη σειράς.
class _ChartRow extends ConsumerWidget {
  const _ChartRow({
    required this.id,
    required this.entry,
    required this.isFirst,
    required this.isLast,
  });

  final ChartId id;
  final ChartEntry entry;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(homeChartConfigProvider.notifier);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(HomePage.titleOf(id)),
          subtitle: Text(ChartPeriodSelector.labelOf(entry.period)),
          value: entry.visible,
          onChanged: (value) => notifier.setVisible(id, value),
        ),
        Row(
          children: [
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.arrow_upward),
              tooltip: AppStrings.chartMoveUp,
              onPressed: isFirst ? null : () => notifier.moveUp(id),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_downward),
              tooltip: AppStrings.chartMoveDown,
              onPressed: isLast ? null : () => notifier.moveDown(id),
            ),
          ],
        ),
      ],
    );
  }
}
