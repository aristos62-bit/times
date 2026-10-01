/// Unit tests — `AppLockController` + support provider (§2.3 · 30-09-2026).
///
/// Scripted fake gate + mock prefs — κανένα platform channel (το
/// `local_auth` δεν pumpάρεται, γι' αυτό υπάρχει το wrapper).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:times/core/constants/app_constants.dart';
import 'package:times/core/constants/app_errors.dart';
import 'package:times/data/providers/app_lock_providers.dart';
import 'package:times/data/providers/settings_providers.dart';

import 'helpers/fake_biometric_gate.dart';

void main() {
  late SharedPreferences prefs;
  late FakeBiometricGate gate;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    gate = FakeBiometricGate();
  });

  ProviderContainer container() => ProviderContainer.test(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          biometricGateProvider.overrideWithValue(gate),
        ],
      );

  /// Το unawaited `_save` του controller προλαβαίνει με ένα microtask —
  /// τα mock prefs είναι in-memory (ντετερμινιστικό).
  Future<void> settleSave() =>
      Future<void>.delayed(const Duration(milliseconds: 10));

  group('AppLockController (§2.3 · 30-09-2026)', () {
    test('build χωρίς τιμή → disabled + unlocked', () {
      final c = container();
      addTearDown(c.dispose);
      expect(c.read(appLockProvider), (enabled: false, locked: false));
    });

    test('build με enabled → locked (zero-flash)', () async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      final c = container();
      addTearDown(c.dispose);
      expect(c.read(appLockProvider), (enabled: true, locked: true));
    });

    test('requestEnable ok → enabled+ξεκλείδωτη+persisted', () async {
      final c = container();
      addTearDown(c.dispose);
      final result =
          await c.read(appLockProvider.notifier).requestEnable('reason');
      expect(result, (ok: true, error: null));
      // Η συνεδρία μένει ξεκλείδωτη (μόλις έγινε auth — το overlay θα
      // ξαναπετούσε δακτυλικό αμέσως, fix 30-09).
      expect(c.read(appLockProvider), (enabled: true, locked: false));
      await settleSave();
      expect(prefs.getBool(AppConstants.appLockEnabledKey), isTrue);
      expect(gate.reasons, ['reason']);
    });

    test('requestEnable fail → αμετάβλητο + όχι persist', () async {
      gate = FakeBiometricGate(authResults: const [false]);
      final c = container();
      addTearDown(c.dispose);
      final result =
          await c.read(appLockProvider.notifier).requestEnable('reason');
      expect(result, (ok: false, error: null));
      expect(c.read(appLockProvider), (enabled: false, locked: false));
      expect(prefs.containsKey(AppConstants.appLockEnabledKey), isFalse);
    });

    test('requestEnable σφάλμα πλατφόρμας → error (ορατό)', () async {
      gate = FakeBiometricGate(
        throwCode: LocalAuthExceptionCode.noBiometricsEnrolled,
      );
      final c = container();
      addTearDown(c.dispose);
      final result =
          await c.read(appLockProvider.notifier).requestEnable('reason');
      expect(result, (ok: false, error: AppErrors.appLockFailed));
      expect(c.read(appLockProvider), (enabled: false, locked: false));
    });

    test('requestEnable userCanceled → σιωπή (null)', () async {
      gate = FakeBiometricGate(
        throwCode: LocalAuthExceptionCode.userCanceled,
      );
      final c = container();
      addTearDown(c.dispose);
      final result =
          await c.read(appLockProvider.notifier).requestEnable('reason');
      expect(result, (ok: false, error: null));
      expect(c.read(appLockProvider), (enabled: false, locked: false));
    });

    test('requestEnable ενώ enabled → no-op (χωρίς auth)', () async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      final c = container();
      addTearDown(c.dispose);
      await c.read(appLockProvider.notifier).requestEnable('reason');
      expect(gate.reasons, isEmpty);
    });

    test('requestDisable ok → off + persisted', () async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      final c = container();
      addTearDown(c.dispose);
      final result =
          await c.read(appLockProvider.notifier).requestDisable('reason');
      expect(result, (ok: true, error: null));
      expect(c.read(appLockProvider), (enabled: false, locked: false));
      await settleSave();
      expect(prefs.getBool(AppConstants.appLockEnabledKey), isFalse);
    });

    test('requestDisable fail → παραμένει enabled+locked', () async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      gate = FakeBiometricGate(authResults: const [false]);
      final c = container();
      addTearDown(c.dispose);
      final result =
          await c.read(appLockProvider.notifier).requestDisable('reason');
      expect(result, (ok: false, error: null));
      expect(c.read(appLockProvider), (enabled: true, locked: true));
    });

    test('requestDisable σφάλμα πλατφόρμας → error (ορατό)', () async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      gate = FakeBiometricGate(
        throwCode: LocalAuthExceptionCode.temporaryLockout,
      );
      final c = container();
      addTearDown(c.dispose);
      final result =
          await c.read(appLockProvider.notifier).requestDisable('reason');
      expect(result, (ok: false, error: AppErrors.appLockFailed));
      expect(c.read(appLockProvider), (enabled: true, locked: true));
    });

    test('unlock ok → locked=false', () async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      final c = container();
      addTearDown(c.dispose);
      final result =
          await c.read(appLockProvider.notifier).unlock('reason');
      expect(result, (ok: true, error: null));
      expect(c.read(appLockProvider), (enabled: true, locked: false));
    });

    test('unlock fail → παραμένει locked', () async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      gate = FakeBiometricGate(authResults: const [false]);
      final c = container();
      addTearDown(c.dispose);
      final result =
          await c.read(appLockProvider.notifier).unlock('reason');
      expect(result, (ok: false, error: null));
      expect(c.read(appLockProvider), (enabled: true, locked: true));
    });

    test('unlock σφάλμα πλατφόρμας → error (ορατό)', () async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      gate = FakeBiometricGate(
        throwCode: LocalAuthExceptionCode.noCredentialsSet,
      );
      final c = container();
      addTearDown(c.dispose);
      final result =
          await c.read(appLockProvider.notifier).unlock('reason');
      expect(result, (ok: false, error: AppErrors.appLockFailed));
      expect(c.read(appLockProvider), (enabled: true, locked: true));
    });

    test('hang native → timeout SPoT → error (F1 · 01-10)', () async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      gate = FakeBiometricGate(hangAuth: true);
      fakeAsync((f) {
        final c = container();
        addTearDown(c.dispose);
        var done = false;
        late ({bool ok, String? error}) result;
        c.read(appLockProvider.notifier).unlock('reason').then((r) {
          result = r;
          done = true;
        });
        f.flushMicrotasks();
        expect(done, isFalse);
        f.elapse(
          Duration(seconds: AppConstants.appLockAuthTimeoutSeconds + 1),
        );
        f.flushMicrotasks();
        expect(done, isTrue);
        expect(result, (ok: false, error: AppErrors.appLockFailed));
      });
    });

    test('lock() → locked (sync, χωρίς auth)', () async {
      await prefs.setBool(AppConstants.appLockEnabledKey, true);
      final c = container();
      addTearDown(c.dispose);
      final notifier = c.read(appLockProvider.notifier);
      await notifier.unlock('reason');
      notifier.lock();
      expect(c.read(appLockProvider), (enabled: true, locked: true));
      expect(gate.reasons, hasLength(1)); // μόνο το unlock
    });

    test('lock() ενώ OFF → no-op', () {
      final c = container();
      addTearDown(c.dispose);
      c.read(appLockProvider.notifier).lock();
      expect(c.read(appLockProvider), (enabled: false, locked: false));
    });
  });

  group('appLockSupportProvider', () {
    test('supported → true', () async {
      final c = container();
      addTearDown(c.dispose);
      expect(await c.read(appLockSupportProvider.future), isTrue);
    });

    test('unsupported → false (κρυφή κάρτα, Q4)', () async {
      gate = FakeBiometricGate(supported: false);
      final c = container();
      addTearDown(c.dispose);
      expect(await c.read(appLockSupportProvider.future), isFalse);
    });
  });
}
