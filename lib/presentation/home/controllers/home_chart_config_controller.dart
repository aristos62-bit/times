/// Controller ρύθμισης γραφημάτων Κεντρικής (§2.1 DESIGN / Φάση 5 Βήμα 3).
///
/// Plain `Notifier<HomeChartConfig>` (όχι AsyncNotifier): το state είναι
/// σύγχρονο (memory-read, pattern `ThemeModeController`)· μόνο το save είναι
/// async (unawaited, δική του μεταχείριση σφαλμάτων). NON-autoDispose
/// (§2.2:221, IndexedStack — η ρύθμιση φορτώνεται ΜΙΑ φορά).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/providers/settings_providers.dart';
import '../state/home_chart_config.dart';

/// SPoT provider ρύθμισης γραφημάτων — μη autoDispose (σύμβαση DI δέντρου).
final homeChartConfigProvider =
    NotifierProvider<HomeChartConfigController, HomeChartConfig>(
  HomeChartConfigController.new,
);

/// Controller ορατότητας/περιόδου/σειράς (persisted SharedPreferences §2.1).
class HomeChartConfigController extends Notifier<HomeChartConfig> {
  /// Σύγχρονο read (pattern theme Βήματος 1): τα prefs είναι προφορτωμένα
  /// (main Q4) → η persisted ρύθμιση επιστρέφεται άμεσα. Σφάλμα → defaults
  /// + log (κανένα crash).
  @override
  HomeChartConfig build() {
    try {
      return ref.read(settingsRepositoryProvider).readHomeChartConfig();
    } catch (e, s) {
      AppLogger.error(
        LogTag.ui,
        'Ανάγνωση ρύθμισης γραφημάτων απέτυχε — χρήση defaults',
        e,
        s,
      );
      return HomeChartConfig.defaults();
    }
  }

  /// Ορίζει την ορατότητα κάρτας. Equality gate: ίδια τιμή → no-op.
  void setVisible(ChartId id, bool visible) {
    final current = state.entryOf(id);
    if (current.visible == visible) return;
    _apply(id, current.copyWith(visible: visible), 'Ορατότητα γραφήματος');
  }

  /// Ορίζει την περίοδο κάρτας. Custom χωρίς έγκυρο range → no-op
  /// (defensive — ο selector στέλνει custom ΜΟΝΟ με range από τον picker).
  void setPeriod(
    ChartId id,
    PeriodType period, {
    DateTime? customFrom,
    DateTime? customTo,
  }) {
    final current = state.entryOf(id);
    if (period == PeriodType.custom &&
        (customFrom == null || customTo == null)) {
      return;
    }
    final next = current.copyWith(
      period: period,
      customFrom: period == PeriodType.custom ? customFrom : null,
      customTo: period == PeriodType.custom ? customTo : null,
    );
    if (next == current) return;
    _apply(id, next, 'Περίοδος γραφήματος');
  }

  /// Μετακινεί την κάρτα μία θέση πάνω (μικρότερο order). Στην κορυφή → no-op.
  void moveUp(ChartId id) {
    final current = state.entryOf(id);
    final above = _entryWithOrder(current.order - 1);
    if (above == null) return;
    _swap(id, current, above.$1, above.$2, 'Σειρά γραφημάτων');
  }

  /// Μετακινεί την κάρτα μία θέση κάτω (μεγαλύτερο order). Στο τέλος → no-op.
  void moveDown(ChartId id) {
    final current = state.entryOf(id);
    final below = _entryWithOrder(current.order + 1);
    if (below == null) return;
    _swap(id, current, below.$1, below.$2, 'Σειρά γραφημάτων');
  }

  /// Επαναφέρει τα defaults §2.1 (4 ορατά/Μήνας/1-2-3-4). Ήδη defaults → no-op.
  void resetDefaults() {
    final defaults = HomeChartConfig.defaults();
    if (state == defaults) return;
    state = defaults;
    AppLogger.info(LogTag.ui, 'Επαναφορά ρύθμισης γραφημάτων');
    unawaited(_save(defaults));
  }

  /// Εφαρμόζει την entry + log + async save (pattern `setMode` theme).
  void _apply(ChartId id, ChartEntry entry, String action) {
    state = state.withEntry(id, entry);
    AppLogger.info(LogTag.ui, '$action: ${id.name}');
    unawaited(_save(state));
  }

  /// Ανταλλάσσει τα orders δύο καρτών.
  void _swap(
    ChartId firstId,
    ChartEntry first,
    ChartId secondId,
    ChartEntry second,
    String action,
  ) {
    var next = state.withEntry(firstId, first.copyWith(order: second.order));
    next = next.withEntry(secondId, second.copyWith(order: first.order));
    state = next;
    AppLogger.info(LogTag.ui, '$action: ${firstId.name} ↔ ${secondId.name}');
    unawaited(_save(next));
  }

  /// Βρίσκει (id, entry) με [order] ή null αν δεν υπάρχει.
  (ChartId, ChartEntry)? _entryWithOrder(int order) {
    for (final id in ChartId.values) {
      final entry = state.entryOf(id);
      if (entry.order == order) return (id, entry);
    }
    return null;
  }

  Future<void> _save(HomeChartConfig config) async {
    if (!ref.mounted) return;
    try {
      await ref.read(settingsRepositoryProvider).saveHomeChartConfig(config);
    } catch (e, s) {
      AppLogger.error(LogTag.ui, 'Αποθήκευση ρύθμισης γραφημάτων απέτυχε', e, s);
    }
  }
}
