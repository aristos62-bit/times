/// SPoT: Χρωματική παλέτα — brand colors + semantic colors
/// (άνοδος τιμής = κόκκινο, πτώση = πράσινο). Τα χρώματα δηλώνονται ΜΟΝΟ
/// εδώ και ενσωματώνονται στο ColorScheme (§1.5) — ποτέ raw Color σε widgets.
library;

import 'dart:ui' show Color;

/// Abstract SPoT namespace — μόνο σταθερές, δεν instantiate (pattern AppConstants).
abstract final class AppColors {
  // ─── Brand (§0 DESIGN — teal, ταυτίζεται με splash §3 pubspec) ─────────────
  /// Seed του ColorScheme. Ήδη σε 2+ σημεία (§0 branding + app_feedback_test.dart).
  static const Color brandSeed = Color(0xFF00897B);

  // ─── Semantic (§4-Φάση 5 charts, fl_chart) ────────────────────────────────
  /// Άνοδος τιμής — κόκκινο.
  static const Color priceUp = Color(0xFFD32F2F);

  /// Πτώση τιμής — πράσινο. (dark variants → Φάση 5, §4)
  static const Color priceDown = Color(0xFF2E7D32);
}