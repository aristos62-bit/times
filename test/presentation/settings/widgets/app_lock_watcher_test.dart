/// Tests — `shouldRelock` (pure) + `AppLockWatcher` wiring (§2.3 · 30-09-2026).
///
/// Το όριο χάριτος ελέγχεται ως pure function (χωρίς time-travel στα
/// widgets)· το widget test καλύπτει pause→resume (άμεση επιστροφή = χωρίς
/// κλείδωμα) + OFF = no-op.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:times/core/constants/app_constants.dart';
import 'package:times/data/providers/app_lock_providers.dart';
import 'package:times/data/providers/settings_providers.dart';
import 'package:times/presentation/settings/widgets/app_lock_watcher.dart';

import '../../../data/providers/helpers/fake_biometric_gate.dart';

void main() {
  group('shouldRelock (Q2 · inclusive >=)', () {
    DateTime at(int seconds) =>
        DateTime(2026, 9, 30, 12, 0, 0).add(Duration(seconds: seconds));

    test('29'' → false (μέσα στη χάρη)', () {
      expect(
        shouldRelock(pausedAt: at(0), now: at(29)),
        isFalse,
      );
    });

    test('30'' → true (όριο inclusive)', () {
      expect(
        shouldRelock(pausedAt: at(0), now: at(30)),
        isTrue,
      );
    });

    test('61'' → true', () {
      expect(
        shouldRelock(pausedAt: at(0), now: at(61)),
        isTrue,
      );
    });

    test('0'' → false', () {
      expect(
        shouldRelock(pausedAt: at(0), now: at(0)),
        isFalse,
      );
    });

    test('χρησιμοποιεί AppConstants.appLockGraceSeconds (=30)', () {
      expect(AppConstants.appLockGraceSeconds, 30);
    });
  });

  group('AppLockWatcher', () {
    late SharedPreferences prefs;
    late FakeBiometricGate gate;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      gate = FakeBiometricGate();
    });

    Future<ProviderContainer> pumpWatcher(WidgetTester tester) async {
      final container = ProviderContainer.test(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          biometricGateProvider.overrideWithValue(gate),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: AppLockWatcher(child: Text('παιδί')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('OFF → pause/resume χωρίς επίπτωση', (tester) async {
      final container = await pumpWatcher(tester);
      // Έγκυρη ακολουθία (assert framework 3.47):
      // paused → hidden → inactive → resumed.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(container.read(appLockProvider).locked, isFalse);
      expect(find.text('παιδί'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ON + άμεση επιστροφή → παραμένει ξεκλείδωτη', (tester) async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      final container = await pumpWatcher(tester);
      await container.read(appLockProvider.notifier).unlock('reason');
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(container.read(appLockProvider).locked, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ON + hide→show (desktop minimize, F3) → χωρίς επίπτωση',
        (tester) async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      final container = await pumpWatcher(tester);
      await container.read(appLockProvider.notifier).unlock('reason');
      await tester.pumpAndSettle();
      // Έγκυρη ακολουθία (assert 3.47 — hidden→resumed κατευθείαν άκυρο):
      // onHide + onShow πυροδοτούνται ενδιάμεσα, η άμεση επιστροφή δεν
      // κλειδώνει (χάρη — ίδιος κώδικας με pause/resume).
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(container.read(appLockProvider).locked, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('launch με ON → κλειδωμένη (build, zero-flash)',
        (tester) async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      final container = await pumpWatcher(tester);
      expect(container.read(appLockProvider).locked, isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}
