/// Φάση 4, Βήμα 1+4+5 — Σελίδα ρυθμίσεων (§2.3 DESIGN).
///
/// Στοιχείο του App Shell: ο `AppShell` δίνει το Scaffold με NavigationBar
/// και η σελίδα προσθέτει δικό της nested Scaffold (AppBar + σώμα).
/// Watches: `themeModeProvider` (section «Θέμα», SharedPreferences — ΟΧΙ η
/// βάση) + `categoryTreeStreamProvider` (section «Κατηγορίες», Βήμα 4) +
/// `receiptsByDayStreamProvider`/`selectedReceiptDayProvider` (section
/// «Αποδείξεις», Φάση Β — η βάση ανοίγει και από εδώ· στο launch είναι ήδη
/// ανοιχτή μέσω PriceEntry, IndexedStack §2.2:221/Α1).
/// Sections «Κατηγορίες»/«Προμηθευτές»/«Αποδείξεις»/«Αντίγραφα» collapsible
/// (24-09-2026 + Βήμα 5): κλειστά εξ αρχής (`ExpansionTile` default) —
/// καθαρή είσοδος στη σελίδα· tap δείχνει τον editor ως ήταν.
/// Το expand-state επιβιώνει σε αλλαγή tab
/// (IndexedStack κρατά το State, §2.2:222).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../data/providers/settings_providers.dart';
import 'widgets/backup_restore_section.dart';
import 'widgets/category_tree_editor.dart';
import 'widgets/receipts_management_editor.dart';
import 'widgets/supplier_list_editor.dart';
import 'widgets/theme_mode_selector.dart';

/// Σελίδα ρυθμίσεων (§2.3) — section «Θέμα» (Βήμα 1 · πάντα ορατό) +
/// collapsible sections «Κατηγορίες» (tree editor, Βήμα 4) + «Προμηθευτές»
/// (CRUD 24-09-2026) + «Αποδείξεις» (διαχείριση, Φάση Β 24-09-2026) +
/// «Αντίγραφα ασφαλείας» (export/restore, Βήμα 5).
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
            // Collapsible section (24-09-2026): κλειστό εξ αρχής
            // (`initiallyExpanded` default false) — tap δείχνει τον editor.
            child: ExpansionTile(
              title: Text(
                AppStrings.titleCategoriesSection,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(
                AppConstants.spacingL,
                0,
                AppConstants.spacingL,
                AppConstants.spacingL,
              ),
              // Tree editor (§2.3 · Βήμα 4): ζωντανό δέντρο + CRUD με
              // πύλη διαγραφής — βλέπει DB providers (όχι μόνο prefs).
              children: const [CategoryTreeEditor()],
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          Card(
            // Collapsible section (24-09-2026) — όπως οι Κατηγορίες.
            child: ExpansionTile(
              title: Text(
                AppStrings.titleSuppliersSection,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(
                AppConstants.spacingL,
                0,
                AppConstants.spacingL,
                AppConstants.spacingL,
              ),
              // Supplier editor (§2.3 · CRUD 24-09-2026): ζωντανή λίστα
              // + CRUD με πύλη διαγραφής (RESTRICT §3).
              children: const [SupplierListEditor()],
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          Card(
            // Collapsible section (§2.3 · Φάση Β): φίλτρο ημέρας + λίστα
            // με edit/delete (reuse controller Φάσης Α, §2.4).
            child: ExpansionTile(
              title: Text(
                AppStrings.titleReceiptsSection,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(
                AppConstants.spacingL,
                0,
                AppConstants.spacingL,
                AppConstants.spacingL,
              ),
              children: const [ReceiptsManagementEditor()],
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          Card(
            // Collapsible section (§2.3 · Βήμα 5): export/restore — data-less
            // (μόνο isWorking flag, όπως το Theme — δεν ανοίγει τη βάση).
            child: ExpansionTile(
              title: Text(
                AppStrings.titleBackupSection,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(
                AppConstants.spacingL,
                0,
                AppConstants.spacingL,
                AppConstants.spacingL,
              ),
              children: const [BackupRestoreSection()],
            ),
          ),
        ],
      ),
    );
  }
}