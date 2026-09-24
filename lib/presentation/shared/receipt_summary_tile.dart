/// SPoT tile γραμμής σύνοψης απόδειξης (§2.2 Βήμα 7 · Φάση Α · §2.3 Φάση Β).
///
/// Dumb widget (§2.0): παίρνει έτοιμο `ReceiptSummary` + actions ως
/// callbacks — δεν διαβάζει providers, δεν ανοίγει βάση. Χρήσεις:
/// `RecentReceiptsList` (μολύβι + κάδος) και `ReceiptsManagementEditor`
/// (ίδια) — μία υλοποίηση, καμία αντιγραφή (§2.4 shared).
/// Προσβασιμότητα (§1.6): tooltips στα εικονίδια (semantics δωρεάν).
library;

import 'package:flutter/material.dart';

import '../../core/constants/app_messages.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/receipt_summary.dart';
import 'currency_text_field.dart';

/// Μία απόδειξη: #αριθμός (title) · προμηθευτής · ημερομηνία · γραμμές
/// (subtitle) · σύνολο € + προαιρετικά μολύβι/κάδος (trailing).
class ReceiptSummaryTile extends StatelessWidget {
  const ReceiptSummaryTile({
    super.key,
    required this.summary,
    this.onEdit,
    this.onDelete,
    this.busy = false,
  });

  /// Η σύνοψη (projection `ReceiptSummary`, §3).
  final ReceiptSummary summary;

  /// null = χωρίς μολύβι (μόνο προβολή).
  final VoidCallback? onEdit;

  /// null = χωρίς κάδο (μόνο προβολή).
  final VoidCallback? onDelete;

  /// CRUD σε εξέλιξη → actions ανενεργά (double-tap guard, §2.4).
  final bool busy;

  @override
  Widget build(BuildContext context) {
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
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: AppStrings.editAction,
              onPressed: busy ? null : onEdit,
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: theme.colorScheme.error,
              tooltip: AppStrings.deleteAction,
              onPressed: busy ? null : onDelete,
            ),
        ],
      ),
    );
  }
}
