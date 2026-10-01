/// Widget tests — `StatisticsTable` (§2.3 · 28-09-2026).
///
/// Dumb πίνακας (έτοιμες γραμμές, χωρίς DB): headers + κελιά + footer
/// συνόλων · 3 μεγέθη · dark. Χωρίς provider overrides.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/models/chart_totals.dart';
import 'package:times/presentation/settings/widgets/statistics_table.dart';
import 'package:times/presentation/shared/currency_text_field.dart';

List<ItemLedgerRow> sampleRows() => [
      (
        receiptId: 12,
        date: DateTime(2026, 9, 9),
        supplierName: 'Μάρκος',
        quantity: 0.456,
        unitAbbreviation: 'κιλ',
        priceCents: 1296,
        discountCents: 35,
      ),
      (
        receiptId: 15,
        date: DateTime(2026, 9, 12),
        supplierName: 'Ερμής',
        quantity: 1.0,
        unitAbbreviation: 'κιλ',
        priceCents: 1296,
        discountCents: 35,
      ),
    ];

Widget wrap(List<ItemLedgerRow> rows, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('el')],
    locale: const Locale('el'),
    home: Scaffold(
      body: SingleChildScrollView(child: StatisticsTable(rows: rows)),
    ),
  );
}

Future<void> pumpSized(
  WidgetTester tester,
  List<ItemLedgerRow> rows,
  Size size, {
  ThemeData? theme,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(wrap(rows, theme: theme));
  await tester.pumpAndSettle();
}

void main() {
  group('StatisticsTable', () {
    testWidgets('headers + κελιά + footer συνόλων', (tester) async {
      await pumpSized(tester, sampleRows(), const Size(1200, 800));
      expect(find.text(AppStrings.statsColumnDate), findsOneWidget);
      expect(find.text(AppStrings.statsColumnReceipt), findsOneWidget);
      expect(find.text(AppStrings.statsColumnSupplier), findsOneWidget);
      expect(find.text(AppStrings.statsColumnQuantity), findsOneWidget);
      expect(find.text(AppStrings.statsColumnPrice), findsOneWidget);
      expect(find.text(AppStrings.statsColumnDiscount), findsOneWidget);
      expect(find.text(AppStrings.statsColumnNet), findsOneWidget);
      // Γραμμές: προμηθευτές + ποσότητα με μονάδα + καθαρές.
      expect(find.text('Μάρκος'), findsOneWidget);
      expect(find.text('0,456 κιλ'), findsOneWidget);
      // (1296−35)×0,456 + (1296−35)×1 = 575 + 1261 = 1836 → «18,36 €».
      expect(
        find.text(
          '${CurrencyTextField.formatCents(1836)} '
          '${AppStrings.currencySymbol}',
        ),
        findsOneWidget,
      );
      expect(find.text('Σύνολο (2)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('responsive 320/800/1200 — κανένα overflow', (tester) async {
      for (final size in const [
        Size(320, 568),
        Size(800, 600),
        Size(1200, 800),
      ]) {
        await pumpSized(tester, sampleRows(), size);
        expect(tester.takeException(), isNull, reason: 'overflow σε $size');
      }
    });

    testWidgets('dark — χωρίς exception', (tester) async {
      await pumpSized(
        tester,
        sampleRows(),
        const Size(1200, 800),
        theme: AppTheme.dark,
      );
      expect(find.text('Μάρκος'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
