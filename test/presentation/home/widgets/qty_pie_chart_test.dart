/// Widget tests — `QtyPieChart` (§2.1 · 29-09-2026 — μετρικές).
///
/// Legend ποσοτήτων + γραμμή συνόλου · fallback στενού/2x · dark ·
/// semantics. Χωρίς DB (canned slices).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/models/chart_totals.dart';
import 'package:times/presentation/home/widgets/qty_pie_chart.dart';
import 'package:times/presentation/shared/quantity_text_field.dart';

List<ChartQtySlice> sampleSlices() => const [
      (label: 'Γάλα', qty: 2.5),
      (label: 'Γιαούρτι', qty: 1.0),
    ];

Widget wrap(
  List<ChartQtySlice> slices, {
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
        body: QtyPieChart(
          slices: slices,
          unitAbbreviation: 'κιλ',
          semanticsLabel: AppStrings.chartTopItemsTitle,
        ),
      ),
    ),
  );
}

Future<void> pumpSized(
  WidgetTester tester,
  List<ChartQtySlice> slices,
  Size size, {
  ThemeData? theme,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    wrap(slices, size: size, theme: theme, textScale: textScale),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('QtyPieChart', () {
    testWidgets('empty → άδειο box (η κάρτα δείχνει empty)', (tester) async {
      await pumpSized(tester, const [], const Size(800, 600));
      expect(find.byType(QtyPieChart), findsOneWidget);
      expect(find.text('Γάλα'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('data → πίτα + legend ποσοτήτων + σύνολο', (tester) async {
      await pumpSized(tester, sampleSlices(), const Size(800, 600));
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('Γάλα'), findsOneWidget);
      // Legend: «2,5 κιλ» · σύνολο «3,5 κιλ».
      expect(
        find.text(
          '${QuantityTextField.formatQuantity(2.5)} κιλ',
        ),
        findsOneWidget,
      );
      expect(find.text(AppStrings.chartTotalLabel), findsOneWidget);
      expect(
        find.text(
          '${QuantityTextField.formatQuantity(3.5)} κιλ',
        ),
        findsOneWidget,
      );
      // Καμία ένδειξη € (μετρική ποσότητας, όχι συνόλου).
      expect(find.textContaining('€'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('στενό (280px) → fallback πίνακας', (tester) async {
      await pumpSized(tester, sampleSlices(), const Size(280, 600));
      expect(find.text('Γάλα'), findsOneWidget);
      expect(find.text(AppStrings.chartTotalLabel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2x κείμενο → fallback', (tester) async {
      await pumpSized(
        tester,
        sampleSlices(),
        const Size(800, 600),
        textScale: 2.0,
      );
      expect(find.text('Γιαούρτι'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark — χωρίς exception', (tester) async {
      await pumpSized(
        tester,
        sampleSlices(),
        const Size(800, 600),
        theme: AppTheme.dark,
      );
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('semantics: label προσβάσιμο (§1.6)', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSized(tester, sampleSlices(), const Size(800, 600));
      expect(
        find.bySemanticsLabel(AppStrings.chartTopItemsTitle),
        findsWidgets,
      );
      handle.dispose();
      expect(tester.takeException(), isNull);
    });
  });
}
