/// Unit tests — `BackupService` (domain/services · Φάση 4 Βήμα 5, §2.3).
///
/// File-backed temp DBs (όχι in-memory: το `VACUUM INTO` αποτυγχάνει σε
/// `:memory:`) + `FakePathProvider` (χωρίς platform channel). Καμία
/// εξάρτηση από UI/Riverpod — καθαρό service.
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/domain/services/backup_service.dart';

import '../../helpers/fake_path_provider.dart';

void main() {
  late Directory tmpRoot;
  final List<AppDatabase> openDbs = [];

  setUpAll(() {
    tmpRoot = Directory.systemTemp.createTempSync('backup_service_test_');
    PathProviderPlatform.instance = FakePathProvider(tmpRoot.path);
  });

  tearDownAll(() {
    try {
      tmpRoot.deleteSync(recursive: true);
    } catch (_) {
      // Windows file-handle best-effort (house precedent seed test).
    }
  });

  setUp(() => openDbs.clear());

  tearDown(() async {
    for (final db in openDbs) {
      await db.closeSafely();
    }
  });

  /// File-backed βάση με σχήμα (skipSeed — άδειοι πίνακες, έγκυρο schema).
  AppDatabase openFileDb(String name) {
    final db = AppDatabase(
      executor: NativeDatabase(File('${tmpRoot.path}/$name')),
      skipSeed: true,
    );
    openDbs.add(db);
    return db;
  }

  group('BackupService.buildBackupFileName', () {
    test('pattern + timestamp + .sqlite (SPoT pattern §2.3)', () {
      expect(
        BackupService.buildBackupFileName(DateTime(2026, 9, 24, 21, 5, 7)),
        'times_backup_20260924_210507.sqlite',
      );
    });

    test('pad μονοψήφιων (μήνας/ώρα)', () {
      expect(
        BackupService.buildBackupFileName(DateTime(2026, 3, 5, 4, 7, 9)),
        'times_backup_20260305_040709.sqlite',
      );
    });
  });

  group('BackupService snapshots', () {
    test('exportSnapshot → αρχείο + validate ΟΚ', () async {
      final db = openFileDb('a.sqlite');
      await db.into(db.categories).insert(
            CategoriesCompanion.insert(name: 'ΤΡΟΦΙΜΑ'),
          );
      final service = BackupService(db);
      final target = '${tmpRoot.path}/snap.sqlite';
      await service.exportSnapshot(target);
      expect(File(target).existsSync(), isTrue);
      await service.validateBackupFile(target);
    });

    test('exportSnapshot σε ανύπαρκτο φάκελο → BackupCreationException', () {
      final db = openFileDb('b.sqlite');
      final service = BackupService(db);
      expect(
        service.exportSnapshot('${tmpRoot.path}/no_dir_xyz/snap.sqlite'),
        throwsA(isA<BackupCreationException>()),
      );
    });

    test('autoBackupCurrent → auto_ αρχείο στο docs', () async {
      final db = openFileDb('c.sqlite');
      final service = BackupService(db);
      final path = await service.autoBackupCurrent();
      expect(path.contains('auto_times_backup_'), isTrue);
      expect(File(path).existsSync(), isTrue);
    });

    test('replaceDatabaseFile → docs/times.sqlite με περιεχόμενο πηγής',
        () async {
      final dbA = openFileDb('ra.sqlite');
      await dbA.into(dbA.categories).insert(
            CategoriesCompanion.insert(name: 'ALPHA'),
          );
      final serviceA = BackupService(dbA);
      final snap = '${tmpRoot.path}/ra_snap.sqlite';
      await serviceA.exportSnapshot(snap);
      await serviceA.replaceDatabaseFile(snap);
      final target = File('${tmpRoot.path}/times.sqlite');
      expect(target.existsSync(), isTrue);
      final reopened = AppDatabase(
        executor: NativeDatabase(target),
        skipSeed: true,
      );
      openDbs.add(reopened);
      final cats = await reopened.select(reopened.categories).get();
      expect(cats.map((c) => c.name), contains('ALPHA'));
    });
  });

  group('BackupService.validateBackupFile', () {
    test('ανύπαρκτο αρχείο → InvalidBackupFileException (καμία αλλαγή)', () {
      final db = openFileDb('v.sqlite');
      final service = BackupService(db);
      expect(
        service.validateBackupFile('${tmpRoot.path}/missing.sqlite'),
        throwsA(isA<InvalidBackupFileException>()),
      );
    });

    test('non-sqlite αρχείο → InvalidBackupFileException', () async {
      final db = openFileDb('w.sqlite');
      final service = BackupService(db);
      final junk = File('${tmpRoot.path}/junk.txt');
      await junk.writeAsString('δεν είναι βάση');
      expect(
        service.validateBackupFile(junk.path),
        throwsA(isA<InvalidBackupFileException>()),
      );
    });

    test('sqlite με λάθος πίνακες → InvalidBackupFileException', () {
      final db = openFileDb('x.sqlite');
      final service = BackupService(db);
      final thin = '${tmpRoot.path}/thin.sqlite';
      final raw = sqlite3.open(thin, mode: OpenMode.readWriteCreate);
      raw.execute('CREATE TABLE notes (id INTEGER PRIMARY KEY)');
      raw.close();
      expect(
        service.validateBackupFile(thin),
        throwsA(isA<InvalidBackupFileException>()),
      );
    });
  });
}
