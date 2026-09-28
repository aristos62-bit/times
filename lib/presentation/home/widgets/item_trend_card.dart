/// Κάρτα πορείας τιμής είδους (§2.1 · 28-09-2026 — 6ο γράφημα, γραμμή).
///
/// Τίτλος + `ChartPeriodSelector` (reuse Βήματος 4) + επιλογή είδους
/// (`SearchableDropdownField`, χωρίς «+» — δημιουργία από Εισαγωγή/Ρυθμίσεις)
/// + locked banner (pattern προμηθευτή/είδους §2.4) + `AsyncValue` states με
/// hasError-priority (εύρημα Ε2 — Riverpod 3 retry, όπως `HomeChartCard`).
/// Self-contained (§2.0 εξαίρεση, όπως το search field): λύνει μόνη της
/// είδος→μονάδα→query από το `range` του γονέα (ο γονέας Βήματος 5 επιλύει
/// μόνο περίοδο/range από το config).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/constants/app_errors.dart';
import '../../../core/constants/app_messages.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/local/app_database.dart';
import '../../../data/models/chart_totals.dart';
import '../../../data/providers/settings_providers.dart';
import '../../../data/providers/stream_providers.dart';
import '../../shared/searchable_dropdown_field.dart';
import 'home_chart_card.dart';
import 'item_trend_chart.dart';

/// Κάρτα πορείας ενός είδους (§2.1).
class ItemTrendCard extends ConsumerStatefulWidget {
  const ItemTrendCard({
    super.key,
    required this.range,
    required this.period,
    required this.onPeriodChanged,
    this.customSubtitle,
  });

  /// Όρια `[from, to)` περιόδου (ο γονέας τα επιλύει από το config, Βήμα 5).
  final ({DateTime from, DateTime to}) range;

  /// Τρέχουσα περίοδος κάρτας (από το config).
  final PeriodType period;

  /// Αλλαγή περιόδου (ο γονέας γράφει στο config + ανοίγει picker).
  final ValueChanged<PeriodType> onPeriodChanged;

  /// Υπότιτλος custom range (ημερομηνίες, ορατός μόνο σε `custom`).
  final String? customSubtitle;

  @override
  ConsumerState<ItemTrendCard> createState() => _ItemTrendCardState();
}

class _ItemTrendCardState extends ConsumerState<ItemTrendCard> {
  /// «Γενιά» του dropdown — αυξάνεται σε αποεπιλογή ώστε το πεδίο να
  /// ξαναχτιστεί άδειο (pattern `_supplierFieldEpoch` header §2.2: το
  /// dropdown δεν στηρίζει εξωτερικό καθάρισμα).
  int _epoch = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Αποεπιλογή (banner «Αλλαγή» ή ορφανό) → φρέσκο άδειο dropdown.
    ref.listen<int?>(
      selectedTrendItemProvider,
      (previous, next) {
        if (previous != null && next == null && mounted) {
          setState(() => _epoch++);
        }
      },
    );
    final selectedId = ref.watch(selectedTrendItemProvider);
    // Gated watch (§2.0.1): η λίστα ειδών παρακολουθείται ΜΟΝΟ με επιλογή —
    // στο idle δεν ανοίγει η βάση (ούτε στιγμιογράφεται provider).
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.chartItemTrendTitle,
              style: theme.textTheme.titleMedium,
            ),
            Text(
              AppStrings.trendAxisUnit,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            ChartPeriodSelector(
              key: ValueKey(widget.period),
              selected: widget.period,
              onSelected: widget.onPeriodChanged,
              customSubtitle: widget.customSubtitle,
            ),
            const SizedBox(height: AppConstants.spacingS),
            if (selectedId == null)
              _IdleBody(epoch: _epoch)
            else
              _SelectedBody(selectedId: selectedId, range: widget.range),
          ],
        ),
      ),
    );
  }
}

/// Idle — dropdown αναζήτησης + hint (όχι σφάλμα, όχι DB access).
class _IdleBody extends ConsumerWidget {
  const _IdleBody({required this.epoch});

  final int epoch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchableDropdownField<Item>(
          key: ValueKey(epoch),
          labelText: AppStrings.fieldItemName,
          hintText: AppStrings.trendItemSearchHint,
          searchProvider: itemTrendSearchProvider.call,
          labelOf: (item) => item.name,
          // Χωρίς «+» (δημιουργία από Εισαγωγή/Ρυθμίσεις, §2.4).
          onSelected: (item) =>
              ref.read(selectedTrendItemProvider.notifier).select(item.id),
          prefixIcon: const Icon(Icons.search),
          resultLeadingIcon: const Icon(Icons.shopping_basket_outlined),
        ),
        const SizedBox(height: AppConstants.spacingS),
        Text(
          AppStrings.trendNoItemSelected,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// Επιλεγμένο είδος: επίλυση Item + μονάδα + δεδομένα (dumb — §2.0).
class _SelectedBody extends ConsumerWidget {
  const _SelectedBody({required this.selectedId, required this.range});

  final int selectedId;
  final ({DateTime from, DateTime to}) range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsStreamProvider);
    final showError = items.hasError && !items.hasValue;
    if (showError) {
      return _TrendError(
        onRetry: () => ref.invalidate(itemsStreamProvider),
      );
    }
    return items.when(
      data: (list) => _ItemBody(
        selectedId: selectedId,
        items: list,
        range: range,
      ),
      loading: () => const _TrendSkeleton(),
      error: (_, _) => _TrendError(
        onRetry: () => ref.invalidate(itemsStreamProvider),
      ),
    );
  }
}

/// Σώμα επιλεγμένου (dumb — έτοιμα δεδομένα, §2.0).
class _ItemBody extends ConsumerWidget {
  const _ItemBody({
    required this.selectedId,
    required this.items,
    required this.range,
  });

  final int selectedId;
  final List<Item> items;
  final ({DateTime from, DateTime to}) range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ορφανή επιλογή (διαγραφή είδους — πρακτικά αδύνατη με γραμμές,
    // RESTRICT §3, defensive όπως `loadReceiptForEdit`).
    Item? selected;
    for (final item in items) {
      if (item.id == selectedId) {
        selected = item;
        break;
      }
    }
    if (selected == null) {
      return _OrphanView(
        onReselect: () =>
            ref.read(selectedTrendItemProvider.notifier).clear(),
      );
    }
    final unitId = selected.defaultUnitId;
    final banner = _LockedItemBanner(
      item: selected,
      onChange: () =>
          ref.read(selectedTrendItemProvider.notifier).clear(),
    );
    // Είδος χωρίς μονάδα → Add-αδύνατο και εδώ: hint, όχι γράφημα
    // (μονάδα ορίζεται από Ρυθμίσεις → Είδη, κλείδωμα 28-09-2026).
    if (unitId == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          banner,
          const SizedBox(height: AppConstants.spacingS),
          Semantics(
            liveRegion: true,
            child: Text(
              AppErrors.unitRequired,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        banner,
        const SizedBox(height: AppConstants.spacingS),
        _TrendData(
          query: (
            itemId: selected.id,
            unitId: unitId,
            from: range.from,
            to: range.to,
          ),
        ),
      ],
    );
  }
}

/// Locked banner επιλεγμένου είδους (pattern προμηθευτή/είδους §2.4).
class _LockedItemBanner extends StatelessWidget {
  const _LockedItemBanner({required this.item, required this.onChange});

  final Item item;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.check_circle_outline),
        title: Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: TextButton(
          onPressed: onChange,
          child: const Text(AppStrings.changeItem),
        ),
      ),
    );
  }
}

/// Ορφανή επιλογή: μήνυμα + «Αλλαγή» (επιστροφή στο dropdown).
class _OrphanView extends StatelessWidget {
  const _OrphanView({required this.onReselect});

  final VoidCallback onReselect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppMessages.trendItemRemoved,
            style: theme.textTheme.bodyMedium),
        TextButton(
          onPressed: onReselect,
          child: const Text(AppStrings.changeItem),
        ),
      ],
    );
  }
}

/// Δεδομένα γραμμής: skeleton/empty/error+retry/data (§2.1:179-185).
class _TrendData extends ConsumerWidget {
  const _TrendData({required this.query});

  final ItemTrendQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(itemTrendProvider(query));
    final instance = itemTrendProvider(query);
    final showError = async.hasError && !async.hasValue;
    if (showError) {
      return _TrendError(onRetry: () => ref.invalidate(instance));
    }
    return async.when(
      data: (data) {
        if (data.points.isEmpty) {
          return Text(
            AppStrings.noPricesForPeriod,
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ItemTrendChart(
              points: data.points,
              semanticsLabel: AppStrings.chartItemTrendTitle,
            ),
            if (data.otherUnitCount > 0) ...[
              const SizedBox(height: AppConstants.spacingS),
              Text(
                AppMessages.trendOtherUnitsNote(data.otherUnitCount),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        );
      },
      loading: () => const _TrendSkeleton(),
      error: (_, _) =>
          _TrendError(onRetry: () => ref.invalidate(instance)),
    );
  }
}

/// Σφάλμα κάρτας: `loadDataFailed` + «Επανάληψη» (SPoT, §2.1).
class _TrendError extends StatelessWidget {
  const _TrendError({required this.onRetry});

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

/// Skeleton φόρτωσης κάρτας (§2.1:179 — pattern `_ChartSkeleton`).
class _TrendSkeleton extends StatelessWidget {
  const _TrendSkeleton();

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
