import 'package:expense_tracker/core/theme/app_colors.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme.lightTheme', () {
    test('brightness light + Material3', () {
      expect(AppTheme.lightTheme.brightness, Brightness.light);
      expect(AppTheme.lightTheme.useMaterial3, isTrue);
    });

    test('χρώματα από AppColors', () {
      expect(
        AppTheme.lightTheme.scaffoldBackgroundColor,
        AppColors.backgroundLight,
      );
      expect(AppTheme.lightTheme.cardTheme.color, AppColors.cardLight);
    });
  });

  group('AppTheme.darkTheme', () {
    test('brightness dark + Material3', () {
      expect(AppTheme.darkTheme.brightness, Brightness.dark);
      expect(AppTheme.darkTheme.useMaterial3, isTrue);
    });

    test('χρώματα από AppColors', () {
      expect(
        AppTheme.darkTheme.scaffoldBackgroundColor,
        AppColors.backgroundDark,
      );
      expect(AppTheme.darkTheme.cardTheme.color, AppColors.cardDark);
    });
  });
}
