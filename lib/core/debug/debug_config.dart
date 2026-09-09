// core/debug/debug_config.dart
import 'package:flutter/foundation.dart';

/// SPO: Debug flags - Ρυθμίζονται ΜΟΝΟ εδώ
class DebugConfig {
  DebugConfig._();
  
  // --- Master Switch ---
  static const bool isDebug = kDebugMode;
  
  // --- Group Flags ---
  static const bool showDbLogs = isDebug && true;
  static const bool showBlocLogs = isDebug && true;
  static const bool showNetworkLogs = isDebug && true;
  static const bool showPerformanceLogs = isDebug && true;
  static const bool showNavigationLogs = isDebug && false;
  
  // --- Thresholds ---
  static const Duration slowQueryThreshold = Duration(milliseconds: 500);
  static const Duration slowBuildThreshold = Duration(milliseconds: 16); // >1 frame
}
