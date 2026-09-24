/// Διαχείριση αποδείξεων (§2.3 DESIGN · Φάση Β 24-09-2026).
///
/// Data-section `ConsumerWidget` (pattern `SupplierListEditor`): φίλτρο
/// ημέρας (date-picker, `selectedReceiptDayProvider` · null = όλες) +
/// ζωντανή λίστα συνόψεων (`receiptsByDayStreamProvider`) + μολύβι/κάδος
/// ανά γραμμή (SPoT `ReceiptSummaryTile`, shared με τη λίστα §2.2).
/// Edit/delete reuse ατόφια τον `ReceiptFormController` (Φάση Α): το μολύβι
/// φορτώνει τη φόρμα και πηδάει στο tab «Εισαγωγή» (`goNamed` — καμία νέα
/// route)· ο κάδος διαγράφει επιτόπου (confirm + CASCADE §3). Feedback ΜΟΝΟ
/// από εδώ μέσω `AppFeedback` — ποτέ μέσα στα dialogs (§2.4).
/// Responsive §1.4: στήλη, ellipsis, κανένα fixed/nested scroll (inner
/// Column με dividers, idiom draft-list)· dark/light από theme.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_errors.dart';
import '../../../core/constants/app_messages.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../data/models/receipt_summary.dart';
import '../../../data/providers/stream_providers.dart';
import '../../price_entry/controllers/item_search_controller.dart';
import '../../price_entry/controllers/receipt_form_controller.dart';
import '../../shared/confirm_dialog.dart';
import '../../shared/controller_op_runner.dart';
import '../../shared/receipt_summary_tile.dart';

/// Διαχείριση αποδείξεων με φίλτρο ημέρας (§2.3 · Φάση Β).
class ReceiptsManagementEditor extends ConsumerWidget {
  const ReceiptsManagementEditor({super.key});

  /// Επιλογή ημέρας φίλτρου (pattern `_pickDate` header §2.2): picker με
  /// SPoT όρια· Ακύρωση/dismiss → καμία αλλαγή. Η ημέρα αποθηκεύεται ως
  /// έχει — τα όρια ημέρας τα υπολογίζει το DAO (καθαρό DateTime, §3).
  Future<void> _pickDay(BuildContext context, WidgetRef ref) async {
    final current = ref.read(selectedReceiptDayProvider) ??
        DateUtils.dateOnly(DateTime.now());
    AppLogger.info(LogTag.ui, 'Άνοιγμα date picker φίλτρου αποδείξεων');
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(AppConstants.datePickerFirstYear),
      lastDate: DateTime(AppConstants.datePickerLastYear, 12, 31),
    );
    if (picked == null || !context.mounted) return;
    ref.read(selectedReceiptDayProvider.notifier).select(picked);
    AppLogger.info(
      LogTag.ui,
      'Φίλτρο αποδείξεων: ${picked.toIso8601String()}',
    );
  }

  /// Καθαρισμός φίλτρου → όλες (τελευταίες `manageReceiptsLimit`).
  void _clearFilter(WidgetRef ref) {
    ref.read(selectedReceiptDayProvider.notifier).clear();
    AppLogger.info(LogTag.ui, 'Καθαρισμός φίλτρου αποδείξεων (όλες)');
  }

  /// Διαγραφή απόδειξης: confirm (destructive) → controller → feedback.
  /// Ίδιο με τη λίστα §2.2 (Φάση Α) — η λίστα εδώ ανανεώνεται μόνη της
  /// (ίδιο readsFrom).
  Future<void> _deleteReceipt(
    BuildContext context,
    WidgetRef ref,
    ReceiptSummary summary,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      message: AppMessages.deleteReceiptConfirm(
        summary.id,
        summary.supplierName,
      ),
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;
    await runControllerOp(
      context,
      () => ref
          .read(receiptFormControllerProvider.notifier)
          .deleteReceipt(summary.id),
      AppMessages.receiptDeleted,
    );
  }

  /// Φόρτωση στη φόρμα + άλμα στο tab «Εισαγωγή» (Φάση Β).
  /// Guard drafts (discard-confirm, πνεύμα exit-confirm §2.2:244) και
  /// `goNamed` (AppRoutes SPoT — καμία νέα route· το pop-assert δεν αφορά
  /// το go). Το banner `editingId` φαίνεται στη φόρμα (Φάση Α).
  Future<void> _editAndGo(
    BuildContext context,
    WidgetRef ref,
    ReceiptSummary summary,
  ) async {
    final form = ref.read(receiptFormControllerProvider);
    if (form.isSaving) return;
    if (form.draftLines.isNotEmpty && form.editingId != summary.id) {
      final discard = await showConfirmDialog(
        context,
        message: AppMessages.editDiscardDraftsConfirm,
      );
      if (discard != true || !context.mounted) return;
    }
    try {
      final result = await ref
          .read(receiptFormControllerProvider.notifier)
          .loadReceiptForEdit(summary.id);
      if (!context.mounted) return;
      if (!result.ok) {
        if (result.error != null) AppFeedback.showError(context, result.error!);
        return;
      }
      ref.read(itemSearchControllerProvider.notifier).clearSelection();
      if (!context.mounted) return;
      context.goNamed(AppRoutes.priceEntry);
    } on DataLoadException catch (e) {
      if (!context.mounted) return;
      AppFeedback.showError(context, e.userMessage);
    }
  }

  /// Γραμμή φίλτρου: ListTile ημερομηνίας (tap → picker) + «Όλες»
  /// (ορατό μόνο με ενεργό φίλτρο). Built-in semantics (pattern header).
  Widget _filterTile(BuildContext context, WidgetRef ref, DateTime? filter) {
    final subtitle = filter == null
        ? AppStrings.clearReceiptFilter
        : MaterialLocalizations.of(context).formatMediumDate(filter);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today_outlined),
          title: const Text(AppStrings.fieldDate),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.edit_calendar_outlined),
          onTap: () => _pickDay(context, ref),
        ),
        if (filter != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _clearFilter(ref),
              child: const Text(AppStrings.clearReceiptFilter),
            ),
          ),
      ],
    );
  }

  /// Δεδομένα: φίλτρο + γραμμές (ή κενό — ανάλογα με το φίλτρο).
  Widget _buildData(
    BuildContext context,
    WidgetRef ref,
    List<ReceiptSummary> summaries,
    DateTime? filter,
    bool busy,
  ) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _filterTile(context, ref, filter),
        if (summaries.isEmpty)
          Text(
            filter == null
                ? AppStrings.recentReceiptsEmpty
                : AppStrings.noReceiptsForDay,
            style: theme.textTheme.bodyMedium,
          )
        else
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingL,
                vertical: AppConstants.spacingS,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < summaries.length; i++) ...[
                    if (i > 0)
                      const Divider(height: AppConstants.listDividerHeight),
                    ReceiptSummaryTile(
                      summary: summaries[i],
                      busy: busy,
                      onEdit: () => _editAndGo(context, ref, summaries[i]),
                      onDelete: () => _deleteReceipt(context, ref, summaries[i]),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(receiptsByDayStreamProvider);
    final filter = ref.watch(selectedReceiptDayProvider);
    // Busy-flag (pattern editors §2.3): απενεργοποιεί μολύβι/κάδο όσο
    // τρέχει save/update/delete (§2.4 guard).
    final busy = ref.watch(
      receiptFormControllerProvider.select((s) => s.isSaving),
    );
    // Καταστάσεις (pattern supplier editor): loading · error+Επανάληψη
    // (invalidate stream) · empty/data.
    return async.when(
      data: (summaries) => _buildData(context, ref, summaries, filter, busy),
      loading: () => const Padding(
        padding: EdgeInsets.all(AppConstants.spacingL),
        child: Center(
          child: SizedBox(
            width: AppConstants.smallSpinnerSize,
            height: AppConstants.smallSpinnerSize,
            child: CircularProgressIndicator(
              strokeWidth: AppConstants.spinnerStrokeWidth,
            ),
          ),
        ),
      ),
      error: (_, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppErrors.loadDataFailed,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextButton(
            onPressed: () => ref.invalidate(receiptsByDayStreamProvider),
            child: const Text(AppStrings.retryButton),
          ),
        ],
      ),
    );
  }
}
