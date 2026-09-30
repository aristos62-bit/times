/// Widget tests — `AppLockSection` (§2.3 · 30-09-2026).
///
/// Dumb switch + fake gate: toggle ON/OFF (persist) · hidden όταν
/// unsupported (Q4) · responsive/dark/semantics (pattern
/// `theme_mode_selector_test`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:times/core/constants/app_constants.dart';
import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/providers/app_lock_providers.dart';
import 'package:times/data/providers/settings_providers.dart';
import 'package:times/presentation/settings/widgets/app_lock_section.dart';

import '../../../data/providers/helpers/fake_biometric_gate.dart';

void main() {
  late SharedPreferences prefs;
  late FakeBiometricGate gate;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    gate = FakeBiometricGate();
  });

  Future<void> pumpSection(
    WidgetTester tester, {
    ThemeData? theme,
    Size size = const Size(800, 600),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          biometricGateProvider.overrideWithValue(gate),
        ],
        child: MaterialApp(
          theme: theme,
          home: const Scaffold(body: AppLockSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AppLockSection (§2.3 · 30-09-2026)', () {
    testWidgets('δείχνει label + subtitle (supported)', (tester) async {
      await pumpSection(tester);
      expect(find.text(AppStrings.appLockEnableLabel), findsOneWidget);
      expect(find.text(AppStrings.appLockEnableSubtitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('toggle ON → auth + persist true', (tester) async {
      await pumpSection(tester);
      await tester.tap(find.text(AppStrings.appLockEnableLabel));
      await tester.pumpAndSettle();
      expect(prefs.getBool(AppConstants.appLockEnabledKey), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('toggle OFF → auth + persist false', (tester) async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      await pumpSection(tester);
      await tester.tap(find.text(AppStrings.appLockEnableLabel));
      await tester.pumpAndSettle();
      expect(prefs.getBool(AppConstants.appLockEnabledKey), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('unsupported → κρυφό (Q4)', (tester) async {
      gate = FakeBiometricGate(supported: false);
      await pumpSection(tester);
      expect(find.text(AppStrings.appLockEnableLabel), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320/800/1200 — κανένα overflow', (tester) async {
      for (final size in const [
        Size(320, 568),
        Size(800, 600),
        Size(1200, 800),
      ]) {
        await pumpSection(tester, size: size);
        expect(tester.takeException(), isNull, reason: 'overflow σε $size');
      }
    });

    testWidgets('dark: αποδίδεται χωρίς σφάλματα', (tester) async {
      await pumpSection(tester, theme: AppTheme.dark);
      expect(find.text(AppStrings.appLockEnableLabel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('switch με semantics (τίτλος + κατάσταση)', (tester) async {
      await pumpSection(tester);
      final handle = tester.ensureSemantics();
      // Το SwitchListTile συγχωνεύει τίτλο + κατάσταση στο semantics label
      // (όχι exact match — `contains`, σε αντίθεση με τα segments).
      final node = tester.getSemantics(find.byType(SwitchListTile));
      expect(node.label, contains(AppStrings.appLockEnableLabel));
      handle.dispose();
    });
  });
}
