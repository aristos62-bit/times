/// Tree editor καταλόγου 4 επιπέδων (§2.3 DESIGN · 27-09-2026).
///
/// Data-section `ConsumerWidget` (pattern `RecentReceiptsList`): βλέπει το
/// ζωντανό `categoryTreeStreamProvider` (in-memory σύνθεση, κανένα νέο query)
/// + ανά γραμμή τους `canDelete*/inUseCount*` providers. CRUD μέσω του
/// `CategoryManagementController` + `CategoryEditDialog` (create/rename —
/// reuse και για Τμήμα) + `ConfirmDialog` (delete, `isDestructive`).
/// Feedback ΜΟΝΟ από εδώ μέσω `AppFeedback` — ποτέ μέσα στα dialogs.
///
/// Πύλη διαγραφής (§2.3:275): `canDelete==false` → greyed-out + tooltip
/// `itemsInUseTooltip(count)`· loading/error πύλης → ανενεργό + tap=retry.
/// One-shot families (IndexedStack) + κουμπί ανανέωσης.
/// Responsive §1.4: στήλη, ellipsis, κανένα fixed ύψος· dark/light από theme.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_errors.dart';
import '../../../core/constants/app_messages.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../data/local/app_database.dart';
import '../../../data/models/category_tree_node.dart';
import '../../../data/providers/settings_providers.dart';
import '../../shared/confirm_dialog.dart';
import '../../shared/controller_op_runner.dart';
import '../../shared/delete_gate_button.dart';
import '../controllers/category_management_controller.dart';
import 'category_edit_dialog.dart';

/// Tree editor «Κατηγορία ▸ Υποκατηγορία ▸ Τμήμα» με CRUD (§2.3).
class CategoryTreeEditor extends ConsumerWidget {
  const CategoryTreeEditor({super.key});

  /// Προσθήκη κατηγορίας: dialog → controller → feedback.
  Future<void> _addCategory(BuildContext context, WidgetRef ref) async {
    final name = await showCategoryEditDialog(
      context,
      title: AppStrings.addNewCategory,
      confirmLabel: AppStrings.newItemSave,
      labelText: AppStrings.fieldCategory,
    );
    if (name == null || !context.mounted) return;
    await runControllerOp(
      context,
      () => ref
          .read(categoryManagementControllerProvider.notifier)
          .createCategory(name),
      AppMessages.categoryAdded,
    );
  }

  /// Μετονομασία κατηγορίας (χωρίς write όταν ίδιο — no-op του controller).
  Future<void> _renameCategory(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final name = await showCategoryEditDialog(
      context,
      title: AppStrings.fieldCategory,
      confirmLabel: AppStrings.saveAction,
      initialName: category.name,
      labelText: AppStrings.fieldCategory,
    );
    if (name == null || !context.mounted) return;
    await runControllerOp(
      context,
      () => ref
          .read(categoryManagementControllerProvider.notifier)
          .renameCategory(category.id, name),
      AppMessages.categoryUpdated,
    );
  }

  /// Διαγραφή κατηγορίας: count (one-shot) → cascade confirm → delete.
  Future<void> _deleteCategory(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final controller = ref.read(
      categoryManagementControllerProvider.notifier,
    );
    int count;
    try {
      count = await controller.getCategoryItemCount(category.id);
    } on DataLoadException catch (e) {
      if (!context.mounted) return;
      AppFeedback.showError(context, e.userMessage);
      return;
    }
    if (!context.mounted) return;
    final confirmed = await showConfirmDialog(
      context,
      message: AppMessages.deleteCategoryConfirm(category.name, count),
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;
    await runControllerOp(
      context,
      () => controller.deleteCategory(category.id),
      AppMessages.categoryDeleted,
    );
  }

  /// Προσθήκη υποκατηγορίας στην [categoryId].
  Future<void> _addSubCategory(
    BuildContext context,
    WidgetRef ref,
    int categoryId,
  ) async {
    final name = await showCategoryEditDialog(
      context,
      title: AppStrings.addNewSubCategory,
      confirmLabel: AppStrings.newItemSave,
      labelText: AppStrings.fieldSubCategory,
    );
    if (name == null || !context.mounted) return;
    await runControllerOp(
      context,
      () => ref
          .read(categoryManagementControllerProvider.notifier)
          .createSubCategory(categoryId: categoryId, name: name),
      AppMessages.subCategoryAdded,
    );
  }

  /// Μετονομασία υποκατηγορίας (χωρίς αλλαγή κατηγορίας — εκτός scope).
  Future<void> _renameSubCategory(
    BuildContext context,
    WidgetRef ref,
    SubCategory sub,
  ) async {
    final name = await showCategoryEditDialog(
      context,
      title: AppStrings.fieldSubCategory,
      confirmLabel: AppStrings.saveAction,
      initialName: sub.name,
      labelText: AppStrings.fieldSubCategory,
    );
    if (name == null || !context.mounted) return;
    await runControllerOp(
      context,
      () => ref
          .read(categoryManagementControllerProvider.notifier)
          .renameSubCategory(sub.id, name),
      AppMessages.subCategoryUpdated,
    );
  }

  /// Διαγραφή υποκατηγορίας: count → confirm → delete (συμμετρικό).
  Future<void> _deleteSubCategory(
    BuildContext context,
    WidgetRef ref,
    SubCategory sub,
  ) async {
    final controller = ref.read(
      categoryManagementControllerProvider.notifier,
    );
    int count;
    try {
      count = await controller.getSubCategoryItemCount(sub.id);
    } on DataLoadException catch (e) {
      if (!context.mounted) return;
      AppFeedback.showError(context, e.userMessage);
      return;
    }
    if (!context.mounted) return;
    final confirmed = await showConfirmDialog(
      context,
      message: AppMessages.deleteSubCategoryConfirm(sub.name, count),
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;
    await runControllerOp(
      context,
      () => controller.deleteSubCategory(sub.id),
      AppMessages.subCategoryDeleted,
    );
  }

  /// Προσθήκη τμήματος στην [subCategoryId] (27-09-2026).
  Future<void> _addItemGroup(
    BuildContext context,
    WidgetRef ref,
    int subCategoryId,
  ) async {
    final name = await showCategoryEditDialog(
      context,
      title: AppStrings.addNewItemGroup,
      confirmLabel: AppStrings.newItemSave,
      labelText: AppStrings.fieldItemGroup,
    );
    if (name == null || !context.mounted) return;
    await runControllerOp(
      context,
      () => ref
          .read(categoryManagementControllerProvider.notifier)
          .createItemGroup(subCategoryId: subCategoryId, name: name),
      AppMessages.itemGroupAdded,
    );
  }

  /// Μετονομασία τμήματος (χωρίς αλλαγή υποκατηγορίας — εκτός scope).
  Future<void> _renameItemGroup(
    BuildContext context,
    WidgetRef ref,
    ItemGroup group,
  ) async {
    final name = await showCategoryEditDialog(
      context,
      title: AppStrings.fieldItemGroup,
      confirmLabel: AppStrings.saveAction,
      initialName: group.name,
      labelText: AppStrings.fieldItemGroup,
    );
    if (name == null || !context.mounted) return;
    await runControllerOp(
      context,
      () => ref
          .read(categoryManagementControllerProvider.notifier)
          .renameItemGroup(group.id, name),
      AppMessages.itemGroupUpdated,
    );
  }

  /// Διαγραφή τμήματος: count → confirm → delete (συμμετρικό).
  Future<void> _deleteItemGroup(
    BuildContext context,
    WidgetRef ref,
    ItemGroup group,
  ) async {
    final controller = ref.read(
      categoryManagementControllerProvider.notifier,
    );
    int count;
    try {
      count = await controller.getItemGroupItemCount(group.id);
    } on DataLoadException catch (e) {
      if (!context.mounted) return;
      AppFeedback.showError(context, e.userMessage);
      return;
    }
    if (!context.mounted) return;
    final confirmed = await showConfirmDialog(
      context,
      message: AppMessages.deleteItemGroupConfirm(group.name, count),
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;
    await runControllerOp(
      context,
      () => controller.deleteItemGroup(group.id),
      AppMessages.itemGroupDeleted,
    );
  }

  /// Γραμμή τμήματος: indented ListTile + edit + πύλη διαγραφής.
  Widget _groupTile(
    BuildContext context,
    WidgetRef ref,
    ItemGroup group,
    bool working,
  ) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: AppConstants.spacingXL * 2),
      leading: const Icon(Icons.folder_open_outlined),
      title: Text(
        group.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: AppStrings.editAction,
            onPressed: working
                ? null
                : () => _renameItemGroup(context, ref, group),
          ),
          DeleteGateButton(
            canDelete: ref.watch(canDeleteItemGroupProvider(group.id)),
            count: ref.watch(inUseCountItemGroupProvider(group.id)),
            blockedTooltip: AppMessages.itemsInUseTooltip,
            onDelete: () => _deleteItemGroup(context, ref, group),
            onRetry: () {
              ref.invalidate(canDeleteItemGroupProvider(group.id));
              ref.invalidate(inUseCountItemGroupProvider(group.id));
            },
            working: working,
          ),
        ],
      ),
    );
  }

  /// Γραμμή υποκατηγορίας: ExpansionTile με τμήματα + «+» τμήματος.
  Widget _subTile(
    BuildContext context,
    WidgetRef ref,
    SubCategoryTreeNode node,
    bool working,
  ) {
    final sub = node.subCategory;
    return ExpansionTile(
      key: ValueKey('sub_${sub.id}'),
      controlAffinity: ListTileControlAffinity.leading,
      tilePadding: const EdgeInsets.only(left: AppConstants.spacingXL),
      leading: const Icon(Icons.folder_outlined),
      title: Text(
        sub.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: AppStrings.editAction,
            onPressed: working
                ? null
                : () => _renameSubCategory(context, ref, sub),
          ),
          DeleteGateButton(
            canDelete: ref.watch(canDeleteSubCategoryProvider(sub.id)),
            count: ref.watch(inUseCountSubCategoryProvider(sub.id)),
            blockedTooltip: AppMessages.itemsInUseTooltip,
            onDelete: () => _deleteSubCategory(context, ref, sub),
            onRetry: () {
              ref.invalidate(canDeleteSubCategoryProvider(sub.id));
              ref.invalidate(inUseCountSubCategoryProvider(sub.id));
            },
            working: working,
          ),
        ],
      ),
      children: [
        for (final group in node.itemGroups)
          _groupTile(context, ref, group, working),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: AppConstants.spacingXL * 2),
            child: TextButton.icon(
              onPressed: working
                  ? null
                  : () => _addItemGroup(context, ref, sub.id),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text(AppStrings.addNewItemGroup),
            ),
          ),
        ),
      ],
    );
  }

  /// Κόμβος κατηγορίας: ExpansionTile + edit/διαγραφή + παιδιά + «+».
  /// `ValueKey` ανά κατηγορία: το expand state ακολουθεί την οντότητα,
  /// όχι τη θέση. `controlAffinity: leading` ΧΩΡΙΣ `leading` icon.
  Widget _categoryTile(
    BuildContext context,
    WidgetRef ref,
    CategoryTreeNode node,
    bool working,
  ) {
    final category = node.category;
    return ExpansionTile(
      key: ValueKey(category.id),
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        category.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: AppStrings.editAction,
            onPressed: working
                ? null
                : () => _renameCategory(context, ref, category),
          ),
          DeleteGateButton(
            canDelete: ref.watch(canDeleteCategoryProvider(category.id)),
            count: ref.watch(inUseCountCategoryProvider(category.id)),
            blockedTooltip: AppMessages.itemsInUseTooltip,
            onDelete: () => _deleteCategory(context, ref, category),
            onRetry: () {
              ref.invalidate(canDeleteCategoryProvider(category.id));
              ref.invalidate(inUseCountCategoryProvider(category.id));
            },
            working: working,
          ),
        ],
      ),
      children: [
        for (final subNode in node.subNodes)
          _subTile(context, ref, subNode, working),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: working
                ? null
                : () => _addSubCategory(context, ref, category.id),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text(AppStrings.addNewSubCategory),
          ),
        ),
      ],
    );
  }

  /// Δεδομένα: κόμβοι (ή κενό) + γραμμή «προσθήκη + ανανέωση».
  Widget _buildData(
    BuildContext context,
    WidgetRef ref,
    List<CategoryTreeNode> nodes,
    bool working,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (nodes.isEmpty)
          Text(
            AppStrings.categoriesEmpty,
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          for (final node in nodes) _categoryTile(context, ref, node, working),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: working ? null : () => _addCategory(context, ref),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text(AppStrings.addNewCategory),
              ),
            ),
            if (nodes.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: AppStrings.refreshAction,
                onPressed: () => ref
                    .read(categoryManagementControllerProvider.notifier)
                    .refreshGuards(
                      categoryIds: [
                        for (final n in nodes) n.category.id,
                      ],
                      subCategoryIds: [
                        for (final n in nodes)
                          for (final s in n.subNodes) s.subCategory.id,
                      ],
                      itemGroupIds: [
                        for (final n in nodes)
                          for (final s in n.subNodes)
                            for (final g in s.itemGroups) g.id,
                      ],
                    ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(categoryTreeStreamProvider);
    // Busy-flag: απενεργοποιεί add/edit/delete όσο τρέχει CRUD (§2.4 guard).
    final working = ref.watch(
      categoryManagementControllerProvider.select((s) => s.isWorking),
    );
    // Καταστάσεις (pattern recent_receipts_list): loading · error+Επανάληψη
    // (invalidate tree) · empty/data (με προσθήκη + ανανέωση).
    return async.when(
      data: (nodes) => _buildData(context, ref, nodes, working),
      loading: () => const Padding(
        padding: EdgeInsets.all(AppConstants.spacingL),
        child: Center(
          child: SizedBox(
            width: AppConstants.smallSpinnerSize,
            height: AppConstants.smallSpinnerSize,
            child: CircularProgressIndicator(
              strokeWidth: AppConstants.spinnerStrokeWidth,
            ),
          ),
        ),
      ),
      error: (_, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppErrors.loadDataFailed,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextButton(
            onPressed: () => ref.invalidate(categoryTreeStreamProvider),
            child: const Text(AppStrings.retryButton),
          ),
        ],
      ),
    );
  }
}
