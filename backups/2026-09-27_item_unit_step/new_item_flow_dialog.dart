/// Popup «Νέο είδος» (4-βημάτων, γραμμικό) — §2.4 DESIGN / 27-09-2026.
///
/// ΡΟΗ: Κατηγορία → Υποκατηγορία → Τμήμα → Όνομα. ΑΥΣΤΗΡΑ ΓΡΑΜΜΙΚΟ (§2.4):
/// το επόμενο βήμα εμφανίζεται ΜΟΝΟ αφού επιλεγεί/δημιουργηθεί το
/// προηγούμενο — κανένα «πίσω» κουμπί (self-reinforcing linear flow).
///
/// ΑΡΧΙΤΕΚΤΟΝΙΚΗ:
///   * Βήματα 1-3 χρησιμοποιούν το generic `SearchableDropdownField<T>`
///     (§2.4) + τα search families `categorySearchProvider` /
///     `subCategorySearchProvider` / `itemGroupSearchProvider`.
///   * Όλες οι δημιουργίες (κατηγορία/υποκατηγορία/τμήμα) γίνονται σιωπηλά
///     (silent intermediate creates — §2.4 απόφαση): ΚΑΝΕΝΑ snackbar μέσα
///     στο dialog. Μόνο το τελικό Είδος «γυρίζει» πίσω με το result.
///     Άκυρο όνομα ή διπλότυπο στο «+»: ΚΑΜΙΑ δημιουργία και inline μήνυμα
///     κάτω από το πεδίο του βήματος (`nameRequired`/`nameTooLong`/
///     `nameExists`) — όχι snackbar. Σβήνει σε επιλογή ή σε επόμενη
///     επιτυχημένη δημιουργία, καθώς και κατά την πληκτρολόγηση (onChanged).
///   * Το feedback (SnackBar) γίνεται πάντα ΜΕΤΑ το pop από τον καλούντα
///     (ScaffoldMessenger caveat). Το AppFeedback καλείται ΜΟΝΟ εκεί.
///   * `isSaving` = double-tap guard (§2.4): όσο τρέχει το save, το «Προσθήκη»
///     απενεργοποιείται. Σφάλμα DB (DataLoadException) → pop `failed`.
///   * Responsive §1.4: `ConstrainedBox` (max width) + `SingleChildScrollView`,
///     κανένα fixed ύψος.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_errors.dart';
import '../../../core/constants/app_messages.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/local/app_database.dart';
import '../../../data/providers/stream_providers.dart';
import '../../../domain/validators/name_validator.dart';
import '../../shared/searchable_dropdown_field.dart';
import '../controllers/item_search_controller.dart';

/// Αποτέλεσμα του dialog — sealed, αποκωδικοποιείται από τον καλούντα.
sealed class NewItemDialogResult {
  const NewItemDialogResult();
}

/// Επιτυχία: νέο ή υπάρχον είδος (+ flag δημιουργίας για το snackbar).
final class NewItemDialogCreated extends NewItemDialogResult {
  const NewItemDialogCreated(this.item, {required this.created});
  final Item item;
  final bool created;
}

/// Ακύρωση χρήστη (κουμπί «Ακύρωση» / dismiss).
final class NewItemDialogCancelled extends NewItemDialogResult {
  const NewItemDialogCancelled();
}

/// Αποτυχία DB (DataLoadException) — ΣΥΝΕΠΕΙΑ: ο καλών δείχνει loadDataFailed.
final class NewItemDialogFailed extends NewItemDialogResult {
  const NewItemDialogFailed();
}

/// Popup δημιουργίας είδους — γραμμικός 4-βημάτος wizard (§2.4).
class NewItemFlowDialog extends ConsumerStatefulWidget {
  const NewItemFlowDialog({super.key, this.initialName = ''});

  /// Προ-συμπλήρωση του πεδίου ονόματος (το query του field, αν υπήρχε).
  final String initialName;

  @override
  ConsumerState<NewItemFlowDialog> createState() => _NewItemFlowDialogState();
}

class _NewItemFlowDialogState extends ConsumerState<NewItemFlowDialog> {
  /// Επιλεγμένη (ή νέα-δημιουργημένη) κατηγορία — «null» = Βήμα 1 σε εκκρεμότητα.
  Category? _category;

  /// Επιλεγμένη (ή νέα-δημιουργημένη) υποκατηγορία — «null» = Βήμα 2 pending.
  SubCategory? _subCategory;

  /// Επιλεγμένο (ή νέο-δημιουργημένο) τμήμα — «null» = Βήμα 3 pending.
  ItemGroup? _itemGroup;

  /// Controller του πεδίου ονόματος (Βήμα 3) — prefill από [initialName].
  late final TextEditingController _nameController;

  /// Double-tap guard του «Προσθήκη» (§2.4).
  bool _isSaving = false;

  /// Inline σφάλμα του «+» ανά βήμα — `null` = κανένα.
  String? _categoryError;
  String? _subCategoryError;
  String? _itemGroupError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName.trim());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Βήμα 1: δημιουργία κατηγορίας από το «+» — ΣΙΩΠΗΛΗ (silent).
  /// Επιστρέφει την κατηγορία (ή null) στο field για να «κλείσει» το overlay
  /// (SearchableDropdownField.onCreate) + ενημερώνει τον τοπικό state.
  /// Βήμα 6ζ: άκυρο όνομα (`NameValidator`, ΠΡΙΝ το DB) ή `null` από τον
  /// controller (διπλότυπο, soft dup-check) → inline `_categoryError`.
  /// Σφάλμα DB (DataLoadException) → inline `_categoryError` =
  /// `AppErrors.loadDataFailed`, χωρίς pop (ίδια ασυμμετρία ευρήματος 1 που
  /// κλείνει εδώ — πρότυπο ο `_createSupplier` του header §2.4).
  Future<Category?> _createCategory(String name) async {
    final nameError = NameValidator.validate(name.trim());
    if (nameError != null) {
      AppLogger.info(LogTag.ui, 'Απόρριψη «+» κατηγορίας "$name": $nameError');
      setState(() => _categoryError = nameError);
      return null;
    }
    try {
      final result = await ref
          .read(itemSearchControllerProvider.notifier)
          .createCategory(name);
      if (!mounted) return result.category;
      if (result.category == null) {
        AppLogger.info(LogTag.ui, 'Απόρριψη «+» κατηγορίας "$name": διπλότυπο');
      }
      setState(() {
        _categoryError = result.category == null ? AppErrors.nameExists : null;
        if (result.category != null) _category = result.category;
      });
      return result.category;
    } on DataLoadException {
      AppLogger.error(LogTag.db, 'Αποτυχία «+» κατηγορίας "$name" (DB)');
      if (!mounted) return null;
      setState(() => _categoryError = AppErrors.loadDataFailed);
      return null;
    }
  }

  /// Βήμα 2: δημιουργία υποκατηγορίας από το «+» — ΣΙΩΠΗΛΗ. Βήμα 6ζ: ίδιο
  /// inline σφάλμα (`_subCategoryError`) με το βήμα 1. Σφάλμα DB
  /// (DataLoadException) → inline `_subCategoryError` = `AppErrors.loadDataFailed`.
  Future<SubCategory?> _createSubCategory(String name) async {
    final nameError = NameValidator.validate(name.trim());
    if (nameError != null) {
      AppLogger.info(
        LogTag.ui,
        'Απόρριψη «+» υποκατηγορίας "$name": $nameError',
      );
      setState(() => _subCategoryError = nameError);
      return null;
    }
    try {
      final result = await ref
          .read(itemSearchControllerProvider.notifier)
          .createSubCategory(categoryId: _category!.id, name: name);
      if (!mounted) return result.subCategory;
      if (result.subCategory == null) {
        AppLogger.info(
          LogTag.ui,
          'Απόρριψη «+» υποκατηγορίας "$name": διπλότυπο',
        );
      }
      setState(() {
        _subCategoryError =
        result.subCategory == null ? AppErrors.nameExists : null;
        if (result.subCategory != null) _subCategory = result.subCategory;
      });
      return result.subCategory;
    } on DataLoadException {
      AppLogger.error(LogTag.db, 'Αποτυχία «+» υποκατηγορίας "$name" (DB)');
      if (!mounted) return null;
      setState(() => _subCategoryError = AppErrors.loadDataFailed);
      return null;
    }
  }

  /// Βήμα 3: δημιουργία τμήματος από το «+» — ΣΙΩΠΗΛΗ (27-09-2026).
  /// Ίδιο inline σφάλμα (`_itemGroupError`) με τα προηγούμενα βήματα.
  Future<ItemGroup?> _createItemGroup(String name) async {
    final nameError = NameValidator.validate(name.trim());
    if (nameError != null) {
      AppLogger.info(
        LogTag.ui,
        'Απόρριψη «+» τμήματος "$name": $nameError',
      );
      setState(() => _itemGroupError = nameError);
      return null;
    }
    try {
      final result = await ref
          .read(itemSearchControllerProvider.notifier)
          .createItemGroup(subCategoryId: _subCategory!.id, name: name);
      if (!mounted) return result.itemGroup;
      if (result.itemGroup == null) {
        AppLogger.info(
          LogTag.ui,
          'Απόρριψη «+» τμήματος "$name": διπλότυπο',
        );
      }
      setState(() {
        _itemGroupError =
        result.itemGroup == null ? AppErrors.nameExists : null;
        if (result.itemGroup != null) _itemGroup = result.itemGroup;
      });
      return result.itemGroup;
    } on DataLoadException {
      AppLogger.error(LogTag.db, 'Αποτυχία «+» τμήματος "$name" (DB)');
      if (!mounted) return null;
      setState(() => _itemGroupError = AppErrors.loadDataFailed);
      return null;
    }
  }

  bool get _nameIsValid => NameValidator.validate(_nameController.text) == null;

  String? get _nameError {
    final error = NameValidator.validate(_nameController.text);
    return error == null || error == AppErrors.nameTooLong
        ? error
        : null; // κενό → χωρίς error πριν τη «Αποθήκευση» (disabled κουμπί)
  }

  /// Βήμα 4: αποθήκευση — αλυσιδωτό save, pop με το αποτέλεσμα. Μόνο το
  /// `NewItemDialogCreated` «επιστρέφει» Είδος· DB error → pop failed.
  Future<void> _save() async {
    if (_isSaving || !_nameIsValid) return;
    setState(() => _isSaving = true);
    try {
      final result = await ref
          .read(itemSearchControllerProvider.notifier)
          .createItem(itemGroupId: _itemGroup!.id, name: _nameController.text);
      if (!mounted) return;
      if (result.item == null) {
        setState(() => _isSaving = false);
        return;
      }
      Navigator.of(context).pop(
        NewItemDialogCreated(result.item!, created: result.created),
      );
    } on DataLoadException {
      if (!mounted) return;
      Navigator.of(context).pop(const NewItemDialogFailed());
    }
  }

  /// Δείχνει το Βήμα 1 (category) — πάντα ορατό στην εκκίνηση.
  Widget _buildCategoryStep() {
    return SearchableDropdownField<Category>(
      labelText: AppStrings.fieldCategory,
      hintText: AppStrings.fieldCategory,
      searchProvider: categorySearchProvider.call,
      labelOf: (category) => category.name,
      createLabel: (query) => '${AppStrings.addNewCategory} "$query"',
      onCreate: _createCategory,
      onChanged: (_) => setState(() => _categoryError = null),
      onSelected: (category) => setState(() {
        _category = category;
        _categoryError = null;
      }),
      prefixIcon: const Icon(Icons.category_outlined),
      resultLeadingIcon: const Icon(Icons.category_outlined),
    );
  }

  /// Δείχνει το Βήμα 2 (subcategory) — ΜΟΝΟ όταν υπάρχει κατηγορία.
  Widget _buildSubCategoryStep() {
    return SearchableDropdownField<SubCategory>(
      labelText: AppStrings.fieldSubCategory,
      hintText: AppStrings.fieldSubCategory,
      searchProvider: (query) => subCategorySearchProvider((
        categoryId: _category!.id,
        query: query,
      )),
      labelOf: (sub) => sub.name,
      createLabel: (query) => '${AppStrings.addNewSubCategory} "$query"',
      onCreate: _createSubCategory,
      onChanged: (_) => setState(() => _subCategoryError = null),
      onSelected: (sub) => setState(() {
        _subCategory = sub;
        _subCategoryError = null;
      }),
      prefixIcon: const Icon(Icons.folder_outlined),
      resultLeadingIcon: const Icon(Icons.folder_open_outlined),
    );
  }

  /// Δείχνει το Βήμα 3 (τμήμα) — ΜΟΝΟ όταν υπάρχει υποκατηγορία.
  Widget _buildItemGroupStep() {
    return SearchableDropdownField<ItemGroup>(
      labelText: AppStrings.fieldItemGroup,
      hintText: AppStrings.fieldItemGroup,
      searchProvider: (query) => itemGroupSearchProvider((
        subCategoryId: _subCategory!.id,
        query: query,
      )),
      labelOf: (group) => group.name,
      createLabel: (query) => '${AppStrings.addNewItemGroup} "$query"',
      onCreate: _createItemGroup,
      onChanged: (_) => setState(() => _itemGroupError = null),
      onSelected: (group) => setState(() {
        _itemGroup = group;
        _itemGroupError = null;
      }),
      prefixIcon: const Icon(Icons.folder_open_outlined),
      resultLeadingIcon: const Icon(Icons.folder_open_outlined),
    );
  }

  /// Βήμα 4 (όνομα + save) — ΜΟΝΟ όταν υπάρχει τμήμα.
  Widget _buildNameStep() {
    return TextField(
      controller: _nameController,
      autofocus: true,
      maxLength: AppConstants.maxItemNameLength,
      inputFormatters: [LengthLimitingTextInputFormatter(AppConstants.maxItemNameLength)],
      decoration: InputDecoration(
        labelText: AppStrings.fieldItemName,
        hintText: AppStrings.addNewItem,
        border: const OutlineInputBorder(),
        errorText: _nameError,
        isDense: true,
      ),
      onChanged: (_) => setState(() {}), // refresh disabled/error state
      onSubmitted: (_) => _save(),
    );
  }

  /// Inline μήνυμα σφάλματος κάτω από ένα βήμα (Βήμα 6ζ) — όχι snackbar
  /// (ScaffoldMessenger caveat). Wrap σε πολλές γραμμές (§1.4), χρώμα από το
  /// theme (dark mode), `liveRegion` για screen readers (§1.6).
  Widget _stepError(String message) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.spacingS),
      child: Semantics(
        liveRegion: true,
        child: Text(
          message,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppStrings.newItemDialogTitle),
      // Responsive §1.4: max-width + scroll — κανένα fixed ύψος.
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppConstants.dialogMaxWidth),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCategoryStep(),
              if (_categoryError case final message?) _stepError(message),
              if (_category != null) ...[
                const SizedBox(height: AppConstants.spacingL),
                _buildSubCategoryStep(),
                if (_subCategoryError case final message?) _stepError(message),
              ],
              if (_subCategory != null) ...[
                const SizedBox(height: AppConstants.spacingL),
                _buildItemGroupStep(),
                if (_itemGroupError case final message?) _stepError(message),
              ],
              if (_itemGroup != null) ...[
                const SizedBox(height: AppConstants.spacingL),
                _buildNameStep(),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () => Navigator.of(context).pop(const NewItemDialogCancelled()),
          child: const Text(AppMessages.confirmDialogCancel),
        ),
        FilledButton(
          onPressed:
              (_isSaving || _itemGroup == null || !_nameIsValid ? null : _save),
          child: _isSaving
              ? SizedBox(
                  width: AppConstants.dialogSpinnerSize,
                  height: AppConstants.dialogSpinnerSize,
                  child: const CircularProgressIndicator(
                    strokeWidth: AppConstants.spinnerStrokeWidth,
                  ),
                )
              : const Text(AppStrings.newItemSave),
        ),
      ],
    );
  }
}