/// Widget tests — `PriceEntryPage` (Φάση 3, Βήμα 2 · §2.2 DESIGN).
///
/// Πλέον ConsumerWidget: watch-άρει τον τοπικό `receiptFormControllerProvider`
/// (καμία εξάρτηση από repository → η βάση δεν ανοίγει, όπως στο Βήμα 1).
/// Βήμα 7: η σελίδα περιέχει πλέον τη λίστα πρόσφατων αποδείξεων
/// (`recentReceiptsStreamProvider`) → override με ΚΕΝΗ λίστα (hermetic:
/// κανένα DB access — αλλιώς θα άνοιγε πραγματική βάση, §2.0.1).
/// Responsive §1.4: 3 μεγέθη (mobile/tablet/desktop) — κανένα overflow.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_messages.dart';
import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/router/app_router.dart';
import 'package:times/data/models/receipt_summary.dart';
import 'package:times/data/providers/stream_providers.dart';
import 'package:times/presentation/price_entry/controllers/receipt_form_controller.dart';
import 'package:times/presentation/price_entry/price_entry_page.dart';
import 'package:times/presentation/price_entry/state/receipt_form_state.dart';
import 'package:times/presentation/price_entry/widgets/item_search_field.dart';
import 'package:times/presentation/price_entry/widgets/receipt_header_section.dart';
import 'package:times/presentation/shared/confirm_dialog.dart';

void main() {
  Widget wrap(Size size) {
    return ProviderScope(
      overrides: [
        // Βήμα 7: read-only λίστα πρόσφατων — κενή ροή (χωρίς DB access).
        recentReceiptsStreamProvider.overrideWith(
          (ref) => Stream.value(const <ReceiptSummary>[]),
        ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: const PriceEntryPage(),
        ),
      ),
    );
  }

  /// Θέτει το μέγεθος θύρας (logical pixels, dpr=1) και περιμένει.
  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap(size));
    await tester.pumpAndSettle();
  }

  group('PriceEntryPage', () {
    // ─── Περιεχόμενο ─────────────────────────────────────────────────────────
    testWidgets('περιέχει AppBar, header ημερομηνίας + item search (Βήμα 4) + '
        'draft list (Βήμα 5γ)', (tester) async {
      await pumpAt(tester, const Size(800, 600));
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text(AppStrings.titlePriceEntry), findsOneWidget);
      expect(find.byType(ReceiptHeaderSection), findsOneWidget);
      // Βήμα 4: inline panel αναζήτησης είναι παρόν (idle — καμία DB access).
      expect(find.byType(ItemSearchField), findsOneWidget);
      // Βήμα 5γ: το placeholder αντικαταστάθηκε από το «καλάθι» (κενό).
      expect(find.text(AppStrings.draftLinesTitle), findsOneWidget);
      expect(find.text(AppStrings.draftLinesEmpty), findsOneWidget);
      // Βήμα 5δ: κουμπί αποθήκευσης παρόν αλλά ανενεργό (κενό + no supplier).
      expect(find.text(AppStrings.saveReceipt), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, AppStrings.saveReceipt),
            )
            .enabled,
        isFalse,
      );
      // Βήμα 7: read-only λίστα πρόσφατων αποδείξεων (κενή — override).
      expect(find.text(AppStrings.recentReceiptsTitle), findsOneWidget);
      expect(find.text(AppStrings.recentReceiptsEmpty), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ─── Responsive (§1.4) ───────────────────────────────────────────────────
    testWidgets('mobile (320×568) — κανένα overflow', (tester) async {
      await pumpAt(tester, const Size(320, 568));
      expect(find.text(AppStrings.draftLinesEmpty), findsOneWidget);
      // Βήμα 7: η λίστα πρόσφατων είναι ορατή και σε στενή οθόνη.
      expect(find.text(AppStrings.recentReceiptsTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tablet (800×600) — κανένα overflow', (tester) async {
      await pumpAt(tester, const Size(800, 600));
      expect(find.text(AppStrings.draftLinesEmpty), findsOneWidget);
      expect(find.text(AppStrings.recentReceiptsTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('desktop (1200×800) — κανένα overflow', (tester) async {
      await pumpAt(tester, const Size(1200, 800));
      expect(find.text(AppStrings.draftLinesEmpty), findsOneWidget);
      expect(find.text(AppStrings.recentReceiptsTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // ─── Exit-confirm (§2.2:244 «Ημιτελής καταχώρηση») ────────────────────────
  // Αντί για το wrap() (MaterialApp με τη σελίδα ως home), αυτό το group
  // χρησιμοποιεί τον ΠΡΑΓΜΑΤΙΚΟ router (StatefulShellRoute, buildAppRouter):
  // η PriceEntryPage είναι η μοναδική route της branch → το pop είναι no-op
  // (όπως σε desktop) και το σενάριο «μετά το Ναι ξανα-γεμίζει η φόρμα»
  // (stale-flag reset) αναπαράγεται αυθεντικά. Το system back περνά από τον
  // GoRouterDelegate (popRoute → maybePop στο branch navigator), που σέβεται
  // το PopScope της σελίδας.
  group('Exit-confirm (§2.2:244)', () {
    // Μία έγκυρη draft γραμμή «καλαθιού» (addDraftLine — συμπληρώνει το state).
    const line = DraftReceiptLine(
      itemId: 1,
      unitId: 1,
      quantity: 1.0,
      priceCents: 250,
      itemName: 'Γάλα',
      unitAbbreviation: 'τεμ',
    );

    Future<void> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Χωρίς DB access (hermetic, ίδιο override με το wrap()).
            recentReceiptsStreamProvider.overrideWith(
              (ref) => Stream.value(const <ReceiptSummary>[]),
            ),
          ],
          child: MaterialApp.router(routerConfig: buildAppRouter()),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// Μετάβαση στο tab «Εισαγωγή» (branch PriceEntry, §2.2).
    Future<void> goToPriceEntry(WidgetTester tester) async {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(AppStrings.navPriceEntry),
        ),
      );
      await tester.pumpAndSettle();
    }

    ProviderContainer container(WidgetTester tester) =>
        ProviderScope.containerOf(tester.element(find.byType(PriceEntryPage)));

    Future<void> addDraft(WidgetTester tester) async {
      container(tester)
          .read(receiptFormControllerProvider.notifier)
          .addDraftLine(line);
      await tester.pump();
    }

    /// Προσομοίωση system back (Android): περνά από τον router delegate
    /// (popRoute → maybePop), οπότε σέβεται το PopScope της σελίδας.
    Future<void> systemBack(WidgetTester tester) async {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }

    testWidgets('back χωρίς drafts → κανένα dialog, κανένα exception',
        (tester) async {
      await pumpApp(tester);
      await goToPriceEntry(tester);
      await systemBack(tester);
      expect(find.byType(ConfirmDialog), findsNothing);
      expect(find.text(AppMessages.exitUnsavedConfirm), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('back με draft → εμφανίζεται το μήνυμα εξόδου (§2.2:244)',
        (tester) async {
      await pumpApp(tester);
      await goToPriceEntry(tester);
      await addDraft(tester);
      await systemBack(tester);
      expect(find.text(AppMessages.exitUnsavedConfirm), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('«Ακύρωση» → dialog κλείνει, τα drafts μένουν άθικτα',
        (tester) async {
      await pumpApp(tester);
      await goToPriceEntry(tester);
      await addDraft(tester);
      await systemBack(tester);
      await tester.tap(find.text(AppMessages.confirmDialogCancel));
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmDialog), findsNothing);
      final form = container(tester).read(receiptFormControllerProvider);
      expect(form.draftLines, hasLength(1));
      expect(form.supplier, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('«Ναι» → φόρμα καθαρή (draftLines κενές + προμηθευτής null)',
        (tester) async {
      await pumpApp(tester);
      await goToPriceEntry(tester);
      await addDraft(tester);
      await systemBack(tester);
      await tester.tap(find.text(AppMessages.confirmDialogConfirm));
      await tester.pumpAndSettle();
      // Η σελίδα παραμένει (no-op branch pop): ο χρήστης βρίσκει ΚΑΘΑΡΗ
      // φόρμα — καμία μη αποθηκευμένη γραμμή προς απώλεια (§2.2:244).
      expect(find.byType(PriceEntryPage), findsOneWidget);
      final form = container(tester).read(receiptFormControllerProvider);
      expect(form.draftLines, isEmpty);
      expect(form.supplier, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'stale-flag reset: μετά «Ναι» + νέο draft → το back ρωτάει ΞΑΝΑ',
        (tester) async {
      await pumpApp(tester);
      await goToPriceEntry(tester);
      await addDraft(tester);
      await systemBack(tester);
      await tester.tap(find.text(AppMessages.confirmDialogConfirm));
      await tester.pumpAndSettle();
      // Desktop-like no-op: ο χρήστης μένει στη σελίδα και ξανα-γεμίζει τη
      // φόρμα — η «άδεια εξόδου» πρέπει να έχει σβήσει (ref.listen) και το
      // επόμενο back να ΞΑΝΑ-ρωτήσει.
      expect(find.byType(PriceEntryPage), findsOneWidget);
      await addDraft(tester);
      await systemBack(tester);
      expect(find.text(AppMessages.exitUnsavedConfirm), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}