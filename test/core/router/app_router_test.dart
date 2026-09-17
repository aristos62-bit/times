/// Widget tests — GoRouter config (Φάση 3, Βήμα 1 · app_router.dart).
///
/// Επαληθεύει:
///   * initialLocation = `/` (Home).
///   * 3 branches (Home/PriceEntry/Settings) με σωστά paths+names (§1.1:33).
///   * Κάθε branch renderάρεται μέσω NavigationBar (AppShell).
///   * Πλοήγηση tab μέσω των AppStrings labels (§1.1:33).
///   * NAV logging μέσω `AppLogger.testSink` (LogTag.nav, §1.7).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/logging/app_logger.dart';
import 'package:times/core/router/app_router.dart';
import 'package:times/core/router/app_routes.dart';
import 'package:times/presentation/home/home_page.dart';
import 'package:times/presentation/price_entry/price_entry_page.dart';
import 'package:times/presentation/settings/settings_page.dart';

void main() {
  // Empty sink για NAV logging — αποφεύγει debugPrint στο test output
  // (τόσο για τα plain tests όσο και κατά το φόρτωμα των testWidgets).
  setUp(() {
    AppLogger.testSink = (_) {};
  });
  // Επαναφορά sink μετά από κάθε test — το NAV test το ορίζει δικό του.
  tearDown(AppLogger.resetTestSink);

  /// Pump με φρέσκο router (αποφεύγει shared GoRouter state μεταξύ tests).
  /// ProviderScope απαραίτητο από το Βήμα 2: η PriceEntryPage είναι πλέον
  /// ConsumerWidget (watch-άρει τον τοπικό receiptFormControllerProvider).
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: buildAppRouter()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AppRouter', () {
    // ─── Initial route ───────────────────────────────────────────────────────
    testWidgets('initialLocation = `/` → HomePage', (tester) async {
      await pumpApp(tester);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text(AppStrings.statsComingSoon), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ─── Branches ────────────────────────────────────────────────────────────
    testWidgets('και τα 3 branches renderάρονται μέσω route paths',
        (tester) async {
      final router = buildAppRouter();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Κάθε branch έχει το δικό του route — σωστά paths/names §1.1:33.
      expect(find.byType(HomePage), findsOneWidget);

      router.go(AppRoutes.priceEntryPath);
      await tester.pumpAndSettle();
      expect(find.byType(PriceEntryPage), findsOneWidget);

      router.go(AppRoutes.settingsPath);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ─── NavigationBar (AppShell) ───────────────────────────────────────────
    testWidgets('AppShell: NavigationBar με 3 destinations (SPoT labels)',
        (tester) async {
      await pumpApp(tester);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(3));
      expect(find.text(AppStrings.navHome), findsOneWidget);
      expect(find.text(AppStrings.navPriceEntry), findsOneWidget);
      expect(find.text(AppStrings.navSettings), findsOneWidget);
    });

    testWidgets('tab switching: «Εισαγωγή» → PriceEntryPage', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(AppStrings.navPriceEntry),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(PriceEntryPage), findsOneWidget);
      // Το Home παραμένει ΖΩΝΤΑΝΟ στο IndexedStack (offstage — state
      // preservation §2.2:222). Με skipOffstage:false επιβεβαιώνουμε ότι η
      // branch ΔΕΝ καταστράφηκε κατά το tab switch.
      expect(find.text(AppStrings.statsComingSoon, skipOffstage: false),
          findsOneWidget);
    });

    // ─── NAV logging (§1.7) ─────────────────────────────────────────────────
    testWidgets('NavLogObserver καταγράφει την πλοήγηση (LogTag.nav)',
        (tester) async {
      final logs = <String>[];
      AppLogger.testSink = logs.add;
      addTearDown(AppLogger.resetTestSink);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: buildAppRouter()),
        ),
      );
      await tester.pumpAndSettle();
      expect(logs, isNotEmpty);
      expect(logs.any((l) => l.startsWith('[NAV]')), isTrue);
      expect(logs.any((l) => l.contains('→ ')), isTrue,
          reason: 'Αρχική πλοήγηση → Home route');
    });
  });
}