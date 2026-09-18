/// Inline panel αναζήτησης είδους (§2.4 DESIGN / Φάση 3 Βήμα 4).
///
/// ΗΜΙΔΙΑΔΙΚΤΥΑΚΟ (Α) κατά DESIGN: η αναζήτηση του είδους (Πίνακας 2.4.1)
/// γίνεται σε ΔΙΚΟ ΤΟΥ inline panel (όχι SearchableDropdownField) με δικό του
/// `itemSearchControllerProvider` (AsyncNotifier). Λόγοι: (α) το είδος έχει
/// σύνθετη κατάσταση (found/notFound/idle/searching/error) που δεν «χωράει»
/// στο dropdown-field· (β) το «+» εδώ ανοίγει το 3-βήματο dialog
/// `NewItemFlowDialog` (γραμμική ροή), όχι inline create.
///
/// STATUS-DRIVEN RENDERING (Αρχή: ένα block ανά status):
///   * idle → hint `itemSearchIdle`.
///   * searching → LinearProgressIndicator.
///   * found → λίστα αποτελεσμάτων (maxHeight searchDropdownMaxHeight) +
///     «+» (addNewItem).
///   * notFound → μήνυμα `itemNotFound(query)` + «+» (addNewItem).
///   * error (AsyncError) → retry.
///
/// ΕΠΙΛΟΓΗ «+» (PROMPT-FLOW §2.4):
///   * Ανοίγει το `NewItemFlowDialog` με prefill query.
///   * After-pop: «ΠΑΝΤΑ μετά το pop» (ScaffoldMessenger caveat — SnackBar
///     ΜΕΣΑ στο dialog κρύβεται πίσω του): created → itemAdded, exists →
///     itemExists, DB error (dialog downcasts `NewItemDialogFailed` → null-ish)
///     → loadDataFailed. Όλα μέσα AppFeedback — ποτέ raw ScaffoldMessenger.
///
/// ΕΠΙΛΕΓΜΕΝΟ (ITEM_SELECTED §2.4): banner με το είδος + κουμπί «Αλλαγή»
/// → clearSelection (επιστροφή σε idle).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_errors.dart';
import '../../../core/constants/app_messages.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../data/local/app_database.dart';
import '../controllers/item_search_controller.dart';
import '../state/item_search_state.dart';
import 'new_item_flow_dialog.dart';

/// Inline panel αναζήτησης είδους — status-driven (§2.4 · Βήμα 4).
class ItemSearchField extends ConsumerStatefulWidget {
  const ItemSearchField({super.key});

  @override
  ConsumerState<ItemSearchField> createState() => _ItemSearchFieldState();
}

class _ItemSearchFieldState extends ConsumerState<ItemSearchField> {
  /// Controller του πεδίου κειμένου — επαναφορά (clear) σε «Αλλαγή» (§2.4).
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Ανοιγμα του 3-βήματου dialog (§2.4). Post-pop feedback:
  /// dinner party rule — όλα τα SnackBar εδώ, ΠΟΤΕ μέσα στο dialog.
  Future<void> _openNewItemDialog() async {
    final query = _textController.text.trim();
    final result = await showDialog<NewItemDialogResult>(
      context: context,
      builder: (_) => NewItemFlowDialog(initialName: query),
    );
    if (!mounted || result == null) return; // dismiss / cancelled
    // DB error → ο καλών εμφανίζει το loadDataFailed (§2.4 απόφαση).
    if (result is NewItemDialogFailed) {
      AppFeedback.showError(context, AppErrors.loadDataFailed);
      return;
    }
    if (result is! NewItemDialogCreated) return;
    ref.read(itemSearchControllerProvider.notifier).selectItem(result.item);
    if (result.created) {
      AppFeedback.showSuccess(context, AppMessages.itemAdded);
    } else {
      AppFeedback.showSuccess(context, AppMessages.itemExists);
    }
  }

  /// Banner επιλεγμένου είδους — πλήρες σταθερό banner (§2.4).
  Widget _buildSelectedBanner(Item item) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.check_circle_outline),
        title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: TextButton(
          onPressed: () {
            _textController.clear();
            ref
                .read(itemSearchControllerProvider.notifier)
                .clearSelection();
          },
          child: const Text(AppStrings.changeItem),
        ),
      ),
    );
  }

  /// Γραμμή «+» — κοινή για found/notFound (§2.4: η δημιουργία εδώ γίνεται
  /// ΠΑΝΤΑ μέσω dialog, όχι inline).
  Widget _buildAddRow() {
    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            onPressed: _openNewItemDialog,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text(AppStrings.addNewItem),
          ),
        ),
      ],
    );
  }

  /// found → λίστα αποτελεσμάτων (maxHeight) + «+».
  Widget _buildResults(ItemSearchState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: AppConstants.searchDropdownMaxHeight,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: state.results.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = state.results[index];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.shopping_basket_outlined),
                title: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => ref
                    .read(itemSearchControllerProvider.notifier)
                    .selectItem(item),
              );
            },
          ),
        ),
        _buildAddRow(),
      ],
    );
  }

  /// notFound → μήνυμα (SPoT δυναμικό) + «+».
  Widget _buildNotFound(ItemSearchState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingS),
          child: Text(
            AppMessages.itemNotFound(state.query),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        _buildAddRow(),
      ],
    );
  }

  /// error (AsyncError) → retry panel.
  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingS),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppErrors.loadDataFailed,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          TextButton.icon(
            onPressed: () =>
                ref.read(itemSearchControllerProvider.notifier).retry(),
            icon: const Icon(Icons.refresh),
            label: const Text(AppStrings.itemSearchRetry),
          ),
        ],
      ),
    );
  }

  /// Status routing — ΟΧΙ brittle deserialization (χειρήζουμε μόνο το
  /// `AsyncData`; error → AsyncError έχει δική του κατάσταση).
  Widget _buildStatusPanel(ItemSearchState state) {
    switch (state.status) {
      case ItemSearchStatus.searching:
        return const Padding(
          padding: EdgeInsets.all(AppConstants.spacingS),
          child: LinearProgressIndicator(),
        );
      case ItemSearchStatus.found:
        return _buildResults(state);
      case ItemSearchStatus.notFound:
        return _buildNotFound(state);
      case ItemSearchStatus.idle:
        return Padding(
          padding: const EdgeInsets.only(top: AppConstants.spacingS),
          child: Text(AppStrings.itemSearchIdle,
              style: Theme.of(context).textTheme.bodySmall),
        );
      case ItemSearchStatus.error:
        return _buildError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(itemSearchControllerProvider);
    // AsyncError → state το καθαρό error (retry panel).
    final state = async.when(
      data: (value) => value,
      error: (_, _) => const ItemSearchState(status: ItemSearchStatus.error),
      loading: () => const ItemSearchState(
        status: ItemSearchStatus.searching,
      ),
    );

    final selected = state.selectedItem;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingS),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingL,
                  ),
                  child: TextField(
                    controller: _textController,
                    enabled: selected == null,
                    onChanged: (value) => ref
                        .read(itemSearchControllerProvider.notifier)
                        .onQueryChanged(value),
                    decoration: InputDecoration(
                      labelText: AppStrings.fieldItemName,
                      hintText: AppStrings.itemSearchHint,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingL,
                  ),
                  child: selected != null
                      ? _buildSelectedBanner(selected)
                      : _buildStatusPanel(state),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}