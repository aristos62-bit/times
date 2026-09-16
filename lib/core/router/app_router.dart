/// SPoT: GoRouter config — route definitions της εφαρμογής (§1.2 DESIGN).
///
/// Χρησιμοποιεί `StatefulShellRoute.indexedStack` ώστε κάθε branch να
/// κρατά τη δική της stack/navigation state (η εναλλαγή tab ΔΕΝ ξαναχτίζει
/// τη σελίδα — προστατεύει draft δεδομένα της φόρμας, §2.2:222).
/// Ο observer (`NavLogObserver`) είναι ξεχωριστό αρχείο — «route definitions»
/// ανεξάρτητα από logging logic (§1.2:42, ίδιο μοτίβο base_dao vs daos).
/// Οι paths/names ΕΡΧΟΝΤΑΙ από το SPoT `AppRoutes` — ποτέ raw strings (§1.1:33).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/home/home_page.dart';
import '../../presentation/price_entry/price_entry_page.dart';
import '../../presentation/settings/settings_page.dart';
import '../constants/app_strings.dart';
import 'app_routes.dart';
import 'nav_log_observer.dart';

/// Δημιουργεί το GoRouter της εφαρμογής με [NavLogObserver] ενσωματωμένο.
///
/// [observers] επιτρέπει στα tests να προσθέτουν δικά τους observer χωρίς
/// να αλλάζουν το production config (βλ. app_router_test.dart).
GoRouter buildAppRouter({List<NavigatorObserver>? observers}) {
  // Ο NavLogObserver μπαίνει ΠΑΝΤΑ — τα tests προσθέτουν πάνω από αυτόν.
  final effectiveObservers = [NavLogObserver(), ...?observers];
  return GoRouter(
    // Αρχική σελίδα = Home (στατιστικά) §2.1 — `/` (§1.1:33).
    initialLocation: AppRoutes.homePath,
    observers: effectiveObservers,
    routes: [
      // Shell: bottom navigation (NavigationBar) κοινό σε όλες τις branches.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // ─── Home / Stats (§2.1) ───────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homePath,
                name: AppRoutes.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          // ─── Price Entry (§2.2) ────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.priceEntryPath,
                name: AppRoutes.priceEntry,
                builder: (context, state) => const PriceEntryPage(),
              ),
            ],
          ),
          // ─── Settings (§2.3) ───────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settingsPath,
                name: AppRoutes.settings,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Το μοναδικό GoRouter instance που χρησιμοποιεί η εφαρμογή (main.dart).
final GoRouter appRouter = buildAppRouter();

/// App shell: `Scaffold` με `NavigationBar` (Material 3) — το «κεφάλι» του
/// StatefulShellRoute. Κάθε branch έχει το δικό της Scaffold+AppBar
/// (nested), εδώ μόνο bottom navigation + το σώμα της ενεργής branch.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  /// Ενεργή branch + index — παρέχεται από τον StatefulShellRoute.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Το IndexedStack της StatefulShellRoute — κρατά όλες τις branches
      // ζωντανές (χωρίς rebuild/απώλεια state στην αλλαγή tab).
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => _selectBranch(index),
        // Labels από SPoT AppStrings (§1.1) — ελληνικά, όχι hardcoded.
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.insert_chart_outlined),
            selectedIcon: Icon(Icons.insert_chart),
            label: AppStrings.navHome,
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: AppStrings.navPriceEntry,
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: AppStrings.navSettings,
          ),
        ],
      ),
    );
  }

  /// Αλλαγή tab: αν πατηθεί το ίδιο ενεργό tab, γυρνάει στο root της branch
  /// (αντί να απλώς «μένει») — αλλιώς εναλλαγή κανονική.
  void _selectBranch(int index) {
    navigationShell.goBranch(
      index,
      // Αν είναι ήδη το ενεργό tab, πήγαινε στην αρχική route της branch.
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}