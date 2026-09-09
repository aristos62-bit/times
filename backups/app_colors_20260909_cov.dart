// core/theme/app_colors.dart
import 'package:flutter/material.dart';

/// SPO: Color palette - single source of truth
/// Τα χρώματα ορίζονται ΕΔΩ. Κανένα άλλο αρχείο δεν ορίζει χρώματα.
class AppColors {
  AppColors._();
  
  // --- Primary ---
  static const Color primaryLight = Color(0xFF1976D2);
  static const Color primaryDark = Color(0xFF90CAF9);
  
  // --- Secondary ---
  static const Color secondaryLight = Color(0xFF26A69A);
  static const Color secondaryDark = Color(0xFF80CBC4);
  
  // --- Error ---
  static const Color error = Color(0xFFD32F2F);
  
  // --- Warning ---
  static const Color warning = Color(0xFFFFA000);
  
  // --- Background ---
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF121212);
  
  // --- Surface ---
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  
  // --- Card ---
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF2C2C2C);
  
  // --- Text ---
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textPrimaryDark = Color(0xFFE0E0E0);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textSecondaryDark = Color(0xFF9E9E9E);
  
  // --- Divider ---
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF424242);

  // --- Overlay (scrim για LoadingOverlay — = Colors.black54) ---
  static const Color overlay = Color(0x8A000000);
  
  // --- Success ---
  static const Color success = Color(0xFF388E3C);
  
  // --- Info ---
  static const Color info = Color(0xFF1976D2);
}
