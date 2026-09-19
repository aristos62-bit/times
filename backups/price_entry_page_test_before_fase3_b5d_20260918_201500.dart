/// Widget tests — `PriceEntryPage` (Φάση 3, Βήμα 2 · §2.2 DESIGN).
///
/// Πλέον ConsumerWidget: watch-άρει τον τοπικό `receiptFormControllerProvider`
/// (καμία εξάρτηση από repository → η βάση δεν ανοίγει, όπως στο Βήμα 1).
/// Responsive §1.4: 3 μεγέθη (mobile/tablet/desktop) — κανένα overflow.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_strings.dart';
import 'package:times/presentation/price_entry/price_entry_page.dart';
import 'package:times/presentation/price_entry/widgets/item_search_field.dart';
import 'package:times/presentation/price_entry/widgets/receipt_header_section.dart';

void main() {
  Widget wrap(Size size) {
    return ProviderScope(
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
      expect(tester.takeException(), isNull);
    });

    // ─── Responsive (§1.4) ───────────────────────────────────────────────────
    testWidgets('mobile (320×568) — κανένα overflow', (tester) async {
      await pumpAt(tester, const Size(320, 568));
      expect(find.text(AppStrings.draftLinesEmpty), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tablet (800×600) — κανένα overflow', (tester) async {
      await pumpAt(tester, const Size(800, 600));
      expect(find.text(AppStrings.draftLinesEmpty), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('desktop (1200×800) — κανένα overflow', (tester) async {
      await pumpAt(tester, const Size(1200, 800));
      expect(find.text(AppStrings.draftLinesEmpty), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}