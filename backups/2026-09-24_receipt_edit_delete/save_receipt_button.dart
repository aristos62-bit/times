/// Κουμπί αποθήκευσης ολόκληρης απόδειξης (§2.2 DESIGN / Βήμα 5δ).
///
/// Disabled-OR (§2.2): ανενεργό ΟΤΑΝ κενό «καλάθι» Ή κανένας προμηθευτής Ή
/// `isSaving` σε εξέλιξη. Ο κανόνας προέρχεται από τον SPoT
/// `ReceiptValidator.validateReceipt` (Βήμα 6ε — ίδιος με το safety-net του
/// `saveReceipt`)· όταν υπάρχουν γραμμές αλλά λείπει ο προμηθευτής
/// εμφανίζεται hint `supplierRequired` κάτω από το κουμπί (εξηγεί γιατί είναι
/// ανενεργό). Το πάτημα καλεί `saveReceipt` και διαχειρίζεται το
/// feedback ΜΟΝΟ από εδώ (dinner party rule — ποτέ μέσα στον controller):
/// επιτυχία → `savedReceipt` + καθάρισμα επιλογής είδους· αποτυχία
/// (`SaveReceiptException`, drafts ΠΑΡΑΜΕΝΟΥΝ §2.2:213) → `e.userMessage`.
/// Ασφάλεια context: `context.mounted` μετά το await (το AppFeedback έχει
/// δικό του guard, εδώ ζώνη άμυνας σε βάθος).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_errors.dart';
import '../../../core/constants/app_messages.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../domain/validators/receipt_validator.dart';
import '../controllers/item_search_controller.dart';
import '../controllers/receipt_form_controller.dart';

/// Κουμπί «Αποθήκευση Απόδειξης» — disabled-OR + feedback (§2.2 · Βήμα 5δ).
class SaveReceiptButton extends ConsumerWidget {
  const SaveReceiptButton({super.key});

  /// Πάτημα: save → success (snackbar + καθάρισμα επιλογής) / error (snackbar).
  /// Απρόβλεπτο σφάλμα (όχι `SaveReceiptException`) → γενικό
  /// `AppErrors.saveFailed`· ο controller έχει ήδη σβήσει το `isSaving` και
  /// έχει καταγράψει το σφάλμα.
  Future<void> _save(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(receiptFormControllerProvider.notifier).saveReceipt();
      if (!context.mounted) return;
      AppFeedback.showSuccess(context, AppMessages.savedReceipt);
      // Η φόρμα καθάρισε (resetForm)· η επιλογή είδους καθαρίζει κι αυτή
      // (no-op αν ήδη null — π.χ. το section έκλεισε με το τελευταίο add).
      ref.read(itemSearchControllerProvider.notifier).clearSelection();
    } on SaveReceiptException catch (e) {
      if (!context.mounted) return;
      AppFeedback.showError(context, e.userMessage);
    } catch (_) {
      if (!context.mounted) return;
      AppFeedback.showError(context, AppErrors.saveFailed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(receiptFormControllerProvider);
    final theme = Theme.of(context);
    // Disabled-OR (§2.2) μέσω SPoT validator (Βήμα 6ε): κενό «καλάθι» ∨
    // κανένας προμηθευτής ∨ σώζει ήδη.
    final error = ReceiptValidator.validateReceipt(
      hasSupplier: form.supplier != null,
      lineCount: form.draftLines.length,
    );
    final canSave = error == null && !form.isSaving;
    // Hint: υπάρχουν γραμμές (οι γραμμές ελέγχονται πρώτα) αλλά λείπει ο
    // προμηθευτής — δεν εμφανίζεται σε κενό «καλάθι».
    final showSupplierHint = error == AppErrors.supplierRequired;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: canSave ? () => _save(context, ref) : null,
          icon: form.isSaving
              ? const SizedBox(
            width: AppConstants.smallSpinnerSize,
            height: AppConstants.smallSpinnerSize,
            child: CircularProgressIndicator(
              strokeWidth: AppConstants.spinnerStrokeWidth,
            ),
          )
              : const Icon(Icons.save_outlined),
          label: const Text(AppStrings.saveReceipt),
        ),
        if (showSupplierHint)
          Padding(
            padding: const EdgeInsets.only(top: AppConstants.spacingS),
            child: Semantics(
              liveRegion: true,
              child: Text(
                AppErrors.supplierRequired,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
