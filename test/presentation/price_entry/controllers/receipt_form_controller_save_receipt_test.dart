/// Unit tests — `saveReceipt` + `resetForm` του `ReceiptFormController`
/// (§2.2 · Βήμα 5δ / Βήμα 6β).
///
/// Πραγματική in-memory βάση (Drift) για τα success-paths· error paths με
/// μοκ repositories (`_FailingReceiptRepo` = σκόπιμα αποτυγχάνον insert,
/// `_BlockingReceiptRepo` = πύλη Completer για ντετερμινιστικό timing του
/// double-save guard). Μέρος του split housekeeping του
/// `receipt_form_controller_test.dart` (Βήμα 8 · κανόνας 7: < 500 γρ. ανά
/// αρχείο) — τα υπόλοιπα groups ζουν στα:
///   * `receipt_form_controller_test.dart` (state mutations)
///   * `receipt_form_controller_create_supplier_test.dart` (createSupplier)
/// Οι logs επαληθεύονται με `AppLogger.testSink` (pattern app_feedback_test).
library;

import 'dart:async';

import 'package:flutter/material.dart' show DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/core/logging/app_logger.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/models/receipt_summary.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/repositories/receipt_repository.dart';
import 'package:times/presentation/price_entry/controllers/receipt_form_controller.dart';
import 'package:times/presentation/price_entry/state/receipt_form_state.dart';

import '../../../data/local/helpers/in_memory_db.dart';

void main() {
  setUp(() {
    AppLogger.resetTestSink();
  });
  tearDown(() {
    AppLogger.resetTestSink();
  });

  /// Δεδομένος προμηθευτής (Drift data-class).
  Supplier supplier({int id = 1, String name = 'Μάρκος'}) => Supplier(
        id: id,
        name: name,
        normalizedName: 'μαρκοσ',
        createdAt: DateTime(2026, 9, 17),
      );

  ProviderContainer containerWithDb() {
    final db = inMemoryDb();
    addTearDown(db.close);
    return ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  }

  group('saveReceipt (Βήμα 5δ)', () {
    /// Δεδομένη γραμμή «καλαθιού».
    DraftReceiptLine line({
      required int itemId,
      required int unitId,
    }) =>
        DraftReceiptLine(
          itemId: itemId,
          unitId: unitId,
          quantity: 1.5,
          priceCents: 250,
          itemName: 'Γάλα',
          unitAbbreviation: 'κιλ',
        );

    /// Seed: προμηθευτής + μονάδα + είδος (για FK-safe save).
    Future<({Supplier supplier, int unitId, int itemId})> seed(
      ProviderContainer container,
    ) async {
      final supplierId =
          await container.read(supplierRepositoryProvider).insert(name: 'Μάρκος');
      final supplier =
          await container.read(supplierRepositoryProvider).getById(supplierId);
      final db = container.read(appDatabaseProvider);
      final unitId = await UnitDao(db).insert(
        name: 'Κιλό',
        abbreviation: 'κιλ',
        allowsDecimal: true,
      );
      final categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
      final subId = await SubCategoryDao(db)
          .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
      final itemId =
          await ItemDao(db).insert(subCategoryId: subId, name: 'Γάλα');
      return (supplier: supplier!, unitId: unitId, itemId: itemId);
    }

    Future<int> receiptCount(ProviderContainer container) => container
        .read(receiptRepositoryProvider)
        .watchAll()
        .first
        .then((receipts) => receipts.length);

    test('χωρίς προμηθευτή → SaveReceiptException, ΚΑΜΙΑ εγγραφή', () async {
      final container = containerWithDb();
      final notifier = container.read(receiptFormControllerProvider.notifier);
      notifier.addDraftLine(line(itemId: 1, unitId: 2));

      await expectLater(
        notifier.saveReceipt(),
        throwsA(isA<SaveReceiptException>()),
      );
      expect(await receiptCount(container), 0);
      expect(
        container.read(receiptFormControllerProvider).draftLines.length,
        1,
        reason: 'Αποτυχία → τα drafts ΠΑΡΑΜΕΝΟΥΝ (§2.2:213)',
      );
      expect(container.read(receiptFormControllerProvider).isSaving, isFalse);
    });

    test('κενό «καλάθι» → SaveReceiptException, ΚΑΜΙΑ εγγραφή', () async {
      final container = containerWithDb();
      final seeded = await seed(container);
      final notifier = container.read(receiptFormControllerProvider.notifier);
      notifier.setSupplier(seeded.supplier);

      await expectLater(
        notifier.saveReceipt(),
        throwsA(isA<SaveReceiptException>()),
      );
      expect(await receiptCount(container), 0);
      expect(container.read(receiptFormControllerProvider).isSaving, isFalse);
    });

    test('επιτυχία → transaction + resetForm + log [DB]', () async {
      final container = containerWithDb();
      final seeded = await seed(container);
      final notifier = container.read(receiptFormControllerProvider.notifier);
      final logged = StringBuffer();
      AppLogger.testSink = logged.write;
      notifier.setSupplier(seeded.supplier);
      notifier.addDraftLine(
        line(itemId: seeded.itemId, unitId: seeded.unitId),
      );

      await notifier.saveReceipt();

      // Φόρμα καθάρισε (§2.2:212).
      final form = container.read(receiptFormControllerProvider);
      expect(form.draftLines, isEmpty);
      expect(form.supplier, isNull);
      expect(form.isSaving, isFalse);
      expect(form.date, DateUtils.dateOnly(DateTime.now()));
      expect(logged.toString(), contains('[DB]'));
      expect(logged.toString(), contains('Αποθήκευση απόδειξης'));

      // Βάση: 1 απόδειξη + 1 γραμμή με SPoT lineTotalCents (250×1.5→375).
      final receipts =
          await container.read(receiptRepositoryProvider).watchAll().first;
      expect(receipts.length, 1);
      expect(receipts[0].supplierId, seeded.supplier.id);
      final lines = await container
          .read(receiptRepositoryProvider)
          .watchLines(receipts[0].id)
          .first;
      expect(lines.length, 1);
      expect(lines[0].itemId, seeded.itemId);
      expect(lines[0].unitId, seeded.unitId);
      expect(lines[0].quantity, 1.5);
      expect(lines[0].priceCents, 250);
      expect(lines[0].lineTotalCents, 375);
    });

    test('σφάλμα DB → SaveReceiptException + drafts ΠΑΡΑΜΕΝΟΥΝ + flag σβήνει',
        () async {
      final container = ProviderContainer.test(
        overrides: [
          receiptRepositoryProvider.overrideWithValue(
            const _FailingReceiptRepo(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(receiptFormControllerProvider.notifier);
      notifier.setSupplier(supplier());
      notifier.addDraftLine(line(itemId: 1, unitId: 2));

      await expectLater(
        notifier.saveReceipt(),
        throwsA(isA<SaveReceiptException>()),
      );

      final form = container.read(receiptFormControllerProvider);
      expect(form.draftLines.length, 1, reason: 'Drafts ΠΑΡΑΜΕΝΟΥΝ (§2.2:213)');
      expect(form.supplier, isNotNull);
      expect(form.isSaving, isFalse);
    });
    test('απρόβλεπτο σφάλμα (όχι SaveReceiptException) → flag σβήνει + drafts '
        'ΜΕΝΟΥΝ + καταγραφή [DB][ERROR]', () async {
      final container = ProviderContainer.test(
        overrides: [
          receiptRepositoryProvider.overrideWithValue(
            _FailingReceiptRepo(StateError('boom')),
          ),
        ],
      );
      addTearDown(container.dispose);
      final logged = StringBuffer();
      AppLogger.testSink = logged.write;
      final notifier = container.read(receiptFormControllerProvider.notifier);
      notifier.setSupplier(supplier());
      notifier.addDraftLine(line(itemId: 1, unitId: 2));

      await expectLater(notifier.saveReceipt(), throwsA(isA<StateError>()));

      final form = container.read(receiptFormControllerProvider);
      expect(
        form.isSaving,
        isFalse,
        reason: 'Αλλιώς το κουμπί μένει ανενεργό για πάντα',
      );
      expect(form.draftLines.length, 1, reason: 'Drafts ΠΑΡΑΜΕΝΟΥΝ (§2.2:213)');
      expect(form.supplier, isNotNull);
      expect(logged.toString(), contains('[DB][ERROR]'));
    });
    test('isSaving true κατά τη διάρκεια + double-save → ένα insert',
        () async {
      final container = containerWithDb();
      final seeded = await seed(container);
      final gate = Completer<void>();
      final blocking = _BlockingReceiptRepo(
        container.read(receiptRepositoryProvider),
        gate,
      );
      final gated = ProviderContainer.test(
        overrides: [
          appDatabaseProvider.overrideWithValue(container.read(appDatabaseProvider)),
          receiptRepositoryProvider.overrideWithValue(blocking),
        ],
      );
      addTearDown(gated.dispose);
      final notifier = gated.read(receiptFormControllerProvider.notifier);
      notifier.setSupplier(seeded.supplier);
      notifier.addDraftLine(
        line(itemId: seeded.itemId, unitId: seeded.unitId),
      );

      // Πρώτο save κολλάει στην πύλη → flag ανεβασμένο, δεύτερο no-op.
      final first = notifier.saveReceipt();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(gated.read(receiptFormControllerProvider).isSaving, isTrue);
      await notifier.saveReceipt(); // double-tap guard (§2.2:235)
      gate.complete();
      await first;

      expect(await receiptCount(container), 1);
      expect(gated.read(receiptFormControllerProvider).isSaving, isFalse);
      expect(
        gated.read(receiptFormControllerProvider).draftLines,
        isEmpty,
      );
    });

    test('resetForm → σήμερα + κανένας προμηθευτής + κενό «καλάθι»', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(receiptFormControllerProvider.notifier);
      notifier.setSupplier(supplier());
      notifier.addDraftLine(line(itemId: 1, unitId: 2));

      notifier.resetForm();

      final form = container.read(receiptFormControllerProvider);
      expect(form.date, DateUtils.dateOnly(DateTime.now()));
      expect(form.supplier, isNull);
      expect(form.draftLines, isEmpty);
      expect(form.isSaving, isFalse);
    });
  });
}

/// Σκόπιμα αποτυγχάνων receipt repository — το `insertReceiptWithLines`
/// ρίχνει `SaveReceiptException` (προσομοίωση σφάλματος βάσης στο save).
class _FailingReceiptRepo implements ReceiptRepository {
  /// [error] = τι ρίχνει το `insertReceiptWithLines` (default: το mapped
  /// `SaveReceiptException`· π.χ. `StateError` προσομοιώνει μη-mapped σφάλμα).
  const _FailingReceiptRepo([this.error = const SaveReceiptException()]);

  final Object error;

  @override
  Stream<List<Receipt>> watchAll() => throw const DataLoadException();
  @override
  Stream<List<ReceiptSummary>> watchRecentSummaries({required int limit}) =>
      throw const DataLoadException();
  @override
  Future<Receipt?> getById(int id) => throw const DataLoadException();
  @override
  Future<int> insert({required DateTime date, required int supplierId}) =>
      throw const DataLoadException();
  @override
  Future<bool> updateById(int id, {DateTime? date, int? supplierId}) =>
      throw const DataLoadException();
  @override
  Future<bool> deleteById(int id) => throw const DataLoadException();
  @override
  Stream<List<ReceiptLine>> watchLines(int receiptId) =>
      throw const DataLoadException();
  @override
  Future<int> insertReceiptWithLines({
    required DateTime date,
    required int supplierId,
    required List<ReceiptLineInput> lines,
  }) =>
      throw error;
}

/// Receipt repository με πύλη (Completer) πριν το πραγματικό insert —
/// δοκιμή `isSaving` flag + double-save guard με ντετερμινιστικό timing.
class _BlockingReceiptRepo implements ReceiptRepository {
  _BlockingReceiptRepo(this.inner, this.gate);

  final ReceiptRepository inner;
  final Completer<void> gate;

  @override
  Stream<List<Receipt>> watchAll() => inner.watchAll();
  @override
  Stream<List<ReceiptSummary>> watchRecentSummaries({required int limit}) =>
      inner.watchRecentSummaries(limit: limit);
  @override
  Future<Receipt?> getById(int id) => inner.getById(id);
  @override
  Future<int> insert({required DateTime date, required int supplierId}) =>
      inner.insert(date: date, supplierId: supplierId);
  @override
  Future<bool> updateById(int id, {DateTime? date, int? supplierId}) =>
      inner.updateById(id, date: date, supplierId: supplierId);
  @override
  Future<bool> deleteById(int id) => inner.deleteById(id);
  @override
  Stream<List<ReceiptLine>> watchLines(int receiptId) =>
      inner.watchLines(receiptId);
  @override
  Future<int> insertReceiptWithLines({
    required DateTime date,
    required int supplierId,
    required List<ReceiptLineInput> lines,
  }) async {
    await gate.future;
    return inner.insertReceiptWithLines(
      date: date,
      supplierId: supplierId,
      lines: lines,
    );
  }
}