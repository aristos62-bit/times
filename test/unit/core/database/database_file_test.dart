import 'dart:io';

import 'package:expense_tracker/core/constants/app_constants.dart';
import 'package:expense_tracker/core/database/database_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Fake υλοποίηση του path_provider που επιστρέφει τον system temp folder,
/// ώστε το test να μην εξαρτάται από πραγματικό plugin channel.
class _FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      Directory.systemTemp.path;
}

void main() {
  final originalInstance = PathProviderPlatform.instance;

  setUp(() {
    PathProviderPlatform.instance = _FakePathProviderPlatform();
  });

  tearDown(() {
    PathProviderPlatform.instance = originalInstance;
  });

  group('resolveDatabaseFile', () {
    test('επιστρέφει File με absolute path', () async {
      final file = await resolveDatabaseFile();
      expect(file.isAbsolute, isTrue);
    });

    test('το όνομα αρχείου ταυτίζεται με AppConstants.dbName', () async {
      final file = await resolveDatabaseFile();
      expect(p.basename(file.path), AppConstants.dbName);
    });

    test('ο γονικός φάκελος του DB υπάρχει', () async {
      final file = await resolveDatabaseFile();
      expect(file.parent.existsSync(), isTrue);
    });

    test('οι διαδοχικές κλήσεις επιστρέφουν ίδιο μονοπάτι (deterministic)', () async {
      final first = await resolveDatabaseFile();
      final second = await resolveDatabaseFile();
      expect(first.path, second.path);
    });
  });
}