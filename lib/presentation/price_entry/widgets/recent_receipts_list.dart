/// Read-only λίστα των τελευταίων αποδείξεων (§2.2 DESIGN · Φάση 3 Βήμα 7).
///
/// Προβολή των `AppConstants.recentReceiptsLimit` τελευταίων αποδείξεων
/// (ReceiptSummary projection, §3): κάθε γραμμή εμφανίζει αριθμό απόδειξης,
/// ημερομηνία (formatShortDate — «Ιαν 1, 2026», με έτος: το formatMediumDate
/// σε αυτή την έκδοση Flutter βγάζει «Πέμ, Ιαν 1» χωρίς έτος, απόφαση
/// χρήστη), προμηθευτή, πλήθος γραμμών και σύνολο ευρώ. **Read-only**: καμία
/// εγγραφή/ενέργεια ανά γραμμή. Σύμφωνα με την Α1: πάντα ορατή στην
/// PriceEntry (η βάση είναι ανοιχτή στο launch, IndexedStack §2.0).
///
/// Πηγή: `recentReceiptsStreamProvider` (NON-autoDispose, §2.0.1). Η λίστα
/// ανανεώνεται ΜΟΝΗ της μετά το save (§2.2:212) — ο customSelectStream
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
import '../../../data/models/receipt_summary.dart';
import '../../../data/providers/stream_providers.dart';
import '../../shared/currency_text_field.dart';

/// Λίστα πρόσφατων αποδείξεων (§2.2 · read-only).
class RecentReceiptsList extends ConsumerWidget {
  const RecentReceiptsList({super.key});

  /// Μία απόδειξη: #αριθμός (title) · προμηθευτής · ημερομηνία · γραμμές
  /// (subtitle) · σύνολο ευρώ (trailing). Read-only — χωρίς tap/icon.
  Widget _buildRow(BuildContext context, ReceiptSummary summary) {
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
      trailing: Text(
        '${CurrencyTextField.formatCents(summary.totalCents)} '
        '${AppStrings.currencySymbol}',
        style: theme.textTheme.titleSmall,
      ),
    );
  }

  /// Card με τις γραμμές (divider μεταξύ τους) — ίδιο idiom με το DraftLinesList.
  Widget _buildList(BuildContext context, List<ReceiptSummary> summaries) {
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
              _buildRow(context, summaries[i]),
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
              : _buildList(context, summaries),
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