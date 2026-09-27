/// Unit tests — `ReceiptFormController` + `receiptFormControllerProvider`
/// (state mutations: ημερομηνία, προμηθευτής, γραμμές «καλαθιού»).
///
/// Σύγχρονο (Notifier) state → plain `ProviderContainer` + `addTearDown(dispose)`
/// (μοτίβο Φάσης 1/2 tests) — ΕΔΩ ΠΟΤΕ δεν ανοίγει βάση. Οι δοκιμές που
/// χρειάζονται DB ζουν στα αδερφά αρχεία (split housekeeping, Βήμα 8 ·
/// κανόνας 7: < 500 γρ. ανά αρχείο):
///   * `receipt_form_controller_create_supplier_test.dart` — `createSupplier`
///   * `receipt_form_controller_save_receipt_test.dart` — `saveReceipt`
/// Οι logs επαληθεύονται με `AppLogger.testSink` (pattern app_feedback_test).
library;

import 'package:flutter/material.dart' show DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/logging/app_logger.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/presentation/price_entry/controllers/receipt_form_controller.dart';
import 'package:times/presentation/price_entry/state/receipt_form_state.dart';

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

  group('ReceiptFormController', () {
    test('build() → σημερινή ημερομηνία (dateOnly, χωρίς ώρα)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final date = container.read(receiptFormControllerProvider).date;
      expect(date, DateUtils.dateOnly(DateTime.now()));
    });

    test('build() → κανένας προμηθευτής (supplier null)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(receiptFormControllerProvider).supplier, isNull);
    });

    test('setDate αλλάζει το state + καταγράφει log [UI]', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Sink πριν το setDate — η εκπομπή του log καταγράφεται (pattern
      // app_feedback_test). Το target = «προηγούμενη ημέρα» διαφέρει ΠΑΝΤΑ
      // από την αρχική (σήμερα) — αλλιώς το equality gate θα απέκλειε το log.
      final logged = StringBuffer();
      AppLogger.testSink = logged.write;
      final target =
          DateUtils.dateOnly(DateTime.now()).subtract(const Duration(days: 1));

      container.read(receiptFormControllerProvider.notifier).setDate(target);
      expect(container.read(receiptFormControllerProvider).date, target);
      expect(logged.toString(), contains('[UI]'));
      expect(logged.toString(), contains('Ημερομηνία απόδειξης'));
    });

    test('setDate με ώρα → κανονικοποιεί σε ημέρα (dateOnly)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final withTime = DateTime(2026, 9, 17, 23, 59, 59);

      container.read(receiptFormControllerProvider.notifier).setDate(withTime);
      expect(
        container.read(receiptFormControllerProvider).date,
        DateTime(2026, 9, 17),
      );
    });

    test('setDate ίδια μέρα → ΔΕΝ επανεκπέμπει (equality gate)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final same = DateUtils.dateOnly(DateTime.now());

      var emissions = 0;
      container.listen(receiptFormControllerProvider,
          (_, _) => emissions++, fireImmediately: true);
      expect(emissions, 1); // αρχική εκπομπή

      container.read(receiptFormControllerProvider.notifier).setDate(same);
      expect(
        emissions,
        1,
        reason: 'Ίδια ημερομηνία → κανένα re-notify (αποφυγή περιττών rebuilds)',
      );
    });

    test('setDate διαφορετική μέρα → νέα εκπομπή', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final today = DateUtils.dateOnly(DateTime.now());
      final other =
          today.isBefore(DateTime(2026, 12, 31)) ? today.add(const Duration(days: 1)) : today.subtract(const Duration(days: 1));

      var emissions = 0;
      container.listen(receiptFormControllerProvider,
          (_, _) => emissions++, fireImmediately: true);
      container.read(receiptFormControllerProvider.notifier).setDate(other);
      expect(emissions, 2);
    });
  });

  group('setSupplier', () {
    test('ορίζει τον προμηθευτή + καταγράφει log [UI]', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final logged = StringBuffer();
      AppLogger.testSink = logged.write;
      final s = supplier();

      container.read(receiptFormControllerProvider.notifier).setSupplier(s);
      expect(container.read(receiptFormControllerProvider).supplier, s);
      expect(logged.toString(), contains('[UI]'));
      expect(logged.toString(), contains('Επιλογή προμηθευτή'));
    });

    test('ίδιο id → ΔΕΝ επανεκπέμπει (equality gate)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(receiptFormControllerProvider.notifier);

      var emissions = 0;
      container.listen(receiptFormControllerProvider,
          (_, _) => emissions++, fireImmediately: true);
      expect(emissions, 1); // αρχική εκπομπή

      notifier.setSupplier(supplier(id: 5));
      expect(emissions, 2);
      // Ίδιο id αλλά διαφορετικό αντικείμενο/όνομα → ακόμα ίδιος προμηθευτής.
      notifier.setSupplier(supplier(id: 5, name: 'Μάρκος ΑΕ'));
      expect(
        emissions,
        2,
        reason: 'Ίδιο supplier id → κανένα re-notify',
      );
    });

    test('διαφορετικό id → νέα εκπομπή', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(receiptFormControllerProvider.notifier);

      var emissions = 0;
      container.listen(receiptFormControllerProvider,
          (_, _) => emissions++, fireImmediately: true);
      notifier.setSupplier(supplier(id: 1));
      notifier.setSupplier(supplier(id: 2));
      expect(emissions, 3);
    });

    test('supplier null → αποεπιλογή (re-notify από null→null όχι)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(receiptFormControllerProvider.notifier);
      notifier.setSupplier(supplier(id: 1));

      var emissions = 0;
      container.listen(receiptFormControllerProvider,
          (_, _) => emissions++, fireImmediately: true);
      expect(emissions, 1); // τρέχουσα εκπομπή (με supplier)

      notifier.setSupplier(supplier(id: 2));
      expect(emissions, 2);
      notifier.setSupplier(null);
      expect(emissions, 3);
      expect(container.read(receiptFormControllerProvider).supplier, isNull);

      // null → null (δεύτερη αποεπιλογή) χωρίς re-notify.
      notifier.setSupplier(null);
      expect(emissions, 3);
    });
  });

  group('draftLines (Βήμα 5γ)', () {
    /// Δεδομένη γραμμή «καλαθιού».
    DraftReceiptLine line({
      int itemId = 1,
      String itemName = 'Γάλα',
    }) =>
        DraftReceiptLine(
          itemId: itemId,
          unitId: 2,
          quantity: 1.5,
          priceCents: 250,
          itemName: itemName,
          unitAbbreviation: 'κιλ',
        );

    test('build() → κενό «καλάθι»', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(receiptFormControllerProvider).draftLines, isEmpty);
    });

    test('addDraftLine προσαρτά + καταγράφει log [UI]', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final logged = StringBuffer();
      AppLogger.testSink = logged.write;
      final notifier = container.read(receiptFormControllerProvider.notifier);

      notifier.addDraftLine(line());
      notifier.addDraftLine(line(itemId: 2, itemName: 'Ψωμί'));

      final lines = container.read(receiptFormControllerProvider).draftLines;
      expect(lines.length, 2);
      expect(lines[0].itemName, 'Γάλα');
      expect(lines[1].itemName, 'Ψωμί');
      expect(logged.toString(), contains('[UI]'));
      expect(logged.toString(), contains('Προσθήκη γραμμής'));
    });

    test('addDraftLine ίδιο είδος δύο φορές → δύο γραμμές (χωρίς merge)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(receiptFormControllerProvider.notifier);

      notifier.addDraftLine(line());
      notifier.addDraftLine(line());

      expect(
        container.read(receiptFormControllerProvider).draftLines.length,
        2,
      );
    });

    test('removeDraftLine αφαιρεί κατά index', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(receiptFormControllerProvider.notifier);
      notifier.addDraftLine(line(itemName: 'Γάλα'));
      notifier.addDraftLine(line(itemId: 2, itemName: 'Ψωμί'));

      notifier.removeDraftLine(0);

      final lines = container.read(receiptFormControllerProvider).draftLines;
      expect(lines.length, 1);
      expect(lines[0].itemName, 'Ψωμί');
    });

    test('removeDraftLine εκτός ορίων → αγνοείται (καμία αλλαγή)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(receiptFormControllerProvider.notifier);
      notifier.addDraftLine(line());

      notifier.removeDraftLine(-1);
      notifier.removeDraftLine(5);

      expect(
        container.read(receiptFormControllerProvider).draftLines.length,
        1,
      );
    });
  });
}