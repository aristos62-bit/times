/// Λίστα προμηθευτών με CRUD (§2.3 DESIGN / CRUD 24-09-2026).
///
/// Data-section `ConsumerWidget` (pattern `CategoryTreeEditor`): βλέπει τον
/// ζωντανό `suppliersStreamProvider` (ταξινόμηση normalizedName, κανένα νέο
/// query) + ανά γραμμή τους `canDeleteSupplierProvider` /
/// `receiptCountSupplierProvider`. CRUD μέσω του
/// `SupplierManagementController` + `CategoryEditDialog` (dumb+parametric,
/// reuse — τίτλοι SPoT καλούντος) + `ConfirmDialog` (delete, `isDestructive`).
/// Feedback ΜΟΝΟ από εδώ μέσω `AppFeedback` — ποτέ μέσα στα dialogs
/// (ScaffoldMessenger caveat, §2.4).
///
/// Πύλη διαγραφής (§2.3:275, πατρόν Βήματος 4): `canDelete==false` →
/// greyed-out + tooltip `supplierReceiptsTooltip(count)` (όχι error-after-tap)·
/// loading/error πύλης → ανενεργό + tap=retry (invalidate). Οι πύλες είναι
/// one-shot (IndexedStack): το κουμπί ανανέωσης ξανατρέχει όλες τις ορατές.
/// Χωρίς search (προσωπική χρήση, δεκάδες — σκόπιμη αποφυγή νέου feature).
/// Responsive §1.4: στήλη, ellipsis, κανένα fixed ύψος· dark/light από theme.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_errors.dart';
import '../../../core/constants/app_messages.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/local/app_database.dart';
import '../../../data/providers/settings_providers.dart';
import '../../../data/providers/stream_providers.dart';
import '../../shared/confirm_dialog.dart';
import '../../shared/controller_op_runner.dart';
import '../../shared/delete_gate_button.dart';
import '../controllers/supplier_management_controller.dart';
import 'category_edit_dialog.dart';

/// Λίστα προμηθευτών με CRUD (§2.3).
class SupplierListEditor extends ConsumerWidget {
  const SupplierListEditor({super.key});

  /// Προσθήκη προμηθευτή: dialog → controller → feedback (dup → snackbar
  /// `nameExists`, όπως το `supplierExists` του header §2.4).
  Future<void> _addSupplier(BuildContext context, WidgetRef ref) async {
    final name = await showCategoryEditDialog(
      context,
      title: AppStrings.addNewSupplier,
      confirmLabel: AppStrings.newItemSave,
      labelText: AppStrings.fieldSupplier,
    );
    if (name == null || !context.mounted) return;
    await runControllerOp(
      context,
      () => ref
          .read(supplierManagementControllerProvider.notifier)
          .createSupplier(name),
      AppMessages.supplierAdded,
    );
  }

  /// Μετονομασία προμηθευτή (χωρίς write όταν ίδιο — no-op του controller).
  /// Οι αποδείξεις δείχνουν το νέο όνομα αυτόματα (join §2.2 Βήμα 7)·
  /// ανοιχτό draft κρατά το παλιό label μέχρι νέα επιλογή (τεκμηριωμένο edge).
  Future<void> _renameSupplier(
    BuildContext context,
    WidgetRef ref,
    Supplier supplier,
  ) async {
    final name = await showCategoryEditDialog(
      context,
      title: AppStrings.fieldSupplier,
      confirmLabel: AppStrings.saveAction,
      initialName: supplier.name,
      labelText: AppStrings.fieldSupplier,
    );
    if (name == null || !context.mounted) return;
    await runControllerOp(
      context,
      () => ref
          .read(supplierManagementControllerProvider.notifier)
          .renameSupplier(supplier.id, name),
      AppMessages.supplierUpdated,
    );
  }

  /// Διαγραφή καθαρού προμηθευτή: η πύλη εγγυάται 0 αποδείξεις (RESTRICT §3),
  /// άρα το confirm θέλει ΜΟΝΟ το όνομα (χωρίς count, χωρίς cascade-διατύπωση
  /// — διαφορά από τις κατηγορίες).
  Future<void> _deleteSupplier(
    BuildContext context,
    WidgetRef ref,
    Supplier supplier,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      message: AppMessages.deleteSupplierConfirm(supplier.name),
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;
    await runControllerOp(
      context,
      () => ref
          .read(supplierManagementControllerProvider.notifier)
          .deleteSupplier(supplier.id),
      AppMessages.supplierDeleted,
    );
  }

  /// Γραμμή προμηθευτή: ListTile + edit + πύλη διαγραφής.
  Widget _supplierTile(
    BuildContext context,
    WidgetRef ref,
    Supplier supplier,
    bool working,
  ) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.store_outlined),
      title: Text(
        supplier.name,
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
                : () => _renameSupplier(context, ref, supplier),
          ),
          DeleteGateButton(
            canDelete: ref.watch(canDeleteSupplierProvider(supplier.id)),
            count: ref.watch(receiptCountSupplierProvider(supplier.id)),
            blockedTooltip: AppMessages.supplierReceiptsTooltip,
            onDelete: () => _deleteSupplier(context, ref, supplier),
            onRetry: () {
              ref.invalidate(canDeleteSupplierProvider(supplier.id));
              ref.invalidate(receiptCountSupplierProvider(supplier.id));
            },
            working: working,
          ),
        ],
      ),
    );
  }

  /// Δεδομένα: γραμμές (ή κενό) + γραμμή «προσθήκη + ανανέωση».
  Widget _buildData(
    BuildContext context,
    WidgetRef ref,
    List<Supplier> suppliers,
    bool working,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (suppliers.isEmpty)
          Text(
            AppStrings.suppliersEmpty,
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          for (final supplier in suppliers)
            _supplierTile(context, ref, supplier, working),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: working ? null : () => _addSupplier(context, ref),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text(AppStrings.addNewSupplier),
              ),
            ),
            if (suppliers.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: AppStrings.refreshAction,
                onPressed: () => ref
                    .read(supplierManagementControllerProvider.notifier)
                    .refreshGuards(
                      supplierIds: [for (final s in suppliers) s.id],
                    ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(suppliersStreamProvider);
    // Busy-flag: απενεργοποιεί add/edit/delete όσο τρέχει CRUD (§2.4 guard).
    final working = ref.watch(
      supplierManagementControllerProvider.select((s) => s.isWorking),
    );
    // Καταστάσεις (pattern recent_receipts_list): loading · error+Επανάληψη
    // (invalidate stream) · empty/data (με προσθήκη + ανανέωση).
    return async.when(
      data: (suppliers) => _buildData(context, ref, suppliers, working),
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
            onPressed: () => ref.invalidate(suppliersStreamProvider),
            child: const Text(AppStrings.retryButton),
          ),
        ],
      ),
    );
  }
}
