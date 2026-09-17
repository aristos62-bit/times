/// Header της φόρμας απόδειξης (§2.2 DESIGN / Φάση 3 Βήμα 2).
///
/// Ημερομηνία (read-only, tap → `showDatePicker` ελληνικά) — ο προμηθευτής
/// προστίθεται στο Βήμα 3 (slot: ίδιο `ReceiptHeaderSection`, νέο πεδίο).
/// Widget "dumb": παίρνει την ημερομηνία από το provider μέσω `ref.watch`·
/// η επιλογή γίνεται μόνο μέσω picker — κανένα χειροκίνητο input.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/logging/app_logger.dart';
import '../controllers/receipt_form_controller.dart';

/// Ενότητα header της φόρμας: field ημερομηνίας με inline date picker.
class ReceiptHeaderSection extends ConsumerWidget {
  const ReceiptHeaderSection({super.key});

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final current = ref.read(receiptFormControllerProvider).date;
    AppLogger.info(LogTag.ui, 'Άνοιγμα date picker απόδειξης');
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(AppConstants.datePickerFirstYear),
      lastDate: DateTime(AppConstants.datePickerLastYear, 12, 31),
    );
    // Guard async gap (use_build_context_synchronously) — μοτίβο app_feedback.
    if (picked == null || !context.mounted) return;
    ref.read(receiptFormControllerProvider.notifier).setDate(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(receiptFormControllerProvider).date;
    final formatted = MaterialLocalizations.of(context).formatMediumDate(date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      child: ListTile(
        leading: const Icon(Icons.calendar_today_outlined),
        title: Text(AppStrings.fieldDate),
        subtitle: Text(formatted),
        trailing: const Icon(Icons.edit_calendar_outlined),
        onTap: () => _pickDate(context, ref),
        // Προσβασιμότητα (§1.6): ListTile συνθέτει μόνο του το semantic label
        // από title+subtitle+onTap — δεν χρειάζεται επιπλέον Semantics.
      ),
    );
  }
}