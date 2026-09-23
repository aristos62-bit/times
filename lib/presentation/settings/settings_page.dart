/// Φάση 4, Βήμα 1 — Σελίδα ρυθμίσεων (§2.3 DESIGN).
///
/// Στοιχείο του App Shell: ο `AppShell` δίνει το Scaffold με NavigationBar
/// και η σελίδα προσθέτει δικό της nested Scaffold (AppBar + σώμα).
/// Watches: `themeModeProvider` (πρώτο section «Θέμα»). SharedPreferences —
/// ΟΧΙ η βάση: ο κανόνας Α1 «η βάση ανοίγει μόνο μέσω PriceEntry»
/// (§2.2:221/Α1) παραμένει — κανένα DB provider εδώ.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../data/providers/settings_providers.dart';
import 'widgets/theme_mode_selector.dart';

/// Σελίδα ρυθμίσεων (§2.3) — section «Θέμα» (Βήμα 1). Τα επόμενα sections
/// (Κατηγορίες/Υποκατηγορίες → Βήμα 4, Backup → Βήμα 5) προστίθενται στη
/// ίδια λίστα.
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
        ],
      ),
    );
  }
}