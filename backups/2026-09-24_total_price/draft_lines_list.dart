/// Λίστα γραμμών «καλαθιού» της τρέχουσας απόδειξης (§2.2 DESIGN / Βήμα 5γ).
///
/// Διαβάζει ΜΟΝΟ το σύγχρονο `receiptFormControllerProvider.draftLines` —
/// καμία DB πρόσβαση (οι γραμμές γράφονται ατομικά στο save, Βήμα 5δ).
/// ΧΩΡΙΣ line totals ανά γραμμή (απόφαση Δ2 — τα σύνολα υπολογίζονται στο
/// Βήμα 7, SPoT μαθηματικών το DAO). Κάθε γραμμή ανεξάρτητη — ίδιο είδος σε
/// πολλές γραμμές ΕΠΙΤΡΕΠΕΤΑΙ (§2.2:237). Διαγραφή ανά γραμμή (index).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../shared/currency_text_field.dart';
import '../../shared/quantity_text_field.dart';
import '../controllers/receipt_form_controller.dart';
import '../state/receipt_form_state.dart';

/// Προβολή του «καλαθιού»: τίτλος + (κενή κατάσταση | γραμμές με διαγραφή).
class DraftLinesList extends ConsumerWidget {
  const DraftLinesList({super.key});

  /// Μία γραμμή: όνομα + «ποσότητα συντ. · τιμή €» + αφαίρεση.
  Widget _buildRow(
    BuildContext context,
    WidgetRef ref,
    DraftReceiptLine line,
    int index,
  ) {
    final detail =
        '${QuantityTextField.formatQuantity(line.quantity)} '
        '${line.unitAbbreviation} · '
        '${CurrencyTextField.formatCents(line.priceCents)} '
        '${AppStrings.currencySymbol}';
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        line.itemName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        detail,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: AppStrings.removeDraftLine,
        onPressed: () => ref
            .read(receiptFormControllerProvider.notifier)
            .removeDraftLine(index),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(receiptFormControllerProvider).draftLines;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.draftLinesTitle,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppConstants.spacingS),
        if (lines.isEmpty)
          Text(
            AppStrings.draftLinesEmpty,
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
                  for (var i = 0; i < lines.length; i++) ...[
                    if (i > 0)
                      const Divider(height: AppConstants.listDividerHeight),
                    _buildRow(context, ref, lines[i], i),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
