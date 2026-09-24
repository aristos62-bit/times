/// Φάση 4, Βήμα 1+4 — Σελίδα ρυθμίσεων (§2.3 DESIGN).
///
/// Στοιχείο του App Shell: ο `AppShell` δίνει το Scaffold με NavigationBar
/// και η σελίδα προσθέτει δικό της nested Scaffold (AppBar + σώμα).
/// Watches: `themeModeProvider` (section «Θέμα», SharedPreferences — ΟΧΙ η
/// βάση) + `categoryTreeStreamProvider` (section «Κατηγορίες», Βήμα 4 —
/// η βάση ανοίγει και από εδώ· στο launch είναι ήδη ανοιχτή μέσω PriceEntry,
/// IndexedStack §2.2:221/Α1).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../data/providers/settings_providers.dart';
import 'widgets/category_tree_editor.dart';
import 'widgets/theme_mode_selector.dart';

/// Σελίδα ρυθμίσεων (§2.3) — section «Θέμα» (Βήμα 1) + section «Κατηγορίες»
/// με tree editor (Βήμα 4). Το Backup section έρχεται στο Βήμα 5.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.titleSettings)),
      body: ListView(
        // Responsive §1.4: padding από SPoT + ListView (scroll αν χρειαστεί) —
        // ποτέ σταθερό ύψος.
        padding: const EdgeInsets.all(AppConstants.spacingL),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.titleThemeSection,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  // Dumb widget (κράτα σε §2.0) — η αλλαγή περνάει στον
                  // ThemeModeController (equality gate + save στο prefs).
                  ThemeModeSelector(
                    selected: themeMode,
                    onChanged: (mode) =>
                        ref.read(themeModeProvider.notifier).setMode(mode),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.titleCategoriesSection,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  // Tree editor (§2.3 · Βήμα 4): ζωντανό δέντρο + CRUD με
                  // πύλη διαγραφής — βλέπει DB providers (όχι μόνο prefs).
                  CategoryTreeEditor(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}