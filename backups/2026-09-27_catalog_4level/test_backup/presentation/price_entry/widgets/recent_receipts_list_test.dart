/// Widget tests — `RecentReceiptsList` (§2.2 · Φάση 3 Βήμα 7).
///
/// Η λίστα read-only διαβάζει `recentReceiptsStreamProvider` — override με
/// stream στο ProviderScope (hermetic, ΚΑΝΕΝΑ DB): data / empty / error /
/// loading. Καλύπτονται: loading (pump ΜΟΝΟ — το spinner δεν «settle»),
/// data (αριθμός/ημερομηνία/προμηθευτής/γραμμές/σύνολο), empty, error +
/// «Επανάληψη» (ref.invalidate → ο provider ξανατρέχει), responsive (3
/// μεγέθη οθόνης χωρίς overflow, idiom searchable_dropdown_field_test) και
/// dark mode (AppTheme.dark, §1.5).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_errors.dart';
import 'package:times/core/constants/app_messages.dart';
import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/models/receipt_summary.dart';
import 'package:times/data/providers/stream_providers.dart';
import 'package:times/presentation/price_entry/widgets/recent_receipts_list.dart';

void main() {
  /// Δείγματα: 2 αποδείξεις (Μάρκος 2 γραμμές / Προμηθευτής Β 1 γραμμή).
  List<ReceiptSummary> sampleSummaries() => [
        (
          id: 1,
          date: DateTime(2026, 1, 1),
          supplierId: 1,
          supplierName: 'Μάρκος',
          lineCount: 2,
          totalCents: 448,
        ),
        (
          id: 2,
          date: DateTime(2026, 1, 5),
          supplierId: 2,
          supplierName: 'Προμηθευτής Β',
          lineCount: 1,
          totalCents: 100,
        ),
      ];

  /// Wrap: override του provider + MaterialApp (light/dark theme §1.5).
  Widget wrap(
    Stream<List<ReceiptSummary>> stream, {
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return ProviderScope(
      overrides: [
        recentReceiptsStreamProvider.overrideWith((ref) => stream),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        home: const Scaffold(body: RecentReceiptsList()),
      ),
    );
  }

  /// Αλλαγή μεγέθους οθόνης (idiom searchable_dropdown_field_test, §1.4).
  void setSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('RecentReceiptsList (Βήμα 7)', () {
    testWidgets('loading: spinner (pump μόνο — infinite animation)',
        (tester) async {
      final controller = StreamController<List<ReceiptSummary>>();
      addTearDown(controller.close);
      await tester.pumpWidget(wrap(controller.stream));

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(AppStrings.recentReceiptsTitle), findsOneWidget);
    });

    testWidgets('data: αριθμός · ημερομηνία · προμηθευτής · γραμμές · σύνολο',
        (tester) async {
      await tester.pumpWidget(wrap(Stream.value(sampleSummaries())));
      await tester.pumpAndSettle();

      // Τίτλος ενότητας (§2.2).
      expect(find.text(AppStrings.recentReceiptsTitle), findsOneWidget);
      // Αριθμός απόδειξης (SPoT AppMessages.receiptNumber).
      expect(find.text(AppMessages.receiptNumber(1)), findsOneWidget);
      expect(find.text(AppMessages.receiptNumber(2)), findsOneWidget);
      // Προμηθευτής + πλήθος γραμμών (subtitle).
      expect(find.textContaining('Μάρκος'), findsOneWidget);
      expect(find.textContaining('Προμηθευτής Β'), findsOneWidget);
      expect(find.textContaining('2 γραμμές'), findsOneWidget);
      // SPoT χωρίς plural distinction («1 γραμμές», όχι «1 γραμμή»).
      expect(find.textContaining('1 γραμμές'), findsOneWidget);
      // Ημερομηνία (formatShortDate — «Jan 1, 2026» en_US στα tests).
      expect(find.textContaining('2026'), findsNWidgets(2));
      // Σύνολα ευρώ: formatCents + currencySymbol (§2.2 Βήμα 7).
      expect(find.text('4,48 €'), findsOneWidget);
      expect(find.text('1,00 €'), findsOneWidget);
    });

    testWidgets('κενή βάση → recentReceiptsEmpty, κανένα Card', (tester) async {
      await tester.pumpWidget(wrap(Stream.value(const <ReceiptSummary>[])));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.recentReceiptsEmpty), findsOneWidget);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('error → loadDataFailed + «Επανάληψη» (ref.invalidate)',
        (tester) async {
      var failing = true;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          recentReceiptsStreamProvider.overrideWith(
            (ref) => failing
                ? Stream<List<ReceiptSummary>>.error(Exception('db down'))
                : Stream.value(sampleSummaries()),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: RecentReceiptsList()),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(AppErrors.loadDataFailed), findsOneWidget);
      expect(find.text(AppStrings.retryButton), findsOneWidget);

      // «Επανάληψη» → ref.invalidate → ο provider ξανατρέχει το override.
      failing = false;
      await tester.tap(find.text(AppStrings.retryButton));
      await tester.pumpAndSettle();

      expect(find.text(AppErrors.loadDataFailed), findsNothing);
      expect(find.text(AppMessages.receiptNumber(1)), findsOneWidget);
    });

    testWidgets('responsive: mobile (360) · tablet (800) · desktop (1280)',
        (tester) async {
      for (final size in const [Size(360, 740), Size(800, 1024), Size(1280, 800)]) {
        setSize(tester, size);
        await tester.pumpWidget(wrap(Stream.value(sampleSummaries())));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'overflow στο $size');
        expect(find.text(AppMessages.receiptNumber(1)), findsOneWidget);
      }
    });

    testWidgets('dark mode: ίδιο περιεχόμενο χωρίς σφάλματα', (tester) async {
      await tester.pumpWidget(
        wrap(Stream.value(sampleSummaries()), themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppMessages.receiptNumber(2)), findsOneWidget);
    });
  });
}