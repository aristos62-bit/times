/// Widget tests — `SettingsPage` placeholder (Φάση 3, Βήμα 1 · §2.3 DESIGN).
///
/// Placeholder ΣΤΑΤΙΚΟ (χωρίς providers): δεν χρειάζεται ProviderScope.
/// Responsive §1.4: 3 μεγέθη (mobile/tablet/desktop) — κανένα overflow.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_strings.dart';
import 'package:times/presentation/settings/settings_page.dart';

void main() {
  Widget wrap(Size size) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: const SettingsPage(),
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

  group('SettingsPage', () {
    // ─── Περιεχόμενο ─────────────────────────────────────────────────────────
    testWidgets('εμφανίζει AppBar «Ρυθμίσεις» + placeholder', (tester) async {
      await pumpAt(tester, const Size(800, 600));
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text(AppStrings.titleSettings), findsOneWidget);
      expect(find.text(AppStrings.settingsComingSoon), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ─── Responsive (§1.4) ───────────────────────────────────────────────────
    testWidgets('mobile (320×568) — κανένα overflow', (tester) async {
      await pumpAt(tester, const Size(320, 568));
      expect(find.text(AppStrings.settingsComingSoon), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tablet (800×600) — κανένα overflow', (tester) async {
      await pumpAt(tester, const Size(800, 600));
      expect(find.text(AppStrings.settingsComingSoon), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('desktop (1200×800) — κανένα overflow', (tester) async {
      await pumpAt(tester, const Size(1200, 800));
      expect(find.text(AppStrings.settingsComingSoon), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}