/// Dumb φίλτρο καταλόγου 3 επιπέδων (§2.3 · 29-09-2026 — στατιστικές).
///
/// Κατηγορία → Υποκατηγορία → Τμήμα με `SearchableDropdownField` (show-all +
/// `onCleared`, pattern dialog «+»/item_edit — in-memory φιλτράρισμα, 0 νέα
/// queries §3). Κενό πεδίο = Όλα (hints, Q1)· αλλαγή γονέα μηδενίζει τα
/// παιδιά (keyed rebuilds + `initialValue`, pattern item_edit — ποτέ
/// ασυνεπής συνδυασμός, Q2)· χωρίς γονέα το παιδί είναι disabled με hint
/// (σταθερό layout, Q5 — όχι εξαφάνιση). Καμία provider-ανάγνωση πέραν των
/// dropdowns (§2.0 — η επιλογή ανεβαίνει με `onChanged`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../data/local/app_database.dart';
import '../../../data/providers/stream_providers.dart';
import '../../shared/searchable_dropdown_field.dart';

/// Επιλογή φίλτρου (null = Όλα στο επίπεδο).
typedef CatalogFilterSelection = ({
  int? categoryId,
  int? subCategoryId,
  int? itemGroupId,
});

/// Φίλτρο καταλόγου για στατιστικές (§2.3).
class CatalogFilterField extends ConsumerStatefulWidget {
  const CatalogFilterField({super.key, required this.onChanged});

  /// Καλείται σε ΚΑΘΕ έγκυρη αλλαγή (επιλογή/καθάρισμα/reset γονέα).
  final ValueChanged<CatalogFilterSelection> onChanged;

  @override
  ConsumerState<CatalogFilterField> createState() => _CatalogFilterFieldState();
}

class _CatalogFilterFieldState extends ConsumerState<CatalogFilterField> {
  int? _categoryId;
  int? _subCategoryId;
  int? _itemGroupId;

  /// Γενιές πεδίων — φρέσκο άδειο dropdown σε reset (pattern header §2.2).
  int _epoch = 0;

  void _emit() => widget.onChanged(
        (
          categoryId: _categoryId,
          subCategoryId: _subCategoryId,
          itemGroupId: _itemGroupId,
        ),
      );

  /// Καθαρισμός όλων (κουμπί «Όλες» — reuse `clearReceiptFilter`).
  void _clearAll() {
    setState(() {
      _categoryId = null;
      _subCategoryId = null;
      _itemGroupId = null;
      _epoch++;
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final categoryId = _categoryId;
    final subCategoryId = _subCategoryId;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchableDropdownField<Category>(
          key: ValueKey('cat_$_epoch'),
          labelText: AppStrings.fieldCategory,
          hintText: AppStrings.statsFilterAllCategories,
          searchProvider: categorySearchProvider.call,
          labelOf: (c) => c.name,
          prefixIcon: const Icon(Icons.category_outlined),
          resultLeadingIcon: const Icon(Icons.category_outlined),
          showAllWhenEmpty: true,
          allOptionsProvider: () => categoryStreamProvider,
          onSelected: (c) {
            setState(() {
              _categoryId = c.id;
              _subCategoryId = null;
              _itemGroupId = null;
              _epoch++;
            });
            _emit();
          },
          onCleared: () {
            setState(() {
              _categoryId = null;
              _subCategoryId = null;
              _itemGroupId = null;
              _epoch++;
            });
            _emit();
          },
        ),
        const SizedBox(height: 8),
        if (categoryId == null)
          const TextField(
            enabled: false,
            decoration: InputDecoration(
              labelText: AppStrings.fieldSubCategory,
              hintText: AppStrings.statsFilterAllSubCategories,
              prefixIcon: Icon(Icons.folder_outlined),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          )
        else
          SearchableDropdownField<SubCategory>(
            key: ValueKey('sub_${categoryId}_$_epoch'),
            labelText: AppStrings.fieldSubCategory,
            hintText: AppStrings.statsFilterAllSubCategories,
            searchProvider: (query) => subCategorySearchProvider(
              (categoryId: categoryId, query: query),
            ),
            labelOf: (s) => s.name,
            prefixIcon: const Icon(Icons.folder_outlined),
            resultLeadingIcon: const Icon(Icons.folder_outlined),
            showAllWhenEmpty: true,
            allOptionsProvider: () =>
                subCategoriesByCategoryProvider(categoryId),
            onSelected: (s) {
              setState(() {
                _subCategoryId = s.id;
                _itemGroupId = null;
                _epoch++;
              });
              _emit();
            },
            onCleared: () {
              setState(() {
                _subCategoryId = null;
                _itemGroupId = null;
                _epoch++;
              });
              _emit();
            },
          ),
        const SizedBox(height: 8),
        if (subCategoryId == null)
          const TextField(
            enabled: false,
            decoration: InputDecoration(
              labelText: AppStrings.fieldItemGroup,
              hintText: AppStrings.statsFilterAllItemGroups,
              prefixIcon: Icon(Icons.folder_open_outlined),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          )
        else
          SearchableDropdownField<ItemGroup>(
            key: ValueKey('group_${subCategoryId}_$_epoch'),
            labelText: AppStrings.fieldItemGroup,
            hintText: AppStrings.statsFilterAllItemGroups,
            searchProvider: (query) => itemGroupSearchProvider(
              (subCategoryId: subCategoryId, query: query),
            ),
            labelOf: (g) => g.name,
            prefixIcon: const Icon(Icons.folder_open_outlined),
            resultLeadingIcon: const Icon(Icons.folder_open_outlined),
            showAllWhenEmpty: true,
            allOptionsProvider: () =>
                itemGroupsBySubCategoryProvider(subCategoryId),
            onSelected: (g) {
              setState(() => _itemGroupId = g.id);
              _emit();
            },
            onCleared: () {
              setState(() => _itemGroupId = null);
              _emit();
            },
          ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _clearAll,
            child: const Text(AppStrings.clearReceiptFilter),
          ),
        ),
      ],
    );
  }
}
