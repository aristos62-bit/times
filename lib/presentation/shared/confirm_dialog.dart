/// SPoT shared widget: generic επιβεβαιωτικό dialog (§2.4 DESIGN).
///
/// Χρήσεις (§2.4 πίνακας): διαγραφή/αντικατάσταση (Φάση 4) και έξοδος με
/// μη αποθηκευμένες γραμμές («Ημιτελής καταχώρηση», §2.2:244). Τίτλος,
/// μήνυμα και κουμπιά από παραμέτρους — SPoT defaults από
/// `AppMessages` (`confirmDialogTitle`/`confirmDialogConfirm`/
/// `confirmDialogCancel`)· το widget ΔΕΝ ορίζει δικά του κείμενα (§1.3).
///
/// Αποτέλεσμα `Future<bool?>`: `true` = επιβεβαίωση, `false` = «Ακύρωση»,
/// `null` = dismiss (tap εκτός dialog / system back) — ο καλών αντιμετωπίζει
/// το `null` ως ακύρωση (κανένα side effect).
///
/// Responsive §1.4: `ConstrainedBox(maxWidth: dialogMaxWidth)` +
/// `SingleChildScrollView` — κανένα fixed ύψος (μακρύ μήνυμα scroll, όχι
/// overflow — ίδιο pattern με το `NewItemFlowDialog`). Dark/light από το
/// theme (`colorScheme`· `isDestructive` χρωματίζει το κουμπί error με
/// `onError` foreground — contrast ασφαλές).
library;

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_messages.dart';

/// Ανοίγει το generic επιβεβαιωτικό dialog.
///
/// Επιστρέφει `true` με το κουμπί επιβεβαίωσης, `false` με «Ακύρωση» και
/// `null` σε dismiss (barrier/back) — ο καλών μετράει μόνο το `true`.
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String message,
  String? title,
  String? confirmLabel,
  String? cancelLabel,
  bool isDestructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => ConfirmDialog(
      message: message,
      title: title,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
    ),
  );
}

/// Generic επιβεβαιωτικό dialog — «χαζό» widget (§2.0): τίτλος/μήνυμα/actions
/// από παραμέτρους με SPoT defaults, καμία business logic, δεν διαβάζει
/// providers και δεν ανοίγει τη βάση (§2.0.1).
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.message,
    this.title,
    this.confirmLabel,
    this.cancelLabel,
    this.isDestructive = false,
  });

  /// Μήνυμα — πάντα SPoT (AppMessages/AppErrors) από τον καλούντα.
  final String message;

  /// Τίτλος — default `AppMessages.confirmDialogTitle` («Επιβεβαίωση»).
  final String? title;

  /// Κουμπί επιβεβαίωσης — default `AppMessages.confirmDialogConfirm` («Ναι»).
  final String? confirmLabel;

  /// Κουμπί ακύρωσης — default `AppMessages.confirmDialogCancel` («Ακύρωση»).
  final String? cancelLabel;

  /// Καταστροφική ενέργεια (π.χ. διαγραφή, §2.3): το κουμπί επιβεβαίωσης
  /// χρωματίζεται error. Default `false` — ουδέτερες επιβεβαιώσεις (έξοδος).
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(title ?? AppMessages.confirmDialogTitle),
      // Responsive (§1.4): max-width + scroll — κανένα fixed ύψος.
      content: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: AppConstants.dialogMaxWidth),
        child: SingleChildScrollView(child: Text(message)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel ?? AppMessages.confirmDialogCancel),
        ),
        FilledButton(
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel ?? AppMessages.confirmDialogConfirm),
        ),
      ],
    );
  }
}