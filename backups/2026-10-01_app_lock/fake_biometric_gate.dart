/// Scripted fake `BiometricGate` για tests (χωρίς platform channel).
///
/// Το `local_auth` δεν pumpάρεται — όλα τα app-lock tests (controller +
/// widgets) δουλεύουν πάνω σε αυτό (pattern `FakeStatsPicker`).
library;

import 'package:local_auth/local_auth.dart';

import 'package:times/data/services/biometric_gate.dart';

/// Fake με ουρά αποτελεσμάτων + καταγραφή reasons + προαιρετικό throw.
class FakeBiometricGate implements BiometricGate {
  FakeBiometricGate({
    this.supported = true,
    List<bool>? authResults,
    this.throwCode,
  }) : _authResults = List.of(authResults ?? const [true]);

  bool supported;
  final List<bool> _authResults;

  /// Όταν ορίζεται, το `authenticate` ρίχνει `LocalAuthException` με αυτό
  /// το code (σφάλμα πλατφόρμας — όχι ακύρωση χρήστη).
  final LocalAuthExceptionCode? throwCode;
  final List<String> reasons = [];

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<bool> authenticate(String reason) async {
    reasons.add(reason);
    final code = throwCode;
    if (code != null) {
      throw LocalAuthException(code: code, description: 'test');
    }
    return _authResults.length == 1
        ? _authResults.single
        : _authResults.removeAt(0);
  }
}
