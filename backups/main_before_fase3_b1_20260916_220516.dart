import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/logging/app_logger.dart';
import 'core/theme/app_theme.dart';

void main() {
  // Dev-facing init log — εφαρμογή ξεκίνησε (tag UI, §1.7).
  AppLogger.info(LogTag.ui, 'Εφαρμογή «Τιμές» ξεκίνησε');
  runApp(const ProviderScope(child: TimesApp()));
}

/// Ρίζα της εφαρμογής — `ProviderScope` φορτώνει το Riverpod DI δέντρο
/// (Φάση 2, Βήμα 3 · DESIGN §2.5).
class TimesApp extends StatelessWidget {
  const TimesApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      // SPoT theme: light/dark από AppColors.brandSeed (§0/§1.5) · ThemeMode
      // system default (§1.5) — override ανά χρήστη στη Φάση 4 (§2.3).
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: AppTheme.defaultMode,
      // Προσωρινό placeholder ώστε να ΜΗΝ φαίνεται το default Flutter
      // template (DESIGN §0). Στη Φάση 3 αντικαθίσταται από το Home.
      home: const _BrandedPlaceholder(),
    );
  }
}

/// Ελάχιστη σελίδα χωρίς default Flutter branding (§0).
/// ΔΕΝ «βλέπει» data providers — η βάση ανοίγει μόνο όταν τη χρειαστεί
/// (π.χ. από την πρώτη σελίδα δεδομένων στη Φάση 3), όχι στο launch.
class _BrandedPlaceholder extends StatelessWidget {
  const _BrandedPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appTitle)),
      body: const Center(child: Text(AppStrings.appTitle)),
    );
  }
}