// core/widgets/confirm_dialog.dart
import 'package:flutter/material.dart';
import '../strings/app_strings.dart';

/// SPoT: Confirmation dialogs - single source of truth
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = AppStrings.confirm,
    this.cancelLabel = AppStrings.cancel,
    this.isDestructive = false,
  });

  /// Δείχνει dialog και επιστρέφει true αν επιβεβαιώθηκε
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = AppStrings.confirm,
    String cancelLabel = AppStrings.cancel,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  /// Shortcut για διαγραφή — destructive + κόκκινο κουμπί
  static Future<bool> showDelete(
    BuildContext context, {
    String title = AppStrings.deleteConfirmTitle,
    String message = AppStrings.deleteConfirmMessage,
  }) {
    return show(
      context,
      title: title,
      message: message,
      confirmLabel: AppStrings.delete,
      isDestructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDestructive
              ? FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
