/// Unit tests — `StatisticsController` (§2.3 · 28-09-2026).
///
/// exportExcel/exportPdf: success (bytes + filename στον picker) · cancel →
/// no-op · picker fail → `statsExportFailed` · double-tap guard.
/// Fake picker (όχι harness — pattern backup tests).
library;

import 'dart:async';

import 'package:excel/excel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_errors.dart';
import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/data/models/chart_totals.dart';
import 'package:times/data/providers/backup_file_picker.dart';
import 'package:times/data/providers/settings_providers.dart';
import 'package:times/presentation/settings/controllers/statistics_controller.dart';

/// Fake picker — καταγράφει (όχι δίσκος).
class FakeStatsPicker implements BackupFilePicker {
  String? savedName;
  List<int>? savedBytes;
  bool cancel = false;
  bool fail = false;
  Completer<void>? gate;

  @override
  Future<bool> saveBytes({
    required String fileName,
    required List<int> bytes,
  }) async {
    if (gate != null) await gate!.future;
    if (fail) throw Exception('picker boom');
    if (cancel) return false;
    savedName = fileName;
    savedBytes = bytes;
    return true;
  }

  @override
  Future<String?> pickSingleFile() => throw UnimplementedError();
}

/// Fixture γραμμής (χωρίς DB — records).
ItemLedgerRow ledgerRow() => (
      receiptId: 12,
      date: DateTime(2026, 9, 9),
      supplierName: 'Μάρκος',
      quantity: 0.456,
      unitAbbreviation: 'κιλ',
      priceCents: 1296,
      discountCents: 35,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeStatsPicker picker;

  setUp(() {
    picker = FakeStatsPicker();
  });

  ProviderContainer container() => ProviderContainer.test(
        overrides: [backupFilePickerProvider.overrideWithValue(picker)],
      );

  group('StatisticsController (§2.3 · 28-09-2026)', () {
    test('exportExcel — ok + .xlsx bytes με header', () async {
      final c = container();
      final result = await c
          .read(statisticsControllerProvider.notifier)
          .exportExcel([ledgerRow()]);
      expect(result, (ok: true, error: null));
      expect(picker.savedName, endsWith('.xlsx'));
      final excel = Excel.decodeBytes(picker.savedBytes!);
      expect(excel.tables.keys, contains('Καρτέλα'));
    });

    test('exportPdf — ok + .pdf με %PDF', () async {
      final c = container();
      final result = await c
          .read(statisticsControllerProvider.notifier)
          .exportPdf((
            title: 'Γάλα',
            headers: const ['Ημερομηνία'],
            body: const [
              ['09/09/2026'],
            ],
            totalsLine: null,
          ));
      expect(result, (ok: true, error: null));
      expect(picker.savedName, endsWith('.pdf'));
      expect(picker.savedBytes!.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]);
    });

    test('cancel picker → (ok:false, error:null), κανένα error', () async {
      picker.cancel = true;
      final c = container();
      final result = await c
          .read(statisticsControllerProvider.notifier)
          .exportExcel([ledgerRow()]);
      expect(result, (ok: false, error: null));
      expect(picker.savedBytes, isNull);
    });

    test('picker fail → StatsExportException (feedback στο widget)', () async {
      picker.fail = true;
      final c = container();
      // Το exception ανεβαίνει ανέγγιχτο (το `runControllerOp` το πιάνει —
      // pattern backup controller).
      await expectLater(
        c
            .read(statisticsControllerProvider.notifier)
            .exportExcel([ledgerRow()]),
        throwsA(
          predicate<Object>(
            (e) =>
                e is StatsExportException &&
                e.userMessage == AppErrors.statsExportFailed,
          ),
        ),
      );
    });

    test('double-tap guard: 2η κλήση εν πτήσει → no-op', () async {
      picker.gate = Completer<void>();
      final c = container();
      final notifier = c.read(statisticsControllerProvider.notifier);
      final first = notifier.exportExcel([ledgerRow()]);
      final second = await notifier.exportExcel([ledgerRow()]);
      expect(second, (ok: false, error: null));
      picker.gate!.complete();
      expect(await first, (ok: true, error: null));
      expect(picker.savedBytes, isNotNull);
    });
  });
}
