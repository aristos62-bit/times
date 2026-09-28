/// Widget tests — `TopItemsCard` (§2.1 · 29-09-2026 — μετρικές).
///
/// € default (πίτα συνόλων, αμετάβλητη) · switch σε μονάδα (canned units +
/// qty family) · miss/empty/error · period callback · responsive · dark ·
/// semantics. Canned providers (όχι DB — εκτός search που δεν υπάρχει εδώ).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:times/core/constants/app_constants.dart';
import 'package:times/core/constants/app_enums.dart';
import 'package:times/core/constants/app_errors.dart';
import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/models/chart_totals.dart';
import 'package:times/data/providers/settings_providers.dart';
import 'package:times/data/providers/stream_providers.dart';
import 'package:times/presentation/home/widgets/pie_3d_chart.dart';
import 'package:times/presentation/home/widgets/qty_pie_chart.dart';
import 'package:times/presentation/home/widgets/top_items_card.dart';

List<ChartSlice> sampleSlices() => const [
      (label: 'Γάλα', totalCents: 398),
    ];

List<ChartQtySlice> sampleQty() => const [
      (label: 'Γάλα', qty: 2.5),
    ];

List<Unit> sampleUnits() => [
      Unit(id: 7, name: 'Κιλό', abbreviation: 'κιλ', allowsDecimal: true),
      Unit(id: 8, name: 'Τεμάχιο', abbreviation: 'τεμ', allowsDecimal: false),
    ];

void main() {
  late SharedPreferences prefs;

  final query = (
    from: DateTime(2026, 9, 1),
    to: DateTime(2026, 10, 1),
  );
  TopItemsQtyQuery qtyQuery(int unitId) =>
      (from: query.from, to: query.to, unitId: unitId);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  /// Wrap: prefs + canned € slices + canned units/qty · period recorder.
  Widget wrap({
    List<ChartSlice>? slices,
    Object? qtyError,
    bool qtyLoading = false,
    List<PeriodType>? periods,
    ThemeData? theme,
  }) {
    final kilos = qtyQuery(7);
    final pieces = qtyQuery(8);
    Stream<List<ChartQtySlice>> qtyStream;
    if (qtyLoading) {
      qtyStream = StreamController<List<ChartQtySlice>>().stream;
    } else if (qtyError != null) {
      qtyStream = Stream.error(qtyError);
    } else {
      qtyStream = Stream.value(sampleQty());
    }
    // Και τα δύο unit queries (kilos/pieces) — αλλιώς real DB.
    Stream<List<ChartQtySlice>> canned(Ref ref) => qtyStream;
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        topItemsTotalsProvider(query).overrideWith(
          (ref) => Stream.value(slices ?? sampleSlices()),
        ),
        unitsStreamProvider.overrideWith((ref) => Stream.value(sampleUnits())),
        topItemsByUnitProvider(kilos).overrideWith(canned),
        topItemsByUnitProvider(pieces).overrideWith(canned),
      ],
      child: MaterialApp(
        theme: theme,
        home: Scaffold(
          body: TopItemsCard(
            query: query,
            period: PeriodType.month,
            onPeriodChanged: periods?.add ?? (_) {},
          ),
        ),
      ),
    );
  }

  Future<void> pumpSized(
    WidgetTester tester,
    Widget widget,
    Size size, {
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  group('TopItemsCard', () {
    testWidgets('€ default: τίτλος + period + metric + πίτα', (tester) async {
      await pumpSized(tester, wrap(), const Size(800, 600));
      expect(find.text(AppStrings.chartTopItemsTitle), findsOneWidget);
      expect(find.text(AppStrings.topItemsMetricLabel), findsWidgets);
      expect(find.byType(Pie3dChart), findsOneWidget);
      expect(find.byType(QtyPieChart), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('switch σε Κιλ → πίτα ποσοτήτων + persist', (tester) async {
      await pumpSized(tester, wrap(), const Size(800, 600));
      // Άνοιγμα metric menu από το εμφανιζόμενο κείμενο (Text, όχι το
      // readOnly EditableText — pattern sort test).
      await tester.tap(
        find
            .byWidgetPredicate(
              (widget) => widget is Text && widget.data == '€',
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Κιλ').last);
      await tester.pumpAndSettle();

      expect(find.byType(QtyPieChart), findsOneWidget);
      expect(find.byType(Pie3dChart), findsNothing);
      expect(prefs.getString(AppConstants.topItemsMetricKey), 'kilos');
      expect(tester.takeException(), isNull);
    });

    testWidgets('προεπιλογή μονάδας (prefs) → qty κατευθείαν', (tester) async {
      await prefs.setString(AppConstants.topItemsMetricKey, 'pieces');
      await pumpSized(tester, wrap(), const Size(800, 600));
      expect(find.byType(QtyPieChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('qty empty → noPricesForPeriod', (tester) async {
      await prefs.setString(AppConstants.topItemsMetricKey, 'kilos');
      await pumpSized(
        tester,
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            unitsStreamProvider
                .overrideWith((ref) => Stream.value(sampleUnits())),
            topItemsByUnitProvider(qtyQuery(7)).overrideWith(
              (ref) => Stream.value(const <ChartQtySlice>[]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: TopItemsCard(
                query: query,
                period: PeriodType.month,
                onPeriodChanged: (_) {},
              ),
            ),
          ),
        ),
        const Size(800, 600),
      );
      expect(find.text(AppStrings.noPricesForPeriod), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('qty error → loadDataFailed + Επανάληψη', (tester) async {
      await prefs.setString(AppConstants.topItemsMetricKey, 'kilos');
      await pumpSized(
        tester,
        wrap(qtyError: Exception('test')),
        const Size(800, 600),
      );
      expect(find.text(AppErrors.loadDataFailed), findsOneWidget);
      expect(find.text(AppStrings.retryButton), findsOneWidget);
      await tester.tap(find.text(AppStrings.retryButton));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('period: Έτος → onPeriodChanged(year)', (tester) async {
      final changed = <PeriodType>[];
      await pumpSized(
        tester,
        wrap(periods: changed),
        const Size(800, 600),
      );
      await tester.tap(find.byIcon(Icons.arrow_drop_down).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.periodYear).last);
      await tester.pumpAndSettle();
      expect(changed, [PeriodType.year]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('responsive 320/800/1200 — κανένα overflow', (tester) async {
      for (final size in const [
        Size(320, 568),
        Size(800, 600),
        Size(1200, 800),
      ]) {
        await pumpSized(tester, wrap(), size);
        expect(tester.takeException(), isNull, reason: 'overflow σε $size');
      }
    });

    testWidgets('dark + semantics (§1.5/§1.6)', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSized(
        tester,
        wrap(theme: AppTheme.dark),
        const Size(800, 600),
      );
      expect(find.byType(Pie3dChart), findsOneWidget);
      expect(
        find.bySemanticsLabel(AppStrings.chartTopItemsTitle),
        findsWidgets,
      );
      handle.dispose();
      expect(tester.takeException(), isNull);
    });
  });
}
