/// SPoT: Snackbar wrapper — το ΜΟΝΟ σημείο εμφάνισης μηνυμάτων ροής (§2.0.6).
///
/// Αντικαθιστά κάθε σκόρπιο `ScaffoldMessenger.of(context).showSnackBar(...)`
/// μέσα σε widgets. Οι οθόνες/controllers καλούν αποκλειστικά:
///   AppFeedback.showSuccess(context, AppMessages.savedReceipt);
///   AppFeedback.showError(context, AppErrors.saveFailed);
/// όπου το κείμενο είναι πάντα SPoT (app_messages/app_errors) — το util
/// ΟΥΔΕΠΟΤΕ ορίζει δικό του κείμενο (§1.3).
///
/// Συμπεριφορά:
///   * Διάρκεια από AppConstants.snackBarDurationSeconds.
///   * Error: errorContainer/onErrorContainer (dark/light-safe, §1.5) και
///     clearSnackBars() πριν — το σφάλμα φαίνεται άμεσα, χωρίς ουρά.
///   * Success: Material default χρώματα, χωρίς clear (μπαίνει κανονικά στην ουρά).
///   * Overflow safety: maxLines = AppConstants.maxFeedbackLines (§1.4).
///   * Ασφάλεια context: mounted guard + maybeOf — κανένα crash χωρίς scaffold.
///     Σε αντίθεση με τον Debouncer, ΔΕΝ έχει timers/state/leak — το Material
///     διαχειρίζεται το lifecycle του snackbar μόνο του.
library;

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../logging/app_logger.dart';

/// SPoT namespace — μόνο static, δεν instantiate (pattern AppConstants).
abstract final class AppFeedback {
  /// Εμφανίζει snackbar επιτυχίας με το SPoT [message] (Material default
  /// χρώματα, χωρίς clear — μπαίνει κανονικά στην ουρά του messenger).
  static void showSuccess(BuildContext context, String message) =>
      _show(context, message, isError: false);

  /// Εμφανίζει snackbar σφάλματος με το SPoT [message]. Διακόπτει (clear)
  /// προηγούμενα μηνύματα ώστε το σφάλμα να μην περιμένει σε ουρά.
  static void showError(BuildContext context, String message) =>
      _show(context, message, isError: true);

  /// Μοναδική υλοποίηση εμφάνισης — ποτέ διπλός κώδικας (§2.0.6).
  static void _show(BuildContext context, String message,
      {required bool isError}) {
    // Προστασία από async caller μετά από `await` (use_build_context_synchronously).
    if (!context.mounted) return;
    // maybeOf (όχι of): χωρίς ScaffoldMessenger → no-op, όχι exception.
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    if (isError) {
      // Log (tag UI, §1.7) — dev-facing μήνυμα, όχι κείμενο UI (§1.3).
      AppLogger.error(LogTag.ui, 'Snackbar σφάλματος εμφανίστηκε');
      // Το σφάλμα διακόπτει παλιά μηνύματα — δεν περιμένει σε ουρά.
      messenger.clearSnackBars();
    } else {
      // Log (tag UI, §1.7) — dev-facing μήνυμα, όχι κείμενο UI (§1.3).
      AppLogger.info(LogTag.ui, 'Snackbar επιτυχίας εμφανίστηκε');
    }

    final scheme = Theme.of(context).colorScheme;
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: AppConstants.snackBarDurationSeconds),
        backgroundColor: isError ? scheme.errorContainer : null,
        content: Text(
          message,
          maxLines: AppConstants.maxFeedbackLines,
          overflow: TextOverflow.ellipsis,
          style: isError ? TextStyle(color: scheme.onErrorContainer) : null,
        ),
      ),
    );
  }
}