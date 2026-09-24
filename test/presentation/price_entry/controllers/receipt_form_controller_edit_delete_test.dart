/// Unit tests — `loadReceiptForEdit` + `cancelEdit` + `deleteReceipt` +
/// save-branch σε edit mode (`ReceiptFormController`, Φάση Α · 24-09-2026).
///
/// Πραγματική in-memory βάση (Drift). Οι logs επαληθεύονται με
/// `AppLogger.testSink` (pattern app_feedback_test).
library;

import 'package:flutter/material.dart' show DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_errors.dart';
import 'package:times/core/logging/app_logger.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/providers/database_providers.dart';
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

  ProviderContainer containerWithDb() {
    final db = inMemoryDb();
    addTearDown(db.close);
    return ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  }

  /// Seed: προμηθευτής + μονάδα + 2 είδη — επιστρέφει τα ids.
  Future<({int supplierId, int unitId, int itemId, int secondItemId})> seed(
    ProviderContainer container,
  ) async {
    final supplierId =
        await container.read(supplierRepositoryProvider).insert(name: 'Μάρκος');
    final db = container.read(appDatabaseProvider);
    final unitId = await UnitDao(db).insert(
      name: 'Κιλό',
      abbreviation: 'κιλ',
      allowsDecimal: true,
    );
    final categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    final subId = await SubCategoryDao(db)
        .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
    final itemId = await ItemDao(db).insert(subCategoryId: subId, name: 'Γάλα');
    final secondItemId =
        await ItemDao(db).insert(subCategoryId: subId, name: 'Τυρί');
    return (
      supplierId: supplierId,
      unitId: unitId,
      itemId: itemId,
      secondItemId: secondItemId
    );
  }

  group('loadReceiptForEdit (Φάση Α)', () {
    test('γεμίζει date/supplier/drafts + editingId + log', () async {
      final container = containerWithDb();
      final s = await seed(container);
      final receiptId = await container
          .read(receiptRepositoryProvider)
          .insertReceiptWithLines(
        date: DateTime(2026, 2, 5),
        supplierId: s.supplierId,
        lines: [
          (
            itemId: s.itemId,
            unitId: s.unitId,
            quantity: 2,
            priceCents: 199,
          ),
        ],
      );

      final logged = StringBuffer();
      AppLogger.testSink = logged.write;
      final notifier = container.read(receiptFormControllerProvider.notifier);
      final result = await notifier.loadReceiptForEdit(receiptId);

      expect(result, (ok: true, error: null));
      final state = container.read(receiptFormControllerProvider);
      expect(state.editingId, receiptId);
      expect(state.date, DateTime(2026, 2, 5));
      expect(state.supplier?.name, 'Μάρκος');
      expect(state.draftLines.length, 1);
      expect(state.draftLines.single.itemName, 'Γάλα');
      expect(state.draftLines.single.unitAbbreviation, 'κιλ');
      expect(state.draftLines.single.unitAllowsDecimal, isTrue);
      expect(
        state.draftLines.single.enteredTotalCents,
        isNull,
        reason: 'δεν ανακατασκευάζεται (stored ±1, §3)',
      );
      expect(state.isSaving, isFalse);
      expect(logged.toString(), contains('Φόρτωση απόδειξης'));
    });

    test('ανύπαρκτο id → (ok:false, loadDataFailed), state άθικτο', () async {
      final container = containerWithDb();
      await seed(container);
      final notifier = container.read(receiptFormControllerProvider.notifier);

      final result = await notifier.loadReceiptForEdit(9999);

      expect(result.ok, isFalse);
      expect(result.error, AppErrors.loadDataFailed);
      expect(
        container.read(receiptFormControllerProvider).editingId,
        isNull,
      );
      expect(
        container.read(receiptFormControllerProvider).isSaving,
        isFalse,
      );
    });

    test('επανείσοδος ενώ isSaving → no-op', () async {
      final container = containerWithDb();
      await seed(container);
      final notifier = container.read(receiptFormControllerProvider.notifier);
      // Τεχνητό isSaving μέσω copyWith — η φόρτωση αγνοείται.
      notifier.state = notifier.state.copyWith(isSaving: true);

      final result = await notifier.loadReceiptForEdit(1);

      expect(result, (ok: false, error: null));
    });
  });

  group('cancelEdit (Φάση Α)', () {
    test('μηδενίζει editingId + drafts + supplier', () async {
      final container = containerWithDb();
      final s = await seed(container);
      final receiptId = await container
          .read(receiptRepositoryProvider)
          .insertReceiptWithLines(
        date: DateTime(2026, 2, 5),
        supplierId: s.supplierId,
        lines: [
          (
            itemId: s.itemId,
            unitId: s.unitId,
            quantity: 1,
            priceCents: 100,
          ),
        ],
      );
      final notifier = container.read(receiptFormControllerProvider.notifier);
      await notifier.loadReceiptForEdit(receiptId);
      expect(
        container.read(receiptFormControllerProvider).editingId,
        receiptId,
      );

      notifier.cancelEdit();

      final state = container.read(receiptFormControllerProvider);
      expect(state.editingId, isNull);
      expect(state.draftLines, isEmpty);
      expect(state.supplier, isNull);
      expect(state.date, DateUtils.dateOnly(DateTime.now()));
    });
  });

  group('deleteReceipt (Φάση Α)', () {
    test('επιτυχία: κεφαλίδα + γραμμές σβησμένες (CASCADE)', () async {
      final container = containerWithDb();
      final s = await seed(container);
      final receiptId = await container
          .read(receiptRepositoryProvider)
          .insertReceiptWithLines(
        date: DateTime(2026, 1, 1),
        supplierId: s.supplierId,
        lines: [
          (
            itemId: s.itemId,
            unitId: s.unitId,
            quantity: 1,
            priceCents: 100,
          ),
        ],
      );

      final logged = StringBuffer();
      AppLogger.testSink = logged.write;
      final result = await container
          .read(receiptFormControllerProvider.notifier)
          .deleteReceipt(receiptId);

      expect(result, (ok: true, error: null));
      expect(
        await container.read(receiptRepositoryProvider).getById(receiptId),
        isNull,
      );
      expect(
        await container
            .read(receiptRepositoryProvider)
            .watchLines(receiptId)
            .first,
        isEmpty,
      );
      expect(logged.toString(), contains('Διαγραφή απόδειξης'));
    });

    test('ανύπαρκτο id → (ok:false, loadDataFailed)', () async {
      final container = containerWithDb();
      await seed(container);

      final result = await container
          .read(receiptFormControllerProvider.notifier)
          .deleteReceipt(9999);

      expect(result.ok, isFalse);
      expect(result.error, AppErrors.loadDataFailed);
    });

    test('διαγραφή υπό-επεξεργασία → cancelEdit (editingId null)', () async {
      final container = containerWithDb();
      final s = await seed(container);
      final receiptId = await container
          .read(receiptRepositoryProvider)
          .insertReceiptWithLines(
        date: DateTime(2026, 1, 1),
        supplierId: s.supplierId,
        lines: [
          (
            itemId: s.itemId,
            unitId: s.unitId,
            quantity: 1,
            priceCents: 100,
          ),
        ],
      );
      final notifier = container.read(receiptFormControllerProvider.notifier);
      await notifier.loadReceiptForEdit(receiptId);

      await notifier.deleteReceipt(receiptId);

      expect(
        container.read(receiptFormControllerProvider).editingId,
        isNull,
      );
    });

    test('DB σφάλμα → εξαίρεση + isSaving σβησμένο (όχι κολλημένο flag)',
        () async {
      final container = containerWithDb();
      await seed(container);
      // Κλείσιμο βάσης → κάθε op ρίχνει (όχι κατ' ανάγκη mapped).
      await container.read(appDatabaseProvider).close();

      await expectLater(
        container
            .read(receiptFormControllerProvider.notifier)
            .deleteReceipt(1),
        throwsA(anything),
      );
      expect(
        container.read(receiptFormControllerProvider).isSaving,
        isFalse,
        reason: 'κάθε σφάλμα σβήνει το flag (pattern saveReceipt)',
      );
    });
  });

  group('saveReceipt σε edit mode (Φάση Α)', () {
    test('update-branch: γραμμές αντικαθίστανται + reset (editingId null)',
        () async {
      final container = containerWithDb();
      final s = await seed(container);
      final receiptId = await container
          .read(receiptRepositoryProvider)
          .insertReceiptWithLines(
        date: DateTime(2026, 1, 1),
        supplierId: s.supplierId,
        lines: [
          (
            itemId: s.itemId,
            unitId: s.unitId,
            quantity: 1,
            priceCents: 100,
          ),
        ],
      );
      final notifier = container.read(receiptFormControllerProvider.notifier);
      await notifier.loadReceiptForEdit(receiptId);
      notifier.addDraftLine(
        DraftReceiptLine(
          itemId: s.secondItemId,
          unitId: s.unitId,
          quantity: 2,
          priceCents: 250,
          itemName: 'Τυρί',
          unitAbbreviation: 'κιλ',
        ),
      );

      final logged = StringBuffer();
      AppLogger.testSink = logged.write;
      await notifier.saveReceipt();

      final lines = await container
          .read(receiptRepositoryProvider)
          .watchLines(receiptId)
          .first;
      expect(lines.length, 2, reason: '1 φορτωμένη + 1 νέα');
      expect(logged.toString(), contains('Ενημέρωση απόδειξης'));
      expect(
        container.read(receiptFormControllerProvider).editingId,
        isNull,
        reason: 'reset μετά το update — επιστροφή σε δημιουργία',
      );
    });
  });
}
