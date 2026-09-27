/// Test helper — fake `path_provider` πάνω σε temp dir (Φάση 4 Βήμα 5).
///
/// Τα backup tests χρειάζονται `getApplicationDocumentsDirectory()` χωρίς
/// platform channel (το flutter_test δεν έχει native). `extends` +
/// `MockPlatformInterfaceMixin` (όχι `implements` — το plugin_platform
/// το απαγορεύει με assertion). Μηδέν νέα runtime packages.
/// Χρήση (setUpAll/tearDownAll του καλούντος):
/// ```dart
/// late Directory tmpRoot;
/// setUpAll(() {
///   tmpRoot = Directory.systemTemp.createTempSync('backup_test_');
///   PathProviderPlatform.instance = FakePathProvider(tmpRoot.path);
/// });
/// tearDownAll(() => tmpRoot.deleteSync(recursive: true));
/// ```
/// (Απομονωμένο ανά test-file isolate — δεν επηρεάζει άλλα tests.)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Fake `PathProviderPlatform` — documents + temp δείχνουν στο [root].
/// Οι υπόλοιπες μέθοδοι ρίχνουν (default) — δεν καλούνται από το Βήμα 5.
final class FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getTemporaryPath() async => root;
}
