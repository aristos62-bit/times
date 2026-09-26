/// Κεντρική σελίδα — Γραφήματα & Στατιστικά (§2.1 · Φάση 5 Βήμα 5).
///
/// Στοιχείο του App Shell: ο `AppShell` δίνει το Scaffold με NavigationBar
/// και η σελίδα προσθέτει δικό της nested Scaffold (AppBar + σώμα).
/// `ConsumerWidget`, ΜΟΝΟ layout/σύνθεση (καθόλου business logic — §2.0):
/// διαβάζει το `homeChartConfigProvider` (ορατές κάρτες `(order,index)`-sorted),
/// επιλύει το query κάθε κάρτας (`resolvePeriodRange`, Βήμα 3) και περνά το
/// resolved family instance στην `HomeChartCard` (η κάρτα κάνει η ίδια watch).
/// Τελευταία γραμμή: «Προσαρμογή Οθόνης» (collapsible, pattern Ρυθμίσεων).
/// Responsive §1.4: single-column `ListView` (κάρτες άνισου ύψους) + padding
/// από SPoT — ποτέ σταθερό ύψος.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_enums.dart';
import '../../core/constants/app_strings.dart';
import '../../core/logging/app_logger.dart';
import '../../data/providers/stream_providers.dart';
import '../../domain/services/chart_helpers.dart';
import 'controllers/home_chart_config_controller.dart';
import 'state/home_chart_config.dart';
import 'widgets/home_chart_card.dart';
import 'widgets/home_customization_section.dart';

/// Σελίδα στατιστικών (§2.1) — 4 πίτες + Προσαρμογή Οθόνης.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// Τίτλος κάρτας ανά γράφημα (SPoT `AppStrings`, §1.1).
  static String titleOf(ChartId id) => switch (id) {
        ChartId.supplier => AppStrings.chartSupplierTitle,
        ChartId.category => AppStrings.chartCategoryTitle,
        ChartId.subCategory => AppStrings.chartSubCategoryTitle,
        ChartId.topItems => AppStrings.chartTopItemsTitle,
      };

  /// Family ανά γράφημα επιλύεται στο `_ChartCard` (switch) — εδώ μόνο τίτλοι.

  /// Επιλογή προσαρμοσμένου range (pattern `_pickDay` §2.3): picker με SPoT
  /// όρια· Ακύρωση/dismiss → καμία αλλαγή. Ημέρες αποθηκεύονται ως έχουν —
  /// τα όρια ημέρας τα υπολογίζει ο resolver (καθαρό DateTime, Βήμα 3).
  Future<void> _pickCustomRange(
    BuildContext context,
    WidgetRef ref,
    ChartId id,
  ) async {
    AppLogger.info(LogTag.ui, 'Άνοιγμα custom range picker γραφήματος');
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(AppConstants.datePickerFirstYear),
      lastDate: DateTime(AppConstants.datePickerLastYear, 12, 31),
    );
    if (picked == null || !context.mounted) return;
    ref.read(homeChartConfigProvider.notifier).setPeriod(
          id,
          PeriodType.custom,
          customFrom: picked.start,
          customTo: picked.end,
        );
    AppLogger.info(LogTag.ui, 'Custom range γραφήματος: ${id.name}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(homeChartConfigProvider);
    final now = DateTime.now();
    final visible = ChartId.values
        .where((id) => config.entryOf(id).visible)
        .toList()
      ..sort((a, b) {
        final orderCompare =
            config.entryOf(a).order.compareTo(config.entryOf(b).order);
        if (orderCompare != 0) return orderCompare;
        return a.index.compareTo(b.index);
      });
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            vertical: AppConstants.spacingL,
          ),
          children: [
            for (final id in visible) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                ),
                child: _ChartCard(id: id, now: now, onCustom: _pickCustomRange),
              ),
              const SizedBox(height: AppConstants.spacingL),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacingM,
              ),
              child: HomeCustomizationSection(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Κάρτα ενός γραφήματος: επιλύει query + καλωδιώνει callbacks (§2.0 —
/// η σελίδα κάνει ΜΟΝΟ σύνθεση, η κάρτα Βήματος 4 το rendering).
class _ChartCard extends ConsumerWidget {
  const _ChartCard({
    required this.id,
    required this.now,
    required this.onCustom,
  });

  final ChartId id;
  final DateTime now;
  final Future<void> Function(BuildContext context, WidgetRef ref, ChartId id)
      onCustom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(
      homeChartConfigProvider.select((config) => config.entryOf(id)),
    );
    final range = resolvePeriodRange(
      entry.period,
      customFrom: entry.customFrom,
      customTo: entry.customTo,
      now: now,
    );
    final query = (from: range.from, to: range.to);
    final family = switch (id) {
      ChartId.supplier => supplierTotalsProvider(query),
      ChartId.category => categoryTotalsProvider(query),
      ChartId.subCategory => subCategoryTotalsProvider(query),
      ChartId.topItems => topItemsTotalsProvider(query),
    };
    final customSubtitle = entry.period == PeriodType.custom &&
            entry.customFrom != null &&
            entry.customTo != null
        ? '${MaterialLocalizations.of(context).formatMediumDate(entry.customFrom!)}'
            ' – ${MaterialLocalizations.of(context).formatMediumDate(entry.customTo!)}'
        : null;
    return HomeChartCard(
      title: HomePage.titleOf(id),
      slicesProvider: family,
      period: entry.period,
      customSubtitle: customSubtitle,
      onPeriodChanged: (period) {
        if (period == PeriodType.custom) {
          onCustom(context, ref, id);
        } else {
          ref.read(homeChartConfigProvider.notifier).setPeriod(id, period);
        }
      },
    );
  }
}
