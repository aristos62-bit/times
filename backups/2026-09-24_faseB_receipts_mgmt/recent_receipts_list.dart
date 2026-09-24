/// Λίστα των τελευταίων αποδείξεων (§2.2 DESIGN · Φάση 3 Βήμα 7 + Φάση Α).
///
/// Προβολή των `AppConstants.recentReceiptsLimit` τελευταίων αποδείξεων
/// (ReceiptSummary projection, §3): κάθε γραμμή εμφανίζει αριθμό απόδειξης,
/// ημερομηνία (formatShortDate — «Ιαν 1, 2026», με έτος: το formatMediumDate
/// σε αυτή την έκδοση Flutter βγάζει «Πέμ, Ιαν 1» χωρίς έτος, απόφαση
/// χρήστη), προμηθευτή, πλήθος γραμμών και σύνολο ευρώ.
/// Φάση Α (24-09-2026): κάθε γραμμή έχει μολύβι (φόρτωση στη φόρμα,
/// `editingId`) + κόκκινο κάδο (διαγραφή με confirm, CASCADE §3).
/// Σύμφωνα με την Α1: πάντα ορατή στην
/// PriceEntry (η βάση είναι ανοιχτή στο launch, IndexedStack §2.0).
///
/// Πηγή: `recentReceiptsStreamProvider` (NON-autoDispose, §2.0.1). Η λίστα
/// ανανεώνεται ΜΟΝΗ της μετά από save/update/delete (§2.2:212) — ο customSelectStream
/// re-emit την αλλαγή, χωρίς ref.invalidate/χειροκίνητο refresh.
/// Καταστάσεις (Γ1 — απλό `when`, το AsyncValueView έρχεται ξεχωριστό):
/// loading → spinner · error → AppErrors.loadDataFailed + «Επανάληψη»
/// (ref.invalidate) · κενή → AppStrings.recentReceiptsEmpty · δεδομένα → Card.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_errors.dart';
import '../../../core/constants/app_messages.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../data/models/receipt_summary.dart';
import '../../../data/providers/stream_providers.dart';
import '../../shared/confirm_dialog.dart';
import '../../shared/controller_op_runner.dart';
import '../../shared/currency_text_field.dart';
import '../controllers/item_search_controller.dart';
import '../controllers/receipt_form_controller.dart';

/// Λίστα πρόσφατων αποδείξεων (§2.2 · Βήμα 7 + Φάση Α actions).
class RecentReceiptsList extends ConsumerWidget {
  const RecentReceiptsList({super.key});

  /// Διαγραφή απόδειξης: confirm (destructive) → controller → feedback.
  /// Pattern `_deleteSupplier` (§2.3): feedback ΜΟΝΟ εδώ, ποτέ στο dialog.
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

  /// Φόρτωση απόδειξης στη φόρμα για επεξεργασία (Φάση Α).
  /// Με γεμάτα drafts (άλλης απόδειξης) → confirm απόρριψης πρώτα
  /// (πνεύμα exit-confirm §2.2:244 — όχι σιωπηλή απώλεια).
  /// Επιτυχία → καθάρισμα επιλογής είδους (banner `editingId` εμφανίζεται
  /// στη σελίδα)· σφάλμα → snackbar (record error ή DataLoadException).
  Future<void> _editReceipt(
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
    } on DataLoadException catch (e) {
      if (!context.mounted) return;
      AppFeedback.showError(context, e.userMessage);
    }
  }

  /// Μία απόδειξη: #αριθμός (title) · προμηθευτής · ημερομηνία · γραμμές
  /// (subtitle) · σύνολο ευρώ + μολύβι/κάδος (trailing, Φάση Α).
  Widget _buildRow(
    BuildContext context,
    WidgetRef ref,
    ReceiptSummary summary,
    bool busy,
  ) {
    final theme = Theme.of(context);
    final date =
        MaterialLocalizations.of(context).formatShortDate(summary.date);
    final subtitle = '${summary.supplierName} · $date · '
        '${AppMessages.receiptLinesLabel(summary.lineCount)}';
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        AppMessages.receiptNumber(summary.id),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${CurrencyTextField.formatCents(summary.totalCents)} '
            '${AppStrings.currencySymbol}',
            style: theme.textTheme.titleSmall,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: AppStrings.editAction,
            onPressed:
                busy ? null : () => _editReceipt(context, ref, summary),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: theme.colorScheme.error,
            tooltip: AppStrings.deleteAction,
            onPressed:
                busy ? null : () => _deleteReceipt(context, ref, summary),
          ),
        ],
      ),
    );
  }

  /// Card με τις γραμμές (divider μεταξύ τους) — ίδιο idiom με το DraftLinesList.
  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<ReceiptSummary> summaries,
    bool busy,
  ) {
    return Card(
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
              _buildRow(context, ref, summaries[i], busy),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(recentReceiptsStreamProvider);
    // Busy-flag (pattern editors §2.3): απενεργοποιεί μολύβι/κάδο όσο
    // τρέχει save/update/delete (§2.4 guard).
    final busy = ref.watch(
      receiptFormControllerProvider.select((s) => s.isSaving),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.recentReceiptsTitle,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppConstants.spacingS),
        // Καταστάσεις (Γ1): loading spinner · error + retry · empty · data.
        async.when(
          data: (summaries) => summaries.isEmpty
              ? Text(
                  AppStrings.recentReceiptsEmpty,
                  style: theme.textTheme.bodyMedium,
                )
              : _buildList(context, ref, summaries, busy),
          loading: () => const Padding(
            padding: EdgeInsets.all(AppConstants.spacingL),
            child: Center(
              // smallSpinnerSize: κοινό μέγεθος μικρών spinners (§1.1).
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
                style: theme.textTheme.bodyMedium,
              ),
              // «Επανάληψη» → invalidate: ο provider ξανατρέχει τον customSelect.
              TextButton(
                onPressed: () => ref.invalidate(recentReceiptsStreamProvider),
                child: const Text(AppStrings.retryButton),
              ),
            ],
          ),
        ),
      ],
    );
  }
}