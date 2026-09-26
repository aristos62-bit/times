/// Λίστα ειδών με αναζήτηση + CRUD (§2.3 DESIGN / ενότητα Ειδών).
///
/// Αναζήτηση = ατόφιο `ItemSearchField` (§2.4) πάνω σε FORK instance του
/// `itemSearchControllerProvider` (`ProviderScope.overrideWith` — ίδιο class,
/// χωριστό state, μηδέν duplication αλγορίθμου): η επιλογή εδώ ΔΕΝ αγγίζει
/// τη φόρμα απόδειξης (isolation, §2.4 — αποδεικνύεται με test). Το «+»
/// δημιουργεί μέσω `NewItemFlowDialog` (reuse) και επιλέγει στο fork — η
/// επεξεργασία/διαγραφή γίνεται πάνω στο επιλεγμένο (tile με edit + πύλη).
/// Ο management controller είναι global singleton — προσβάσιμος και από το
/// fork ref· το `clearSelection` μετά από CRUD καθαρίζει το fork (το root
/// το καθαρίζει ο controller, §2.3).
/// CRUD μέσω `ItemManagementController` + `ItemEditDialog` (όνομα/
/// υποκατηγορία/μονάδα) + `ConfirmDialog` (delete, `isDestructive`).
/// Feedback ΜΟΝΟ από εδώ μέσω `AppFeedback` (§2.4).
///
/// Πύλη διαγραφής (§2.3:275, πατρόν Βήματος 4): `canDelete==false` →
/// greyed-out + tooltip `itemLinesTooltip(count)`· loading/error → ανενεργό +
/// tap=retry (invalidate). One-shot families (IndexedStack) + κουμπί «↻».
/// Responsive §1.4: στήλη, ellipsis, κανένα fixed ύψος· dark/light από theme.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_errors.dart';
import '../../../core/constants/app_messages.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../data/local/app_database.dart';
import '../../../data/providers/database_providers.dart';
import '../../../data/providers/settings_providers.dart';
import '../../price_entry/controllers/item_search_controller.dart';
import '../../price_entry/widgets/item_search_field.dart';
import '../../shared/confirm_dialog.dart';
import '../../shared/controller_op_runner.dart';
import '../../shared/delete_gate_button.dart';
import '../controllers/item_management_controller.dart';
import 'item_edit_dialog.dart';

/// Λίστα ειδών (§2.3) — fork scope + περιεχόμενο (το περιεχόμενο διαβάζει
/// το forked instance, ο γονέας μένει dumb).
class ItemListEditor extends ConsumerWidget {
  const ItemListEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: [
        itemSearchControllerProvider.overrideWith(
          ItemSearchController.new,
        ),
      ],
      child: const _ItemListContent(),
    );
  }
}

/// Περιεχόμενο (ΚΑΤΩ από το override — βλέπει το forked instance).
class _ItemListContent extends ConsumerWidget {
  const _ItemListContent();

  /// Επεξεργασία επιλεγμένου: lookups (υποκατηγορία → κατηγορία + μονάδα)
  /// ΠΡΙΝ το open (το dialog μένει σύγχρονο, §2.4) → dialog → controller →
  /// feedback + καθάρισμα fork-επιλογής (dup → snackbar `nameExists`).
  /// Ανύπαρκτα refs (race διαγραφής) → `loadDataFailed` χωρίς dialog.
  Future<void> _editItem(
    BuildContext context,
    WidgetRef ref,
    Item item,
  ) async {
    final sub = await ref.read(subCategoryRepositoryProvider).getById(
          item.subCategoryId,
        );
    if (sub == null || !context.mounted) {
      if (context.mounted) {
        AppFeedback.showError(context, AppErrors.loadDataFailed);
      }
      return;
    }
    final category =
        await ref.read(categoryRepositoryProvider).getById(sub.categoryId);
    if (category == null || !context.mounted) {
      if (context.mounted) {
        AppFeedback.showError(context, AppErrors.loadDataFailed);
      }
      return;
    }
    Unit? unit;
    if (item.defaultUnitId != null) {
      unit = await ref
          .read(unitRepositoryProvider)
          .getById(item.defaultUnitId!);
    }
    if (!context.mounted) return;
    final result = await showItemEditDialog(
      context,
      item: item,
      subCategory: sub,
      category: category,
      unit: unit,
    );
    if (result == null || !context.mounted) return;
    await runControllerOp(
      context,
      () => ref.read(itemManagementControllerProvider.notifier).updateItem(
            id: item.id,
            name: result.name,
            subCategoryId: result.subCategoryId,
            defaultUnitId: result.defaultUnitId,
          ),
      AppMessages.itemUpdated,
    );
    if (!context.mounted) return;
    ref.read(itemSearchControllerProvider.notifier).clearSelection();
  }

  /// Διαγραφή καθαρού είδους: η πύλη εγγυάται 0 γραμμές (RESTRICT §3).
  Future<void> _deleteItem(
    BuildContext context,
    WidgetRef ref,
    Item item,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      message: AppMessages.deleteItemConfirm(item.name),
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;
    await runControllerOp(
      context,
      () => ref
          .read(itemManagementControllerProvider.notifier)
          .deleteItem(item.id),
      AppMessages.itemDeleted,
    );
    if (!context.mounted) return;
    ref.read(itemSearchControllerProvider.notifier).clearSelection();
  }

  /// Γραμμή επιλεγμένου είδους: όνομα + edit + πύλη διαγραφής.
  Widget _itemTile(
    BuildContext context,
    WidgetRef ref,
    Item item,
    bool working,
  ) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.shopping_basket_outlined),
      title: Text(
        item.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: AppStrings.editAction,
            onPressed: working ? null : () => _editItem(context, ref, item),
          ),
          DeleteGateButton(
            canDelete: ref.watch(canDeleteItemProvider(item.id)),
            count: ref.watch(itemLinesCountProvider(item.id)),
            blockedTooltip: AppMessages.itemLinesTooltip,
            onDelete: () => _deleteItem(context, ref, item),
            onRetry: () {
              ref.invalidate(canDeleteItemProvider(item.id));
              ref.invalidate(itemLinesCountProvider(item.id));
            },
            working: working,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Busy-flag (pattern editors §2.3): απενεργοποιεί edit/delete όσο
    // τρέχει CRUD (§2.4 guard).
    final working = ref.watch(
      itemManagementControllerProvider.select((s) => s.isWorking),
    );
    // Forked επιλογή (βλ. doc `ItemListEditor`).
    final selected =
        ref.watch(itemSearchControllerProvider).value?.selectedItem;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ίδια αναζήτηση/«+» με την απόδειξη (§2.4, forked instance).
        const ItemSearchField(),
        if (selected != null) ...[
          const SizedBox(height: AppConstants.spacingS),
          _itemTile(context, ref, selected, working),
          TextButton.icon(
            onPressed: () => ref
                .read(itemManagementControllerProvider.notifier)
                .refreshGuards(itemIds: [selected.id]),
            icon: const Icon(Icons.refresh),
            label: const Text(AppStrings.refreshAction),
          ),
        ],
      ],
    );
  }
}
