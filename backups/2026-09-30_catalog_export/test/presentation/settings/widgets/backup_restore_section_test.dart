/// Widget tests — `BackupRestoreSection` (Φάση 4 Βήμα 5, §2.3).
///
/// Ελάχιστο scope (μόνο το section): ProviderScope με file-backed DB + fake
/// picker + FakePathProvider. ΣΚΟΠΙΜΑ μόνο isolate-free διαδρομές (εύρημα Ε2
/// Βήματος 4 — drift background isolate + widget fake-async = hang): τα
/// submit flows (export/restore με VACUUM) καλύπτονται από το controller test
/// (real async). Εδώ: wiring κουμπιών, pick-cancel, invalid→error,
/// valid→dialog, dialog-cancel. Pump-σύμβαση: σκέτο `pump` με snackbar
/// (4s timer μπλοκάρει το settle)· dialogs κάνουν settle κανονικά.
/// Responsive §1.4 (3 μεγέθη) + dark (§1.5, πρότυπο V12). Χωρίς FakeAsync.
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:times/core/constants/app_errors.dart';
import 'package:times/core/constants/app_messages.dart';
import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/providers/backup_file_picker.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/providers/settings_providers.dart';
import 'package:times/domain/services/backup_service.dart';
import 'package:times/presentation/settings/widgets/backup_restore_section.dart';

import '../../../helpers/fake_path_provider.dart';

/// Fake picker με προγραμματιζόμενα αποτελέσματα.
final class FakeBackupPicker implements BackupFilePicker {
  bool saveResult = true;
  String? pickPath;

  @override
  Future<bool> saveBytes({
    required String fileName,
    required List<int> bytes,
  }) async => saveResult;

  @override
  Future<String?> pickSingleFile() async => pickPath;
}

void main() {
  late Directory tmpRoot;
  late AppDatabase db;
  late FakeBackupPicker picker;
  var n = 0;

  setUpAll(() {
    tmpRoot = Directory.systemTemp.createTempSync('backup_section_test_');
    PathProviderPlatform.instance = FakePathProvider(tmpRoot.path);
  });

  tearDownAll(() async {
    // Windows file-handle best-effort (house precedent seed test).
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
      executor: NativeDatabase(File('${tmpRoot.path}/s${n++}.sqlite')),
      skipSeed: true,
    );
    picker = FakeBackupPicker();
  });

  tearDown(() => db.closeSafely());

  Widget wrap({ThemeData? theme}) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        backupFilePickerProvider.overrideWithValue(picker),
      ],
      child: MaterialApp(
        theme: theme,
        home: const Scaffold(body: BackupRestoreSection()),
      ),
    );
  }

  Future<void> pumpAt(WidgetTester tester, Size size, {ThemeData? theme}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap(theme: theme));
    await tester.pumpAndSettle();
  }

  /// Χτίζει έγκυρο fixture αντιγράφου με ΣΥΓΧΡΟΝΟ sqlite3 FFI (όχι drift:
  /// το drift worker isolate κρατά Windows locks που κολλάνε το widget
  /// fake-async). Οι 7 πίνακες §3, άδειοι αρκούν για το validation.
  String makeFixture(String name) {
    final path = '${tmpRoot.path}/$name';
    final raw = sqlite3.open(path, mode: OpenMode.readWriteCreate);
    for (final t in BackupService.expectedTables) {
      raw.execute('CREATE TABLE $t (id INTEGER PRIMARY KEY)');
    }
    raw.close();
    return path;
  }

  /// Tap + πραγματικός χρόνος για IO (house pattern
  /// `new_item_flow_dialog_validation_test`: `runAsync` delay πριν το pump).
  Future<void> tapReal(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
  }

  group('BackupRestoreSection', () {
    testWidgets('δείχνει τα 2 κουμπιά', (tester) async {
      await pumpAt(tester, const Size(800, 600));
      expect(find.text(AppStrings.backupExportAction), findsOneWidget);
      expect(find.text(AppStrings.backupRestoreAction), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('restore ακύρωση pick → τίποτα (ούτε dialog)', (tester) async {
      picker.pickPath = null;
      await pumpAt(tester, const Size(800, 600));
      await tester.tap(find.text(AppStrings.backupRestoreAction));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(AppMessages.restoreConfirmWithBackup), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('restore άκυρο αρχείο → error, χωρίς dialog', (tester) async {
      picker.pickPath = '${tmpRoot.path}/missing.sqlite';
      await pumpAt(tester, const Size(800, 600));
      await tapReal(tester, find.text(AppStrings.backupRestoreAction));
      expect(find.text(AppErrors.invalidBackupFile), findsOneWidget);
      expect(find.text(AppMessages.restoreConfirmWithBackup), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('restore έγκυρο → εμφανίζεται confirm dialog', (tester) async {
      picker.pickPath = makeFixture('ok.sqlite');
      await pumpAt(tester, const Size(800, 600));
      await tapReal(tester, find.text(AppStrings.backupRestoreAction));
      await tester.pumpAndSettle();
      expect(find.text(AppMessages.restoreConfirmWithBackup), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('restore έγκυρο → Ακύρωση → παραμονή, χωρίς αλλαγή',
        (tester) async {
      picker.pickPath = makeFixture('ok2.sqlite');
      await pumpAt(tester, const Size(800, 600));
      await tapReal(tester, find.text(AppStrings.backupRestoreAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppMessages.confirmDialogCancel));
      await tester.pumpAndSettle();
      expect(find.text(AppMessages.restoreSuccess), findsNothing);
      expect(tester.takeException(), isNull);
    });

    // ─── Responsive (§1.4) ───────────────────────────────────────────────
    testWidgets('mobile (320×568) — κανένα overflow', (tester) async {
      await pumpAt(tester, const Size(320, 568));
      expect(tester.takeException(), isNull);
    });

    testWidgets('tablet (800×600) — κανένα overflow', (tester) async {
      await pumpAt(tester, const Size(800, 600));
      expect(tester.takeException(), isNull);
    });

    testWidgets('desktop (1200×800) — κανένα overflow', (tester) async {
      await pumpAt(tester, const Size(1200, 800));
      expect(tester.takeException(), isNull);
    });

    // ─── Dark (§1.5, πρότυπο V12) ──────────────────────────────────────────
    testWidgets('dark: αποδίδεται σωστά', (tester) async {
      await pumpAt(tester, const Size(800, 600), theme: AppTheme.dark);
      expect(find.text(AppStrings.backupExportAction), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
