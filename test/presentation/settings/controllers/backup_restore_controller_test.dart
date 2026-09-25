/// Tests `BackupRestoreController` — ProviderContainer με file-backed DB +
/// fake picker + FakePathProvider (Φάση 4 Βήμα 5, §2.3). Χωρίς FakeAsync:
/// real IO σε temp files, κανένα pending timer.
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/providers/backup_file_picker.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/providers/settings_providers.dart';
import 'package:times/domain/services/backup_service.dart';
import 'package:times/presentation/price_entry/controllers/receipt_form_controller.dart';
import 'package:times/presentation/settings/controllers/backup_restore_controller.dart';

import '../../../helpers/fake_path_provider.dart';

/// Fake picker — προγραμματιζόμενο save/pick αποτέλεσμα.
final class FakeBackupPicker implements BackupFilePicker {
  bool saveResult = true;
  bool throwOnSave = false;
  String? lastFileName;
  List<int>? lastBytes;

  @override
  Future<bool> saveBytes({
    required String fileName,
    required List<int> bytes,
  }) async {
    if (throwOnSave) throw Exception('picker boom');
    lastFileName = fileName;
    lastBytes = bytes;
    return saveResult;
  }

  @override
  Future<String?> pickSingleFile() async => null;
}

void main() {
  late Directory tmpRoot;
  late AppDatabase db;
  late FakeBackupPicker picker;
  late ProviderContainer container;
  var n = 0;

  setUpAll(() {
    tmpRoot = Directory.systemTemp.createTempSync('backup_ctrl_test_');
    PathProviderPlatform.instance = FakePathProvider(tmpRoot.path);
  });

  tearDownAll(() async {
    // Windows κρατά καμιά φορά το file handle (house precedent seed test:
    // καθαρισμός best-effort, χωρίς flaky αποτυχία).
    for (var i = 0; i < 3; i++) {
      try {
        tmpRoot.deleteSync(recursive: true);
        return;
      } on PathAccessException {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }
    try {
      tmpRoot.deleteSync(recursive: true);
    } catch (_) {
      // Best-effort (βλ. seed_database_test).
    }
  });

  setUp(() {
    db = AppDatabase(
      executor: NativeDatabase(File('${tmpRoot.path}/c${n++}.sqlite')),
      skipSeed: true,
    );
    picker = FakeBackupPicker();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        backupFilePickerProvider.overrideWithValue(picker),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    return db.closeSafely();
  });

  BackupRestoreController controller() =>
      container.read(backupRestoreControllerProvider.notifier);

  group('BackupRestoreController.exportBackup', () {
    test('επιτυχία → ok + filename.sqlite + bytes', () async {
      final result = await controller().exportBackup();
      expect(result.ok, isTrue);
      expect(picker.lastFileName, endsWith('.sqlite'));
      expect(picker.lastFileName, startsWith('times_backup_'));
      expect(picker.lastBytes, isNotEmpty);
      expect(
        container.read(backupRestoreControllerProvider).isWorking,
        isFalse,
      );
    });

    test('ακύρωση picker → (ok:false, error:null), χωρίς snackbar-λόγο', () async {
      picker.saveResult = false;
      final result = await controller().exportBackup();
      expect(result.ok, isFalse);
      expect(result.error, isNull);
    });

    test('σφάλμα picker → BackupCreationException (isWorking σβήνει)', () async {
      picker.throwOnSave = true;
      await expectLater(
        controller().exportBackup(),
        throwsA(isA<BackupCreationException>()),
      );
      expect(
        container.read(backupRestoreControllerProvider).isWorking,
        isFalse,
      );
    });
  });

  group('BackupRestoreController.validateCandidate', () {
    test('άκυρο path → (ok:false, error:invalidBackupFile)', () async {
      final result = await controller().validateCandidate(
        '${tmpRoot.path}/missing.sqlite',
      );
      expect(result.ok, isFalse);
      expect(result.error, isNotNull);
    });

    test('έγκυρο snapshot → (ok:true)', () async {
      final service = BackupService(db);
      final snap = '${tmpRoot.path}/cand.sqlite';
      await service.exportSnapshot(snap);
      final result = await controller().validateCandidate(snap);
      expect(result.ok, isTrue);
    });
  });

  group('BackupRestoreController.restoreBackup', () {
    test('επιτυχία → ok + auto-backup + reset φόρμας', () async {
      final service = BackupService(db);
      final snap = '${tmpRoot.path}/rest.sqlite';
      await service.exportSnapshot(snap);

      final result = await controller().restoreBackup(snap);
      expect(result.ok, isTrue);
      // Auto-backup δημιουργήθηκε στο (fake) docs.
      final autos = tmpRoot
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('auto_times_backup_'))
          .toList();
      expect(autos, isNotEmpty);
      // Φόρμα μηδενισμένη (stale ids θα έσκαγαν σε FK).
      final form = container.read(receiptFormControllerProvider);
      expect(form.supplier, isNull);
      expect(form.draftLines, isEmpty);
      expect(form.editingId, isNull);
    });

    test('άκυρο αρχείο → InvalidBackupFileException, βάση ΑΝΟΙΧΤΗ', () async {
      await expectLater(
        controller().restoreBackup('${tmpRoot.path}/missing.sqlite'),
        throwsA(isA<InvalidBackupFileException>()),
      );
      // Η βάση δεν έκλεισε (abort πριν το close — καμία απώλεια).
      final cats = await db.select(db.categories).get();
      expect(cats, isEmpty);
    });
  });
}
