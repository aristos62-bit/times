/// SPoT widget: γενική πίτα με 3D-εφέ + legend δεξιά (§2.1 · Φάση 5 Βήμα 4).
///
/// Το `fl_chart` ΔΕΝ έχει 3D (evidence pub cache 25-09) → custom
/// `Pie3dPainter` (tilt + πάχος φέτας), 0 νέα packages. Labels ΠΑΝΤΑ δεξιά
/// (στήλη, όχι overlay — §1.4). Auto-size μέσω `LayoutBuilder`: στενό
/// container → `ChartFallbackTable` (όχι overflow/μικροσκοπική πίτα).
/// Χρώματα ΜΟΝΟ από `ColorScheme` (dark-safe, §1.5) — καμία raw τιμή.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/chart_totals.dart';
import '../../shared/currency_text_field.dart';
import 'chart_fallback_table.dart';

/// Ζωγραφίζει την πίτα: στοιβαγμένα τόξα (βάθος) + κεκλιμένοι τομείς.
///
/// Συντεταγμένες ελλειπτικές (γωνία 0 = +x, φορά ωρολογιακή όπως το canvas).
/// `fractions` (0..1, άθροισμα > 0) + `colors` (ίδιο μήκος).
class Pie3dPainter extends CustomPainter {
  Pie3dPainter({
    required this.fractions,
    required this.colors,
    required this.depthRatio,
    required this.tiltRatio,
  });

  final List<double> fractions;
  final List<Color> colors;
  final double depthRatio;
  final double tiltRatio;

  /// Σκοτεινιάζει το [color] κατά [amount] (0..1) — πλευρά/βάση 3D.
  static Color darken(Color color, [double amount = 0.15]) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Σημείο έλλειψης (κέντρο [center], ακτίνες [rx]/[ry]) στη [angle].
  static Offset ellipsePoint(
    Offset center,
    double rx,
    double ry,
    double angle,
  ) =>
      Offset(
        center.dx + rx * math.cos(angle),
        center.dy + ry * math.sin(angle),
      );

  @override
  void paint(Canvas canvas, Size size) {
    final total = fractions.fold<double>(0, (acc, f) => acc + f);
    if (fractions.isEmpty || total <= 0 || colors.isEmpty) return;
    final depth = size.height * depthRatio;
    final cx = size.width / 2;
    final rx = size.width / 2 * 0.92;
    final ry = rx * tiltRatio;
    if (rx <= 0 || ry <= 0) return;
    final cyTop = (size.height - depth) / 2;
    final topCenter = Offset(cx, cyTop);
    final bottomCenter = Offset(cx, cyTop + depth);

    // Βάση: σκούρα έλλειψη στο κάτω επίπεδο (ορατό χείλος).
    canvas.drawOval(
      Rect.fromCenter(
        center: bottomCenter,
        width: rx * 2,
        height: ry * 2,
      ),
      Paint()..color = darken(colors.first, 0.25),
    );

    // Πλευρές ανά τομέα (κορυφή → κάτω επίπεδο).
    var start = -math.pi / 2;
    for (var i = 0; i < fractions.length; i++) {
      final sweep = fractions[i] / total * math.pi * 2;
      if (sweep > 0) {
        final color = colors[i % colors.length];
        final path = Path()
          ..moveTo(ellipsePoint(topCenter, rx, ry, start).dx,
              ellipsePoint(topCenter, rx, ry, start).dy)
          ..lineTo(ellipsePoint(bottomCenter, rx, ry, start).dx,
              ellipsePoint(bottomCenter, rx, ry, start).dy)
          ..arcTo(
            Rect.fromCenter(
              center: bottomCenter,
              width: rx * 2,
              height: ry * 2,
            ),
            start,
            sweep,
            false,
          )
          ..lineTo(ellipsePoint(topCenter, rx, ry, start + sweep).dx,
              ellipsePoint(topCenter, rx, ry, start + sweep).dy)
          ..close();
        canvas.drawPath(path, Paint()..color = darken(color));
      }
      start += sweep;
    }

    // Κορυφές (φωτεινές) — καλύπτουν τις πίσω πλευρές.
    start = -math.pi / 2;
    for (var i = 0; i < fractions.length; i++) {
      final sweep = fractions[i] / total * math.pi * 2;
      if (sweep > 0) {
        canvas.drawArc(
          Rect.fromCenter(
            center: topCenter,
            width: rx * 2,
            height: ry * 2,
          ),
          start,
          sweep,
          true,
          Paint()..color = colors[i % colors.length],
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant Pie3dPainter oldDelegate) =>
      oldDelegate.fractions != fractions ||
      oldDelegate.colors != colors ||
      oldDelegate.depthRatio != depthRatio ||
      oldDelegate.tiltRatio != tiltRatio;
}

/// Γενική πίτα 3D-εφέ + legend δεξιά (§2.1).
class Pie3dChart extends StatelessWidget {
  const Pie3dChart({
    super.key,
    required this.slices,
    this.height = AppConstants.pieChartHeight,
    this.semanticsLabel,
  });

  /// Οι φέτες (top-N + «Λοιπά») — κενές → άδειο box (η κάρτα δείχνει empty).
  final List<ChartSlice> slices;

  /// Ύψος πίτας (SPoT §1.1 — πλάτος από τον γονέα).
  final double height;

  /// Προσβάσιμο label (η κάρτα περνά τον τίτλο, §1.6).
  final String? semanticsLabel;

  /// Παλέτα φετών από το `ColorScheme` (dark-safe, §1.5 — κυκλική).
  static List<Color> sliceColors(ColorScheme scheme) => [
        scheme.primary,
        scheme.secondary,
        scheme.tertiary,
        scheme.primaryContainer,
        scheme.secondaryContainer,
        scheme.tertiaryContainer,
      ];

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) return const SizedBox.shrink();
    final total = slices.fold<int>(0, (acc, s) => acc + s.totalCents);
    if (total <= 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = sliceColors(theme.colorScheme);
    final fractions = [
      for (final slice in slices) slice.totalCents / total,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppConstants.pieFallbackMaxWidth) {
          return ChartFallbackTable(slices: slices);
        }
        return Semantics(
          // container + explicitChildNodes: το label μένει στον δικό του
          // κόμβο (αλλιώς mergάρει προς τα πάνω και δεν βρίσκεται — ούτε
          // αυτό ούτε οι τίτλοι καρτών, §1.6).
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
                                '${CurrencyTextField.formatCents(slices[i].totalCents)} '
                                '${AppStrings.currencySymbol}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                          ],
                        ),
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
