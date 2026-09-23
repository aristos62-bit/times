/// Dialog δημιουργίας/μετονομασίας κατηγορίας/υποκατηγορίας (§2.3 DESIGN /
/// Φάση 4 Βήμα 4).
///
/// Απλό dumb-stateful dialog (pattern βήματος ονόματος του
/// `NewItemFlowDialog`): παίρνει τίτλο + αρχικό κείμενο, επιστρέφει το
/// trimmed όνομα ή `null` (Ακύρωση/dismiss). Inline validation μέσω
/// `NameValidator` (`errorText`, σβήνει στην επόμενη πληκτρολόγηση —
/// pattern Βήματος 21): άκυρο submit ΔΕΝ κάνει pop. Το dup-check
/// (`nameExists`) γίνεται ΜΕΤΑ το pop από τον καλούντα (controller) με
/// snackbar — όπως το `supplierExists` του header (§2.4).
///
/// Τίτλοι/κουμπιά πάντα SPoT από τον καλούντα: create → `addNewCategory`,
/// rename → `fieldCategory`· κουμπί: create → `newItemSave`, rename →
/// `saveAction`.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_messages.dart';
import '../../../domain/validators/name_validator.dart';

/// Ανοίγει το dialog ονόματος κατηγορίας/υποκατηγορίας.
///
/// Επιστρέφει το trimmed όνομα ή `null` (Ακύρωση/dismiss) — ο καλών μετράει
/// μόνο το non-null (pattern `showConfirmDialog`).
Future<String?> showCategoryEditDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initialName = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => CategoryEditDialog(
      title: title,
      confirmLabel: confirmLabel,
      initialName: initialName,
    ),
  );
}

/// Dialog απλού ονόματος — «χαζό» (§2.0): τίτλος/labels από παραμέτρους,
/// καμία business logic, δεν διαβάζει providers και δεν ανοίγει τη βάση.
class CategoryEditDialog extends StatefulWidget {
  const CategoryEditDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    this.initialName = '',
  });

  /// Τίτλος — πάντα SPoT από τον καλούντα.
  final String title;

  /// Label κουμπιού επιβεβαίωσης — πάντα SPoT από τον καλούντα.
  final String confirmLabel;

  /// Αρχικό κείμενο (μετονομασία) — κενό στη δημιουργία.
  final String initialName;

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  /// Controller πεδίου — prefill από [CategoryEditDialog.initialName].
  late final TextEditingController _controller;

  /// Inline σφάλμα validation — `null` = κανένα.
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Submit: άκυρο → inline σφάλμα (χωρίς pop)· έγκυρο → pop trimmed.
  void _submit() {
    final error = NameValidator.validate(_controller.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      // Responsive §1.4: max-width + scroll — κανένα fixed ύψος.
      content: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: AppConstants.dialogMaxWidth),
        child: SingleChildScrollView(
          child: TextField(
            controller: _controller,
            autofocus: true,
            maxLength: AppConstants.maxItemNameLength,
            inputFormatters: [
              LengthLimitingTextInputFormatter(
                AppConstants.maxItemNameLength,
              ),
            ],
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              errorText: _error,
              errorMaxLines: AppConstants.fieldErrorMaxLines,
              isDense: true,
            ),
            textInputAction: TextInputAction.done,
            // Καθαρισμός inline σφάλματος με την πληκτρολόγηση της
            // διόρθωσης (Βήμα 21 — pattern dialog «+» Βήμα 4).
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppMessages.confirmDialogCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
