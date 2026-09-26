/// Widget tests — `HomeChartCard` (§2.1 · Φάση 5 Βήμα 4).
///
/// Τίτλος + selector + states (skeleton/empty/error+retry/data) με override
/// του resolved instance (idiom `recent_receipts_list_test`): loading με
/// `StreamController` (pump μόνο) · error + «Επανάληψη» · responsive/dark ·
/// selector callback.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_enums.dart';
import 'package:times/core/constants/app_errors.dart';
import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/models/chart_totals.dart';
import 'package:times/presentation/home/widgets/home_chart_card.dart';
import 'package:times/presentation/home/widgets/pie_3d_chart.dart';

void main() {
  List<ChartSlice> sampleSlices() => const [
        (label: 'Μάρκος', totalCents: 398),
        (label: 'Ερμής', totalCents: 100),
      ];

  /// Wrap: ο resolved instance χτίζεται από το [stream] (χωρίς DB).
  Widget wrap(
    Stream<List<ChartSlice>> stream, {
    ThemeData? theme,
    PeriodType period = PeriodType.month,
    ValueChanged<PeriodType>? onPeriodChanged,
  }) {
    final slicesProvider =
        StreamProvider<List<ChartSlice>>((ref) => stream);
    return ProviderScope(
      child: MaterialApp(
        theme: theme,
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: Scaffold(
            body: HomeChartCard(
              title: AppStrings.chartSupplierTitle,
              slicesProvider: slicesProvider,
              period: period,
              onPeriodChanged: onPeriodChanged ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pumpSized(
    WidgetTester tester,
    Stream<List<ChartSlice>> stream,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap(stream));
    await tester.pumpAndSettle();
  }

  group('HomeChartCard', () {
    testWidgets('loading: skeleton (όχι spinner, §2.1:179)', (tester) async {
      final controller = StreamController<List<ChartSlice>>();
      addTearDown(controller.close);
      await tester.pumpWidget(wrap(controller.stream));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text(AppStrings.chartSupplierTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('data: τίτλος + πίτα + selector', (tester) async {
      await tester.pumpWidget(wrap(Stream.value(sampleSlices())));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.chartSupplierTitle), findsOneWidget);
      expect(find.byType(Pie3dChart), findsOneWidget);
      expect(
        find.text(AppStrings.periodMonth, skipOffstage: false),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty: noPricesForPeriod (όχι πίτα)', (tester) async {
      await tester.pumpWidget(wrap(Stream.value(const [])));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.noPricesForPeriod), findsOneWidget);
      expect(find.byType(Pie3dChart), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('error: loadDataFailed + Επανάληψη', (tester) async {
      await tester.pumpWidget(
        wrap(Stream.error(Exception('test'))),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppErrors.loadDataFailed), findsOneWidget);
      expect(find.text(AppStrings.retryButton), findsOneWidget);
      await tester.tap(find.text(AppStrings.retryButton));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('selector: επιλογή Έτους → onPeriodChanged(year)', (tester) async {
      final changed = <PeriodType>[];
      await tester.pumpWidget(
        wrap(Stream.value(sampleSlices()), onPeriodChanged: changed.add),
      );
      await tester.pumpAndSettle();
      // Άνοιγμα μενού από το trailing βέλος (το field tap εστιάζει το κείμενο).
      await tester.tap(find.byIcon(Icons.arrow_drop_down).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.periodYear).last);
      await tester.pumpAndSettle();
      expect(changed, [PeriodType.year]);
    });

    testWidgets('320/800/1200 — κανένα overflow', (tester) async {
      for (final size in const [
        Size(320, 568),
        Size(800, 600),
        Size(1200, 800),
      ]) {
        await pumpSized(tester, Stream.value(sampleSlices()), size);
        expect(tester.takeException(), isNull, reason: 'overflow σε $size');
      }
    });

    testWidgets('dark: αποδίδεται χωρίς σφάλματα', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.dark,
            home: MediaQuery(
              data: const MediaQueryData(size: Size(800, 600)),
              child: Scaffold(
                body: HomeChartCard(
                  title: AppStrings.chartSupplierTitle,
                  slicesProvider: StreamProvider<List<ChartSlice>>(
                    (ref) => Stream.value(sampleSlices()),
                  ),
                  period: PeriodType.month,
                  onPeriodChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Pie3dChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ChartPeriodSelector', () {
    test('labelOf: 5 SPoT labels (§2.1)', () {
      expect(ChartPeriodSelector.labelOf(PeriodType.day), AppStrings.periodDay);
      expect(ChartPeriodSelector.labelOf(PeriodType.week), AppStrings.periodWeek);
      expect(
        ChartPeriodSelector.labelOf(PeriodType.month),
        AppStrings.periodMonth,
      );
      expect(ChartPeriodSelector.labelOf(PeriodType.year), AppStrings.periodYear);
      expect(
        ChartPeriodSelector.labelOf(PeriodType.custom),
        AppStrings.periodCustom,
      );
    });
  });
}
