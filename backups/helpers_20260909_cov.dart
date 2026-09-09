// core/utils/helpers.dart
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../debug/app_logger.dart';
import '../theme/app_dimensions.dart';
import 'extensions.dart';

/// SPO: Helper functions - reusable utilities
class Helpers {
  Helpers._();
  
  /// Show a snackbar with a message
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        duration: AppConstants.snackBarDuration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
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
  
  /// Hide the current dialog — edge: ελέγχει canPop για να μην κλείσει οθόνη
  static void hideDialog(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }
  
  /// Format a double as percentage
  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }
  
  /// Check if a string is a valid number — reuse StringExtensions.isNumeric (όχι duplicate)
  static bool isNumeric(String str) {
    return str.isNumeric;
  }
  
  /// Log a performance metric
  static void logPerformance(String operation, Duration duration) {
    AppLogger.performance('$operation: ${duration.inMilliseconds}ms');
  }
  
  /// Get the current timestamp as ISO8601 string — UTC για συνέπεια με DB (UtcDateTimeConverter)
  static String getTimestamp() {
    return DateTime.now().toUtc().toIso8601String();
  }
}
