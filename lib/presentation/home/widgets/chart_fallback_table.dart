/// SPoT shared widget: fallback πίνακας γραφήματος (§2.1 · Φάση 5 Βήμα 4).
///
/// Στενό container (`< AppConstants.pieFallbackMaxWidth`, §1.4): αντί για
/// μικροσκοπική πίτα δείχνει τις φέτες ως γραμμές (label + €). Dumb widget
/// (§2.0): έτοιμα `ChartSlice`, καμία provider-ανάγνωση.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/chart_totals.dart';
import '../../shared/currency_text_field.dart';

/// Πίνακας φετών για στενά containers (§1.4 + §2.1:184).
class ChartFallbackTable extends StatelessWidget {
  const ChartFallbackTable({super.key, required this.slices});

  /// Οι φέτες (ήδη top-N + «Λοιπά» από τον provider, Βήμα 3).
  final List<ChartSlice> slices;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < slices.length; i++) ...[
          if (i > 0) const Divider(height: AppConstants.listDividerHeight),
          Row(
            children: [
              Expanded(
                child: Text(
                  slices[i].label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: AppConstants.spacingS),
              Text(
                '${CurrencyTextField.formatCents(slices[i].totalCents)} '
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
