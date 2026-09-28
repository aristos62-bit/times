/// Widget tests — `PurchasesTable` (§2.3 · 29-09-2026 — 2η ανάλυση).
///
/// Dumb πίνακας (έτοιμα δεδομένα, χωρίς DB): δυναμικές στήλες μονάδων +
/// footer · 3 μεγέθη · dark. Χωρίς provider overrides.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/models/chart_totals.dart';
import 'package:times/domain/services/statistics_export.dart';
import 'package:times/presentation/settings/widgets/purchases_table.dart';

List<Unit> sampleUnits() => [
      Unit(id: 1, name: 'Κιλό', abbreviation: 'κιλ', allowsDecimal: true),
      Unit(id: 2, name: 'Τεμάχιο', abbreviation: 'τεμ', allowsDecimal: false),
    ];

List<PeriodPurchaseRow> sampleRows() => [
      (
        receiptId: 12,
        date: DateTime(2026, 9, 9),
        itemName: 'Γάλα',
        categoryName: 'ΤΡΟΦΙΜΑ',
        supplierName: 'Μάρκος',
        quantity: 0.456,
        unitId: 1,
        unitAbbreviation: 'κιλ',
        priceCents: 1296,
        discountCents: 35,
      ),
      (
        receiptId: 15,
        date: DateTime(2026, 9, 12),
        itemName: 'Ψωμί',
        categoryName: 'ΑΡΤΟΣΚΕΥΑΣΜΑΤΑ',
        supplierName: 'Ερμής',
        quantity: 3.0,
        unitId: 2,
        unitAbbreviation: 'τεμ',
        priceCents: 120,
        discountCents: 0,
      ),
    ];

Widget wrap({
  required List<PeriodPurchaseRow> rows,
  required List<Unit> units,
  ThemeData? theme,
}) {
  return MaterialApp(
    theme: theme,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('el')],
    locale: const Locale('el'),
    home: Scaffold(
      body: SingleChildScrollView(
        child: PurchasesTable(
          rows: rows,
          units: units,
          totals: StatisticsExportService.purchasesTotalsOf(rows),
        ),
      ),
    ),
  );
}

Future<void> pumpSized(
  WidgetTester tester,
  List<PeriodPurchaseRow> rows,
  List<Unit> units,
  Size size, {
  ThemeData? theme,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(wrap(rows: rows, units: units, theme: theme));
  await tester.pumpAndSettle();
}

void main() {
  group('PurchasesTable', () {
    testWidgets('δυναμικές στήλες + κελιά + footer', (tester) async {
      await pumpSized(
        tester,
        sampleRows(),
        sampleUnits(),
        const Size(1200, 800),
      );
      // Σταθερές + δυναμικές στήλες.
      expect(find.text(AppStrings.statsColumnCategory), findsOneWidget);
      expect(find.text('Κιλό'), findsOneWidget);
      expect(find.text('Τεμάχιο'), findsOneWidget);
      expect(find.text(AppStrings.fieldItemName), findsOneWidget);
      // Γραμμές: προμηθευτές + ποσότητα στη στήλη της μονάδας.
      expect(find.text('Μάρκος'), findsOneWidget);
      // Footer: sums/μονάδα + σύνολο ((1296−35)×0,456 + 120×3 = 575+360).
      // '0,456'/'3': σώμα + footer.
      expect(find.text('Σύνολο (2)'), findsOneWidget);
      expect(find.text('0,456'), findsNWidgets(2));
      expect(find.text('3'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('responsive 320/800/1200 — κανένα overflow', (tester) async {
      for (final size in const [
        Size(320, 568),
        Size(800, 600),
        Size(1200, 800),
      ]) {
        await pumpSized(tester, sampleRows(), sampleUnits(), size);
        expect(tester.takeException(), isNull, reason: 'overflow σε $size');
      }
    });

    testWidgets('dark — χωρίς exception', (tester) async {
      await pumpSized(
        tester,
        sampleRows(),
        sampleUnits(),
        const Size(1200, 800),
        theme: AppTheme.dark,
      );
      expect(find.text('Μάρκος'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
