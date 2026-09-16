import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/logging/app_logger.dart';
import 'core/router/app_router.dart';
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
    return MaterialApp.router(
      title: AppStrings.appTitle,
      // SPoT theme: light/dark από AppColors.brandSeed (§0/§1.5) · ThemeMode
      // system default (§1.5) — override ανά χρήστη στη Φάση 4 (§2.3).
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: AppTheme.defaultMode,
      // GoRouter (Φάση 3, Βήμα 1) — StatefulShellRoute + NavLogObserver
      // (§1.2). Οι placeholder σελίδες ΔΕΝ «βλέπουν» data providers →
      // η βάση δεν ανοίγει στο launch (αντίθετα με το default template §0).
      routerConfig: appRouter,
    );
  }
}