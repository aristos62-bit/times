/// Widget tests — `ThemeModeSelector` (Φάση 4, Βήμα 1 · DESIGN §2.3:264).
///
/// Dumb widget → δοκιμάζεται με callback tracking (κανένα provider). Labels
/// SPoT, responsive §1.4 (320/800/1200 — κανένα overflow), dark §1.5
/// (πρότυπο V12) και semantics §1.6.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/presentation/settings/widgets/theme_mode_selector.dart';

void main() {
  /// Pump του selector μέσα σε Scaffold (context material για το Material
  /// 3 SegmentedButton) με προαιρετικό [theme]/[selected]/[onChanged].
  Future<void> pumpSelector(
    WidgetTester tester, {
    ThemeMode selected = ThemeMode.system,
    ValueChanged<ThemeMode>? onChanged,
    ThemeData? theme,
    Size size = const Size(800, 600),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Scaffold(
            body: Center(
              child: ThemeModeSelector(
                selected: selected,
                onChanged: onChanged ?? (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ThemeModeSelector', () {
    // ─── Labels & επιλογές ───────────────────────────────────────────────────
    testWidgets('εμφανίζει τα 3 SPoT labels (§2.3:270)', (tester) async {
      await pumpSelector(tester);
      expect(find.text(AppStrings.themeModeLight), findsOneWidget);
      expect(find.text(AppStrings.themeModeDark), findsOneWidget);
      expect(find.text(AppStrings.themeModeSystem), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap «Σκοτεινό» → onChanged(ThemeMode.dark)', (tester) async {
      final changed = <ThemeMode>[];
      await pumpSelector(tester, onChanged: changed.add);
      await tester.tap(find.text(AppStrings.themeModeDark));
      expect(changed, [ThemeMode.dark]);
    });

    testWidgets('tap «Φωτεινό» → onChanged(ThemeMode.light)', (tester) async {
      final changed = <ThemeMode>[];
      await pumpSelector(tester, onChanged: changed.add);
      await tester.tap(find.text(AppStrings.themeModeLight));
      expect(changed, [ThemeMode.light]);
    });

    testWidgets('tap «Αυτόματο» → onChanged(ThemeMode.system)', (tester) async {
      final changed = <ThemeMode>[];
      // Ξεκινάμε selected: light — αν ήταν system, το «Αυτόματο» θα ήταν ήδη
      // επιλεγμένο και ο SegmentedButton δεν καλεί onChanged σε ήδη επιλεγμένο.
      await pumpSelector(tester,
          selected: ThemeMode.light, onChanged: changed.add);
      await tester.tap(find.text(AppStrings.themeModeSystem));
      expect(changed, [ThemeMode.system]);
    });

    testWidgets('το επιλεγμένο segment αντανακλά τη selected', (tester) async {
      await pumpSelector(tester, selected: ThemeMode.dark);
      final button = tester.widget<SegmentedButton<ThemeMode>>(
        find.byType(SegmentedButton<ThemeMode>),
      );
      expect(button.selected, {ThemeMode.dark});
      // Η μοναδική επιλογή είναι δεσμευτική (ποτέ κενή set).
      expect(button.emptySelectionAllowed, isFalse);
    });

    // ─── Responsive (§1.4) ───────────────────────────────────────────────────
    testWidgets('320/800/1200 — κανένα overflow', (tester) async {
      for (final size in const [
        Size(320, 568),
        Size(800, 600),
        Size(1200, 800),
      ]) {
        await pumpSelector(tester, size: size);
        expect(tester.takeException(), isNull,
            reason: 'overflow/σφάλμα σε $size');
      }
    });

    // ─── Dark (§1.5, πρότυπο V12) ────────────────────────────────────────────
    testWidgets('dark: αποδίδεται χωρίς σφάλματα', (tester) async {
      await pumpSelector(tester, theme: AppTheme.dark);
      expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ─── Semantics (§1.6) ────────────────────────────────────────────────────
    testWidgets('τα 3 labels είναι προσβάσιμα (semantics)', (tester) async {
      await pumpSelector(tester);
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel(AppStrings.themeModeLight), findsOneWidget);
      expect(find.bySemanticsLabel(AppStrings.themeModeDark), findsOneWidget);
      expect(find.bySemanticsLabel(AppStrings.themeModeSystem), findsOneWidget);
      handle.dispose();
    });
  });
}