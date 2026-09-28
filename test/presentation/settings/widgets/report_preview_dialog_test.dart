/// Widget tests — `ReportPreviewDialog` (§2.3 · 3η ανάλυση).
///
/// Grand banner + sections + actions Excel/PDF/Κλείσιμο/dismiss · dark.
/// Χωρίς providers (dumb — έτοιμα δεδομένα).
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_messages.dart';
import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/models/chart_totals.dart';
import 'package:times/domain/services/statistics_export.dart';
import 'package:times/presentation/settings/widgets/report_preview_dialog.dart';

List<PeriodPurchaseRow> sampleRows() => [
      (
        receiptId: 12,
        date: DateTime(2026, 9, 9),
        itemName: 'Γάλα',
        categoryName: 'ΤΡΟΦΙΜΑ',
        supplierName: 'Μάρκος',
        quantity: 2.0,
        unitId: 1,
        unitAbbreviation: 'κιλ',
        priceCents: 250,
        discountCents: 50,
      ),
    ];

List<Unit> sampleUnits() => [
      Unit(id: 1, name: 'Κιλό', abbreviation: 'κιλ', allowsDecimal: true),
    ];

Future<ReportPreviewAction?> pumpDialog(
  WidgetTester tester,
  Future<void> Function()? afterOpen,
) async {
  ReportPreviewAction? result;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('el')],
      locale: const Locale('el'),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showReportPreview(
                context,
                title: AppStrings.statsGroupedTitle,
                grandTotals: StatisticsExportService.purchasesTotalsOf(
                  sampleRows(),
                  sampleUnits(),
                ),
                units: sampleUnits(),
                sections: const [],
              );
            },
            child: const Text('άνοιγμα'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('άνοιγμα'));
  await tester.pumpAndSettle();
  if (afterOpen != null) await afterOpen();
  return result;
}

void main() {
  group('ReportPreviewDialog', () {
    testWidgets('grand banner + Κλείσιμο → null', (tester) async {
      final result = await pumpDialog(tester, () async {
        expect(find.text(AppStrings.statsGroupedTitle), findsOneWidget);
        // Grand: (250−50)×2 = 400 → «4,00 €».
        expect(find.textContaining('4,00'), findsWidgets);
        await tester.tap(find.text(AppMessages.confirmDialogCancel));
        await tester.pumpAndSettle();
      });
      expect(result, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Excel → excel · PDF → pdf', (tester) async {
      var result = await pumpDialog(tester, () async {
        await tester.tap(find.text(AppStrings.statsExportExcelAction));
        await tester.pumpAndSettle();
      });
      expect(result, ReportPreviewAction.excel);

      result = await pumpDialog(tester, () async {
        await tester.tap(find.text(AppStrings.statsExportPdfAction));
        await tester.pumpAndSettle();
      });
      expect(result, ReportPreviewAction.pdf);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sections: τίτλος + γραμμές ομάδας', (tester) async {
      ReportPreviewAction? result;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('el')],
          locale: const Locale('el'),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await showReportPreview(
                    context,
                    title: AppStrings.statsGroupedTitle,
                    grandTotals: StatisticsExportService.purchasesTotalsOf(
                      sampleRows(),
                      sampleUnits(),
                    ),
                    units: sampleUnits(),
                    sections: [
                      (display: 'ΤΡΟΦΙΜΑ', rows: sampleRows()),
                    ],
                  );
                },
                child: const Text('άνοιγμα'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('άνοιγμα'));
      await tester.pumpAndSettle();
      expect(find.text('ΤΡΟΦΙΜΑ'), findsWidgets);
      expect(find.text('Γάλα'), findsOneWidget);
      expect(result, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark — χωρίς exception', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('el')],
          locale: const Locale('el'),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showReportPreview(
                  context,
                  title: AppStrings.statsGroupedTitle,
                  grandTotals: StatisticsExportService.purchasesTotalsOf(
                    sampleRows(),
                    sampleUnits(),
                  ),
                  units: sampleUnits(),
                  sections: const [],
                ),
                child: const Text('άνοιγμα'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('άνοιγμα'));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.statsGroupedTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
