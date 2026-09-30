/// Widget tests — `AppLockGate` + `AppLockOverlay` (§2.3 · 30-09-2026).
///
/// Fake gate (ok/fail/pending): ορατότητα πύλης · unlock ροές · busy guard
/// (ένα native dialog ανά tap, pattern `_isCreating`) · responsive/dark.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:times/core/constants/app_constants.dart';
import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/providers/app_lock_providers.dart';
import 'package:times/data/providers/settings_providers.dart';
import 'package:times/data/services/biometric_gate.dart';
import 'package:times/presentation/settings/widgets/app_lock_overlay.dart';

import '../../../data/providers/helpers/fake_biometric_gate.dart';

/// Gate με ελεγχόμενο pending (busy-guard test).
class PendingGate implements BiometricGate {
  final completer = Completer<bool>();
  int calls = 0;

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<bool> authenticate(String reason) {
    calls++;
    return completer.future;
  }
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pumpGate(
    WidgetTester tester, {
    required BiometricGate gate,
    Size size = const Size(800, 600),
    ThemeData? theme,
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
          home: const Scaffold(body: AppLockGate()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AppLockGate/AppLockOverlay (§2.3 · 30-09-2026)', () {
    testWidgets('ξεκλείδωτη → καθόλου overlay', (tester) async {
      await pumpGate(tester, gate: FakeBiometricGate());
      expect(find.text(AppStrings.appLockUnlockAction), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('κλειδωμένη → overlay με reason + κουμπί', (tester) async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      await pumpGate(tester, gate: FakeBiometricGate());
      expect(find.text(AppStrings.appLockReason), findsOneWidget);
      expect(find.text(AppStrings.appLockUnlockAction), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('unlock ok → overlay φεύγει', (tester) async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      await pumpGate(tester, gate: FakeBiometricGate());
      await tester.tap(find.text(AppStrings.appLockUnlockAction));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.appLockUnlockAction), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('unlock fail → overlay παραμένει', (tester) async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      await pumpGate(
        tester,
        gate: FakeBiometricGate(authResults: const [false]),
      );
      await tester.tap(find.text(AppStrings.appLockUnlockAction));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.appLockUnlockAction), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('double-tap → ένα auth (busy guard)', (tester) async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      final gate = PendingGate();
      await pumpGate(tester, gate: gate);
      await tester.tap(find.text(AppStrings.appLockUnlockAction));
      await tester.tap(find.text(AppStrings.appLockUnlockAction));
      gate.completer.complete(true);
      await tester.pumpAndSettle();
      expect(gate.calls, 1);
      expect(find.text(AppStrings.appLockUnlockAction), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320/800/1200 — κανένα overflow', (tester) async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      for (final size in const [
        Size(320, 568),
        Size(800, 600),
        Size(1200, 800),
      ]) {
        await pumpGate(tester, gate: FakeBiometricGate(), size: size);
        expect(tester.takeException(), isNull, reason: 'overflow σε $size');
      }
    });

    testWidgets('dark: αποδίδεται χωρίς σφάλματα', (tester) async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      await pumpGate(tester, gate: FakeBiometricGate(), theme: AppTheme.dark);
      expect(find.text(AppStrings.appLockUnlockAction), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
