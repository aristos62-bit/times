/// SPoT helper: controller-op → feedback (§2.3 editors · 24-09-2026).
///
/// Κοινός δρόμος για τους settings editors (κατηγορίες/προμηθευτές — πριν
/// αντιγραμμένος και στους δύο): `ok` → success snackbar· validation/dup
/// `error` → error snackbar· DB (`DataLoadException`, λογκαρισμένο μία φορά
/// στον DAO guard) → `userMessage` (pattern `_save` του save button).
/// Feedback ΜΟΝΟ εδώ (καλείται από widgets) — ποτέ μέσα στα dialogs
/// (ScaffoldMessenger caveat, §2.4). Dumb function: καθόλου state/logging.
library;

import 'package:flutter/material.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/utils/app_feedback.dart';

/// Εκτελεί [op] και δείχνει το αντίστοιχο feedback.
/// Απαιτεί `context.mounted` μετά το await (pattern `_save`).
Future<void> runControllerOp(
  BuildContext context,
  Future<({bool ok, String? error})> Function() op,
  String successMessage,
) async {
  try {
    final result = await op();
    if (!context.mounted) return;
    if (result.ok) {
      AppFeedback.showSuccess(context, successMessage);
    } else if (result.error != null) {
      AppFeedback.showError(context, result.error!);
    }
  } on DataLoadException catch (e) {
    if (!context.mounted) return;
    AppFeedback.showError(context, e.userMessage);
  }
}
