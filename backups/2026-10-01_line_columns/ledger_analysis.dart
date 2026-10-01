/// Ανάλυση «Ιστορικό αγορών είδους» (§2.3 · 1η ανάλυση).
///
/// Part αρχείο (split 30-09-2026, κανόνας 7 <500 γρ.): `_LedgerAnalysis` +
/// banner + body. Τα imports του `statistics_section.dart` ισχύουν εδώ.
part of 'statistics_section.dart';

/// Ανάλυση «Ιστορικό αγορών είδους» — καρτέλα + export (§2.3 · 1η ανάλυση).
///
/// `ConsumerStatefulWidget` με τοπικό state (επιλογή + περίοδος — ad-hoc,
/// όχι persist, Q5): dropdown αναζήτησης (`SearchableDropdownField`, χωρίς
/// «+») + locked banner (pattern §2.4) + `ChartPeriodSelector` (reuse Home)
/// + `StatisticsTable` + Wrap εξαγωγής (Excel/PDF, pattern backup section).
/// Gated watches (§2.0.1): λίστες/ledger ΜΟΝΟ με επιλογή. Feedback ΜΟΝΟ από
/// εδώ μέσω `AppFeedback` (§2.4).
class _LedgerAnalysis extends ConsumerStatefulWidget {
  const _LedgerAnalysis();

  @override
  ConsumerState<_LedgerAnalysis> createState() => _LedgerAnalysisState();
}

class _LedgerAnalysisState extends ConsumerState<_LedgerAnalysis> {
  /// Επιλεγμένο είδος (null = idle) — τοπικό, όχι persist (Q5).
  int? _itemId;

  /// Περίοδος ανάλυσης (default Μήνας, όπως οι κάρτες §2.1).
  PeriodType _period = PeriodType.month;

  /// Custom range (μόνο σε `custom` — pattern HomePage `_pickCustomRange`).
  DateTime? _customFrom;
  DateTime? _customTo;

  /// «Γενιά» dropdown — φρέσκο άδειο σε αποεπιλογή (pattern header §2.2).
  int _epoch = 0;

  /// Επιλογή custom range (picker με SPoT όρια· Ακύρωση → καμία αλλαγή).
  Future<void> _pickCustomRange() async {
    AppLogger.info(LogTag.ui, 'Άνοιγμα custom range καρτέλας');
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

  /// Αποεπιλογή (banner «Αλλαγή» / ορφανό) → idle + φρέσκο dropdown.
  void _clearSelection() {
    setState(() {
      _itemId = null;
      _epoch++;
    });
    AppLogger.info(LogTag.ui, 'Αποεπιλογή είδους καρτέλας');
  }

  /// Export Excel: rows → controller → feedback (ακύρωση = no-op).
  Future<void> _exportExcel(
    BuildContext context,
    WidgetRef ref,
    List<ItemLedgerRow> rows,
  ) async {
    await runControllerOp(
      context,
      () => ref.read(statisticsControllerProvider.notifier).exportExcel(rows),
      AppMessages.statsExported,
    );
  }

  /// Export PDF: προβολή strings (presentation SPoT, §2.5) → controller.
  Future<void> _exportPdf(
    BuildContext context,
    WidgetRef ref,
    String itemName,
    List<ItemLedgerRow> rows,
  ) async {
    final localizations = MaterialLocalizations.of(context);
    final totals = StatisticsExportService.totalsOf(rows);
    await runControllerOp(
      context,
      () => ref.read(statisticsControllerProvider.notifier).exportPdf((
        title: itemName,
        headers: const [
          AppStrings.statsColumnDate,
          AppStrings.statsColumnReceipt,
          AppStrings.statsColumnSupplier,
          AppStrings.statsColumnQuantity,
          AppStrings.statsColumnPrice,
          AppStrings.statsColumnDiscount,
          AppStrings.statsColumnNet,
        ],
        body: [
          for (final row in rows)
            [
              localizations.formatShortDate(row.date),
              '${row.receiptId}',
              row.supplierName,
              StatisticsExportService.quantityText(row),
              '${CurrencyTextField.formatCents(row.priceCents)} '
                  '${AppStrings.currencySymbol}',
              '${CurrencyTextField.formatCents(row.discountCents)} '
                  '${AppStrings.currencySymbol}',
              '${CurrencyTextField.formatCents(row.priceCents - row.discountCents)} '
                  '${AppStrings.currencySymbol}',
            ],
        ],
        totalsLine:
            '${totals.label}: ${CurrencyTextField.formatCents(totals.totalCents)} '
            '${AppStrings.currencySymbol}',
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
        if (_itemId == null)
          SearchableDropdownField<Item>(
            key: ValueKey(_epoch),
            labelText: AppStrings.fieldItemName,
            hintText: AppStrings.trendItemSearchHint,
            searchProvider: itemTrendSearchProvider.call,
            labelOf: (item) => item.name,
            // Χωρίς «+» (δημιουργία από Εισαγωγή/Ρυθμίσεις, §2.4).
            onSelected: (item) {
              setState(() => _itemId = item.id);
              AppLogger.info(
                LogTag.ui,
                'Επιλογή είδους καρτέλας: ${item.name}',
              );
            },
            prefixIcon: const Icon(Icons.search),
            resultLeadingIcon: const Icon(Icons.shopping_basket_outlined),
          )
        else
          _SelectedItemBanner(itemId: _itemId!, onChange: _clearSelection),
        const SizedBox(height: AppConstants.spacingM),
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
        if (_itemId == null)
          Text(
            AppStrings.trendNoItemSelected,
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          _LedgerBody(
            itemId: _itemId!,
            range: (from: range.from, to: range.to),
            onExportExcel: (rows) => _exportExcel(context, ref, rows),
            onExportPdf: (name, rows) => _exportPdf(context, ref, name, rows),
          ),
      ],
    );
  }
}

/// Locked banner επιλεγμένου είδους (pattern §2.4 — όνομα από live λίστα,
/// rename φαίνεται αυτόματα· ορφανό → επαναπιλογή).
class _SelectedItemBanner extends ConsumerWidget {
  const _SelectedItemBanner({required this.itemId, required this.onChange});

  final int itemId;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsStreamProvider);
    return items.when(
      data: (list) {
        Item? selected;
        for (final item in list) {
          if (item.id == itemId) {
            selected = item;
            break;
          }
        }
        if (selected == null) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppMessages.trendItemRemoved,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextButton(
                onPressed: onChange,
                child: const Text(AppStrings.changeItem),
              ),
            ],
          );
        }
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.check_circle_outline),
            title: Text(
              selected.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: TextButton(
              onPressed: onChange,
              child: const Text(AppStrings.changeItem),
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        width: AppConstants.smallSpinnerSize,
        height: AppConstants.smallSpinnerSize,
        child: CircularProgressIndicator(
          strokeWidth: AppConstants.spinnerStrokeWidth,
        ),
      ),
      error: (_, _) => TextButton.icon(
        onPressed: () => ref.invalidate(itemsStreamProvider),
        icon: const Icon(Icons.refresh),
        label: const Text(AppStrings.retryButton),
      ),
    );
  }
}

/// Σώμα ledger: skeleton/empty/error+retry/data + Wrap εξαγωγής (§2.1 states).
class _LedgerBody extends ConsumerWidget {
  const _LedgerBody({
    required this.itemId,
    required this.range,
    required this.onExportExcel,
    required this.onExportPdf,
  });

  final int itemId;
  final ({DateTime from, DateTime to}) range;
  final Future<void> Function(List<ItemLedgerRow> rows) onExportExcel;
  final Future<void> Function(String itemName, List<ItemLedgerRow> rows)
  onExportPdf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (itemId: itemId, from: range.from, to: range.to);
    final async = ref.watch(itemLedgerProvider(query));
    final instance = itemLedgerProvider(query);
    final showError = async.hasError && !async.hasValue;
    if (showError) {
      return _LedgerError(onRetry: () => ref.invalidate(instance));
    }
    return async.when(
      data: (rows) {
        if (rows.isEmpty) {
          return Text(
            AppStrings.noPricesForPeriod,
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }
        String itemName = '';
        final items = ref.watch(itemsStreamProvider).value;
        if (items != null) {
          for (final item in items) {
            if (item.id == itemId) {
              itemName = item.name;
              break;
            }
          }
        }
        final working = ref.watch(
          statisticsControllerProvider.select((s) => s.isWorking),
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StatisticsTable(rows: rows),
            const SizedBox(height: AppConstants.spacingM),
            Wrap(
              spacing: AppConstants.spacingM,
              runSpacing: AppConstants.spacingM,
              children: [
                FilledButton.icon(
                  onPressed: working ? null : () => onExportExcel(rows),
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
                  onPressed: working ? null : () => onExportPdf(itemName, rows),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text(AppStrings.statsExportPdfAction),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const Padding(
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
      ),
      error: (_, _) => _LedgerError(onRetry: () => ref.invalidate(instance)),
    );
  }
}
