/// SPoT shared views καταστάσεων καρτών γραφημάτων (§2.1 · 29-09-2026).
///
/// Εξαγωγή από `home_chart_card.dart` ΧΩΡΙΣ αλλαγή συμπεριφοράς (οι πίτες
/// συνεχίζουν να τις χρησιμοποιούν): skeleton φόρτωσης + error με
/// «Επανάληψη». Dumb (§2.0) — ο γονέας περνά `onRetry`.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_errors.dart';
import '../../../core/constants/app_strings.dart';

/// Σφάλμα κάρτας: `loadDataFailed` + «Επανάληψη» (SPoT, §2.1).
class ChartErrorView extends StatelessWidget {
  const ChartErrorView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppErrors.loadDataFailed, style: theme.textTheme.bodyMedium),
        TextButton(
          onPressed: onRetry,
          child: const Text(AppStrings.retryButton),
        ),
      ],
    );
  }
}

/// Skeleton φόρτωσης κάρτας (§2.1:179 — όχι κενή κάρτα, όχι spinner).
///
/// 3 bars από `surfaceContainerHighest` (dark-safe, §1.5) + SPoT μεγέθη.
class ChartSkeletonView extends StatelessWidget {
  const ChartSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    final barColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double widthFactor) => FractionallySizedBox(
          widthFactor: widthFactor,
          alignment: Alignment.centerLeft,
          child: Container(
            height: AppConstants.spacingL,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
            ),
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        bar(1.0),
        const SizedBox(height: AppConstants.spacingS),
        bar(0.7),
        const SizedBox(height: AppConstants.spacingS),
        bar(0.85),
      ],
    );
  }
}
