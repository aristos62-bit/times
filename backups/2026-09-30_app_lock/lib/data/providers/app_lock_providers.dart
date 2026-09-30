/// Providers κλειδώματος εφαρμογής (§2.3 · 30-09-2026).
///
/// Ξεχωριστό αρχείο (όχι στο `settings_providers.dart`): εκείνο είναι 411
/// γρ. και ο controller θέλει ~90 — θα έσπαγε τον κανόνα 7 (<500).
/// Import ΜΟΝΟ από `settings_providers` (το repository) — καμία κυκλικότητα.
/// NON-autoDispose (σύμβαση DI δέντρου).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
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
  /// αποκλείει «το άναψα και δεν δουλεύει»). Αποτυχία/ακύρωση → όλα
  /// αμετάβλητα, μόνο log (pattern `ThemeModeController._save`).
  Future<void> requestEnable(String reason) async {
    if (state.enabled) return;
    if (!await _auth(reason) || !ref.mounted) return;
    state = (enabled: true, locked: true);
    AppLogger.info(LogTag.ui, 'Κλείδωμα εφαρμογής: ON');
    unawaited(_save(true));
  }

  /// Αίτημα απενεργοποίησης: auth ΠΡΙΝ (αλλιώς ο κάτοχος της συσκευής
  /// θα το έσβηνε χωρίς έλεγχο). Ήδη OFF → no-op.
  Future<void> requestDisable(String reason) async {
    if (!state.enabled) return;
    if (!await _auth(reason) || !ref.mounted) return;
    state = (enabled: false, locked: false);
    AppLogger.info(LogTag.ui, 'Κλείδωμα εφαρμογής: OFF');
    unawaited(_save(false));
  }

  /// Ξεκλείδωμα συνεδρίας (overlay). Επιτυχία → `locked=false`.
  Future<void> unlock(String reason) async {
    if (!state.enabled || !state.locked) return;
    if (!await _auth(reason) || !ref.mounted) return;
    state = (enabled: true, locked: false);
    AppLogger.info(LogTag.ui, 'Εφαρμογή ξεκλειδώθηκε');
  }

  /// Κλείδωμα από τον watcher (λήξη χάριτος — σύγχρονο, χωρίς auth).
  /// Ήδη κλειδωμένη ή OFF → no-op.
  void lock() {
    if (!state.enabled || state.locked) return;
    state = (enabled: true, locked: true);
    AppLogger.info(LogTag.ui, 'Εφαρμογή κλειδώθηκε (background)');
  }

  Future<bool> _auth(String reason) async {
    try {
      return await ref.read(biometricGateProvider).authenticate(reason);
    } catch (e, s) {
      AppLogger.error(LogTag.ui, 'Ταυτοποίηση απέτυχε', e, s);
      return false;
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
