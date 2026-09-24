/// SPoT delete-gate button (§2.3:275 · 24-09-2026).
///
/// Κοινό κουμπί πύλης διαγραφής για τους settings editors (κατηγορίες/
/// προμηθευτές — πριν αντιγραμμένο και στους δύο): καθαρό → ενεργό·
/// μπλοκαρισμένο → greyed-out + tooltip με πλήθος (όχι error-after-tap)·
/// loading πύλης → ανενεργό· error πύλης → ανενεργό + tap=retry.
/// Dumb `StatelessWidget` (§2.0): ο γονέας κάνει watch και περνά
/// `AsyncValue`s — καμία provider-ανάγνωση εδώ.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_errors.dart';
import '../../../core/constants/app_strings.dart';

/// Κουμπί διαγραφής με πύλη (§2.3:275).
class DeleteGateButton extends StatelessWidget {
  const DeleteGateButton({
    super.key,
    required this.canDelete,
    required this.count,
    required this.blockedTooltip,
    required this.onDelete,
    required this.onRetry,
    required this.working,
  });

  /// Πύλη: `true` = καθαρό (ενεργό) · `false` = μπλοκαρισμένο (greyed +
  /// tooltip) · error = ανενεργό + tap retry.
  final AsyncValue<bool> canDelete;

  /// Πλήθος για το blocked tooltip (sibling int provider, Βήμα 4).
  final AsyncValue<int> count;

  /// Χτίζει το blocked tooltip από το πλήθος (π.χ. `itemsInUseTooltip`,
  /// `supplierReceiptsTooltip` — SPoT καλούντος).
  final String Function(int count) blockedTooltip;

  /// Διαγραφή (null = ανενεργό λόγω `working` — το gate ήδη πέρασε).
  final VoidCallback? onDelete;

  /// Επανάληψη πύλης σε error (invalidate families — καλούντος).
  final VoidCallback onRetry;

  /// CRUD σε εξέλιξη → όλα ανενεργά (double-tap guard, §2.4).
  final bool working;

  @override
  Widget build(BuildContext context) {
    final ok = canDelete.value;
    if (ok == true) {
      return IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: AppStrings.deleteAction,
        onPressed: working ? null : onDelete,
      );
    }
    if (canDelete.hasError) {
      return IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: AppErrors.loadDataFailed,
        onPressed: onRetry,
      );
    }
    final loaded = count.value;
    return IconButton(
      icon: const Icon(Icons.delete_outline),
      tooltip: ok == false && loaded != null
          ? blockedTooltip(loaded)
          : AppStrings.deleteAction,
      onPressed: null,
    );
  }
}
