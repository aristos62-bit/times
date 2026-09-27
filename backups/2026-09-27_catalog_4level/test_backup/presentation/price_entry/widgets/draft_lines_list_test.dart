/// Widget tests — `DraftLinesList` (§2.2 · Φάση 3 Βήμα 5γ).
///
/// Προβολή του «καλαθιού»: τίτλος + (κενή κατάσταση | γραμμές με διαγραφή).
/// Καθαρά σύγχρονο state (`receiptFormControllerProvider`) — ΚΑΝΕΝΑ DB
/// override, plain `ProviderScope` (μοτίβο controller tests).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/presentation/price_entry/controllers/receipt_form_controller.dart';
import 'package:times/presentation/price_entry/state/receipt_form_state.dart';
import 'package:times/presentation/price_entry/widgets/draft_lines_list.dart';

void main() {
  Widget wrap({ThemeData? theme}) {
    return ProviderScope(
      child: MaterialApp(
        theme: theme,
        home: const Scaffold(body: DraftLinesList()),
      ),
    );
  }

  /// Δεδομένη γραμμή «καλαθιού».
  DraftReceiptLine line({int itemId = 1, String itemName = 'Γάλα'}) =>
      DraftReceiptLine(
        itemId: itemId,
        unitId: 2,
        quantity: 2.5,
        priceCents: 250,
        itemName: itemName,
        unitAbbreviation: 'κιλ',
      );

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(DraftLinesList)));

  group('DraftLinesList (Βήμα 5γ)', () {
    testWidgets('κενό «καλάθι» → τίτλος + draftLinesEmpty, κανένα crash',
        (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.draftLinesTitle), findsOneWidget);
      expect(find.text(AppStrings.draftLinesEmpty), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('γραμμές → όνομα + «ποσότητα συντ. · τιμή €»', (tester) async {
      await tester.pumpWidget(wrap());
      final container = containerOf(tester);
      container.read(receiptFormControllerProvider.notifier).addDraftLine(
            line(),
          );
      container.read(receiptFormControllerProvider.notifier).addDraftLine(
            line(itemId: 2, itemName: 'Ψωμί'),
          );
      await tester.pumpAndSettle();

      expect(find.text('Γάλα'), findsOneWidget);
      expect(find.text('Ψωμί'), findsOneWidget);
      // Χωρίς line totals (απόφαση Δ2) — μόνο ποσότητα + τιμή μονάδας.
      expect(find.text('2,5 κιλ · 2,50 €'), findsNWidgets(2));
      expect(find.text(AppStrings.draftLinesEmpty), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('διαγραφή → αφαιρείται η σωστή γραμμή', (tester) async {
      await tester.pumpWidget(wrap());
      final container = containerOf(tester);
      final notifier =
          container.read(receiptFormControllerProvider.notifier);
      notifier.addDraftLine(line(itemName: 'Γάλα'));
      notifier.addDraftLine(line(itemId: 2, itemName: 'Ψωμί'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(find.text('Γάλα'), findsNothing);
      expect(find.text('Ψωμί'), findsOneWidget);
      expect(
        container.read(receiptFormControllerProvider).draftLines.length,
        1,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('τελευταία διαγραφή → επιστροφή σε κενή κατάσταση',
        (tester) async {
      await tester.pumpWidget(wrap());
      final container = containerOf(tester);
      container.read(receiptFormControllerProvider.notifier).addDraftLine(
            line(),
          );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.draftLinesEmpty), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark mode: γραμμές ορατές χωρίς exception (§1.5)',
        (tester) async {
      await tester.pumpWidget(wrap(theme: AppTheme.dark));
      final container = containerOf(tester);
      container.read(receiptFormControllerProvider.notifier).addDraftLine(
            line(),
          );
      await tester.pumpAndSettle();

      expect(find.text('Γάλα'), findsOneWidget);
      expect(find.text('2,5 κιλ · 2,50 €'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('γραμμή συνολικής τιμής → «ποσότητα συντ. · τιμή € (σύνολο €)»',
        (tester) async {
      await tester.pumpWidget(wrap());
      final container = containerOf(tester);
      container.read(receiptFormControllerProvider.notifier).addDraftLine(
            DraftReceiptLine(
              itemId: 1,
              unitId: 2,
              quantity: 0.35,
              priceCents: 3429,
              itemName: 'Γάλα',
              unitAbbreviation: 'κιλ',
              enteredTotalCents: 1200,
            ),
          );
      await tester.pumpAndSettle();

      // Μοναδιαία + snapshot συνόλου (stored, χωρίς επαν-υπολογισμό).
      expect(
        find.text('0,35 κιλ · 34,29 € (${AppStrings.lineTotalLabel} 12,00 €)'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('γραμμή total + έκπτωση → ένα σύνολο (το καθαρό)',
        (tester) async {
      await tester.pumpWidget(wrap());
      final container = containerOf(tester);
      container.read(receiptFormControllerProvider.notifier).addDraftLine(
            DraftReceiptLine(
              itemId: 1,
              unitId: 2,
              quantity: 0.634,
              priceCents: 1090,
              discountCents: 170,
              itemName: 'Φέτα',
              unitAbbreviation: 'κιλ',
              enteredTotalCents: 691,
            ),
          );
      await tester.pumpAndSettle();

      // Καθαρό (1090−170)×0.634 = 583· το μικτό snapshot παραλείπεται (όχι
      // διπλό «σύνολο»).
      expect(
        find.text('0,634 κιλ · 10,90 € -1,70 € (${AppStrings.lineTotalLabel} '
            '5,83 €)'),
        findsOneWidget,
      );
      expect(find.textContaining('6,91'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('γραμμή μοναδιαίας → χωρίς σύνολο (Δ2 preserved)',
        (tester) async {
      await tester.pumpWidget(wrap());
      final container = containerOf(tester);
      container.read(receiptFormControllerProvider.notifier).addDraftLine(
            line(),
          );
      await tester.pumpAndSettle();

      expect(find.text('2,5 κιλ · 2,50 €'), findsOneWidget);
      expect(
        find.textContaining(AppStrings.lineTotalLabel),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('γραμμή με έκπτωση → «τιμή −έκπτωση (σύνολο net)» (§2.2)',
        (tester) async {
      await tester.pumpWidget(wrap());
      final container = containerOf(tester);
      container.read(receiptFormControllerProvider.notifier).addDraftLine(
            DraftReceiptLine(
              itemId: 1,
              unitId: 2,
              quantity: 2.5,
              priceCents: 250,
              discountCents: 50,
              itemName: 'Γάλα',
              unitAbbreviation: 'κιλ',
            ),
          );
      await tester.pumpAndSettle();

      expect(
        find.text('2,5 κιλ · 2,50 € -0,50 € (${AppStrings.lineTotalLabel} '
            '5,00 €)'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark mode: γραμμή με έκπτωση ορατή χωρίς exception (§1.5)',
        (tester) async {
      await tester.pumpWidget(wrap(theme: AppTheme.dark));
      final container = containerOf(tester);
      container.read(receiptFormControllerProvider.notifier).addDraftLine(
            DraftReceiptLine(
              itemId: 1,
              unitId: 2,
              quantity: 1,
              priceCents: 100,
              discountCents: 20,
              itemName: 'Γάλα',
              unitAbbreviation: 'κιλ',
            ),
          );
      await tester.pumpAndSettle();

      expect(find.text('Γάλα'), findsOneWidget);
      expect(find.textContaining('-0,20 €'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
