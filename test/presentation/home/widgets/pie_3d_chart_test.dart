/// Widget tests — `Pie3dChart` (§2.1 · Φάση 5 Βήμα 4).
///
/// Φέτες + legend δεξιά (labels + €) · κενό/μηδενικό → άδειο box ·
/// στενό (< pieFallbackMaxWidth) → fallback πίνακας · dark · 3 μεγέθη +
/// scaler · semantics label.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_constants.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/models/chart_totals.dart';
import 'package:times/presentation/home/widgets/chart_fallback_table.dart';
import 'package:times/presentation/home/widgets/pie_3d_chart.dart';

void main() {
  List<ChartSlice> sampleSlices() => const [
        (label: 'Μάρκος', totalCents: 398),
        (label: 'Ερμής', totalCents: 100),
      ];

  /// Βρίσκει ΜΟΝΟ τον δικό μας painter (το Material/Scaffold βάζει δικό του
  /// CustomPaint για ink — `byType` θα έβρισκε 2).
  Finder findPie() => find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is Pie3dPainter,
      );

  Future<void> pumpChart(
    WidgetTester tester,
    List<ChartSlice> slices, {
    ThemeData? theme,
    Size size = const Size(800, 600),
    TextScaler textScaler = TextScaler.noScaling,
    String? semanticsLabel,
    double? width,
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
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: width ?? size.width,
                child: Pie3dChart(
                  slices: slices,
                  semanticsLabel: semanticsLabel,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Pie3dChart', () {
    testWidgets('φέτες + legend δεξιά (labels + €)', (tester) async {
      await pumpChart(tester, sampleSlices());
      expect(findPie(), findsOneWidget);
      expect(find.text('Μάρκος'), findsOneWidget);
      expect(find.text('Ερμής'), findsOneWidget);
      expect(find.textContaining('3,98'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('κενές φέτες → άδειο box (η κάρτα δείχνει empty)', (tester) async {
      await pumpChart(tester, const []);
      expect(findPie(), findsNothing);
      expect(find.byType(ChartFallbackTable), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('μηδενικό σύνολο → άδειο box (όχι διαίρεση με 0)', (tester) async {
      await pumpChart(tester, const [(label: 'X', totalCents: 0)]);
      expect(findPie(), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('στενό container → fallback πίνακας (§1.4)', (tester) async {
      await pumpChart(
        tester,
        sampleSlices(),
        size: const Size(800, 600),
        width: AppConstants.pieFallbackMaxWidth - 1,
      );
      expect(find.byType(ChartFallbackTable), findsOneWidget);
      expect(findPie(), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('μία φέτα (100%) → πλήρης κύκλος', (tester) async {
      await pumpChart(tester, const [(label: 'Μάρκος', totalCents: 398)]);
      expect(findPie(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320/800/1200 + scaler 2.0 — κανένα overflow', (tester) async {
      for (final size in const [
        Size(320, 568),
        Size(800, 600),
        Size(1200, 800),
      ]) {
        await pumpChart(tester, sampleSlices(), size: size);
        expect(tester.takeException(), isNull, reason: 'overflow σε $size');
      }
      await pumpChart(
        tester,
        sampleSlices(),
        size: const Size(320, 568),
        textScaler: const TextScaler.linear(2.0),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark: αποδίδεται χωρίς σφάλματα', (tester) async {
      await pumpChart(tester, sampleSlices(), theme: AppTheme.dark);
      expect(findPie(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('semantics label (τίτλος κάρτας, §1.6)', (tester) async {
      // Semantics ΠΡΙΝ το pump (το explicit label χτίζεται στο πρώτο frame).
      final handle = tester.ensureSemantics();
      await pumpChart(
        tester,
        sampleSlices(),
        semanticsLabel: 'Ανά προμηθευτή',
      );
      expect(find.bySemanticsLabel('Ανά προμηθευτή'), findsOneWidget);
      handle.dispose();
    });
  });

  group('Pie3dPainter', () {
    test('shouldRepaint: ίδια δεδομένα → false', () {
      const fractions = [0.7, 0.3];
      const colors = [Colors.blue, Colors.red];
      final a = Pie3dPainter(
        fractions: fractions,
        colors: colors,
        depthRatio: 0.12,
        tiltRatio: 0.5,
      );
      final b = Pie3dPainter(
        fractions: fractions,
        colors: colors,
        depthRatio: 0.12,
        tiltRatio: 0.5,
      );
      expect(a.shouldRepaint(b), isFalse);
    });

    test('shouldRepaint: νέα δεδομένα → true', () {
      const colors = [Colors.blue, Colors.red];
      final a = Pie3dPainter(
        fractions: const [0.7, 0.3],
        colors: colors,
        depthRatio: 0.12,
        tiltRatio: 0.5,
      );
      final b = Pie3dPainter(
        fractions: const [0.5, 0.5],
        colors: colors,
        depthRatio: 0.12,
        tiltRatio: 0.5,
      );
      expect(a.shouldRepaint(b), isTrue);
    });

    test('darken: πιο σκούρο + clamped', () {
      final dark = Pie3dPainter.darken(Colors.white, 2.0);
      expect(dark, isNot(Colors.white));
    });
  });
}
