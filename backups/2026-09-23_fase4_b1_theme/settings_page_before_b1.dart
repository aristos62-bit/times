/// Φάση 3, Βήμα 1 — Settings placeholder (σελίδα ρυθμίσεων §2.3).
///
/// Στοιχείο του App Shell: ο `AppShell` δίνει το Scaffold με NavigationBar
/// και κάθε σελίδα προσθέτει δικό της nested Scaffold (AppBar + σώμα).
/// ΔΕΝ watch-άρει providers — η βάση δεν ανοίγει όσο είναι placeholder
/// (το πραγματικό UI ρυθμίσεων έρχεται στη Φάση 4).
library;

import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

/// Σελίδα ρυθμίσεων (§2.3) — placeholder μέχρι τη Φάση 4.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.titleSettings)),
      body: const Center(
        child: Text(AppStrings.settingsComingSoon),
      ),
    );
  }
}