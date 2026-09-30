/// Ανάλυση «Συνολικές αγορές» (§2.3 · 2η ανάλυση).
///
/// Part αρχείο (split 30-09-2026, κανόνας 7 <500 γρ.): `_PurchasesAnalysis` +
/// body. Τα imports του `statistics_section.dart` ισχύουν εδώ.
part of 'statistics_section.dart';

/// Ανάλυση «Συνολικές αγορές» — πίνακας + export (§2.3 · 2η ανάλυση).
///
/// `ConsumerStatefulWidget` με τοπικό state (περίοδος + sort — ad-hoc, όχι
/// persist, Q5): `ChartPeriodSelector` (reuse Home) + sort `DropdownMenu`
/// (pattern selector κάρτας §2.1) + `PurchasesTable` + Wrap εξαγωγής.
/// Χωρίς επιλογή είδους (όλα τα είδη) — άρα χωρίς banner/orphan.
/// Gated watches (§2.0.1): streams ΜΟΝΟ στο detail (το μενού δεν ανοίγει
/// βάση). Feedback ΜΟΝΟ από εδώ μέσω `AppFeedback` (§2.4).
class _PurchasesAnalysis extends ConsumerStatefulWidget {
  const _PurchasesAnalysis();

  @override
  ConsumerState<_PurchasesAnalysis> createState() => _PurchasesAnalysisState();
}

class _PurchasesAnalysisState extends ConsumerState<_PurchasesAnalysis> {
  /// Περίοδος ανάλυσης (default Μήνας, όπως οι κάρτες §2.1).
  PeriodType _period = PeriodType.month;

  /// Custom range (μόνο σε `custom`).
  DateTime? _customFrom;
  DateTime? _customTo;

  /// Ταξινόμηση (default παλιές → νέες, Q2).
  PurchasesSort _sort = PurchasesSort.dateAsc;

  /// Φίλτρο καταλόγου (null-ids = Όλα — τοπικό, όχι persist, Q5).
  CatalogFilterSelection _filter = (
    categoryId: null,
    subCategoryId: null,
    itemGroupId: null,
  );

  /// Επιλογή custom range (picker με SPoT όρια· Ακύρωση → καμία αλλαγή).
  Future<void> _pickCustomRange() async {
    AppLogger.info(LogTag.ui, 'Άνοιγμα custom range αγορών');
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

  /// Export Excel: rows + units → controller → feedback (ακύρωση = no-op).
  Future<void> _exportExcel(
    BuildContext context,
    WidgetRef ref,
    List<PeriodPurchaseRow> rows,
    List<Unit> units,
  ) async {
    await runControllerOp(
      context,
      () => ref
          .read(statisticsControllerProvider.notifier)
          .exportPurchasesExcel(rows: rows, units: units),
      AppMessages.statsExported,
    );
  }

  /// Export PDF: προβολή strings (shared helpers §1.1, §2.5) → controller.
  Future<void> _exportPdf(
    BuildContext context,
    WidgetRef ref,
    List<PeriodPurchaseRow> rows,
    List<Unit> units,
  ) async {
    final localizations = MaterialLocalizations.of(context);
    final totals = StatisticsExportService.purchasesTotalsOf(rows, units);
    await runControllerOp(
      context,
      () => ref.read(statisticsControllerProvider.notifier).exportPurchasesPdf((
        title: AppStrings.statsPurchasesTitle,
        headers: _purchasesHeaders(units),
        body: [
          for (final row in rows) _purchasesBodyRow(row, units, localizations),
        ],
        totalsLine: _purchasesTotalsLine(totals),
      )),
      AppMessages.statsExported,
    );
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
        CatalogFilterField(
          onChanged: (filter) => setState(() => _filter = filter),
        ),
        const SizedBox(height: AppConstants.spacingS),
        _PurchasesBody(
          query: (
            from: range.from,
            to: range.to,
            sort: _sort,
            categoryId: _filter.categoryId,
            subCategoryId: _filter.subCategoryId,
            itemGroupId: _filter.itemGroupId,
          ),
          onExportExcel: (rows, units) =>
              _exportExcel(context, ref, rows, units),
          onExportPdf: (rows, units) => _exportPdf(context, ref, rows, units),
        ),
      ],
    );
  }
}

/// Σώμα αγορών: units + rows (skeleton/empty/error+retry/data) + exports.
class _PurchasesBody extends ConsumerWidget {
  const _PurchasesBody({
    required this.query,
    required this.onExportExcel,
    required this.onExportPdf,
  });

  final PeriodPurchasesQuery query;
  final Future<void> Function(List<PeriodPurchaseRow>, List<Unit>)
  onExportExcel;
  final Future<void> Function(List<PeriodPurchaseRow>, List<Unit>) onExportPdf;

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
        final totals = StatisticsExportService.purchasesTotalsOf(
          result.rows,
          units,
        );
        final working = ref.watch(
          statisticsControllerProvider.select((s) => s.isWorking),
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PurchasesTable(rows: result.rows, units: units, totals: totals),
            if (result.truncated) ...[
              const SizedBox(height: AppConstants.spacingS),
              Text(
                AppMessages.statsTruncatedNote(AppConstants.statsTableMaxRows),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: AppConstants.spacingM),
            Wrap(
              spacing: AppConstants.spacingM,
              runSpacing: AppConstants.spacingM,
              children: [
                FilledButton.icon(
                  onPressed: working
                      ? null
                      : () => onExportExcel(result.rows, units),
                  icon: working
                      ? const SizedBox(
                          width: AppConstants.smallSpinnerSize,
                          height: AppConstants.smallSpinnerSize,
                          child: CircularProgressIndicator(
                            strokeWidth: AppConstants.spinnerStrokeWidth,
                          ),
                        )
                      : const Icon(Icons.table_chart_outlined),
                  label: const Text(AppStrings.statsExportExcelAction),
                ),
                OutlinedButton.icon(
                  onPressed: working
                      ? null
                      : () => onExportPdf(result.rows, units),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text(AppStrings.statsExportPdfAction),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => _LedgerError(onRetry: () => ref.invalidate(instance)),
    );
  }
}
