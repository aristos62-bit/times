// features/receipt/presentation/widgets/receipt_card.dart
import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';

/// SPoT: Card απόδειξης για τη λίστα (Βήμα 7, DESIGN §5.1.7).
///
/// Εμφανίζει: "Απόδειξη #N" ([AppStrings.receiptPreviewPrefix]), ημερομηνία
/// (short), σύνολο με ΦΠΑ (gross = totalAmount + vatTotal, §5.1.6) και ένα
/// chip κατάστασης πληρωμής με χρώμα που εξαρτάται από το status:
/// paid→[AppColors.success], partial→[AppColors.warning], pending→[AppColors.error].
///
/// Χρήση: [ReceiptListScreen] (onTap προαιρετικό). Stateless – χωρίς BLoC.
class ReceiptCard extends StatelessWidget {
  final Receipt receipt;
  final VoidCallback? onTap;

  const ReceiptCard({super.key, required this.receipt, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gross = receipt.totalAmount + receipt.vatTotal;
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical: AppDimensions.xs,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppStrings.receiptPreviewPrefix}${receipt.receiptNumber}',
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: AppDimensions.xs),
                    Text(
                      DateFormatter.formatShort(receipt.receiptDate),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(gross),
                    style: AppTextStyles.currency,
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  _ReceiptStatusChip(status: receipt.paymentStatus),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Εσωτερικό chip κατάστασης πληρωμής — χρώμα από APPColors, label από
/// AppStrings (SPoT). Το status-string είναι literal συνεπές με τον DAO
/// (_paymentStatus: 'paid'/'partial'/'pending').
class _ReceiptStatusChip extends StatelessWidget {
  final String status;

  const _ReceiptStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusData;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (String, Color) get _statusData => switch (status) {
        'paid' => (AppStrings.receiptStatusPaid, AppColors.success),
        'partial' => (AppStrings.receiptStatusPartial, AppColors.warning),
        _ => (AppStrings.receiptStatusPending, AppColors.error),
      };
}