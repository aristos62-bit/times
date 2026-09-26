/// Widget tests — `HomePage` (§2.1 · Φάση 5 Βήμα 5).
///
/// Real σελίδα (ConsumerWidget): prefs mock (config, Βήμα 3) + overrides
/// των 4 families με canned streams (hermetic, ΚΑΝΕΝΑ DB — idiom λίστας
/// Βήματος 7). Καλύπτονται: 4 τίτλοι + Προσαρμογή · κενά → empty msgs ·
/// data → πίτες · responsive 3 μεγέθη · dark · semantics.
/// Pattern `theme_mode_selector_test` (pump helper + scaler + dispose).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/models/chart_totals.dart';
import 'package:times/data/providers/settings_providers.dart';
import 'package:times/data/providers/stream_providers.dart';
import 'package:times/presentation/home/home_page.dart';
import 'package:times/presentation/home/widgets/home_chart_card.dart';
import 'package:times/presentation/home/widgets/pie_3d_chart.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  /// Wrap με prefs + canned streams (κενά default — ΞΕΧΩΡΙΣΤΟ stream ανά
  /// family: το `Stream.value` είναι single-subscription, 4 κάρτες).
  Widget wrap({
    List<ChartSlice> slices = const [],
    ThemeData? theme,
    Size size = const Size(800, 600),
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        supplierTotalsProvider.overrideWith(
          (ref, query) => Stream.value(slices),
        ),
        categoryTotalsProvider.overrideWith(
          (ref, query) => Stream.value(slices),
        ),
        subCategoryTotalsProvider.overrideWith(
          (ref, query) => Stream.value(slices),
        ),
        topItemsTotalsProvider.overrideWith(
          (ref, query) => Stream.value(slices),
        ),
      ],
      child: MaterialApp(
        theme: theme,
        home: MediaQuery(
          data: MediaQueryData(size: size, textScaler: textScaler),
          child: const HomePage(),
        ),
      ),
    );
  }

/// Ψηλό viewport για τα count asserts: το SliverList χτίζει παιδιά ΜΟΝΟ
/// εντός cache-extent — με 600px ύψος η 4η κάρτα δεν χτίζεται καν (ούτε
/// με skipOffstage:false βρίσκεται).
const Size tallSize = Size(800, 2500);

  Future<void> pumpPage(
    WidgetTester tester,
    Widget widget,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  group('HomePage (Βήμα 5)', () {
    testWidgets('AppBar «Τιμές» + 4 τίτλοι + Προσαρμογή', (tester) async {
      await pumpPage(tester, wrap(), tallSize);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text(AppStrings.appTitle), findsOneWidget);
      // skipOffstage: οι κάτω κάρτες είναι εκτός οθόνης (ListView scroll).
      expect(
        find.text(AppStrings.chartSupplierTitle, skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.chartCategoryTitle, skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.chartSubCategoryTitle, skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.chartTopItemsTitle, skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.homeCustomizationTitle, skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text(AppStrings.statsComingSoon), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('κενά streams → 4 empty msgs (noPricesForPeriod)', (tester) async {
      await pumpPage(tester, wrap(), tallSize);
      expect(
        find.text(AppStrings.noPricesForPeriod, skipOffstage: false),
        findsNWidgets(4),
      );
      expect(find.byType(Pie3dChart), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('data → 4 πίτες', (tester) async {
      await pumpPage(
        tester,
        wrap(slices: const [(label: 'Μάρκος', totalCents: 398)]),
        tallSize,
      );
      expect(
        find.byType(Pie3dChart, skipOffstage: false),
        findsNWidgets(4),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('320/800/1200 + scaler — κανένα overflow', (tester) async {
      for (final size in const [
        Size(320, 568),
        Size(800, 600),
        Size(1200, 800),
      ]) {
        await pumpPage(tester, wrap(), size);
        expect(tester.takeException(), isNull, reason: 'overflow σε $size');
      }
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        wrap(
          size: const Size(320, 568),
          textScaler: const TextScaler.linear(2.0),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark: αποδίδεται χωρίς σφάλματα', (tester) async {
      await pumpPage(tester, wrap(theme: AppTheme.dark), tallSize);
      expect(
        find.byType(HomeChartCard, skipOffstage: false),
        findsNWidgets(4),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('semantics: τίτλοι προσβάσιμοι (§1.6)', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPage(
        tester,
        wrap(slices: const [(label: 'Μάρκος', totalCents: 398)]),
        tallSize,
      );
      // Τίτλος κάρτας + pie-group label (container boundary) — τουλάχιστον
      // 1 ανά κάρτα (ο τίτλος-Text έχει δικό του node).
      expect(
        find.bySemanticsLabel(AppStrings.chartSupplierTitle),
        findsWidgets,
      );
      expect(
        find.bySemanticsLabel(AppStrings.chartTopItemsTitle),
        findsWidgets,
      );
      handle.dispose();
    });
  });
}
