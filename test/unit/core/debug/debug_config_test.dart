import 'package:expense_tracker/core/debug/debug_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DebugConfig', () {
    test('isDebug true στα tests', () {
      expect(DebugConfig.isDebug, isTrue);
    });

    test('group flags', () {
      expect(DebugConfig.showDbLogs, isTrue);
      expect(DebugConfig.showBlocLogs, isTrue);
      expect(DebugConfig.showNetworkLogs, isTrue);
      expect(DebugConfig.showPerformanceLogs, isTrue);
      expect(DebugConfig.showNavigationLogs, isFalse);
    });

    test('thresholds', () {
      expect(
        DebugConfig.slowQueryThreshold,
        const Duration(milliseconds: 500),
      );
      expect(
        DebugConfig.slowBuildThreshold,
        const Duration(milliseconds: 16),
      );
    });
  });
}
