import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_strings.dart';
import 'core/logging/app_logger.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/providers/settings_providers.dart';
import 'presentation/settings/widgets/app_lock_overlay.dart';
import 'presentation/settings/widgets/app_lock_watcher.dart';

Future<void> main() async {
  // Φάση 4, Βήμα 1 (Q4) + review fix (sync read, Q3 αναθεωρήθηκε): προφόρτωση
  // των SharedPreferences ΠΡΙΝ το runApp + σύγχρονο memory-read στο build —
  // το persisted ThemeMode είναι ορατό στο πρώτο frame (αληθινό μηδέν flash).
  WidgetsFlutterBinding.ensureInitialized();
  // Global error handlers (R3 · 01-10): απρόβλεπτα αφήνουν ίχνος αντί
  // σιωπηλού red screen. Σε release τα logs σβήνουν (DebugConfig by
  // design) — οι handlers μένουν ως hook για μελλοντικό crash reporting.
  FlutterError.onError = (details) {
    AppLogger.error(LogTag.ui, 'Ανεπάντεχο σφάλμα UI', details.exception,
        details.stack);
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error(LogTag.ui, 'Ανεπάντεχο async σφάλμα', error, stack);
    return true;
  };
  final prefs = await SharedPreferences.getInstance();

  runApp(ProviderScope(
    // Το prefs δίνεται με injection (pattern database tests) — ο provider
    // ρίχνει σκόπιμα UnimplementedError χωρίς override (settings_providers).
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const TimesApp(),
  ));
  // Dev-facing init log — μετά το runApp (review fix 23-09, §1.7).
  AppLogger.info(LogTag.ui, 'Εφαρμογή «Τιμές» ξεκίνησε');
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
      // (§1.2). Και τα 3 branches χτίζονται στο launch (IndexedStack +
      // Offstage inactive, evidence go_router 18) → η βάση ανοίγει στο
      // launch από παντού (Home κάρτες, PriceEntry λίστα, Settings
      // editors). Η παλιά Α1 («ΜΟΝΟ μέσω PriceEntry») ίσχυε μέχρι το
      // Βήμα 7 — το θέμα παραμένει SharedPreferences.
      routerConfig: appRouter,
      // Κλείδωμα εφαρμογής (§2.3 · 30-09-2026): ο builder σκεπάζει ΟΛΟ το
      // navigator (NavigationBar + dialogs — τίποτα ορατό πριν το unlock).
      // TimesApp μένει ConsumerWidget (ο watcher/overlay έχουν δικό state).
      builder: (context, child) => AppLockWatcher(
        child: Stack(
          children: [
            AppLockBackground(child: child ?? const SizedBox.shrink()),
            const AppLockGate(),
          ],
        ),
      ),
    );
  }
}
