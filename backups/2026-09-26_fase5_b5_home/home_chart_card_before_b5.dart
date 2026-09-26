/// Κάρτα γραφήματος Κεντρικής (§2.1 · Φάση 5 Βήμα 4).
///
/// Τίτλος + period selector + `AsyncValue` states (Γ1): loading → skeleton
/// (όχι κενή κάρτα, §2.1:179) · κενό → `noPricesForPeriod` · error →
/// `loadDataFailed` + «Επανάληψη» (`ref.invalidate` του instance) · data →
/// `Pie3dChart`. Τοπικό `Consumer` (όχι rebuild σελίδας — §2.1Perf).
/// Dumb-contract: η κάρτα διαβάζει ΜΟΝΟ το resolved instance (όχι family) —
/// ο γονέας (Βήμα 5) επιλύει το query από το config.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/constants/app_errors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/chart_totals.dart';
import 'pie_3d_chart.dart';

/// Κάρτα ενός γραφήματος (§2.1).
class HomeChartCard extends ConsumerWidget {
  const HomeChartCard({
    super.key,
    required this.title,
    required this.slicesProvider,
    required this.period,
    required this.onPeriodChanged,
    this.customSubtitle,
  });

  /// Τίτλος κάρτας (SPoT `AppStrings`, §1.1).
  final String title;

  /// Resolved stream instance (ο γονέας περνά `family(query)` — ίδιο idiom
  /// με το `RecentReceiptsList` + `recentReceiptsStreamProvider`).
  final StreamProvider<List<ChartSlice>> slicesProvider;

  /// Τρέχουσα περίοδος κάρτας (από το config, Βήμα 3).
  final PeriodType period;

  /// Αλλαγή περιόδου (ο γονέας γράφει στο config + ανοίγει picker, Βήμα 5).
  final ValueChanged<PeriodType> onPeriodChanged;

  /// Υπότιτλος custom range (ημερομηνίες, ορατός μόνο σε `custom`).
  final String? customSubtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(slicesProvider);
    // Προτεραιότητα σφάλματος (εύρημα Ε2 Βήματος 3 — Riverpod 3 retry): σε
    // μόνιμη βλάβη το upstream μένει `AsyncLoading` με συνημμένο σφάλμα (το
    // Riverpod ξαναπροσπαθεί αυτόματα) και το σκέτο `.when` θα έπαιρνε το
    // `loading` branch → η κάρτα θα έμενε skeleton ΓΙΑ ΠΑΝΤΑ. Γι' αυτό το
    // `hasError` (χωρίς τιμή) προηγείται. Με τιμή (stale) δείχνουμε τα data.
    final showError = async.hasError && !async.hasValue;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppConstants.spacingS),
            ChartPeriodSelector(
              selected: period,
              onSelected: onPeriodChanged,
              customSubtitle: customSubtitle,
            ),
            const SizedBox(height: AppConstants.spacingS),
            if (showError)
              _ChartError(onRetry: () => ref.invalidate(slicesProvider))
            else
              async.when(
                data: (slices) => slices.isEmpty
                    ? Text(
                        AppStrings.noPricesForPeriod,
                        style: theme.textTheme.bodyMedium,
                      )
                    : Pie3dChart(slices: slices, semanticsLabel: title),
                loading: () => const _ChartSkeleton(),
                error: (_, _) =>
                    _ChartError(onRetry: () => ref.invalidate(slicesProvider)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Σφάλμα κάρτας: `loadDataFailed` + «Επανάληψη» (SPoT, §2.1).
class _ChartError extends StatelessWidget {
  const _ChartError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppErrors.loadDataFailed, style: theme.textTheme.bodyMedium),
        TextButton(
          onPressed: onRetry,
          child: const Text(AppStrings.retryButton),
        ),
      ],
    );
  }
}

/// Επιλογή περιόδου κάρτας (§2.1 · Βήμα 4) — dumb (`ThemeModeSelector`
/// pattern §2.0): 5 SPoT labels σε `DropdownMenu` (όχι `SegmentedButton` —
/// 5 segments σπάνε τα 320px, §1.4). Το custom range picker ανοίγει ο
/// γονέας (Βήμα 5)· dismiss → no-op.
class ChartPeriodSelector extends StatelessWidget {
  const ChartPeriodSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    this.customSubtitle,
  });

  /// Τρέχουσα περίοδος (από το config).
  final PeriodType selected;

  /// Καλείται με τη νέα περίοδο (custom → ο γονέας ανοίγει picker).
  final ValueChanged<PeriodType> onSelected;

  /// Υπότιτλος custom range (ημερομηνίες) — ορατός μόνο σε `custom`.
  final String? customSubtitle;

  /// SPoT label περιόδου (§1.1).
  static String labelOf(PeriodType period) => switch (period) {
        PeriodType.day => AppStrings.periodDay,
        PeriodType.week => AppStrings.periodWeek,
        PeriodType.month => AppStrings.periodMonth,
        PeriodType.year => AppStrings.periodYear,
        PeriodType.custom => AppStrings.periodCustom,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownMenu<PeriodType>(
          initialSelection: selected,
          onSelected: (value) {
            if (value != null) onSelected(value);
          },
          dropdownMenuEntries: [
            for (final period in PeriodType.values)
              DropdownMenuEntry(value: period, label: labelOf(period)),
          ],
        ),
        if (selected == PeriodType.custom && customSubtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: AppConstants.spacingS),
            child: Text(
              customSubtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }
}

/// Skeleton φόρτωσης κάρτας (§2.1:179 — όχι κενή κάρτα, όχι spinner).
///
/// Private (μόνο οι κάρτες το χρησιμοποιούν): 3 bars από
/// `surfaceContainerHighest` (dark-safe, §1.5) + SPoT μεγέθη (§1.1).
class _ChartSkeleton extends StatelessWidget {
  const _ChartSkeleton();

  @override
  Widget build(BuildContext context) {
    final barColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double widthFactor) => FractionallySizedBox(
          widthFactor: widthFactor,
          alignment: Alignment.centerLeft,
          child: Container(
            height: AppConstants.spacingL,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
            ),
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        bar(1.0),
        const SizedBox(height: AppConstants.spacingS),
        bar(0.7),
        const SizedBox(height: AppConstants.spacingS),
        bar(0.85),
      ],
    );
  }
}
