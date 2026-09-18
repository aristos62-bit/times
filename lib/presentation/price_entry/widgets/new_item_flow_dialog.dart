/// Popup «Νέο είδος» (3-βημάτων, γραμμικό) — §2.4 DESIGN / Φάση 3 Βήμα 4.
///
/// ΡΟΗ: Κατηγορία → Υποκατηγορία → Όνομα. ΑΥΣΤΗΡΑ ΓΡΑΜΜΙΚΟ (§2.4): το
/// επόμενο βήμα εμφανίζεται ΜΟΝΟ αφού επιλεγεί/δημιουργηθεί το προηγούμενο —
/// κανένα «πίσω» κουμπί (self-reinforcing linear flow, απόφαση Βήμα 4).
///
/// ΑΡΧΙΤΕΚΤΟΝΙΚΗ:
///   * Βήματα 1-2 χρησιμοποιούν το generic `SearchableDropdownField<T>`
///     (§2.4) με τις νέες icon παραμέτρους (prefixIcon/resultLeadingIcon,
///     Βήμα 4) + τα search families `categorySearchProvider` /
///     `subCategorySearchProvider` (stream_providers · Βήμα 4).
///   * Όλες οι δημιουργίες (κατηγορία/υποκατηγορία) γίνονται σιωπηλά
///     (silent intermediate creates — §2.4 απόφαση): ΚΑΝΕΝΑ snackbar μέσα
///     στο dialog. Μόνο το τελικό Είδος «γυρίζει» πίσω με το result.
///   * Το feedback (SnackBar) γίνεται πάντα ΜΕΤΑ το pop από τον καλούντα
///     (ScaffoldMessenger caveat — αλλιώς το snackbar «κρύβεται» πίσω από
///     το dialog overlay). Το AppFeedback καλείται ΜΟΝΟ εκεί.
///   * `isSaving` = double-tap guard (§2.4): όσο τρέχει το save, το «Προσθήκη»
///     απενεργοποιείται. Σφάλμα DB (DataLoadException) → pop `failed` —
///     χωρίς αλλαγή state· ο καλών εμφανίζει AppErrors.loadDataFailed.
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

/// Popup δημιουργίας είδους — γραμμικός 3-βημάτος wizard (§2.4).
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

  /// Controller του πεδίου ονόματος (Βήμα 3) — prefill από [initialName].
  late final TextEditingController _nameController;

  /// Double-tap guard του «Προσθήκη» (§2.4).
  bool _isSaving = false;

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
  Future<Category?> _createCategory(String name) async {
    final result =
        await ref.read(itemSearchControllerProvider.notifier).createCategory(name);
    if (result.category != null && mounted) {
      setState(() => _category = result.category);
    }
    return result.category;
  }

  /// Βήμα 2: δημιουργία υποκατηγορίας από το «+» — ΣΙΩΠΗΛΗ.
  Future<SubCategory?> _createSubCategory(String name) async {
    final result = await ref
        .read(itemSearchControllerProvider.notifier)
        .createSubCategory(categoryId: _category!.id, name: name);
    if (result.subCategory != null && mounted) {
      setState(() => _subCategory = result.subCategory);
    }
    return result.subCategory;
  }

  bool get _nameIsValid => NameValidator.validate(_nameController.text) == null;

  String? get _nameError {
    final error = NameValidator.validate(_nameController.text);
    return error == null || error == AppErrors.nameTooLong
        ? error
        : null; // κενό → χωρίς error πριν τη «Αποθήκευση» (disabled κουμπί)
  }

  /// Βήμα 3: αποθήκευση — αλυσιδωτό save, pop με το αποτέλεσμα. Μόνο το
  /// `NewItemDialogCreated` «επιστρέφει» Είδος· DB error → pop failed.
  Future<void> _save() async {
    if (_isSaving || !_nameIsValid) return;
    setState(() => _isSaving = true);
    try {
      final result = await ref
          .read(itemSearchControllerProvider.notifier)
          .createItem(subCategoryId: _subCategory!.id, name: _nameController.text);
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
      onSelected: (category) => setState(() => _category = category),
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
      onSelected: (sub) => setState(() => _subCategory = sub),
      prefixIcon: const Icon(Icons.folder_outlined),
      resultLeadingIcon: const Icon(Icons.folder_open_outlined),
    );
  }

  /// Βήμα 3 (όνομα + save) — ΜΟΝΟ όταν υπάρχει υποκατηγορία.
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppStrings.newItemDialogTitle),
      // Responsive §1.4: max-width + scroll — κανένα fixed ύψος.
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCategoryStep(),
              if (_category != null) ...[
                const SizedBox(height: AppConstants.spacingL),
                _buildSubCategoryStep(),
              ],
              if (_subCategory != null) ...[
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
              (_isSaving || _subCategory == null || !_nameIsValid ? null : _save),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(AppStrings.newItemSave),
        ),
      ],
    );
  }
}