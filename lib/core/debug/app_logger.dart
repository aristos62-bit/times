// core/debug/app_logger.dart
import 'package:flutter/foundation.dart';
import 'debug_config.dart';

/// SPoT: Κεντρικός logger — το DebugConfig ελέγχει αν τυπώνεται
/// 
/// Usage:
///   AppLogger.db('SELECT FROM receipts WHERE...');
///   AppLogger.bloc('ReceiptBloc: event=LoadReceipts');
///   AppLogger.network('GET /api/receipts - 200 OK');
///   AppLogger.performance('Slow query: 620ms - receipts join items');
///   AppLogger.error('Failed to insert', stackTrace);
class AppLogger {
  AppLogger._();
  
  static void db(String message) {
    if (!DebugConfig.showDbLogs) return;
    debugPrint('[DB] $message');
  }
  
  static void bloc(String message) {
    if (!DebugConfig.showBlocLogs) return;
    debugPrint('[BLOC] $message');
  }
  
  static void network(String message) {
    if (!DebugConfig.showNetworkLogs) return;
    debugPrint('[NET] $message');
  }
  
  static void performance(String message) {
    if (!DebugConfig.showPerformanceLogs) return;
    debugPrint('[PERF] $message');
  }
  
  static void navigation(String message) {
    if (!DebugConfig.showNavigationLogs) return;
    debugPrint('[NAV] $message');
  }
  
  static void info(String message) {
    if (!DebugConfig.isDebug) return;
    debugPrint('[INFO] $message');
  }
  
  static void error(String message, [StackTrace? stackTrace]) {
    if (!DebugConfig.isDebug) return;
    debugPrint('[ERROR] $message');
    if (stackTrace != null) {
      debugPrint('[ERROR] StackTrace: $stackTrace');
    }
  }
}
