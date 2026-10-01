/// Providers κλειδώματος εφαρμογής (§2.3 · 30-09-2026).
///
/// Ξεχωριστό αρχείο (όχι στο `settings_providers.dart`): εκείνο είναι 411
/// γρ. και ο controller θέλει ~90 — θα έσπαγε τον κανόνα 7 (<500).
/// Import ΜΟΝΟ από `settings_providers` (το repository) — καμία κυκλικότητα.
/// NON-autoDispose (σύμβαση DI δέντρου).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_errors.dart';
import '../../core/logging/app_logger.dart';
import '../services/biometric_gate.dart';
import 'settings_providers.dart';

/// Κατάσταση κλειδώματος: persisted `enabled` + session `locked`
/// (plain record — pattern `PeriodPurchasesData`, όχι Freezed).
typedef AppLockState = ({bool enabled, bool locked});

/// Κανόνας χάριτος Q2 (pure — unit-testable χωρίς widgets): επιστροφή
/// μετά από [AppConstants.appLockGraceSeconds] ή παραπάνω → κλείδωμα.
/// Όριο inclusive (`>=` — στα ακριβώς 30'' κλειδώνει, τεκμηριωμένο).
bool shouldRelock({required DateTime pausedAt, required DateTime now}) =>
    now.difference(pausedAt).inSeconds >=
    AppConstants.appLockGraceSeconds;

/// SPoT gate — production impl εδώ, override με fake στα tests (pattern
/// `backupFilePickerProvider`).
final biometricGateProvider = Provider<BiometricGate>(
  (ref) => LocalAuthBiometricGate(),
);

/// Υποστήριξη ελέγχου στη συσκευή (Q4: κρυφή κάρτα όταν `false`).
/// One-shot FutureProvider — η δυνατότητα δεν αλλάζει εν πτήσει.
final appLockSupportProvider = FutureProvider<bool>(
  (ref) => ref.watch(biometricGateProvider).isSupported(),
);

/// Controller κλειδώματος — plain Notifier (pattern `ThemeModeController`):
/// σύγχρονο state + async auth/save με δική τους μεταχείριση σφαλμάτων.
/// NON-autoDispose.
final appLockProvider = NotifierProvider<AppLockController, AppLockState>(
  AppLockController.new,
);

/// Controller κλειδώματος — βλ. `appLockProvider`.
class AppLockController extends Notifier<AppLockState> {
  /// Σύγχρονο read (pattern theme): enabled από prefs· fresh launch με
  /// enabled → locked (zero-flash — κανένα frame με ορατά δεδομένα,
  /// review fix 23-09). Σφάλμα → ξεκλείδωτη (fail-open στο read· το
  /// κλείδωμα δεν μπλοκάρει ποτέ την εκκίνηση από σφάλμα prefs).
  @override
  AppLockState build() {
    try {
      final enabled =
          ref.read(settingsRepositoryProvider).readAppLockEnabled();
      return (enabled: enabled, locked: enabled);
    } catch (e, s) {
      AppLogger.error(
        LogTag.ui,
        'Ανάγνωση κλειδώματος απέτυχε — ξεκλείδωτη',
        e,
        s,
      );
      return (enabled: false, locked: false);
    }
  }

  /// Αίτημα ενεργοποίησης: auth ΠΡΙΝ το persist (proof-of-capability —
  /// αποκλείει «το άναψα και δεν δουλεύει»). Επιστρέφει record για το
  /// `runControllerOp` (pattern editors §2.3): ok → success snackbar·
  /// error → error snackbar· (false, null) = ακύρωση χρήστη → σιωπή.
  /// Η συνεδρία μένει ξεκλείδωτη (μόλις αποδείχτηκε ταυτότητα — το
  /// κλείδωμα πιάνει σε επόμενο launch/background, αλλιώς το overlay θα
  /// ξαναπετούσε δακτυλικό αμέσως, fix 30-09).
  Future<({bool ok, String? error})> requestEnable(String reason) async {
    if (state.enabled) return (ok: false, error: null);
    final auth = await _auth(reason);
    if (!ref.mounted) return (ok: false, error: null);
    if (!auth.ok) return auth;
    state = (enabled: true, locked: false);
    AppLogger.info(LogTag.ui, 'Κλείδωμα εφαρμογής: ON');
    unawaited(_save(true));
    return (ok: true, error: null);
  }

  /// Αίτημα απενεργοποίησης: auth ΠΡΙΝ (αλλιώς ο κάτοχος της συσκευής
  /// θα το έσβηνε χωρίς έλεγχο). Ήδη OFF → σιωπηλό no-op.
  Future<({bool ok, String? error})> requestDisable(String reason) async {
    if (!state.enabled) return (ok: false, error: null);
    final auth = await _auth(reason);
    if (!ref.mounted) return (ok: false, error: null);
    if (!auth.ok) return auth;
    state = (enabled: false, locked: false);
    AppLogger.info(LogTag.ui, 'Κλείδωμα εφαρμογής: OFF');
    unawaited(_save(false));
    return (ok: true, error: null);
  }

  /// Ξεκλείδωμα συνεδρίας (overlay). Επιτυχία → `locked=false`.
  Future<({bool ok, String? error})> unlock(String reason) async {
    if (!state.enabled || !state.locked) return (ok: false, error: null);
    final auth = await _auth(reason);
    if (!ref.mounted) return (ok: false, error: null);
    if (!auth.ok) return auth;
    state = (enabled: true, locked: false);
    AppLogger.info(LogTag.ui, 'Εφαρμογή ξεκλειδώθηκε');
    return (ok: true, error: null);
  }

  /// Κλείδωμα από τον watcher (λήξη χάριτος — σύγχρονο, χωρίς auth).
  /// Ήδη κλειδωμένη ή OFF → no-op.
  void lock() {
    if (!state.enabled || state.locked) return;
    state = (enabled: true, locked: true);
    AppLogger.info(LogTag.ui, 'Εφαρμογή κλειδώθηκε (background)');
  }

  /// Ταυτοποίηση με ορατά σφάλματα (fix 30-09): `userCanceled` → σιωπή·
  /// κάθε άλλο `LocalAuthException` code → log με code + `appLockFailed`
  /// (ο κωδικός φαίνεται στο debug log για διάγνωση συσκευής).
  Future<({bool ok, String? error})> _auth(String reason) async {
    try {
      final ok = await ref.read(biometricGateProvider).authenticate(reason);
      return (ok: ok, error: null);
    } on LocalAuthException catch (e, s) {
      if (e.code == LocalAuthExceptionCode.userCanceled) {
        return (ok: false, error: null);
      }
      AppLogger.error(
        LogTag.ui,
        'Ταυτοποίηση απέτυχε (${e.code.name})',
        e,
        s,
      );
      return (ok: false, error: AppErrors.appLockFailed);
    } catch (e, s) {
      AppLogger.error(LogTag.ui, 'Ταυτοποίηση απέτυχε', e, s);
      return (ok: false, error: AppErrors.appLockFailed);
    }
  }

  Future<void> _save(bool enabled) async {
    if (!ref.mounted) return;
    try {
      await ref.read(settingsRepositoryProvider).saveAppLockEnabled(enabled);
    } catch (e, s) {
      AppLogger.error(LogTag.ui, 'Αποθήκευση κλειδώματος απέτυχε', e, s);
    }
  }
}
