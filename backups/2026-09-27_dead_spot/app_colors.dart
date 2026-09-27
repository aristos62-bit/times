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

  // ─── Pie palette (§2.1 · Φάση 5) ──────────────────────────────────────────
  // Γεμάτα, διακριτά χρώματα φετών (όχι παστέλ containers — fix 26-09: οι
  // container αποχρώσεις ήταν αχνές). Teal πρώτο (brand §0) · dark λίστα με
  // ανοιχτές εκδοχές για κοντράστ σε σκούρο φόντο (§1.5). Κυκλική χρήση.
  static const List<Color> pieSliceColors = [
    Color(0xFF00897B), // teal brand
    Color(0xFF1565C0), // μπλε
    Color(0xFFEF6C00), // πορτοκαλί
    Color(0xFF6A1B9A), // μοβ
    Color(0xFFC62828), // κόκκινο
    Color(0xFF558B2F), // πράσινο
    Color(0xFF795548), // καφέ
    Color(0xFF455A64), // γκρι-μπλε
  ];

  /// Dark εκδοχές παλέτας πιτών (ανοιχτές — κοντράστ σε σκούρο φόντο).
  static const List<Color> pieSliceColorsDark = [
    Color(0xFF4DB6AC),
    Color(0xFF64B5F6),
    Color(0xFFFFB74D),
    Color(0xFFCE93D8),
    Color(0xFFE57373),
    Color(0xFFAED581),
    Color(0xFFBCAAA4),
    Color(0xFFB0BEC5),
  ];
}