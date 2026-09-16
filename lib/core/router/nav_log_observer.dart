/// SPoT: `NavigatorObserver` που καταγράφει την πλοήγηση μέσω `AppLogger`
/// (tag `NAV`, §1.7 DESIGN). Προστίθεται στους observers του GoRouter
/// (app_router.dart) — «route definitions» ανεξάρτητα από observer/logging
/// logic (§1.2:42, ίδιο μοτίβο base_dao.dart vs daos/*.dart).
///
/// Καταγράφει: `→` push, `←` pop, `↻` replace, `✗` remove (route name).
/// Η έξοδος ελέγχεται πλήρως από το `DebugConfig` (release = καμία έξοδος).
library;

import 'package:flutter/widgets.dart';

import '../logging/app_logger.dart';

/// Observer πλοήγησης — log κάθε transition αλλαγής route.
class NavLogObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.info(LogTag.nav, '→ ${_name(route)}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.info(LogTag.nav, '← ${_name(route)}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.info(LogTag.nav, '✗ ${_name(route)}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    AppLogger.info(LogTag.nav, '↻ ${_name(newRoute)}');
  }

  // Fallback σε runtimeType όταν το route δεν έχει name (π.χ. dialog).
  static String _name(Route<dynamic>? route) =>
      route?.settings.name ?? route?.runtimeType.toString() ?? 'unknown';
}