// core/widgets/error_widget.dart
import 'package:flutter/material.dart';
import '../strings/app_strings.dart';
import '../theme/app_dimensions.dart';

/// SPoT: Error display - single source of truth
/// Όνομα AppErrorWidget για αποφυγή σύγκρουσης με Flutter's ErrorWidget
class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  /// Factory για generic error
  factory AppErrorWidget.generic({VoidCallback? onRetry}) {
    return AppErrorWidget(
      message: AppStrings.genericError,
      onRetry: onRetry,
    );
  }

  /// Factory για database error
  factory AppErrorWidget.database({VoidCallback? onRetry}) {
    return AppErrorWidget(
      message: AppStrings.databaseError,
      onRetry: onRetry,
      icon: Icons.storage_outlined,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: AppDimensions.lg),
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.xl),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text(AppStrings.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
