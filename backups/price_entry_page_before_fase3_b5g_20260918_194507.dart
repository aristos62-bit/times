/// Φάση 3, Βήμα 2 — Price Entry (σελίδα εισαγωγής §2.2).
///
/// Στοιχείο του App Shell: ο `AppShell` δίνει το Scaffold με NavigationBar
/// και η σελίδα προσθέτει δικό της nested Scaffold (AppBar + σώμα).
/// Watch-άρει ΜΟΝΟ τον τοπικό `receiptFormControllerProvider` (header
/// ημερομηνίας, Βήμα 2) — καμία εξάρτηση από repository → η βάση παραμένει
/// κλειστή όσο η σελίδα δείχνει μόνο τον σκελετό (ίδια αρχή με §3 Βήμα 1).
/// Οι γραμμές απόδειξης (draftLines) εμφανίζονται από τα Βήματα 4-5.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import 'widgets/item_search_field.dart';
import 'widgets/receipt_header_section.dart';

/// Σελίδα εισαγωγής τιμών (§2.2) — σκελετός φόρμας από το Βήμα 2.
class PriceEntryPage extends ConsumerWidget {
  const PriceEntryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.titlePriceEntry)),
      body: SafeArea(
        child: ListView(
          // Responsive §1.4: ListView + padding από SPoT, κανένα σταθερό ύψος.
          padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingL),
          children: const [
            ReceiptHeaderSection(),
            SizedBox(height: AppConstants.spacingL),
            // Βήμα 4: inline panel αναζήτησης είδους (§2.4).
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
              child: ItemSearchField(),
            ),
            SizedBox(height: AppConstants.spacingXL),
            // Γραμμές απόδειξης από τα Βήματα 4-5 → placeholder για τώρα.
            Center(child: Text(AppStrings.priceEntryLinesComingSoon)),
          ],
        ),
      ),
    );
  }
}