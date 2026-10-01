/// Widget tests — `AppLockGate` + `AppLockOverlay` (§2.3 · 30-09-2026).
///
/// Fake gate (ok/fail/pending): ορατότητα πύλης · unlock ροές · busy guard
/// (ένα native dialog ανά tap, pattern `_isCreating`) · responsive/dark.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:times/core/constants/app_constants.dart';
import 'package:times/core/constants/app_errors.dart';
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
    // Pending gate + spinner (animation) → το pumpAndSettle δεν
    // ολοκληρώνεται ποτέ: σταθερά pumps (pattern debounce tests).
    bool settle = true,
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
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('AppLockGate/AppLockOverlay (§2.3 · 30-09-2026)', () {
    testWidgets('ξεκλείδωτη → καθόλου overlay', (tester) async {
      await pumpGate(tester, gate: FakeBiometricGate());
      expect(find.text(AppStrings.appLockUnlockAction), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('κλειδωμένη → overlay με reason + κουμπί retry', (tester) async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      // Αποτυχημένο auto-prompt → εμφανίζεται το κουμπί (retry).
      await pumpGate(
        tester,
        gate: FakeBiometricGate(authResults: const [false]),
      );
      expect(find.text(AppStrings.appLockReason), findsOneWidget);
      expect(find.text(AppStrings.appLockUnlockAction), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('auto-prompt: ξεκλειδώνει χωρίς tap', (tester) async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      final gate = FakeBiometricGate();
      await pumpGate(tester, gate: gate);
      expect(find.text(AppStrings.appLockUnlockAction), findsNothing);
      expect(gate.reasons, hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('unlock ok → overlay φεύγει', (tester) async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      final gate = PendingGate();
      await pumpGate(tester, gate: gate, settle: false);
      gate.completer.complete(true);
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.appLockUnlockAction), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('unlock fail → overlay παραμένει (σιωπή)', (tester) async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      await pumpGate(
        tester,
        gate: FakeBiometricGate(authResults: const [false]),
      );
      await tester.tap(find.text(AppStrings.appLockUnlockAction));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.appLockUnlockAction), findsOneWidget);
      expect(find.text(AppErrors.appLockFailed), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('unlock σφάλμα πλατφόρμας → error snackbar (auto-prompt)',
        (tester) async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      await pumpGate(
        tester,
        gate: FakeBiometricGate(
          throwCode: LocalAuthExceptionCode.noCredentialsSet,
        ),
      );
      // Το auto-prompt κατανάλωσε ήδη το σφάλμα — χωρίς tap.
      expect(find.text(AppStrings.appLockUnlockAction), findsOneWidget);
      expect(find.text(AppErrors.appLockFailed), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('pending auto-prompt → τίποτα ορατό (μόνο δακτυλικό)',
        (tester) async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      final gate = PendingGate();
      await pumpGate(tester, gate: gate, settle: false);
      // Ούτε κείμενο ούτε κουμπί — η οθόνη βγαίνει ΜΟΝΟ σε αποτυχία.
      expect(find.text(AppStrings.appLockReason), findsNothing);
      expect(find.text(AppStrings.appLockUnlockAction), findsNothing);
      expect(tester.takeException(), isNull);
      // Καθαρισμός: ολοκλήρωση του pending auth για να ακυρωθεί το 60s
      // timeout-timer (F1) — αλλιώς pending-timer στο τέλος (invariant).
      gate.completer.complete(false);
      await tester.pump();
    });

    testWidgets('320/800/1200 — κανένα overflow', (tester) async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      for (final size in const [
        Size(320, 568),
        Size(800, 600),
        Size(1200, 800),
      ]) {
        // Αποτυχημένο auto → κουμπί retry (πλήρες layout με spinner/button).
        await pumpGate(
          tester,
          gate: FakeBiometricGate(authResults: const [false]),
          size: size,
        );
        expect(tester.takeException(), isNull, reason: 'overflow σε $size');
      }
    });

    testWidgets('dark: αποδίδεται χωρίς σφάλματα', (tester) async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      await pumpGate(
        tester,
        gate: FakeBiometricGate(authResults: const [false]),
        theme: AppTheme.dark,
      );
      expect(find.text(AppStrings.appLockUnlockAction), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('AppLockBackground (F2 · 01-10 — semantics/focus trap)', () {
    Future<void> pumpBackground(
      WidgetTester tester, {
      required bool lockedPrefs,
      FocusNode? focusNode,
    }) async {
      if (lockedPrefs) {
        await prefs.setBool(AppConstants.appLockEnabledKey, true);
      }
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            biometricGateProvider.overrideWithValue(FakeBiometricGate()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AppLockBackground(
                child: Column(
                  children: [
                    const Text('μυστικό'),
                    TextButton(
                      focusNode: focusNode,
                      onPressed: () {},
                      child: const Text('πίσω-κουμπί'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('κλειδωμένα → φόντο εκτός semantics tree', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpBackground(tester, lockedPrefs: true);
      // Το widget υπάρχει οπτικά, αλλά ΟΧΙ στο semantics (reader τυφλό).
      expect(find.text('μυστικό'), findsOneWidget);
      expect(find.bySemanticsLabel('μυστικό'), findsNothing);
      handle.dispose();
      expect(tester.takeException(), isNull);
    });

    testWidgets('ξεκλείδωτα → φόντο κανονικά στο semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpBackground(tester, lockedPrefs: false);
      expect(find.bySemanticsLabel('μυστικό'), findsOneWidget);
      handle.dispose();
      expect(tester.takeException(), isNull);
    });

    testWidgets('κλειδωμένα → Tab δεν πιάνει φόντο', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pumpBackground(tester, lockedPrefs: true, focusNode: node);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(node.hasFocus, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ξεκλείδωτα → Tab πιάνει φόντο (control)', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pumpBackground(tester, lockedPrefs: false, focusNode: node);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(node.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}
