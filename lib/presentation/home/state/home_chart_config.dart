/// SPoT state — Ρύθμιση γραφημάτων Κεντρικής (§2.1 DESIGN / Φάση 5 Βήμα 3).
///
/// Freezed immutable state (pattern `SettingsState`/`ReceiptFormState`):
/// ανά γράφημα ορατότητα + σειρά + περίοδος (+ custom range). Persisted σε
/// SharedPreferences μέσω `SettingsRepository` (pattern theme Βήματος 1) —
/// η σειριοποίηση (JSON/ISO) ζει ΜΟΝΟ στο implementation, εδώ καθαρές τιμές.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/constants/app_enums.dart';

part 'home_chart_config.freezed.dart';

/// Γράφημα Κεντρικής — οι 6 κάρτες (§2.1: supplier/category/subCategory/
/// itemGroup/topItems + itemTrend πορείας 28-09-2026).
/// Home-specific enum (όχι SPoT `app_enums` — το χρησιμοποιεί
/// μόνο η Κεντρική).
enum ChartId { supplier, category, subCategory, itemGroup, topItems, itemTrend }

/// Ρύθμιση ενός γραφήματος: ορατότητα + σειρά + περίοδος.
@freezed
abstract class ChartEntry with _$ChartEntry {
  /// `visible` — ορατότητα κάρτας (switch, §2.1) · `order` — σειρά εμφάνισης
  /// (βέλη, 0-based) · `period` — περίοδος κάρτας (default Μήνας, §2.1) ·
  /// `customFrom`/`customTo` — range Προσαρμοσμένου (null = δεν ορίστηκε).
  const factory ChartEntry({
    @Default(true) bool visible,
    @Default(0) int order,
    @Default(PeriodType.month) PeriodType period,
    DateTime? customFrom,
    DateTime? customTo,
  }) = _ChartEntry;
}

/// Ρύθμιση και των 6 γραφημάτων — state του `homeChartConfigProvider`.
@freezed
abstract class HomeChartConfig with _$HomeChartConfig {
  const factory HomeChartConfig({
    required ChartEntry supplier,
    required ChartEntry category,
    required ChartEntry subCategory,
    required ChartEntry itemGroup,
    required ChartEntry topItems,
    required ChartEntry itemTrend,
  }) = _HomeChartConfig;

  /// Defaults §2.1: και τα 6 ορατά, Μήνας, σειρά 1-2-3-4-5-6 (order 0-based).
  factory HomeChartConfig.defaults() => const HomeChartConfig(
        supplier: ChartEntry(order: 0),
        category: ChartEntry(order: 1),
        subCategory: ChartEntry(order: 2),
        itemGroup: ChartEntry(order: 3),
        topItems: ChartEntry(order: 4),
        itemTrend: ChartEntry(order: 5),
      );
}

/// Επιστρέφει την entry του [id] (switch — 6 κάρτες, §2.1).
extension HomeChartConfigById on HomeChartConfig {
  ChartEntry entryOf(ChartId id) => switch (id) {
        ChartId.supplier => supplier,
        ChartId.category => category,
        ChartId.subCategory => subCategory,
        ChartId.itemGroup => itemGroup,
        ChartId.topItems => topItems,
        ChartId.itemTrend => itemTrend,
      };

  /// Αντίγραφο με αντικατεστημένη την entry του [id].
  HomeChartConfig withEntry(ChartId id, ChartEntry entry) => switch (id) {
        ChartId.supplier => copyWith(supplier: entry),
        ChartId.category => copyWith(category: entry),
        ChartId.subCategory => copyWith(subCategory: entry),
        ChartId.itemGroup => copyWith(itemGroup: entry),
        ChartId.topItems => copyWith(topItems: entry),
        ChartId.itemTrend => copyWith(itemTrend: entry),
      };
}
