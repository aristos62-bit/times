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
///
/// Exit-confirm (§2.2:244 «Ημιτελής καταχώρηση»): `PopScope` γύρω από το
/// Scaffold — όταν υπάρχουν μη αποθηκευμένες `draftLines`, το system back
/// (Android/iOS) ανοίγει το generic `ConfirmDialog` («Έξοδος χωρίς
/// αποθήκευση;»). «Ναι» → `resetForm` + `clearSelection` (καθαρή φόρμα που
/// βρίσκει ο χρήστης αν γυρίσει) + άδεια εξόδου (το επόμενο back ολοκληρώνει
/// την έξοδο)· «Ακύρωση»/dismiss → παραμονή, τα drafts μένουν. ΚΑΝΕΝΑ
/// flag-στάσιμο: η «άδεια εξόδου» (`_allowPop`) σβήνει ξανά όταν ο χρήστης
/// προσθέσει νέες γραμμές (ref.listen). Η αλλαγή tab ΔΕΝ ενεργοποιεί τον
/// έλεγχο (IndexedStack κρατά τα drafts σκόπιμα, §2.2:222).
/// Κλείσιμο παραθύρου desktop (X/Alt+F4) και browser-close: εκτός ελέγχου
/// Flutter-επιπέδου (native listener εκτός MVP — τεκμηριωμένο όριο).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_messages.dart';
import '../../core/constants/app_strings.dart';
import '../../core/logging/app_logger.dart';
import '../shared/confirm_dialog.dart';
import 'controllers/item_search_controller.dart';
import 'controllers/receipt_form_controller.dart';
import 'widgets/draft_lines_list.dart';
import 'widgets/item_search_field.dart';
import 'widgets/receipt_header_section.dart';
import 'widgets/recent_receipts_list.dart';
import 'widgets/save_receipt_button.dart';
import 'widgets/unit_quantity_price_section.dart';

/// Σελίδα εισαγωγής τιμών (§2.2) — header + search + section + draft + save.
class PriceEntryPage extends ConsumerStatefulWidget {
  const PriceEntryPage({super.key});

  @override
  ConsumerState<PriceEntryPage> createState() => _PriceEntryPageState();
}

class _PriceEntryPageState extends ConsumerState<PriceEntryPage> {
  /// Άδεια εξόδου μετά από επιβεβαίωση του exit-confirm. Μοναδικό σημείο
  /// `true`: ο χρήστης πάτησε «Ναι». Ο `ref.listen` παρακάτω την επαναφέρει
  /// σε `false` όταν εμφανιστούν (ξανά) draft γραμμές — η προστασία ξανα-ενεργο-
  /// ποιείται (edge: root-pop σε desktop δεν «φεύγει» πραγματικά από τη
  /// σελίδα, αλλά η φόρμα έχει ήδη καθαρίσει).
  bool _allowPop = false;

  /// Guard διπλού ανοίγματος του dialog από γρήγορο double back-tap.
  bool _dialogOpen = false;

  @override
  Widget build(BuildContext context) {
    // Watch για το `canPop`: draftLines — η προδιαγραφή §2.2:244 αφορά ΜΟΝΟ
    // draft γραμμές («μη αποθηκευμένες draftLines») — μόνος ο προμηθευτής ή
    // η ημερομηνία ΔΕΝ μπλοκάρουν την έξοδο.
    final hasDrafts =
        ref.watch(receiptFormControllerProvider).draftLines.isNotEmpty;
    // Επαναφορά της άδειας εξόδου όταν ο χρήστης ξανα-γεμίζει τη φόρμα.
    ref.listen(receiptFormControllerProvider, (previous, next) {
      if (_allowPop && next.draftLines.isNotEmpty) _allowPop = false;
    });

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

    return PopScope(
      // Χωρίς drafts (ή μετά από «Ναι») το back περνάει κανονικά — με drafts
      // μπλοκάρεται και ανοίγει το exit-confirm (§2.2:244).
      canPop: _allowPop || !hasDrafts,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // _allowPop=true: ο χρήστης ήδη επιβεβαίωσε. ΚΑΝΕΝΑ ρητό pop εδώ —
        // η σελίδα είναι η μοναδική route της branch· το να «φύγει» θα
        // αφαιρούσε όλο το shell (go_router assert «no pages left»). Ο δικός
        // μας back-χειρισμός τελειώνει· η έξοδος ολοκληρώνεται από το επόμενο
        // system-back (canPop=true → φυσιολογικό root pop / app-exit Android).
        if (_allowPop) return;
        _confirmExit();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text(AppStrings.titlePriceEntry)),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide =
                  constraints.maxWidth >= AppConstants.tabletMaxWidth;
              return ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.spacingL,
                ),
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
      ),
    );
  }

  /// Exit-confirm (§2.2:244): εμφανίζει το generic `ConfirmDialog` με το SPoT
  /// μήνυμα «Έχετε μη αποθηκευμένες γραμμές. Έξοδος χωρίς αποθήκευση;».
  ///   * «Ναι» → καθαρισμός φόρμας (`resetForm` + `clearSelection`, ίδιο
  ///     μοτίβο με το αποτέλεσμα save §2.2:212) + άδεια εξόδου. ΚΑΝΕΝΑ ρητό
  ///     `pop`: η σελίδα είναι η μόνη route της branch (go_router assert) —
  ///     το επόμενο system-back με `canPop=true` ολοκληρώνει την έξοδο
  ///     (Android) ή απλώς τίποτα (desktop: η φόρμα είναι ΕΤΣΙ ΚΑΙ ΑΛΛΙΩΣ
  ///     καθαρή — τίποτα προς απώλεια).
  ///   * «Ακύρωση»/dismiss/back → παραμονή, τα drafts μένουν άθικτα.
  Future<void> _confirmExit() async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    try {
      final confirmed = await showConfirmDialog(
        context,
        message: AppMessages.exitUnsavedConfirm,
      );
      if (!mounted) return;
      if (confirmed != true) return; // «Ακύρωση» — καμία αλλαγή
      AppLogger.info(LogTag.ui, 'Έξοδος χωρίς αποθήκευση — καθαρισμός φόρμας');
      ref.read(receiptFormControllerProvider.notifier).resetForm();
      ref.read(itemSearchControllerProvider.notifier).clearSelection();
      setState(() => _allowPop = true);
    } finally {
      _dialogOpen = false;
    }
  }
}