/// Widget + unit tests — `ItemTrendChart` + `ItemTrendFallbackList`
/// (§2.1 · 28-09-2026): bounds (pure), data/fallback switch (στενό/2x),
/// 1 point, dark, semantics. Χωρίς DB (canned points).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/models/chart_totals.dart';
import 'package:times/presentation/home/widgets/item_trend_chart.dart';
import 'package:times/presentation/home/widgets/item_trend_fallback_list.dart';
import 'package:times/presentation/shared/currency_text_field.dart';

List<ItemPricePoint> samplePoints() => [
      (
        date: DateTime(2026, 1, 5),
        netPriceCents: 200,
        quantity: 1.0,
        unitId: 1,
        supplierName: 'Μάρκος',
      ),
      (
        date: DateTime(2026, 1, 20),
        netPriceCents: 300,
        quantity: 2.0,
        unitId: 1,
        supplierName: 'Ερμής',
      ),
    ];

Widget wrap(
  List<ItemPricePoint> points, {
  Size size = const Size(800, 600),
  ThemeData? theme,
  double textScale = 1.0,
}) {
  return MaterialApp(
    theme: theme,
    home: MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(
        body: ItemTrendChart(
          points: points,
          semanticsLabel: AppStrings.chartItemTrendTitle,
        ),
      ),
    ),
  );
}

Future<void> pumpSized(
  WidgetTester tester,
  List<ItemPricePoint> points,
  Size size, {
  ThemeData? theme,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    wrap(points, size: size, theme: theme, textScale: textScale),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ItemTrendChart.boundsOf (pure)', () {
    test('εύρος ±15% γύρω από min/max', () {
      final bounds = ItemTrendChart.boundsOf([200.0, 300.0]);
      expect(bounds.lo, lessThan(200));
      expect(bounds.hi, greaterThan(300));
      expect(bounds.lo, 200 - 15);
      expect(bounds.hi, 300 + 15);
    });

    test('εκφυλισμένο (1 τιμή) → ανοίγει ±max(1 €, 5%)', () {
      final bounds = ItemTrendChart.boundsOf([250.0]);
      expect(bounds.lo, lessThan(250));
      expect(bounds.hi, greaterThan(250));
    });
  });

  group('ItemTrendChart (widget)', () {
    testWidgets('empty → άδειο box (η κάρτα δείχνει empty)', (tester) async {
      await pumpSized(tester, const [], const Size(800, 600));
      expect(find.byType(ItemTrendChart), findsOneWidget);
      expect(find.byType(ItemTrendFallbackList), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('data (φαρδύ) → CustomPaint, όχι fallback', (tester) async {
      await pumpSized(tester, samplePoints(), const Size(800, 600));
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(ItemTrendFallbackList), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1 point → dot χωρίς crash', (tester) async {
      await pumpSized(
        tester,
        [samplePoints().first],
        const Size(800, 600),
      );
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('στενό (280px) → fallback λίστα', (tester) async {
      await pumpSized(tester, samplePoints(), const Size(280, 600));
      expect(find.byType(ItemTrendFallbackList), findsOneWidget);
      // Γραμμές: ημερομηνία · προμηθευτής · τιμή (χωρίς γραμμή συνόλου).
      expect(find.textContaining('Μάρκος'), findsWidgets);
      expect(
        find.text(
          '${CurrencyTextField.formatCents(200)} '
          '${AppStrings.currencySymbol}',
        ),
        findsOneWidget,
      );
      expect(find.text(AppStrings.chartTotalLabel), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2x κείμενο → fallback (όχι στριμωγμένη γραμμή)', (tester) async {
      await pumpSized(
        tester,
        samplePoints(),
        const Size(800, 600),
        textScale: 2.0,
      );
      expect(find.byType(ItemTrendFallbackList), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark — αποδίδεται χωρίς exception', (tester) async {
      await pumpSized(
        tester,
        samplePoints(),
        const Size(800, 600),
        theme: AppTheme.dark,
      );
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('semantics: label προσβάσιμο (§1.6)', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSized(tester, samplePoints(), const Size(800, 600));
      expect(
        find.bySemanticsLabel(AppStrings.chartItemTrendTitle),
        findsWidgets,
      );
      handle.dispose();
      expect(tester.takeException(), isNull);
    });
  });
}
