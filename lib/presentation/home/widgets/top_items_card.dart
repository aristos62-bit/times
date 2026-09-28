/// Κάρτα Top-10 με επιλογή μετρικής (§2.1 · 29-09-2026).
///
/// Τίτλος + period selector (reuse `ChartPeriodSelector`, Βήμα 4) + metric
/// selector (DropdownMenu κάτω από period — 320px §1.4, `ValueKey` E5) +
/// body: € → πίτα συνόλων (ίδιο rendering με `HomeChartCard`) · μονάδα →
/// `QtyPieChart`. Gated unit lookup (§2.0.1): η λίστα μονάδων
/// παρακολουθείται ΜΟΝΟ εκτός € (smoke-test συμβατότητα — αλλιώς real DB
/// χωρίς user action). `AsyncValue` states με hasError-priority (Ε2).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/local/app_database.dart';
import '../../../data/models/chart_totals.dart';
import '../../../data/providers/settings_providers.dart';
import '../../../data/providers/stream_providers.dart';
import 'chart_state_views.dart';
import 'home_chart_card.dart';
import 'pie_3d_chart.dart';
import 'qty_pie_chart.dart';

/// Κάρτα Top-10 ειδών με μετρική (§2.1).
class TopItemsCard extends ConsumerWidget {
  const TopItemsCard({
    super.key,
    required this.query,
    required this.period,
    required this.onPeriodChanged,
    this.customSubtitle,
  });

  /// Όρια `[from, to)` περιόδου (ο γονέας τα επιλύει από το config, Βήμα 5).
  final ChartQuery query;

  /// Τρέχουσα περίοδος κάρτας (από το config).
  final PeriodType period;

  /// Αλλαγή περιόδου (ο γονέας γράφει στο config + ανοίγει picker).
  final ValueChanged<PeriodType> onPeriodChanged;

  /// Υπότιτλος custom range (ημερομηνίες, ορατός μόνο σε `custom`).
  final String? customSubtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final metric = ref.watch(topItemsMetricProvider);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.chartTopItemsTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppConstants.spacingS),
            ChartPeriodSelector(
              key: ValueKey(period),
              selected: period,
              onSelected: onPeriodChanged,
              customSubtitle: customSubtitle,
            ),
            const SizedBox(height: AppConstants.spacingS),
            DropdownMenu<TopItemsMetric>(
              key: ValueKey(metric),
              label: const Text(AppStrings.topItemsMetricLabel),
              initialSelection: metric,
              onSelected: (value) {
                if (value != null) {
                  ref
                      .read(topItemsMetricProvider.notifier)
                      .setMetric(value);
                }
              },
              dropdownMenuEntries: [
                for (final m in TopItemsMetric.values)
                  DropdownMenuEntry(
                    value: m,
                    label: topItemsMetricLabel(m),
                  ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingS),
            if (metric == TopItemsMetric.euros)
              _EurosBody(query: query)
            else
              _QtyBody(query: query, metric: metric),
          ],
        ),
      ),
    );
  }
}

/// Body €: πίτα συνόλων (ίδιο rendering με `HomeChartCard` — states +
/// skeleton + retry, §2.1:179-185).
class _EurosBody extends ConsumerWidget {
  const _EurosBody({required this.query});

  final ChartQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slicesProvider = topItemsTotalsProvider(query);
    final async = ref.watch(slicesProvider);
    // Προτεραιότητα σφάλματος (Ε2 — Riverpod 3 retry, όπως `HomeChartCard`).
    final showError = async.hasError && !async.hasValue;
    if (showError) {
      return ChartErrorView(onRetry: () => ref.invalidate(slicesProvider));
    }
    return async.when(
      data: (slices) => slices.isEmpty
          ? Text(
              AppStrings.noPricesForPeriod,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          : Pie3dChart(
              slices: slices,
              semanticsLabel: AppStrings.chartTopItemsTitle,
            ),
      loading: () => const ChartSkeletonView(),
      error: (_, _) =>
          ChartErrorView(onRetry: () => ref.invalidate(slicesProvider)),
    );
  }
}

/// Body μονάδας: lookup id + πίτα ποσοτήτων (§2.1 · μετρικές).
class _QtyBody extends ConsumerWidget {
  const _QtyBody({required this.query, required this.metric});

  final ChartQuery query;
  final TopItemsMetric metric;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abbr = topItemsMetricAbbreviation(metric);
    final unitsAsync = ref.watch(unitsStreamProvider);
    final unitsError = unitsAsync.hasError && !unitsAsync.hasValue;
    if (unitsError) {
      return ChartErrorView(
        onRetry: () => ref.invalidate(unitsStreamProvider),
      );
    }
    return unitsAsync.when(
      data: (units) {
        Unit? unit;
        for (final u in units) {
          if (u.abbreviation == abbr) {
            unit = u;
            break;
          }
        }
        // Miss (σβησμένη/μετονομασμένη — μονάδες χωρίς editor, defensive) →
        // empty msg, όχι crash.
        if (unit == null) {
          AppLogger.info(LogTag.stats, 'Μετρική χωρίς μονάδα: $abbr');
          return Text(
            AppStrings.noPricesForPeriod,
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }
        return _QtyData(
          family: topItemsByUnitProvider(
            (
              from: query.from,
              to: query.to,
              unitId: unit.id,
            ),
          ),
          abbreviation: unit.abbreviation,
        );
      },
      loading: () => const ChartSkeletonView(),
      error: (_, _) => ChartErrorView(
        onRetry: () => ref.invalidate(unitsStreamProvider),
      ),
    );
  }
}

/// Δεδομένα πίτας ποσοτήτων: skeleton/empty/error+retry/data (§2.1).
class _QtyData extends ConsumerWidget {
  const _QtyData({required this.family, required this.abbreviation});

  final StreamProvider<List<ChartQtySlice>> family;
  final String abbreviation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(family);
    final showError = async.hasError && !async.hasValue;
    if (showError) {
      return ChartErrorView(onRetry: () => ref.invalidate(family));
    }
    return async.when(
      data: (slices) => slices.isEmpty
          ? Text(
              AppStrings.noPricesForPeriod,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          : QtyPieChart(
              slices: slices,
              unitAbbreviation: abbreviation,
              semanticsLabel: AppStrings.chartTopItemsTitle,
            ),
      loading: () => const ChartSkeletonView(),
      error: (_, _) =>
          ChartErrorView(onRetry: () => ref.invalidate(family)),
    );
  }
}
