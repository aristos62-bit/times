/// Φάση 3, Βήμα 1 — Home placeholder (σελίδα στατιστικών §2.1).
///
/// Στοιχείο του App Shell: ο `AppShell` δίνει το Scaffold με NavigationBar
/// και κάθε σελίδα προσθέτει δικό της nested Scaffold (AppBar + σώμα).
/// ΔΕΝ watch-άρει providers — η βάση δεν ανοίγει όσο είναι placeholder
/// (η πρώτη πραγματική σελίδα δεδομένων έρχεται στη Φάση 5, §2.1).
library;

import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

/// Σελίδα στατιστικών (§2.1) — placeholder μέχρι τη Φάση 5.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appTitle)),
      body: const Center(
        // Placeholder ΣΤΑΤΙΚΟ (SPoT) — όχι σκελετό-loading, μέχρι τη Φάση 5.
        child: Text(AppStrings.statsComingSoon),
      ),
    );
  }
}