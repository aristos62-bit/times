/// Unit tests — όριο `maxReceiptLines` στον `ReceiptFormController.addDraftLine`
/// (Φάση 3, Βήμα 5ε-2 · §2.2). Σύγχρονο state — καμία βάση.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_constants.dart';
import 'package:times/presentation/price_entry/controllers/receipt_form_controller.dart';
import 'package:times/presentation/price_entry/state/receipt_form_state.dart';

void main() {
  DraftReceiptLine lineOf(int id) => DraftReceiptLine(
    itemId: id,
    unitId: 1,
    quantity: 1,
    priceCents: 100,
    itemName: 'Είδος $id',
    unitAbbreviation: 'τεμ',
  );

  group('addDraftLine — όριο maxReceiptLines (Β5ε-2)', () {
    test('μέχρι το όριο προστίθενται όλες οι γραμμές', () {
      final container = ProviderContainer.test();
      final notifier = container.read(receiptFormControllerProvider.notifier);
      for (var i = 0; i < AppConstants.maxReceiptLines; i++) {
        notifier.addDraftLine(lineOf(i));
      }
      expect(
        container.read(receiptFormControllerProvider).draftLines,
        hasLength(AppConstants.maxReceiptLines),
      );
    });

    test('πέρα από το όριο → η γραμμή αγνοείται (χωρίς exception)', () {
      final container = ProviderContainer.test();
      final notifier = container.read(receiptFormControllerProvider.notifier);
      for (var i = 0; i < AppConstants.maxReceiptLines; i++) {
        notifier.addDraftLine(lineOf(i));
      }
      notifier.addDraftLine(lineOf(999));
      final lines = container.read(receiptFormControllerProvider).draftLines;
      expect(lines, hasLength(AppConstants.maxReceiptLines));
      expect(lines.any((l) => l.itemId == 999), isFalse);
    });

    test('μετά από αφαίρεση γραμμής → ξαναδέχεται γραμμή', () {
      final container = ProviderContainer.test();
      final notifier = container.read(receiptFormControllerProvider.notifier);
      for (var i = 0; i < AppConstants.maxReceiptLines; i++) {
        notifier.addDraftLine(lineOf(i));
      }
      notifier.removeDraftLine(0);
      notifier.addDraftLine(lineOf(999));
      final lines = container.read(receiptFormControllerProvider).draftLines;
      expect(lines, hasLength(AppConstants.maxReceiptLines));
      expect(lines.last.itemId, 999);
    });
  });
}