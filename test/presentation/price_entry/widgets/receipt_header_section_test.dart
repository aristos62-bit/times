/// Widget tests — `ReceiptHeaderSection` (§2.2 / Φάση 3 Βήμα 2).
///
/// Ελληνικά medium-format (formatMediumDate με el locale, §0). Το picker
/// ελέγχεται σε μεγάλη θύρα (grid mode) — στα responsive tests ΔΕΝ ανοίγει.
/// Αποφυγή DateTime.now() σε asserts: η "σήμερα" παράγεται από το controller
/// (μέσω `MaterialLocalizations.formatMediumDate`), άρα ο expected προκύπτει
/// την ίδια στιγμή της δοκιμής — προσθήκη 1 ημέρας ως "επόμενη" είναι
/// πάντα εντός bounds κι εκτός "σήμερα".
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_strings.dart';
import 'package:times/presentation/price_entry/widgets/receipt_header_section.dart';

/// Shared wrap: ProviderScope + MaterialApp με ελληνικά locale (όπως στο main).
Widget wrap(Size size, {Widget? child}) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('el')],
      locale: const Locale('el'),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: child ?? const ReceiptHeaderSection(),
      ),
    ),
  );
}

void main() {
  /// Θέτει τη θύρα (logical, dpr=1) και περιμένει το δέντρο.
  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap(size));
    await tester.pumpAndSettle();
  }

  String mediumNow(WidgetTester tester) {
    final ctx = tester.element(find.byType(ReceiptHeaderSection));
    final today = DateUtils.dateOnly(DateTime.now());
    return MaterialLocalizations.of(ctx).formatMediumDate(today);
  }

  group('ReceiptHeaderSection', () {
    testWidgets('εμφανίζει label «Ημερομηνία» + formatMediumDate(σήμερα)',
        (tester) async {
      await pumpAt(tester, const Size(800, 600));

      expect(find.text(AppStrings.fieldDate), findsOneWidget);
      expect(find.text(mediumNow(tester)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('είναι interactive (tap → ανοίγει DatePickerDialog)',
        (tester) async {
      await pumpAt(tester, const Size(800, 600));

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('OK χωρίς αλλαγή → παραμένει η σημερινή ημερομηνία',
        (tester) async {
      await pumpAt(tester, const Size(800, 600));

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text(MaterialLocalizations.of(
              tester.element(find.byType(ReceiptHeaderSection)))
          .okButtonLabel));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsNothing);
      expect(find.text(mediumNow(tester)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('επιλογή διαφορετικής ημέρας → ημερομηνία ενημερώνεται',
        (tester) async {
      await pumpAt(tester, const Size(800, 600));

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      // Άλλη ημέρα του τρέχοντος μήνα (πάντα εντός bounds, ≠ σημερινή).
      final now = DateTime.now();
      final altDay = now.day == 15 ? 16 : 15;

      await tester.tap(find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.text('$altDay'),
      ));
      await tester.pump();
      await tester.tap(find.text(MaterialLocalizations.of(
              tester.element(find.byType(ReceiptHeaderSection)))
          .okButtonLabel));
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(ReceiptHeaderSection));
      final expected = MaterialLocalizations.of(ctx)
          .formatMediumDate(DateTime(now.year, now.month, altDay));
      expect(find.text(expected), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ─── Responsive §1.4 — κανένα overflow ─────────────────────────────────────
    testWidgets('mobile (320×568) — κανένα overflow', (tester) async {
      await pumpAt(tester, const Size(320, 568));
      expect(find.text(mediumNow(tester)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tablet (800×600) — κανένα overflow', (tester) async {
      await pumpAt(tester, const Size(800, 600));
      expect(find.text(mediumNow(tester)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('desktop (1200×800) — κανένα overflow', (tester) async {
      await pumpAt(tester, const Size(1200, 800));
      expect(find.text(mediumNow(tester)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}