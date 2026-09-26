/// Widget tests — `HomePage` placeholder (Φάση 3, Βήμα 1 · §2.1 DESIGN).
///
/// Placeholder ΣΤΑΤΙΚΟ (χωρίς providers): δεν χρειάζεται ProviderScope.
/// Responsive §1.4: ελέγχει 3 μεγέθη (mobile/tablet/desktop) — κανένα
/// overflow, η σελίδα είναι κεντραρισμένο κείμενο σε Center.
/// Σχόλιο (δεξιά): ο AppBar τίτλος είναι «Τιμές» (appTitle §0), όχι
/// «Στατιστικά» — το Home είναι η σελίδα στατιστικών §2.1.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_strings.dart';
import 'package:times/presentation/home/home_page.dart';

void main() {
  Widget wrap(Size size) {
    return MaterialApp(
      // Χωρίς themeMode persistence — το placeholder δεν εξαρτάται.
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: const HomePage(),
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

  group('HomePage', () {
    // ─── Περιεχόμενο ─────────────────────────────────────────────────────────
    testWidgets('εμφανίζει AppBar «Τιμές» + placeholder στατιστικών',
        (tester) async {
      await pumpAt(tester, const Size(800, 600));
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text(AppStrings.appTitle), findsOneWidget);
      expect(find.text(AppStrings.statsComingSoon), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ─── Responsive (§1.4) ───────────────────────────────────────────────────
    testWidgets('mobile (320×568) — κανένα overflow', (tester) async {
      await pumpAt(tester, const Size(320, 568));
      expect(find.text(AppStrings.statsComingSoon), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tablet (800×600) — κανένα overflow', (tester) async {
      await pumpAt(tester, const Size(800, 600));
      expect(find.text(AppStrings.statsComingSoon), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('desktop (1200×800) — κανένα overflow', (tester) async {
      await pumpAt(tester, const Size(1200, 800));
      expect(find.text(AppStrings.statsComingSoon), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}