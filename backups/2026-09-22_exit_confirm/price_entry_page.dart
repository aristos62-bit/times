/// Φάση 3, Βήμα 5δ — Price Entry (σελίδα εισαγωγής §2.2).
///
/// Στοιχείο του App Shell: ο `AppShell` δίνει το Scaffold με NavigationBar
/// και η σελίδα προσθέτει δικό της nested Scaffold (AppBar + σώμα).
/// Watches: τοπικούς controllers (`receiptFormControllerProvider` για το
/// header, `itemSearchControllerProvider` για το επιλεγμένο είδος) + — από το
/// Βήμα 7 §2.2 (Α1) — τη λίστα πρόσφατων αποδείξεων μέσω
/// `recentReceiptsStreamProvider` (**NON-autoDispose**): η βάση είναι ανοιχτή
/// στο launch (IndexedStack AppShell, §2.0.1) και η λίστα ανανεώνεται ΜΟΝΗ
/// της μετά το save (§2.2:212) — κανένα χειροκίνητο refresh.
///
/// ΔΟΜΗ (§2.2 state machine): header → item search → (όταν ITEM_SELECTED)
/// ενότητα μονάδας/ποσότητας/τιμής → λίστα draft γραμμών («καλάθι») →
/// κουμπί αποθήκευσης (Βήμα 5δ, disabled-OR) → read-only λίστα πρόσφατων
/// αποδείξεων (Βήμα 7, §2.2).
/// Responsive §1.4: `LayoutBuilder` — σε φαρδιά οθόνη (≥ `tabletMaxWidth`)
/// search + section δίπλα-δίπλα, αλλιώς στοίβα κατακόρυφα. Κανένα σταθερό
/// ύψος (ListView + padding από SPoT).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import 'controllers/item_search_controller.dart';
import 'widgets/draft_lines_list.dart';
import 'widgets/item_search_field.dart';
import 'widgets/receipt_header_section.dart';
import 'widgets/recent_receipts_list.dart';
import 'widgets/save_receipt_button.dart';
import 'widgets/unit_quantity_price_section.dart';

/// Σελίδα εισαγωγής τιμών (§2.2) — header + search + section + draft + save.
class PriceEntryPage extends ConsumerWidget {
  const PriceEntryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Επιλεγμένο είδος (ITEM_SELECTED §2.4) → εμφάνιση της ενότητας
    // μονάδας/ποσότητας/τιμής. `valueOrNull`: σε loading/error → καμία
    // ενότητα (το field δείχνει spinner/retry μόνος του).
    final selected =
        ref.watch(itemSearchControllerProvider).value?.selectedItem;

    // Σταθερά blocks (ίδια και στις δύο διατάξεις).
    const searchBlock = Padding(
      padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      child: ItemSearchField(),
    );
    // `ValueKey(item.id)` → φρέσκια κατάσταση section ανά είδος (Δ8).
    final sectionBlock = selected == null
        ? null
        : Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
            child: UnitQuantityPriceSection(
              key: ValueKey(selected.id),
              item: selected,
            ),
          );
    const draftBlock = Padding(
      padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      child: DraftLinesList(),
    );
    // Κουμπί αποθήκευσης (Βήμα 5δ) — πάντα ορατό, disabled-OR όταν άκυρο.
    const saveBlock = Padding(
      padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      child: SaveReceiptButton(),
    );
    // Read-only λίστα πρόσφατων αποδείξεων (Βήμα 7 §2.2) — κάτω από το save,
    // ΠΑΝΤΑ ορατή (Α1: η βάση είναι ανοιχτή στο launch, IndexedStack §2.0.1).
    const recentBlock = Padding(
      padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      child: RecentReceiptsList(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.titlePriceEntry)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >= AppConstants.tabletMaxWidth;
            return ListView(
              padding:
                  const EdgeInsets.symmetric(vertical: AppConstants.spacingL),
              children: [
                const ReceiptHeaderSection(),
                const SizedBox(height: AppConstants.spacingL),
                if (wide && sectionBlock != null)
                  // Φαρδιά οθόνη: search + section δίπλα-δίπλα (§1.4).
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(child: searchBlock),
                      const SizedBox(width: AppConstants.spacingM),
                      Expanded(child: sectionBlock),
                    ],
                  )
                else ...[
                  searchBlock,
                  if (sectionBlock != null) ...[
                    const SizedBox(height: AppConstants.spacingL),
                    sectionBlock,
                  ],
                ],
                const SizedBox(height: AppConstants.spacingXL),
                draftBlock,
                const SizedBox(height: AppConstants.spacingL),
                saveBlock,
                const SizedBox(height: AppConstants.spacingXL),
                recentBlock,
              ],
            );
          },
        ),
      ),
    );
  }
}
