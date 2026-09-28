/// SPoT widget: γραμμή πορείας τιμής είδους (§2.1 · 28-09-2026).
///
/// Custom painter (0 νέα packages — precedent `Pie3dPainter`: το fl_chart
/// αφαιρέθηκε 27-09-2026): grid + γραμμή + dots + ετικέτες αξόνων με
/// TextPainter. Χ ομοιόμορφα ανά index (όχι χρονο-αναλογικά — γραμμές ίδιας
/// ημέρας δεν επικαλύπτονται, §2.2:291 καμία συγχώνευση)· ετικέτες Χ:
/// πρώτη/μέση/τελευταία ημερομηνία. Χρώματα ΜΟΝΟ από `ColorScheme` (§1.5).
/// Στενό container ή τεράστια κλίμακα κειμένου → `ItemTrendFallbackList`
/// (pattern `Pie3dChart`, §1.4).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/chart_totals.dart';
import '../../shared/currency_text_field.dart';
import 'item_trend_fallback_list.dart';

/// Κατεύθυνση μεταβολής τιμής (χρώμα ετικέτας — SPoT `ColorScheme` §1.5).
enum TrendMove { up, down, flat }

/// Ζωγραφίζει grid + γραμμή + dots + ετικέτες (dumb — όλα έτοιμα ορίσματα).
///
/// `values` καθαρές μοναδιαίες (double) · `lo/hi` padded όρια Υ (τα
/// υπολογίζει το widget) · `yLabels` 3 (max/mid/min) · `xLabels` 3
/// (πρώτη/μέση/τελευταία, χωρίς έτος) · `priceLabels` ανά σημείο (αριστερά
/// του dot) · `changeLabels` % μεταβολή από το προηγούμενο (δεξιά του dot,
/// null στο 1ο — δεν έχει προηγούμενο).
class ItemTrendPainter extends CustomPainter {
  ItemTrendPainter({
    required this.values,
    required this.lo,
    required this.hi,
    required this.lineColor,
    required this.dotColor,
    required this.gridColor,
    required this.labelStyle,
    required this.yLabels,
    required this.xLabels,
    required this.priceLabels,
    required this.changeLabels,
  });

  final List<double> values;
  final double lo;
  final double hi;
  final Color lineColor;
  final Color dotColor;
  final Color gridColor;
  final TextStyle labelStyle;
  final List<String> yLabels;
  final List<String> xLabels;
  final List<String> priceLabels;
  final List<({String text, Color color})?> changeLabels;

  /// Οριζόντια θέση σημείου [i] (n==1 → κέντρο).
  double _dx(int i, int n, double plotW) =>
      AppConstants.trendAxisGutterLeft +
      (n == 1 ? plotW / 2 : plotW * i / (n - 1));

  /// Κατακόρυφη θέση τιμής [v] (y=0 κορυφή).
  double _dy(double v, double plotH) =>
      plotH - (v - lo) / (hi - lo) * plotH;

  /// Ζωγραφίζει μία ετικέτα με [TextPainter] στο ([x], [y]).
  /// [rightAlign]: δεξί άκρο στο [x] (τιμές αριστερά του dot) — αλλιώς
  /// αριστερό άκρο στο [x]. [color]: παρακάμπτει το `labelStyle` (μεταβολές).
  void _drawLabel(
    Canvas canvas,
    String text,
    double x,
    double y, {
    Color? color,
    bool rightAlign = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: color == null ? labelStyle : labelStyle.copyWith(color: color),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: AppConstants.trendAxisGutterLeft + 40);
    painter.paint(
      canvas,
      Offset(rightAlign ? x - painter.width : x, y),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n == 0 || hi <= lo) return;
    final plotW = size.width - AppConstants.trendAxisGutterLeft;
    final plotH = size.height - AppConstants.trendAxisGutterBottom;
    if (plotW <= 0 || plotH <= 0) return;

    // Grid + ετικέτες Υ (max/mid/min).
    final gridPaint = Paint()..color = gridColor;
    for (var g = 0; g < 3; g++) {
      final y = plotH * g / 2;
      canvas.drawLine(
        Offset(AppConstants.trendAxisGutterLeft, y),
        Offset(size.width, y),
        gridPaint,
      );
      _drawLabel(canvas, yLabels[g], 0, y - 7);
    }

    // Γραμμή (≥2 σημεία) + dots.
    if (n > 1) {
      final path = Path()
        ..moveTo(_dx(0, n, plotW), _dy(values[0], plotH));
      for (var i = 1; i < n; i++) {
        path.lineTo(_dx(i, n, plotW), _dy(values[i], plotH));
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = lineColor
          ..strokeWidth = AppConstants.trendLineWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(
        Offset(_dx(i, n, plotW), _dy(values[i], plotH)),
        AppConstants.trendDotRadius,
        Paint()..color = dotColor,
      );
    }

    // Ετικέτες σημείων ΠΑΝΩ από το dot (όχι επάνω στη γραμμή — report
    // χρήστη): τιμή αριστερά · % μεταβολή δεξιά (εκτός 1ου). Clamp στο 0
    // για dots κορυφής (χωρίς κλιπάρισμα εκτός canvas).
    for (var i = 0; i < n; i++) {
      final cx = _dx(i, n, plotW);
      final ly = math.max(0.0, _dy(values[i], plotH) - 22);
      _drawLabel(canvas, priceLabels[i], cx - 6, ly, rightAlign: true);
      final change = changeLabels[i];
      if (change != null) {
        _drawLabel(canvas, change.text, cx + 6, ly, color: change.color);
      }
    }

    // Ετικέτες Χ (πρώτη/μέση/τελευταία).
    final mid = n ~/ 2;
    final baseline = plotH + 5;
    _drawLabel(canvas, xLabels[0], _dx(0, n, plotW) - 8, baseline);
    if (n > 2) {
      _drawLabel(canvas, xLabels[1], _dx(mid, n, plotW) - 8, baseline);
    }
    if (n > 1) {
      _drawLabel(
        canvas,
        xLabels[2],
        _dx(n - 1, n, plotW) - 44,
        baseline,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ItemTrendPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.lo != lo ||
      oldDelegate.hi != hi ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.dotColor != dotColor ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.labelStyle != labelStyle ||
      oldDelegate.yLabels != yLabels ||
      oldDelegate.xLabels != xLabels ||
      oldDelegate.priceLabels != priceLabels ||
      oldDelegate.changeLabels != changeLabels;
}

/// Γραμμή πορείας + fallback (§2.1).
class ItemTrendChart extends StatelessWidget {
  const ItemTrendChart({
    super.key,
    required this.points,
    this.height = AppConstants.trendChartHeight,
    this.semanticsLabel,
  });

  /// Τα σημεία (κενά → άδειο box, η κάρτα δείχνει empty).
  final List<ItemPricePoint> points;

  /// Ύψος γραφήματος (SPoT §1.1 — πλάτος από τον γονέα).
  final double height;

  /// Προσβάσιμο label (η κάρτα περνά τον τίτλο, §1.6).
  final String? semanticsLabel;

  /// Padded όρια Υ: ±15% εύρους· εκφυλισμένο (min==max) → ±max(1 €, 5%).
  @visibleForTesting
  static ({double lo, double hi}) boundsOf(List<double> values) {
    var lo = values.reduce(math.min);
    var hi = values.reduce(math.max);
    var pad = (hi - lo) * 0.15;
    if (pad <= 0) {
      pad = math.max(100, hi * 0.05);
    }
    return (lo: lo - pad, hi: hi + pad);
  }

  /// % μεταβολή [curr] από [prev] («+5,3%»/«−2,1%»/«0,0%», 1 δεκαδικό με
  /// κόμμα — parity προβολής §2.2). Ισότητα (και αμυντικά prev ≤ 0) → flat.
  @visibleForTesting
  static ({String text, TrendMove move}) changeOf(int prev, int curr) {
    if (prev <= 0 || curr == prev) return (text: '0,0%', move: TrendMove.flat);
    final pct = (curr - prev) / prev * 100;
    final tenths = (pct.abs() * 10).round();
    final text =
        '${pct < 0 ? '-' : '+'}${tenths ~/ 10},${tenths % 10}%';
    if (pct > 0) return (text: text, move: TrendMove.up);
    return (text: text, move: TrendMove.down);
  }

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Fallback πίνακα (§1.4 — ίδιο contract με την πίτα).
        final hugeText =
            MediaQuery.textScalerOf(context).scale(1.0) > 1.5;
        if (constraints.maxWidth < AppConstants.pieFallbackMaxWidth ||
            hugeText) {
          return ItemTrendFallbackList(points: points);
        }
        final values = [
          for (final p in points) p.netPriceCents.toDouble(),
        ];
        final bounds = boundsOf(values);
        final mid = (bounds.lo + bounds.hi) / 2;
        final midIndex = points.length ~/ 2;
        // Ετικέτες σημείων: τιμή αριστερά · % μεταβολή δεξιά (up=error,
        // down=tertiary, flat=primary — SPoT ColorScheme, §1.5).
        String dayMonth(DateTime date) => '${date.day}/${date.month}';
        final changes = <({String text, Color color})?>[
          null,
          for (var i = 1; i < points.length; i++)
            switch (changeOf(
              points[i - 1].netPriceCents,
              points[i].netPriceCents,
            )) {
              (text: final text, move: TrendMove.up) => (
                  text: text,
                  color: scheme.error,
                ),
              (text: final text, move: TrendMove.down) => (
                  text: text,
                  color: scheme.tertiary,
                ),
              (text: final text, move: _) => (
                  text: text,
                  color: scheme.primary,
                ),
            },
        ];
        return Semantics(
          // container + explicitChildNodes (precedent πίτας, §1.6).
          container: true,
          explicitChildNodes: true,
          label: semanticsLabel,
          child: SizedBox(
            height: height,
            child: CustomPaint(
              painter: ItemTrendPainter(
                values: values,
                lo: bounds.lo,
                hi: bounds.hi,
                lineColor: scheme.primary,
                dotColor: scheme.primary,
                gridColor: scheme.surfaceContainerHighest,
                labelStyle: (theme.textTheme.bodySmall ?? const TextStyle())
                    .copyWith(color: scheme.onSurfaceVariant),
                yLabels: [
                  CurrencyTextField.formatCents(bounds.hi.round()),
                  CurrencyTextField.formatCents(mid.round()),
                  CurrencyTextField.formatCents(bounds.lo.round()),
                ],
                xLabels: [
                  dayMonth(points.first.date),
                  dayMonth(points[midIndex].date),
                  dayMonth(points.last.date),
                ],
                priceLabels: [
                  for (final p in points)
                    CurrencyTextField.formatCents(p.netPriceCents),
                ],
                changeLabels: changes,
              ),
            ),
          ),
        );
      },
    );
  }
}
