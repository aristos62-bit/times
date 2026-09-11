// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/receipt/domain/repositories/receipt_repository.dart';
import 'features/receipt/presentation/bloc/receipt_bloc.dart';
import 'features/receipt/presentation/screens/receipts_home_screen.dart';

/// SPoT: Root widget της εφαρμογής (Phase 3 Fix-B — minimal wiring έως το
/// Phase 9, όπου θα αντικατασταθεί από το responsive AppNavigation/go_router).
///
/// Καθαρό constructor injection: τόσο το [ThemeProvider] όσο και το
/// [ReceiptRepository] περνιούνται από το main() (ή από τα widget tests).
/// Κανένα `DependencyInjection.get` εδώ — το wiring γίνεται στο startup.
///
/// - [ListenableBuilder] πάνω στο themeProvider: το themeMode αλλάζει live
///   από το reactive stream του SettingDao (reuse ThemeProvider — Phase 2).
/// - [BlocProvider] τοποθετείται ΠΑΝΩ από το MaterialApp, ώστε όσα routes
///   πιέζει ο Navigator (Entry/Detail) να κληρονομούν τον ίδιο [ReceiptBloc].
/// - Home: [ReceiptsHomeScreen] — ο μόνος τόπος όπου γίνεται Navigator.push.
class ExpenseTrackerApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  final ReceiptRepository receiptRepository;

  const ExpenseTrackerApp({
    super.key,
    required this.themeProvider,
    required this.receiptRepository,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        return BlocProvider(
          create: (_) => ReceiptBloc(repository: receiptRepository),
          child: MaterialApp(
            title: AppConstants.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const ReceiptsHomeScreen(),
          ),
        );
      },
    );
  }
}