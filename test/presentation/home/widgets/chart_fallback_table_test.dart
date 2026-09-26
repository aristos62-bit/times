/// Widget tests — `ChartFallbackTable` (§2.1 · Φάση 5 Βήμα 4).
///
/// Dumb widget (έτοιμα slices): γραμμές label + € · 320px + textScaler 2.0
/// (χωρίς overflow) · dark V12 · κενή λίστα → άδειο Column.
/// Pattern `theme_mode_selector_test` (pump helper + 3 μεγέθη + semantics).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/models/chart_totals.dart';
import 'package:times/presentation/home/widgets/chart_fallback_table.dart';

void main() {
  List<ChartSlice> sampleSlices() => const [
        (label: 'Μάρκος', totalCents: 398),
        (label: 'Προμηθευτής με πολύ μακρύ όνομα για ellipsis', totalCents: 100),
      ];

  Future<void> pumpTable(
    WidgetTester tester,
    List<ChartSlice> slices, {
    ThemeData? theme,
    Size size = const Size(800, 600),
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: MediaQuery(
          data: MediaQueryData(size: size, textScaler: textScaler),
          child: Scaffold(body: ChartFallbackTable(slices: slices)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ChartFallbackTable', () {
    testWidgets('γραμμές label + € (SPoT formatCents)', (tester) async {
      await pumpTable(tester, sampleSlices());
      expect(find.text('Μάρκος', skipOffstage: false), findsOneWidget);
      expect(find.textContaining('3,98'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('κενή λίστα → άδειο (χωρίς γραμμές)', (tester) async {
      await pumpTable(tester, const []);
      expect(find.byType(Row), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320/800/1200 + scaler 2.0 — κανένα overflow', (tester) async {
      for (final size in const [
        Size(320, 568),
        Size(800, 600),
        Size(1200, 800),
      ]) {
        await pumpTable(tester, sampleSlices(), size: size);
        expect(tester.takeException(), isNull, reason: 'overflow σε $size');
      }
      await pumpTable(
        tester,
        sampleSlices(),
        size: const Size(320, 568),
        textScaler: const TextScaler.linear(2.0),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark: αποδίδεται χωρίς σφάλματα', (tester) async {
      await pumpTable(tester, sampleSlices(), theme: AppTheme.dark);
      expect(find.text('Μάρκος', skipOffstage: false), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
