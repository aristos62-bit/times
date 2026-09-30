/// Ανάλυση «Ομαδοποιημένη αναφορά» (§2.3 · 3η ανάλυση).
///
/// Part αρχείο (split 30-09-2026, κανόνας 7 <500 γρ.): `_GroupedAnalysis` +
/// body. Τα imports του `statistics_section.dart` ισχύουν εδώ.
part of 'statistics_section.dart';

/// Ανάλυση «Ομαδοποιημένη αναφορά» (§2.3 · 3η ανάλυση).
///
/// `ConsumerStatefulWidget` με τοπικό state (περίοδος + sort + group —
/// ad-hoc, όχι persist, Q5): selectors (reuse) + κουμπί «Προεπισκόπηση».
/// Χωρίς inline πίνακα (dialog-only display — λεπτό detail). Gated watches
/// (§2.0.1): streams ΜΟΝΟ στο detail. Feedback ΜΟΝΟ από εδώ (§2.4).
class _GroupedAnalysis extends ConsumerStatefulWidget {
  const _GroupedAnalysis();

  @override
  ConsumerState<_GroupedAnalysis> createState() => _GroupedAnalysisState();
}

class _GroupedAnalysisState extends ConsumerState<_GroupedAnalysis> {
  /// Περίοδος ανάλυσης (default Μήνας, όπως οι κάρτες §2.1).
  PeriodType _period = PeriodType.month;

  /// Custom range (μόνο σε `custom`).
  DateTime? _customFrom;
  DateTime? _customTo;

  /// Ταξινόμηση εντός ομάδων (default παλιές → νέες, Q2).
  PurchasesSort _sort = PurchasesSort.dateAsc;

  /// Ομαδοποίηση (default κατηγορία).
  PurchasesGroup _group = PurchasesGroup.category;

  /// Φίλτρο καταλόγου (null-ids = Όλα — τοπικό, όχι persist, Q5).
  CatalogFilterSelection _groupFilter = (
    categoryId: null,
    subCategoryId: null,
    itemGroupId: null,
  );

  /// Επιλογή custom range (picker με SPoT όρια· Ακύρωση → καμία αλλαγή).
  Future<void> _pickCustomRange() async {
    AppLogger.info(LogTag.ui, 'Άνοιγμα custom range ομαδοποιημένης');
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(AppConstants.datePickerFirstYear),
      lastDate: DateTime(AppConstants.datePickerLastYear, 12, 31),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _period = PeriodType.custom;
      _customFrom = picked.start;
      _customTo = picked.end;
    });
  }

  /// Προεπισκόπηση → export (Excel/PDF) ή τίποτα (dismiss/Κλείσιμο).
  Future<void> _preview(
    BuildContext context,
    WidgetRef ref,
    List<PeriodPurchaseRow> rows,
    List<Unit> units,
  ) async {
    final localizations = MaterialLocalizations.of(context);
    final groups = StatisticsExportService.groupPurchases(rows, _group);
    final grand = StatisticsExportService.purchasesTotalsOf(rows, units);
    final action = await showReportPreview(
      context,
      title: AppStrings.statsGroupedTitle,
      grandTotals: grand,
      units: units,
      sections: [
        for (final group in groups)
          (
            display: _groupDisplay(_group, group.key, localizations),
            rows: group.rows,
          ),
      ],
    );
    if (action == null || !context.mounted) return;
    if (action == ReportPreviewAction.excel) {
      await runControllerOp(
        context,
        () => ref
            .read(statisticsControllerProvider.notifier)
            .exportGroupedExcel(
              rows: rows,
              groups: [
                for (final group in groups)
                  (
                    key: _groupDisplay(_group, group.key, localizations),
                    rows: group.rows,
                  ),
              ],
              units: units,
            ),
        AppMessages.statsExported,
      );
    } else {
      final headers = _purchasesHeaders(units);
      await runControllerOp(
        context,
        () => ref
            .read(statisticsControllerProvider.notifier)
            .exportGroupedPdf(
              title: AppStrings.statsGroupedTitle,
              headers: headers,
              sections: [
                for (final group in groups)
                  (
                    title: _groupDisplay(_group, group.key, localizations),
                    rows: [
                      for (final row in group.rows)
                        _purchasesBodyRow(row, units, localizations),
                    ],
                    subtotal: StatisticsExportService.groupSubtotalLabel(
                      _groupDisplay(_group, group.key, localizations),
                      StatisticsExportService.purchasesTotalsOf(
                        group.rows,
                        units,
                      ),
                    ),
                  ),
              ],
              grandTotalsLine: _purchasesTotalsLine(grand),
            ),
        AppMessages.statsExported,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(todayProvider);
    final range = resolvePeriodRange(
      _period,
      customFrom: _customFrom,
      customTo: _customTo,
      now: now,
    );
    final customSubtitle =
        _period == PeriodType.custom && _customFrom != null && _customTo != null
        ? '${MaterialLocalizations.of(context).formatMediumDate(_customFrom!)}'
              ' – ${MaterialLocalizations.of(context).formatMediumDate(_customTo!)}'
        : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChartPeriodSelector(
          key: ValueKey(_period),
          selected: _period,
          onSelected: (period) {
            if (period == PeriodType.custom) {
              _pickCustomRange();
            } else {
              setState(() {
                _period = period;
                _customFrom = null;
                _customTo = null;
              });
            }
          },
          customSubtitle: customSubtitle,
        ),
        const SizedBox(height: AppConstants.spacingS),
        _SortDropdown(
          sort: _sort,
          onChanged: (sort) => setState(() => _sort = sort),
        ),
        const SizedBox(height: AppConstants.spacingS),
        _GroupDropdown(
          group: _group,
          onChanged: (group) => setState(() => _group = group),
        ),
        const SizedBox(height: AppConstants.spacingS),
        CatalogFilterField(
          onChanged: (filter) => setState(() => _groupFilter = filter),
        ),
        const SizedBox(height: AppConstants.spacingS),
        _GroupedBody(
          query: (
            from: range.from,
            to: range.to,
            sort: _sort,
            categoryId: _groupFilter.categoryId,
            subCategoryId: _groupFilter.subCategoryId,
            itemGroupId: _groupFilter.itemGroupId,
          ),
          onPreview: (rows, units) => _preview(context, ref, rows, units),
        ),
      ],
    );
  }
}

/// Σώμα ομαδοποιημένης: units + rows → κουμπί προεπισκόπησης (§2.3).
class _GroupedBody extends ConsumerWidget {
  const _GroupedBody({required this.query, required this.onPreview});

  final PeriodPurchasesQuery query;
  final Future<void> Function(List<PeriodPurchaseRow>, List<Unit>) onPreview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(unitsStreamProvider);
    final dataAsync = ref.watch(periodPurchasesProvider(query));
    final instance = periodPurchasesProvider(query);
    final unitsError = unitsAsync.hasError && !unitsAsync.hasValue;
    final dataError = dataAsync.hasError && !dataAsync.hasValue;
    if (unitsError || dataError) {
      return _LedgerError(
        onRetry: () {
          ref.invalidate(unitsStreamProvider);
          ref.invalidate(instance);
        },
      );
    }
    final units = unitsAsync.value;
    final data = dataAsync.value;
    if (units == null || data == null) {
      return const Padding(
        padding: EdgeInsets.all(AppConstants.spacingL),
        child: Center(
          child: SizedBox(
            width: AppConstants.smallSpinnerSize,
            height: AppConstants.smallSpinnerSize,
            child: CircularProgressIndicator(
              strokeWidth: AppConstants.spinnerStrokeWidth,
            ),
          ),
        ),
      );
    }
    return dataAsync.when(
      data: (result) {
        if (result.rows.isEmpty) {
          return Text(
            AppStrings.noPricesForPeriod,
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }
        final working = ref.watch(
          statisticsControllerProvider.select((s) => s.isWorking),
        );
        return FilledButton.icon(
          onPressed: working ? null : () => onPreview(result.rows, units),
          icon: working
              ? const SizedBox(
                  width: AppConstants.smallSpinnerSize,
                  height: AppConstants.smallSpinnerSize,
                  child: CircularProgressIndicator(
                    strokeWidth: AppConstants.spinnerStrokeWidth,
                  ),
                )
              : const Icon(Icons.preview_outlined),
          label: const Text(AppStrings.statsPreviewAction),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => _LedgerError(onRetry: () => ref.invalidate(instance)),
    );
  }
}
