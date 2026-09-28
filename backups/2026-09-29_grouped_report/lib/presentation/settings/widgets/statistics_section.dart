/// Section «Στατιστικά» (§2.3 · 28-09-2026).
///
/// Μενού αναλύσεων + detail ανά ανάλυση (όχι στοίβα — κλιμακώνεται σε Ν
/// αναλύσεις: νέα = νέα γραμμή στο `_entries`). 1η ανάλυση: «Ιστορικό
/// αγορών είδους» (`_LedgerAnalysis`, καρτέλα + export Excel/PDF).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/constants/app_errors.dart';
import '../../../core/constants/app_messages.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/logging/app_logger.dart';
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
import 'purchases_table.dart';
import 'statistics_table.dart';

/// SPoT label ταξινόμησης αγορών (§2.3 · 2η ανάλυση).
String _sortLabel(PurchasesSort sort) => switch (sort) {
      PurchasesSort.dateAsc => AppStrings.statsSortDateAsc,
      PurchasesSort.dateDesc => AppStrings.statsSortDateDesc,
      PurchasesSort.supplier => AppStrings.statsSortSupplier,
      PurchasesSort.category => AppStrings.statsSortCategory,
    };

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

  /// Export PDF: προβολή strings (presentation SPoT, §2.5) → controller.
  Future<void> _exportPdf(
    BuildContext context,
    WidgetRef ref,
    List<PeriodPurchaseRow> rows,
    List<Unit> units,
  ) async {
    final localizations = MaterialLocalizations.of(context);
    final totals = StatisticsExportService.purchasesTotalsOf(rows, units);
    String money(int cents) =>
        '${CurrencyTextField.formatCents(cents)} ${AppStrings.currencySymbol}';
    await runControllerOp(
      context,
      () => ref.read(statisticsControllerProvider.notifier).exportPurchasesPdf(
            (
              title: AppStrings.statsPurchasesTitle,
              headers: [
                AppStrings.statsColumnDate,
                AppStrings.statsColumnReceipt,
                AppStrings.fieldItemName,
                AppStrings.statsColumnCategory,
                AppStrings.statsColumnSupplier,
                for (final unit in units) unit.name,
                AppStrings.statsColumnPrice,
                AppStrings.statsColumnDiscount,
                AppStrings.statsColumnNet,
              ],
              body: [
                for (final row in rows)
                  [
                    localizations.formatShortDate(row.date),
                    '${row.receiptId}',
                    row.itemName,
                    row.categoryName,
                    row.supplierName,
                    for (final unit in units)
                      if (row.unitId == unit.id)
                        QuantityTextField.formatQuantity(row.quantity)
                      else
                        '',
                    money(row.priceCents),
                    money(row.discountCents),
                    money(row.priceCents - row.discountCents),
                  ],
              ],
              totalsLine:
                  '${totals.label}: ${money(totals.netTotalCents)}',
            ),
          ),
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
        // Ταξινόμηση (DropdownMenu — 4 entries, pattern selector §2.1).
        DropdownMenu<PurchasesSort>(
          key: ValueKey(_sort),
          initialSelection: _sort,
          label: const Text(AppStrings.statsSortLabel),
          onSelected: (value) {
            if (value != null) setState(() => _sort = value);
          },
          dropdownMenuEntries: [
            for (final sort in PurchasesSort.values)
              DropdownMenuEntry(value: sort, label: _sortLabel(sort)),
          ],
        ),
        const SizedBox(height: AppConstants.spacingS),
        _PurchasesBody(
          query: (from: range.from, to: range.to, sort: _sort),
          onExportExcel: (rows, units) =>
              _exportExcel(context, ref, rows, units),
          onExportPdf: (rows, units) =>
              _exportPdf(context, ref, rows, units),
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
        final totals =
            StatisticsExportService.purchasesTotalsOf(result.rows, units);
        final working = ref.watch(
          statisticsControllerProvider.select((s) => s.isWorking),
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PurchasesTable(
              rows: result.rows,
              units: units,
              totals: totals,
            ),
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
      error: (_, _) =>
          _LedgerError(onRetry: () => ref.invalidate(instance)),
    );
  }
}

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

  /// Μενού (κλιμακώνεται — 29-09-2026: 2 γραμμές).
  static const _entries = <_StatsEntry>[
    (
      title: AppStrings.statsLedgerTitle,
      description: AppStrings.statsLedgerDescription,
    ),
    (
      title: AppStrings.statsPurchasesTitle,
      description: AppStrings.statsPurchasesDescription,
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
        if (open == 0) const _LedgerAnalysis() else const _PurchasesAnalysis(),
      ],
    );
  }
}

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
      () => ref
          .read(statisticsControllerProvider.notifier)
          .exportExcel(rows),
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
      () => ref.read(statisticsControllerProvider.notifier).exportPdf(
            (
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
            ),
          ),
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
            resultLeadingIcon:
                const Icon(Icons.shopping_basket_outlined),
          )
        else
          _SelectedItemBanner(
            itemId: _itemId!,
            onChange: _clearSelection,
          ),
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
    final query = (
      itemId: itemId,
      from: range.from,
      to: range.to,
    );
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
                  onPressed: working
                      ? null
                      : () => onExportPdf(itemName, rows),
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
      error: (_, _) =>
          _LedgerError(onRetry: () => ref.invalidate(instance)),
    );
  }
}

/// Σφάλμα ledger: `loadDataFailed` + «Επανάληψη» (SPoT, §2.1).
class _LedgerError extends StatelessWidget {
  const _LedgerError({required this.onRetry});

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
