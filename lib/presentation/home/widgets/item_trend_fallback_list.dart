/// SPoT widget: λίστα σημείων πορείας για στενά containers (§2.1 · 28-09-2026).
///
/// Dumb widget (§2.0): έτοιμα `ItemPricePoint`, καμία provider-ανάγνωση.
/// Ίδια styling tokens με το `ChartFallbackTable` (dividers, ellipsis,
/// `formatCents`) αλλά ΧΩΡΙΣ γραμμή συνόλου — άθροισμα μοναδιαίων τιμών =
/// νόημα μηδέν, γι' αυτό νέο widget αντί reuse (επανέλεγχος Α2).
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/chart_totals.dart';
import '../../shared/currency_text_field.dart';

/// Πίνακας σημείων πορείας για στενά containers (§1.4).
class ItemTrendFallbackList extends StatelessWidget {
  const ItemTrendFallbackList({super.key, required this.points});

  /// Τα σημεία (ήδη φιλτραρισμένα κλειδωμένης μονάδας + cap, provider).
  final List<ItemPricePoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (points.isEmpty) return const SizedBox.shrink();
    final localizations = MaterialLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < points.length; i++) ...[
          if (i > 0) const Divider(height: AppConstants.listDividerHeight),
          Row(
            children: [
              Expanded(
                child: Text(
                  localizations.formatShortDate(points[i].date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: AppConstants.spacingS),
              Expanded(
                child: Text(
                  points[i].supplierName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: AppConstants.spacingS),
              Text(
                '${CurrencyTextField.formatCents(points[i].netPriceCents)} '
                '${AppStrings.currencySymbol}',
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
