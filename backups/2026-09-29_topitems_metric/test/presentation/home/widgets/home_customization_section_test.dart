/// Widget tests — `HomeCustomizationSection` (§2.1 · Φάση 5 Βήμα 5).
///
/// Collapsible (κλειστή by default) · switch ορατότητας → controller ·
/// βέλη σειράς (άκρα ανενεργά) · prefs mock (persisted config, Βήμα 3).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:times/core/constants/app_strings.dart';
import 'package:times/data/providers/settings_providers.dart';
import 'package:times/presentation/home/controllers/home_chart_config_controller.dart';
import 'package:times/presentation/home/widgets/home_customization_section.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget wrap() => ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
          home: Scaffold(body: HomeCustomizationSection()),
        ),
      );

  /// Ψηλό viewport (pattern `tallSize` home_page_test): με 5 γραμμές το
  /// expanded section ξεπερνά τα 600px — σε production ζει σε ListView
  /// (scroll), εδώ το viewport ψηλώνει ώστε όλα να είναι ορατά.
  Future<void> pumpExpanded(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.homeCustomizationTitle));
    await tester.pumpAndSettle();
  }

  group('HomeCustomizationSection', () {
    testWidgets('κλειστή by default (τίτλος ορατός, γραμμές όχι)', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.homeCustomizationTitle), findsOneWidget);
      expect(find.text(AppStrings.chartSupplierTitle), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap ανοίγει: 6 γραμμές + βέλη', (tester) async {
      await pumpExpanded(tester);
      expect(find.text(AppStrings.chartSupplierTitle), findsOneWidget);
      expect(find.text(AppStrings.chartTopItemsTitle), findsOneWidget);
      expect(find.text(AppStrings.chartItemTrendTitle), findsOneWidget);
      expect(
        find.byTooltip(AppStrings.chartMoveUp, skipOffstage: false),
        findsNWidgets(6),
      );
      expect(
        find.byTooltip(AppStrings.chartMoveDown, skipOffstage: false),
        findsNWidgets(6),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('άκρα ανενεργά: πάνω στην 1η, κάτω στην 6η', (tester) async {
      await pumpExpanded(tester);
      // byTooltip βρίσκει το Tooltip — τα κουμπιά με predicate (tooltip).
      Finder upFinder = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton && widget.tooltip == AppStrings.chartMoveUp,
      );
      Finder downFinder = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton && widget.tooltip == AppStrings.chartMoveDown,
      );
      expect(upFinder, findsNWidgets(6));
      expect(downFinder, findsNWidgets(6));
      final upButtons = tester.widgetList<IconButton>(upFinder).toList();
      final downButtons = tester.widgetList<IconButton>(downFinder).toList();
      // 1η γραμμή (supplier, order 0): πάνω ανενεργό · 6η: κάτω ανενεργό.
      expect(upButtons.first.onPressed, isNull);
      expect(downButtons.first.onPressed, isNotNull);
      expect(upButtons.last.onPressed, isNotNull);
      expect(downButtons.last.onPressed, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('switch κρύβει κάρτα (controller + persist)', (tester) async {
      ProviderContainer? captured;
      // Ψηλό viewport (βλ. pumpExpanded): 6 γραμμές expanded.
      tester.view.physicalSize = const Size(800, 2500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  captured = ProviderScope.containerOf(context);
                  return const HomeCustomizationSection();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.homeCustomizationTitle));
      await tester.pumpAndSettle();
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(6));
      await tester.tap(switches.first);
      await tester.pumpAndSettle();
      expect(
        captured!.read(homeChartConfigProvider).supplier.visible,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
