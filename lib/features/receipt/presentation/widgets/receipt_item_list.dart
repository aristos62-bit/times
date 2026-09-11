// features/receipt/presentation/widgets/receipt_item_list.dart
import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';

/// SPoT: Λίστα γραμμών απόδειξης (read-only, Βήμα 7) για το detail screen.
///
/// Εμφανίζει κάθε [ReceiptItem] ως σειρά: "Είδος #itemId", ποσότητα × τιμή,
/// ΦΠΑ %, έκδοση % και καθαρό + με ΦΠΑ σύνολο της γραμμής. Το σύνολο της
/// απόδειξης (footer) υπολογίζεται από τον DAO (receipt.totalAmount +
/// vatTotal) — εδώ ΕΝΑ καταναλωτής, όχι υπολογισμός.
///
/// Χρήση: [ReceiptDetailScreen] (BLOCConsumer → state.items). Stateless.
class ReceiptItemList extends StatelessWidget {
  final List<ReceiptItem> items;

  const ReceiptItemList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppDimensions.xl),
        child: Text(
          AppStrings.noItemsInReceipt,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _ReceiptItemRow(item: item, index: index);
      },
    );
  }
}

/// Μία γραμμή απόδειξης — layout: αριστερά "Είδος N", δεξιά ποσά.
class _ReceiptItemRow extends StatelessWidget {
  final ReceiptItem item;
  final int index;

  const _ReceiptItemRow({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical: AppDimensions.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppStrings.item} #${item.itemId}',
                style: AppTextStyles.labelLarge,
              ),
              Text(
                CurrencyFormatter.format(item.totalWithVat),
                style: AppTextStyles.currency,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            _lineSummary(item),
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Σύνοψη γραμμής: "2 × 10,00€ ΦΠΑ 24%".
  String _lineSummary(ReceiptItem item) {
    final qty = _num(item.quantity);
    final price = CurrencyFormatter.format(item.unitPrice);
    return '$qty × $price ${AppStrings.vatRate}${_num(item.vatRate)}';
  }

  /// Μορφοποίηση αριθμού χωρίς δεκαδικά αν είναι ακέραιος (αντί magic
  /// toStringAsFixed — φιλική εμφάνιση ποσοτήτων/ΦΠΑ).
  static String _num(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }
}