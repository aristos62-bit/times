import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_strings.dart';
import 'core/logging/app_logger.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/providers/settings_providers.dart';

Future<void> main() async {
  // Φάση 4, Βήμα 1 (Q4): προφόρτωση των SharedPreferences ΠΡΙΝ το runApp —
  // το ThemeMode είναι γνωστό πριν το πρώτο frame (μηδέν flash) και ο
  // themeModeProvider διαβάζει memory-read (κανένα platform channel στο build).
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Dev-facing init log — εφαρμογή ξεκίνησε (tag UI, §1.7).
  AppLogger.info(LogTag.ui, 'Εφαρμογή «Τιμές» ξεκίνησε');
  runApp(ProviderScope(
    // Το prefs δίνεται με injection (pattern database tests) — ο provider
    // ρίχνει σκόπιμα UnimplementedError χωρίς override (settings_providers).
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const TimesApp(),
  ));
}

/// Ρίζα της εφαρμογής — `ProviderScope` φορτώνει το Riverpod DI δέντρο
/// (Φάση 2, Βήμα 3 · DESIGN §2.5) + τα SharedPreferences προφορτωμένα (Q4).
class TimesApp extends ConsumerWidget {
  const TimesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppStrings.appTitle,
      // Ελληνικό UI — μοναδική γλώσσα (§0 DESIGN): localizations delegates +
      // locale el, ώστε Material components (showDatePicker, formatMediumDate)
      // να εμφανίζονται ελληνικά (§1.0 / Φάση 3 Βήμα 2).
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('el')],
      locale: const Locale('el'),
      // SPoT theme: light/dark από AppColors.brandSeed (§0/§1.5) · ThemeMode
      // από τον themeModeProvider (Φάση 4 Βήμα 1, §2.3:270): persisted μέσω
      // SettingsRepository (SharedPreferences), default AppTheme.defaultMode.
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      // GoRouter (Φάση 3, Βήμα 1) — StatefulShellRoute + NavLogObserver
      // (§1.2). Μόνο η PriceEntry βλέπει data providers → η βάση ανοίγει
      // ΜΟΝΟ μέσω PriceEntry (Α1, §2.2:221) — το θέμα είναι SharedPreferences.
      routerConfig: appRouter,
    );
  }
}