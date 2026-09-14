/// Unit tests για το SPoT `DebugConfig` (core/debug/debug_config.dart) — §1.7.
///
/// Στο test environment το `kDebugMode` είναι πάντα true, οπότε ελέγχουμε:
/// ενεργά tags, `forceDisable` (release-like) και `reset`. Πάντα tearDown reset.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/debug/debug_config.dart';

void main() {
  group('DebugConfig', () {
    // Κάθε test ξεκινά από καθαρή κατάσταση (κανένα forceDisable).
    tearDown(DebugConfig.reset);

    test('isTagEnabled=true για όλα τα tags σε debug mode', () {
      for (final tag in LogTag.values) {
        expect(DebugConfig.isTagEnabled(tag), isTrue, reason: tag.name);
      }
    });

    test('forceDisable → κανένα tag ενεργό (release-like)', () {
      DebugConfig.forceDisable();

      for (final tag in LogTag.values) {
        expect(DebugConfig.isTagEnabled(tag), isFalse, reason: tag.name);
      }
    });

    test('reset επαναφέρει τα tags σε ενεργά', () {
      DebugConfig.forceDisable();
      DebugConfig.reset();

      expect(DebugConfig.isTagEnabled(LogTag.db), isTrue);
      expect(DebugConfig.isTagEnabled(LogTag.backup), isTrue);
    });

    test('enabledTags περιέχει ακριβώς τα 5 tags του §1.7', () {
      expect(DebugConfig.enabledTags, LogTag.values.toSet());
    });
  });
}