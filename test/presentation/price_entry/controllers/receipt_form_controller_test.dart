/// Unit tests — `ReceiptFormController` + `receiptFormControllerProvider`.
///
/// Σύγχρονο (Notifier) state → plain`ProviderContainer` + `addTearDown(dispose)`
/// (μοτίβο Φάσης 1/2 tests). Οι logs επαληθεύονται με `AppLogger.testSink`
/// (pattern app_feedback_test).
library;

import 'package:flutter/material.dart' show DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/logging/app_logger.dart';
import 'package:times/presentation/price_entry/controllers/receipt_form_controller.dart';

void main() {
  setUp(() {
    AppLogger.resetTestSink();
  });
  tearDown(() {
    AppLogger.resetTestSink();
  });

  group('ReceiptFormController', () {
    test('build() → σημερινή ημερομηνία (dateOnly, χωρίς ώρα)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final date = container.read(receiptFormControllerProvider).date;
      expect(date, DateUtils.dateOnly(DateTime.now()));
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
}