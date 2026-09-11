// lib/main.dart — Entry point (Phase 3 Fix-B: minimal wiring).
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/debug/app_logger.dart';
import 'core/theme/theme_provider.dart';
import 'features/receipt/domain/repositories/receipt_repository.dart';
import 'injection/dependency_injection.dart';

/// App startup:
/// 1. `DependencyInjection.configure()` — γράφει AppDatabase → 7 DAOs →
///    5 repositories → ThemeProvider (Phase 2).
/// 2. `ThemeProvider.initialize()` — διαβάζει το αποθηκευμένο theme mode
///    πριν από το πρώτο frame (SettingDao-backed, reactive).
/// 3. `runApp(ExpenseTrackerApp)` — root με constructor injection.
Future<void> main() async { // coverage:ignore-line
  WidgetsFlutterBinding.ensureInitialized(); // coverage:ignore-line
  await DependencyInjection.configure(); // coverage:ignore-line
  final themeProvider = DependencyInjection.get<ThemeProvider>(); // coverage:ignore-line
  try {
    await themeProvider.initialize(); // coverage:ignore-line
  } catch (e, st) {
    AppLogger.error('main: themeProvider.initialize failed: $e', st); // coverage:ignore-line
  }
  final receiptRepository =
      DependencyInjection.get<ReceiptRepository>(); // coverage:ignore-line
  runApp( // coverage:ignore-line
    ExpenseTrackerApp( // coverage:ignore-line
      themeProvider: themeProvider, // coverage:ignore-line
      receiptRepository: receiptRepository, // coverage:ignore-line
    ), // coverage:ignore-line
  ); // coverage:ignore-line
}