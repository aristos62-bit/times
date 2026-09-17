/// Φάση 3, Βήμα 1 — Price Entry placeholder (σελίδα εισαγωγής §2.2).
///
/// Στοιχείο του App Shell: ο `AppShell` δίνει το Scaffold με NavigationBar
/// και κάθε σελίδα προσθέτει δικό της nested Scaffold (AppBar + σώμα).
/// ΔΕΝ watch-άρει providers — η βάση δεν ανοίγει όσο είναι placeholder
/// (το πραγματικό UI εισαγωγής χτίζεται από το Βήμα 2 της Φάσης 3).
library;

import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

/// Σελίδα εισαγωγής τιμών (§2.2) — placeholder μέχρι το Βήμα 2 της Φάσης 3.
class PriceEntryPage extends StatelessWidget {
  const PriceEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.titlePriceEntry)),
      body: const Center(
        child: Text(AppStrings.priceEntryComingSoon),
      ),
    );
  }
}