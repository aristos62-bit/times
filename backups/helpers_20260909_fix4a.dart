// core/utils/helpers.dart
import 'package:flutter/material.dart';
import '../debug/app_logger.dart';

/// SPO: Helper functions - reusable utilities
class Helpers {
  Helpers._();
  
  /// Show a snackbar with a message
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  /// Show a loading dialog
  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  /// Hide the current dialog
  static void hideDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
  
  /// Format a double as percentage
  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }
  
  /// Check if a string is a valid number
  static bool isNumeric(String str) {
    return double.tryParse(str) != null;
  }
  
  /// Log a performance metric
  static void logPerformance(String operation, Duration duration) {
    AppLogger.performance('$operation: ${duration.inMilliseconds}ms');
  }
  
  /// Get the current timestamp as ISO8601 string
  static String getTimestamp() {
    return DateTime.now().toIso8601String();
  }
}
