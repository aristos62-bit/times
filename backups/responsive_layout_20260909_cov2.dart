// core/widgets/responsive_layout.dart
import 'package:flutter/material.dart';

/// SPoT: Responsive wrapper - single source of truth
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < Breakpoints.mobile) {
          return mobile;
        }
        if (constraints.maxWidth < Breakpoints.tablet) {
          return tablet ?? mobile;
        }
        return desktop;
      },
    );
  }
}

/// SPoT: Breakpoint constants
/// mobile:  <600   → mobile layout
/// tablet:  ≥600   → tablet layout (600-1199)
/// desktop: ≥1200  → desktop layout (1200+)
class Breakpoints {
  Breakpoints._(); // coverage:ignore-line — SPoT static-only, δεν instanti-άρεται.

  /// Mobile: width < 600
  static const double mobile = 600;

  /// Tablet: 600 ≤ width < 1200 (desktop ξεκινά εδώ)
  static const double tablet = 1200;

  /// Desktop large: width ≥ 1600 → 4 στήλες (αντί magic number στο gridColumns)
  static const double desktopLarge = 1600;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < tablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet;

  /// Returns number of columns based on screen width
  static int gridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobile) return 1;
    if (width < tablet) return 2;
    if (width < desktopLarge) return 3;
    return 4;
  }
}
