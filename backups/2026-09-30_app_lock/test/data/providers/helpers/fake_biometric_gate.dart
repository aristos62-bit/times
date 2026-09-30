/// Scripted fake `BiometricGate` για tests (χωρίς platform channel).
///
/// Το `local_auth` δεν pumpάρεται — όλα τα app-lock tests (controller +
/// widgets) δουλεύουν πάνω σε αυτό (pattern `FakeStatsPicker`).
library;

import 'package:times/data/services/biometric_gate.dart';

/// Fake με ουρά αποτελεσμάτων + καταγραφή reasons.
class FakeBiometricGate implements BiometricGate {
  FakeBiometricGate({this.supported = true, List<bool>? authResults})
      : _authResults = List.of(authResults ?? const [true]);

  bool supported;
  final List<bool> _authResults;
  final List<String> reasons = [];

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<bool> authenticate(String reason) async {
    reasons.add(reason);
    return _authResults.length == 1
        ? _authResults.single
        : _authResults.removeAt(0);
  }
}
