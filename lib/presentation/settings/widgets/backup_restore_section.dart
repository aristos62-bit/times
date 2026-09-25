/// Section «Αντίγραφα ασφαλείας» (§2.3 DESIGN / Φάση 4 Βήμα 5).
///
/// Data-less `ConsumerWidget` (pattern Theme section + `SaveReceiptButton`):
/// ΚΑΝΕΝΑ stream/`AsyncValue.when` — μόνο το `isWorking` flag του
/// `BackupRestoreController` (disabled + spinner όσο τρέχει export/restore,
/// §2.4 guard). Export → `runControllerOp` (`backupCreated`)· restore →
/// pick → validate (ΠΡΙΝ το confirm, κλειδωμένη σειρά Δ) → `ConfirmDialog`
/// (destructive) → `runControllerOp` (`restoreSuccess`). Feedback ΜΟΝΟ από
/// εδώ μέσω `AppFeedback` — ποτέ μέσα σε dialogs (§2.4).
/// Responsive §1.4: `Wrap` (320px, κανένα fixed ύψος)· dark/light από theme·
/// semantics από τα text labels (§1.6).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_messages.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../data/providers/settings_providers.dart';
import '../../shared/confirm_dialog.dart';
import '../../shared/controller_op_runner.dart';
import '../controllers/backup_restore_controller.dart';

/// Section εξαγωγής/επαναφοράς αντιγράφου (§2.3 · Βήμα 5).
class BackupRestoreSection extends ConsumerWidget {
  const BackupRestoreSection({super.key});

  /// Εξαγωγή: controller → feedback (ακύρωση = no-op, χωρίς snackbar).
  Future<void> _export(BuildContext context, WidgetRef ref) async {
    await runControllerOp(
      context,
      () => ref.read(backupRestoreControllerProvider.notifier).exportBackup(),
      AppMessages.backupCreated,
    );
  }

  /// Επαναφορά: pick → validate → confirm → controller → feedback.
  /// Ακύρωση pick/dialog → no-op. Άκυρο αρχείο → error, καμία αλλαγή.
  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(backupRestoreControllerProvider.notifier);
    AppLogger.info(LogTag.ui, 'Άνοιγμα επιλογής αντιγράφου');
    final path = await ref.read(backupFilePickerProvider).pickSingleFile();
    if (path == null || !context.mounted) return;
    try {
      final check = await controller.validateCandidate(path);
      if (!context.mounted) return;
      if (!check.ok) {
        if (check.error != null) AppFeedback.showError(context, check.error!);
        return;
      }
    } on AppException catch (e) {
      if (!context.mounted) return;
      AppFeedback.showError(context, e.userMessage);
      return;
    }
    if (!context.mounted) return;
    final confirmed = await showConfirmDialog(
      context,
      message: AppMessages.restoreConfirmWithBackup,
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;
    await runControllerOp(
      context,
      () => controller.restoreBackup(path),
      AppMessages.restoreSuccess,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Busy-flag: απενεργοποιεί και τα δύο κουμπιά όσο τρέχει op (§2.4 guard).
    final working = ref.watch(
      backupRestoreControllerProvider.select((s) => s.isWorking),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppConstants.spacingM,
          runSpacing: AppConstants.spacingM,
          children: [
            FilledButton.icon(
              onPressed: working ? null : () => _export(context, ref),
              icon: working
                  ? const SizedBox(
                      width: AppConstants.smallSpinnerSize,
                      height: AppConstants.smallSpinnerSize,
                      child: CircularProgressIndicator(
                        strokeWidth: AppConstants.spinnerStrokeWidth,
                      ),
                    )
                  : const Icon(Icons.upload_outlined),
              label: const Text(AppStrings.backupExportAction),
            ),
            OutlinedButton.icon(
              onPressed: working ? null : () => _restore(context, ref),
              icon: const Icon(Icons.download_outlined),
              label: const Text(AppStrings.backupRestoreAction),
            ),
          ],
        ),
      ],
    );
  }
}
