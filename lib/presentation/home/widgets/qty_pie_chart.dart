/// SPoT widget: πίτα ποσοτήτων με legend δεξιά (§2.1 · 29-09-2026 — μετρικές).
///
/// Reuse `Pie3dPainter` (fractions — ο ζωγράφος δεν ξέρει €) + palette
/// (`Pie3dChart.sliceColors`, dark-safe §1.5). Legend με `formatQuantity` +
/// συντομογραφία + γραμμή συνόλου (Q6). Στενό container ή τεράστια κλίμακα
/// → fallback πίνακας (pattern `Pie3dChart`, §1.4).
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/chart_totals.dart';
import '../../shared/quantity_text_field.dart';
import 'pie_3d_chart.dart';

/// Πίτα ποσοτήτων Top-10 (§2.1 · μετρικές).
class QtyPieChart extends StatelessWidget {
  const QtyPieChart({
    super.key,
    required this.slices,
    required this.unitAbbreviation,
    this.height = AppConstants.pieChartHeight,
    this.semanticsLabel,
  });

  /// Οι φέτες (top-10 + «Λοιπά») — κενές → άδειο box (η κάρτα δείχνει empty).
  final List<ChartQtySlice> slices;

  /// Συντομογραφία μονάδας για το legend («κιλ» — ζωντανή, από ΒΔ).
  final String unitAbbreviation;

  /// Ύψος πίτας (SPoT §1.1 — πλάτος από τον γονέα, ίδιο με τις πίτες €).
  final double height;

  /// Προσβάσιμο label (η κάρτα περνά τον τίτλο, §1.6).
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) return const SizedBox.shrink();
    final total = slices.fold<double>(0, (acc, s) => acc + s.qty);
    if (total <= 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = Pie3dChart.sliceColors(theme.colorScheme);
    final fractions = [for (final slice in slices) slice.qty / total];
    return LayoutBuilder(
      builder: (context, constraints) {
        // Fallback πίνακα (§1.4 — ίδιο contract με την πίτα €).
        final hugeText =
            MediaQuery.textScalerOf(context).scale(1.0) > 1.5;
        if (constraints.maxWidth < AppConstants.pieFallbackMaxWidth ||
            hugeText) {
          return _QtyFallbackTable(
            slices: slices,
            unitAbbreviation: unitAbbreviation,
          );
        }
        return Semantics(
          // container + explicitChildNodes (precedent πίτας, §1.6).
          container: true,
          explicitChildNodes: true,
          label: semanticsLabel,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SizedBox(
                  height: height,
                  child: CustomPaint(
                    painter: Pie3dPainter(
                      fractions: fractions,
                      colors: colors,
                      depthRatio: AppConstants.pieDepthRatio,
                      tiltRatio: AppConstants.pieTiltRatio,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < slices.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppConstants.spacingS / 2,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: AppConstants.spacingM,
                              height: AppConstants.spacingM,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors[i % colors.length],
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingS),
                            Expanded(
                              child: Text(
                                slices[i].label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingS),
                            Flexible(
                              child: Text(
                                '${QuantityTextField.formatQuantity(slices[i].qty)} '
                                '$unitAbbreviation',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Divider(height: AppConstants.spacingL),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppStrings.chartTotalLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingS),
                        Text(
                          '${QuantityTextField.formatQuantity(total)} '
                          '$unitAbbreviation',
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Fallback πίνακας ποσοτήτων για στενά containers (§1.4).
///
/// Dumb (§2.0): έτοιμα slices + συντομογραφία. Δίπλα στο `ChartFallbackTable`
/// (εκείνο είναι €-bound — ίδια αιτία με την πίτα, Δ1).
class _QtyFallbackTable extends StatelessWidget {
  const _QtyFallbackTable({
    required this.slices,
    required this.unitAbbreviation,
  });

  final List<ChartQtySlice> slices;
  final String unitAbbreviation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (slices.isEmpty) return const SizedBox.shrink();
    final total = slices.fold<double>(0, (acc, s) => acc + s.qty);
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
                '${QuantityTextField.formatQuantity(slices[i].qty)} '
                '$unitAbbreviation',
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
        ],
        const Divider(height: AppConstants.spacingL),
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.chartTotalLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ),
            const SizedBox(width: AppConstants.spacingS),
            Flexible(
              child: Text(
                '${QuantityTextField.formatQuantity(total)} '
                '$unitAbbreviation',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: theme.textTheme.titleSmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
