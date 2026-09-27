/// Dialog επεξεργασίας είδους (§2.3 DESIGN · 4 επίπεδα 27-09-2026).
///
/// Όνομα + τμήμα (μετακίνηση σε Κατηγορία/Υποκατηγορία/Τμήμα) +
/// προτεινόμενη μονάδα — επιστρέφει record ή `null` (Ακύρωση/dismiss).
/// Κατηγορία/υποκατηγορία/τμήμα/μονάδα δίνονται ΕΤΟΙΜΑ από τον καλούντα
/// (lookups πριν το open — το dialog μένει σύγχρονο, χωρίς async prefill
/// που θα κόλλαγε σε widget-test fake-async με infinite spinner).
/// Dropdowns = ατόφιο `SearchableDropdownField` (§2.4): κατηγορία (show-all) ·
/// υποκατηγορία (keyed ανά κατηγορία) · τμήμα (keyed ανά υποκατηγορία) ·
/// μονάδα (show-all, `onCleared`). Όνομα με inline `NameValidator`:
/// άκυρο → χωρίς pop. Dup-check ΜΕΤΑ το pop από τον controller με snackbar.
library;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_messages.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/local/app_database.dart';
import '../../../data/providers/stream_providers.dart';
import '../../../domain/validators/name_validator.dart';
import '../../shared/searchable_dropdown_field.dart';

/// Ανοίγει το dialog επεξεργασίας είδους.
///
/// Επιστρέφει `(name, itemGroupId, defaultUnitId)` ή `null` — ο καλών
/// μετράει μόνο το non-null (pattern `showConfirmDialog`). Το
/// [defaultUnitId] είναι `Value`: absent = αμετάβλητο, `Value(null)` =
/// καθάρισμα (pattern `ItemDao.updateById`).
Future<({String name, int itemGroupId, Value<int?> defaultUnitId})?>
    showItemEditDialog(
  BuildContext context, {
  required Item item,
  required ItemGroup itemGroup,
  required SubCategory subCategory,
  required Category category,
  required Unit? unit,
}) {
  return showDialog<({String name, int itemGroupId, Value<int?> defaultUnitId})>(
    context: context,
    builder: (_) => ItemEditDialog(
      item: item,
      itemGroup: itemGroup,
      subCategory: subCategory,
      category: category,
      unit: unit,
    ),
  );
}

/// Dialog επεξεργασίας είδους — «χαζό» (§2.0): διαβάζει providers ΜΟΝΟ για
/// επιλογές dropdowns, καμία business logic (validation ονόματος inline).
class ItemEditDialog extends ConsumerStatefulWidget {
  const ItemEditDialog({
    super.key,
    required this.item,
    required this.itemGroup,
    required this.subCategory,
    required this.category,
    required this.unit,
  });

  /// Το επεξεργαζόμενο είδος (prefill ονόματος).
  final Item item;

  /// Τρέχον τμήμα (prefill dropdown).
  final ItemGroup itemGroup;

  /// Τρέχουσα υποκατηγορία (prefill dropdown).
  final SubCategory subCategory;

  /// Τρέχουσα κατηγορία (prefill dropdown).
  final Category category;

  /// Τρέχουσα προτεινόμενη μονάδα (null = καμία).
  final Unit? unit;

  @override
  ConsumerState<ItemEditDialog> createState() => _ItemEditDialogState();
}

class _ItemEditDialogState extends ConsumerState<ItemEditDialog> {
  late final TextEditingController _nameController;
  String? _nameError;

  /// Επιλεγμένη κατηγορία/υποκατηγορία/τμήμα/μονάδα (prefill).
  late Category? _category;
  late SubCategory? _subCategory;
  late ItemGroup? _itemGroup;
  late Unit? _unit;

  /// Ο χρήστης άγγιξε τη μονάδα (επιλογή/καθάρισμα) — αλλιώς no-op.
  bool _unitTouched = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _category = widget.category;
    _subCategory = widget.subCategory;
    _itemGroup = widget.itemGroup;
    _unit = widget.unit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Submit: άκυρο όνομα ή ελλιπής επιλογή → inline σφάλμα (χωρίς pop)·
  /// αλλιώς pop record.
  void _submit() {
    final error = NameValidator.validate(_nameController.text);
    if (error != null) {
      setState(() => _nameError = error);
      return;
    }
    if (_itemGroup == null) return;
    Value<int?> unitValue = const Value.absent();
    if (_unitTouched) {
      unitValue = _unit == null ? const Value(null) : Value(_unit!.id);
    }
    Navigator.of(context).pop((
      name: _nameController.text.trim(),
      itemGroupId: _itemGroup!.id,
      defaultUnitId: unitValue,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.fieldItemName),
      // Responsive (§1.4): max-width + scroll — κανένα fixed ύψος.
      content: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: AppConstants.dialogMaxWidth),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                    TextField(
                      controller: _nameController,
                      autofocus: true,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                          AppConstants.maxItemNameLength,
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText: AppStrings.fieldItemName,
                        border: const OutlineInputBorder(),
                        errorText: _nameError,
                        errorMaxLines: AppConstants.fieldErrorMaxLines,
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.next,
                      onChanged: (_) {
                        if (_nameError != null) {
                          setState(() => _nameError = null);
                        }
                      },
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: AppConstants.spacingM),
                    // Κατηγορία (show-all, αρχική = τρέχουσα).
                    SearchableDropdownField<Category>(
                      labelText: AppStrings.fieldCategory,
                      hintText: AppStrings.fieldCategory,
                      searchProvider: categorySearchProvider.call,
                      labelOf: (category) => category.name,
                      prefixIcon: const Icon(Icons.category_outlined),
                      resultLeadingIcon:
                          const Icon(Icons.category_outlined),
                      showAllWhenEmpty: true,
                      allOptionsProvider: () => categoryStreamProvider,
                      initialValue: _category,
                      onSelected: (category) => setState(() {
                        _category = category;
                        _subCategory = null;
                        _itemGroup = null;
                      }),
                    ),
                    const SizedBox(height: AppConstants.spacingM),
                    // Υποκατηγορία (keyed ανά κατηγορία — φρέσκο state).
                    if (_category != null)
                      SearchableDropdownField<SubCategory>(
                        key: ValueKey('sub_${_category!.id}'),
                        labelText: AppStrings.fieldSubCategory,
                        hintText: AppStrings.fieldSubCategory,
                        searchProvider: (query) => subCategorySearchProvider(
                          (categoryId: _category!.id, query: query),
                        ),
                        labelOf: (sub) => sub.name,
                        prefixIcon: const Icon(Icons.folder_outlined),
                        resultLeadingIcon:
                            const Icon(Icons.folder_outlined),
                        showAllWhenEmpty: true,
                        allOptionsProvider: () =>
                            subCategoriesByCategoryProvider(_category!.id),
                        initialValue: _subCategory,
                        onSelected: (sub) => setState(() {
                          _subCategory = sub;
                          _itemGroup = null;
                        }),
                      ),
                    const SizedBox(height: AppConstants.spacingM),
                    // Τμήμα (keyed ανά υποκατηγορία — 27-09-2026).
                    if (_subCategory != null)
                      SearchableDropdownField<ItemGroup>(
                        key: ValueKey('group_${_subCategory!.id}'),
                        labelText: AppStrings.fieldItemGroup,
                        hintText: AppStrings.fieldItemGroup,
                        searchProvider: (query) => itemGroupSearchProvider(
                          (subCategoryId: _subCategory!.id, query: query),
                        ),
                        labelOf: (group) => group.name,
                        prefixIcon:
                            const Icon(Icons.folder_open_outlined),
                        resultLeadingIcon:
                            const Icon(Icons.folder_open_outlined),
                        showAllWhenEmpty: true,
                        allOptionsProvider: () =>
                            itemGroupsBySubCategoryProvider(_subCategory!.id),
                        initialValue: _itemGroup,
                        onSelected: (group) =>
                            setState(() => _itemGroup = group),
                      ),
                    const SizedBox(height: AppConstants.spacingM),
                    // Προτεινόμενη μονάδα (show-all, κενή = καμία).
                    SearchableDropdownField<Unit>(
                      labelText: AppStrings.fieldUnit,
                      hintText: AppStrings.unitSearchHint,
                      searchProvider: unitSearchProvider.call,
                      labelOf: (unit) => unit.name,
                      showAllWhenEmpty: true,
                      allOptionsProvider: () => unitsStreamProvider,
                      initialValue: _unit,
                      onSelected: (unit) => setState(() {
                        _unit = unit;
                        _unitTouched = true;
                      }),
                      onCleared: () => setState(() {
                        _unit = null;
                        _unitTouched = true;
                      }),
                    ),
                  ],
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppMessages.confirmDialogCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text(AppStrings.saveAction),
        ),
      ],
    );
  }
}
