/// Header της φόρμας απόδειξης (§2.2 DESIGN / Φάση 3 Βήμα 3).
///
/// Ημερομηνία (read-only, tap → `showDatePicker` ελληνικά) + προμηθευτής
/// (`SearchableDropdownField`, §2.4) στο ίδιο Card. Widget "dumb" για την
/// ημερομηνία· η ΜΟΝΗ repo πρόσβαση είναι η inline δημιουργία προμηθευτή
/// («+») — user action, επιτρεπτή (§2.0.1). Το feedback (SnackBar) γίνεται
/// μόνο από εδώ μέσω AppFeedback (SPoT app_messages/app_errors).
/// Κλείδωμα προμηθευτή (όπως είδος, §2.4): μετά επιλογή το dropdown
/// αντικαθίσταται από locked banner (ListTile + «Αλλαγή») μέχρι καθαρισμό
/// φόρμας (save/reset/exit-Ναι) ή χειροκίνητη «Αλλαγή».
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_errors.dart';
import '../../../core/constants/app_messages.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../data/local/app_database.dart';
import '../../../data/providers/stream_providers.dart';
import '../../../domain/validators/name_validator.dart';
import '../../shared/searchable_dropdown_field.dart';
import '../controllers/receipt_form_controller.dart';

//// Ενότητα header της φόρμας: field ημερομηνίας (inline date picker) +
/// field προμηθευτή (live search + «+» δημιουργία).
class ReceiptHeaderSection extends ConsumerStatefulWidget {
  const ReceiptHeaderSection({super.key});

  @override
  ConsumerState<ReceiptHeaderSection> createState() =>
      _ReceiptHeaderSectionState();
}

class _ReceiptHeaderSectionState extends ConsumerState<ReceiptHeaderSection> {
  /// «Γενιά» του πεδίου προμηθευτή. Αυξάνεται όταν ο προμηθευτής της φόρμας
  /// γίνει null μετά από τιμή (resetForm μετά από save, §2.2:212, ή
  /// χειροκίνητη «Αλλαγή»), ώστε το πεδίο να αναδημιουργηθεί άδειο — το
  /// SearchableDropdownField δεν υποστηρίζει εξωτερικό καθάρισμα.
  int _supplierFieldEpoch = 0;

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

  /// Δημιουργία προμηθευτή από το «+» του dropdown (§2.4). Επιστρέφει τον
  /// προμηθευτή (νέο ή υπάρχον) για εμφάνιση στο πεδίο· εμφανίζει το σωστό
  /// SnackBar (supplierAdded vs supplierExists) μέσω AppFeedback. Σφάλμα DB
  /// (DataLoadException) → AppErrors.loadDataFailed. Βήμα 6ε: το όνομα
  /// επικυρώνεται ΠΡΙΝ το DB (`NameValidator`, §2.2) — κενό ή πάνω από
  /// `maxItemNameLength` → snackbar σφάλματος, καμία εγγραφή.
  Future<Supplier?> _createSupplier(
    BuildContext context,
    WidgetRef ref,
    String name,
  ) async {
    final nameError = NameValidator.validate(name);
    if (nameError != null) {
      AppFeedback.showError(context, nameError);
      return null;
    }
    try {
      final result = await ref
          .read(receiptFormControllerProvider.notifier)
          .createSupplier(name);
      if (!context.mounted) return result.supplier;
      if (result.supplier == null) return null;
      if (result.created) {
        AppFeedback.showSuccess(context, AppMessages.supplierAdded);
      } else {
        AppFeedback.showSuccess(context, AppMessages.supplierExists);
      }
      return result.supplier;
    } on DataLoadException {
      if (context.mounted) {
        AppFeedback.showError(context, AppErrors.loadDataFailed);
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Καθάρισμα πεδίου προμηθευτή όταν η φόρμα μηδενίζεται (§2.2:212) ή
    // πατιέται «Αλλαγή» — το dropdown ξαναχτίζεται άδειο (νέο epoch).
    ref.listen<Supplier?>(
      receiptFormControllerProvider.select((s) => s.supplier),
      (previous, next) {
        if (previous != null && next == null) {
          setState(() => _supplierFieldEpoch++);
        }
      },
    );
    final form = ref.watch(receiptFormControllerProvider);
    final date = form.date;
    final supplier = form.supplier;
    final formatted = MaterialLocalizations.of(context).formatMediumDate(date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(AppStrings.fieldDate),
            subtitle: Text(formatted),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: () => _pickDate(context, ref),
            // Προσβασιμότητα (§1.6): ListTile συνθέτει μόνο του το semantic
            // label από title+subtitle+onTap — δεν χρειάζεται επιπλέον Semantics.
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spacingL,
              AppConstants.spacingS,
              AppConstants.spacingL,
              AppConstants.spacingL,
            ),
            // Κλείδωμα προμηθευτή (όπως είδος §2.4): επιλεγμένος →
            // locked banner (ListTile + «Αλλαγή», reuse `changeItem`)·
            // κανένας → live search dropdown. Το dropdown υπάρχει ΜΟΝΟ
            // χωρίς επιλογή, άρα το `onCleared` είναι νεκρό και αφαιρέθηκε.
            child: supplier != null
                ? ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(
                      supplier.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: TextButton(
                      onPressed: () => ref
                          .read(receiptFormControllerProvider.notifier)
                          .setSupplier(null),
                      child: const Text(AppStrings.changeItem),
                    ),
                  )
                : SearchableDropdownField<Supplier>(
                    key: ValueKey(_supplierFieldEpoch),
                    labelText: AppStrings.fieldSupplier,
                    hintText: AppStrings.supplierSearchHint,
                    searchProvider: supplierSearchProvider.call,
                    labelOf: (s) => s.name,
                    // «+» ΠΑΝΤΑ στην ουρά όταν υπάρχει query — ορατό ακόμα
                    // με 0 αποτελέσματα (απόφαση χρήστη §2.4).
                    createLabel: (query) =>
                        '${AppStrings.addNewSupplier} "$query"',
                    onSelected: (s) => ref
                        .read(receiptFormControllerProvider.notifier)
                        .setSupplier(s),
                    onCreate: (name) => _createSupplier(context, ref, name),
                  ),
          ),
        ],
      ),
    );
  }
}
