/// Unit tests — safety-net validation στον `ReceiptFormController`
/// (Φάση 3, Βήμα 6γ · §2.2 «Validation πριν την αποθήκευση»).
///
/// Καλύπτει: `addDraftLine` (απόρριψη άκυρης γραμμής + log [UI][ERROR]) ·
/// `saveReceipt` (safety-net ΠΡΙΝ το isSaving/repository) · `createSupplier`
/// (NameValidator: πάνω από maxItemNameLength → χωρίς εγγραφή).
/// Νέο αρχείο: το receipt_form_controller_test.dart ξεπερνά ήδη τις 500 γρ.
library;

import 'package:flutter/material.dart' show DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_constants.dart';
import 'package:times/core/constants/app_errors.dart';
import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/core/logging/app_logger.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/models/receipt_summary.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/repositories/receipt_repository.dart';
import 'package:times/presentation/price_entry/controllers/receipt_form_controller.dart';
import 'package:times/presentation/price_entry/state/receipt_form_state.dart';

import '../../../data/local/helpers/in_memory_db.dart';

/// Δεδομένος προμηθευτής (Drift data-class).
final Supplier _supplier = Supplier(
  id: 1,
  name: 'Μάρκος',
  normalizedName: 'μαρκοσ',
  createdAt: DateTime(2026, 9, 17),
);

void main() {
  setUp(() {
    AppLogger.resetTestSink();
  });
  tearDown(() {
    AppLogger.resetTestSink();
  });

  /// Δεδομένη γραμμή «καλαθιού» (default: έγκυρη).
  DraftReceiptLine lineOf({
    double quantity = 1.5,
    int priceCents = 250,
    bool unitAllowsDecimal = true,
    String itemName = 'Γάλα',
  }) =>
      DraftReceiptLine(
        itemId: 1,
        unitId: 2,
        quantity: quantity,
        priceCents: priceCents,
        itemName: itemName,
        unitAbbreviation: 'κιλ',
        unitAllowsDecimal: unitAllowsDecimal,
      );

  /// Καταγράφει την έξοδο του AppLogger σε StringBuffer.
  StringBuffer captureLogs() {
    final logged = StringBuffer();
    AppLogger.testSink = logged.write;
    return logged;
  }

  ProviderContainer containerWithDb() {
    final db = inMemoryDb();
    addTearDown(db.close);
    return ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  }

  group('addDraftLine — safety-net (Βήμα 6γ)', () {
    test('τιμή 0 → αγνοείται + log [UI][ERROR] με τον λόγο', () {
      final container = ProviderContainer.test();
      final logged = captureLogs();

      container
          .read(receiptFormControllerProvider.notifier)
          .addDraftLine(lineOf(priceCents: 0));

      expect(container.read(receiptFormControllerProvider).draftLines,
          isEmpty);
      expect(logged.toString(), contains('[UI][ERROR]'));
      expect(logged.toString(), contains('Άκυρη γραμμή — αγνοήθηκε: Γάλα'));
      expect(logged.toString(), contains(AppErrors.priceMustBePositive));
    });

    test('ποσότητα 0 → αγνοείται + log με τον λόγο', () {
      final container = ProviderContainer.test();
      final logged = captureLogs();

      container
          .read(receiptFormControllerProvider.notifier)
          .addDraftLine(lineOf(quantity: 0));

      expect(container.read(receiptFormControllerProvider).draftLines,
          isEmpty);
      expect(logged.toString(), contains(AppErrors.quantityMustBePositive));
    });

    test('τιμή πάνω από maxPriceCents → αγνοείται (priceTooLarge)', () {
      final container = ProviderContainer.test();
      final logged = captureLogs();

      container
          .read(receiptFormControllerProvider.notifier)
          .addDraftLine(lineOf(priceCents: AppConstants.maxPriceCents + 1));

      expect(container.read(receiptFormControllerProvider).draftLines,
          isEmpty);
      expect(logged.toString(), contains(AppErrors.priceTooLarge));
    });

    test('ποσότητα πάνω από maxQuantity → αγνοείται (quantityTooLarge)', () {
      final container = ProviderContainer.test();
      final logged = captureLogs();

      container
          .read(receiptFormControllerProvider.notifier)
          .addDraftLine(lineOf(quantity: AppConstants.maxQuantity + 1));

      expect(container.read(receiptFormControllerProvider).draftLines,
          isEmpty);
      expect(logged.toString(), contains(AppErrors.quantityTooLarge));
    });

    test('δεκαδική ποσότητα σε integer-only μονάδα → αγνοείται (§2.2:218)',
            () {
          final container = ProviderContainer.test();
          final logged = captureLogs();

          container
              .read(receiptFormControllerProvider.notifier)
              .addDraftLine(lineOf(quantity: 2.5, unitAllowsDecimal: false));

          expect(container.read(receiptFormControllerProvider).draftLines,
              isEmpty);
          expect(logged.toString(), contains(AppErrors.quantityMustBeInteger));
        });

    test('όρια αποδεκτά: 1 λεπτό × 0,001 · max × max · integer-only 2.0', () {
      final container = ProviderContainer.test();
      final notifier = container.read(receiptFormControllerProvider.notifier);

      notifier.addDraftLine(lineOf(priceCents: 1, quantity: 0.001));
      notifier.addDraftLine(
        lineOf(
          priceCents: AppConstants.maxPriceCents,
          quantity: AppConstants.maxQuantity,
        ),
      );
      notifier.addDraftLine(lineOf(quantity: 2.0, unitAllowsDecimal: false));

      expect(container.read(receiptFormControllerProvider).draftLines,
          hasLength(3));
    });

    test('απορριφθείσα γραμμή δεν επηρεάζει τις επόμενες έγκυρες', () {
      final container = ProviderContainer.test();
      final notifier = container.read(receiptFormControllerProvider.notifier);

      notifier.addDraftLine(lineOf(quantity: 0));
      notifier.addDraftLine(lineOf());

      expect(container.read(receiptFormControllerProvider).draftLines,
          hasLength(1));
    });

    test('default unitAllowsDecimal=true → δεκαδική ποσότητα γίνεται δεκτή',
            () {
          final container = ProviderContainer.test();

          container
              .read(receiptFormControllerProvider.notifier)
              .addDraftLine(lineOf(quantity: 2.5));

          expect(container.read(receiptFormControllerProvider).draftLines,
              hasLength(1));
        });
  });

  group('saveReceipt — safety-net (Βήμα 6γ)', () {
    test('άκυρη γραμμή στο «καλάθι» → SaveReceiptException, ΚΑΝΕΝΑ insert',
            () async {
          final repo = _NeverInsertReceiptRepo();
          final container = ProviderContainer.test(
            overrides: [
              receiptFormControllerProvider.overrideWith(
                    () => _SeededController([lineOf(quantity: 0)],
                    withSupplier: true),
              ),
              receiptRepositoryProvider.overrideWithValue(repo),
            ],
          );
          final logged = captureLogs();
          final notifier = container.read(receiptFormControllerProvider.notifier);

          await expectLater(
            notifier.saveReceipt(),
            throwsA(isA<SaveReceiptException>()),
          );

          expect(repo.insertCalls, 0, reason: 'Απορρίπτεται ΠΡΙΝ το repository');
          expect(logged.toString(), contains('[UI][ERROR]'));
          expect(logged.toString(), contains('Απόρριψη αποθήκευσης'));
          expect(logged.toString(), contains(AppErrors.quantityMustBePositive));
          final form = container.read(receiptFormControllerProvider);
          expect(form.isSaving, isFalse);
          expect(form.draftLines, hasLength(1),
              reason: 'Τα drafts ΠΑΡΑΜΕΝΟΥΝ (§2.2:213)');
        });

    test('χωρίς προμηθευτή → SaveReceiptException + log supplierRequired',
            () async {
          final container = ProviderContainer.test();
          final notifier = container.read(receiptFormControllerProvider.notifier);
          notifier.addDraftLine(lineOf());
          final logged = captureLogs();

          await expectLater(
            notifier.saveReceipt(),
            throwsA(isA<SaveReceiptException>()),
          );

          expect(logged.toString(), contains(AppErrors.supplierRequired));
          expect(container.read(receiptFormControllerProvider).isSaving, isFalse);
        });

    test('κενό «καλάθι» → SaveReceiptException + log receiptLinesRequired',
            () async {
          final container = ProviderContainer.test(
            overrides: [
              receiptFormControllerProvider.overrideWith(
                    () => _SeededController(const [], withSupplier: true),
              ),
            ],
          );
          final logged = captureLogs();
          final notifier = container.read(receiptFormControllerProvider.notifier);

          await expectLater(
            notifier.saveReceipt(),
            throwsA(isA<SaveReceiptException>()),
          );

          expect(logged.toString(), contains(AppErrors.receiptLinesRequired));
          expect(container.read(receiptFormControllerProvider).isSaving, isFalse);
        });
  });

  group('createSupplier — NameValidator (Βήμα 6γ)', () {
    test('όνομα πάνω από maxItemNameLength → (null, false), καμία εγγραφή',
            () async {
          final container = containerWithDb();
          final notifier = container.read(receiptFormControllerProvider.notifier);
          final tooLong =
          List.filled(AppConstants.maxItemNameLength + 1, 'α').join();

          final result = await notifier.createSupplier(tooLong);

          expect(result.supplier, isNull);
          expect(result.created, isFalse);
          expect(container.read(receiptFormControllerProvider).supplier, isNull);
          final all =
          await container.read(supplierRepositoryProvider).watchAll().first;
          expect(all, isEmpty);
        });

    test('όνομα ακριβώς maxItemNameLength → δημιουργείται (όριο αποδεκτό)',
            () async {
          final container = containerWithDb();
          final notifier = container.read(receiptFormControllerProvider.notifier);
          final exact = List.filled(AppConstants.maxItemNameLength, 'α').join();

          final result = await notifier.createSupplier(exact);

          expect(result.created, isTrue);
          expect(result.supplier?.name, exact);
        });
  });
}

/// Controller με προ-γεμισμένο state (άκυρες γραμμές που ο `addDraftLine`
/// δεν θα δεχόταν) — για το safety-net του `saveReceipt`.
class _SeededController extends ReceiptFormController {
  _SeededController(this._lines, {required this.withSupplier});

  final List<DraftReceiptLine> _lines;
  final bool withSupplier;

  @override
  ReceiptFormState build() => ReceiptFormState(
    date: DateUtils.dateOnly(DateTime.now()),
    supplier: withSupplier ? _supplier : null,
    draftLines: _lines,
  );
}

/// Repository που μετρά τις κλήσεις `insertReceiptWithLines` — αν το
/// safety-net δεν απέρριπτε, θα καλούνταν (και θα έριχνε StateError).
class _NeverInsertReceiptRepo implements ReceiptRepository {
  int insertCalls = 0;

  @override
  Future<int> insertReceiptWithLines({
    required DateTime date,
    required int supplierId,
    required List<ReceiptLineInput> lines,
  }) {
    insertCalls++;
    throw StateError('insertReceiptWithLines δεν έπρεπε να κληθεί');
  }

  @override
  Stream<List<Receipt>> watchAll() => throw UnimplementedError();
  @override
  Stream<List<ReceiptSummary>> watchRecentSummaries({required int limit}) =>
      throw UnimplementedError();
  @override
  Future<Receipt?> getById(int id) => throw UnimplementedError();
  @override
  Future<int> insert({required DateTime date, required int supplierId}) =>
      throw UnimplementedError();
  @override
  Future<bool> updateById(int id, {DateTime? date, int? supplierId}) =>
      throw UnimplementedError();
  @override
  Future<bool> deleteById(int id) => throw UnimplementedError();
  @override
  Future<int> countBySupplierId(int supplierId) =>
      throw UnimplementedError();
  @override
  Stream<List<ReceiptLine>> watchLines(int receiptId) =>
      throw UnimplementedError();
}