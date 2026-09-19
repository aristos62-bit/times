/// Ενότητα μονάδας/ποσότητας/τιμής για το επιλεγμένο είδος (§2.2 DESIGN /
/// Φάση 3 Βήμα 5γ).
///
/// Εμφανίζεται ΜΟΝΟ όταν υπάρχει επιλεγμένο είδος (`selectedItem != null`) —
/// η σελίδα την τοποθετεί με `key: ValueKey(item.id)` ώστε κάθε είδος να έχει
/// ΦΡΕΣΚΙΑ κατάσταση (controllers/μονάδα από την αρχή — απόφαση Δ8).
///
/// ΡΟΗ (§2.2 state machine):
///   * Unit dropdown (`SearchableDropdownField`, show-all-on-focus Δ1) με
///     προεπιλογή `Item.defaultUnitId` αν υπάρχει (§2.2:236 — πρόταση, όχι
///     δέσμευση· αλλαγή ΔΕΝ γράφει πίσω στο Item).
///   * Ποσότητα (`QuantityTextField`, `allowsDecimal` από `Unit.allowsDecimal`,
///     suffix = συντομογραφία μονάδας) — prefill `defaultReceiptQuantity`
///     στην πρώτη επιλογή μονάδας (Δ8).
///   * Τιμή (`CurrencyTextField`, suffix = `currencySymbol`) — SPoT
///     parse/format, ΚΑΝΕΝΑ double ενδιάμεσο (απόφαση Βήμα 5).
///   * «Προσθήκη γραμμής» (ανενεργό ΟΤΑΝ unit null Ή ποσότητα/τιμή άκυρη —
///     OR) → `addDraftLine` + `clearSelection` (το search field καθαρίζει και
///     επιστρέφει σε IDLE, §2.2:206 — έτοιμο για επόμενο είδος).
///
/// Δεκαδική ποσότητα + integer-only μονάδα (§2.2:218): η αλλαγή μονάδας
/// περικόπτει ΑΥΤΟΜΑΤΑ στο ακέραιο μέρος + inline ειδοποίηση
/// (`quantityTruncatedForUnit`) — απόρριψη «2.5 τεμάχια» (απόφαση Δ).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/local/app_database.dart';
import '../../../data/providers/stream_providers.dart';
import '../../shared/currency_text_field.dart';
import '../../shared/quantity_text_field.dart';
import '../../shared/searchable_dropdown_field.dart';
import '../controllers/item_search_controller.dart';
import '../controllers/receipt_form_controller.dart';
import '../state/receipt_form_state.dart';

/// Φόρμα γραμμής για το [item]: μονάδα + ποσότητα + τιμή + «Προσθήκη».
class UnitQuantityPriceSection extends ConsumerStatefulWidget {
  const UnitQuantityPriceSection({super.key, required this.item});

  /// Το επιλεγμένο είδος (ITEM_SELECTED §2.4) — η σελίδα περνά
  /// `key: ValueKey(item.id)` για φρέσκια κατάσταση ανά είδος (Δ8).
  final Item item;

  @override
  ConsumerState<UnitQuantityPriceSection> createState() =>
      _UnitQuantityPriceSectionState();
}

class _UnitQuantityPriceSectionState
    extends ConsumerState<UnitQuantityPriceSection> {
  /// Επιλεγμένη μονάδα — `null` = καμία (κουμπί ανενεργό).
  Unit? _unit;

  /// Έγινε η (μία) απόπειρα προεπιλογής default — δεν ξανατρέχει.
  bool _defaultResolved = false;

  /// Inline ειδοποίηση περικοπής (§2.2:218) — `null` = καμία.
  String? _quantityNotice;

  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// Προεπιλογή `Item.defaultUnitId` (§2.2:236) + prefill ποσότητας (Δ8).
  /// Τρέχει ΜΙΑ φορά, με την πρώτη άφιξη της λίστας units.
  void _applyDefaultUnit(List<Unit> units) {
    final defaultId = widget.item.defaultUnitId;
    if (defaultId == null) return;
    Unit? match;
    for (final unit in units) {
      if (unit.id == defaultId) {
        match = unit;
        break;
      }
    }
    if (match == null) return; // σβησμένη μονάδα → SET NULL (§3), χωρίς πρόταση
    setState(() {
      _unit = match;
      if (_quantityController.text.isEmpty) {
        _quantityController.text = QuantityTextField.formatQuantity(
          AppConstants.defaultReceiptQuantity,
        );
      }
    });
  }

  /// Επιλογή μονάδας από το dropdown (προεπιλογή ή χειροκίνητη).
  void _onUnitSelected(Unit unit) {
    setState(() {
      _unit = unit;
      // Prefill ποσότητας στην πρώτη επιλογή, ΜΟΝΟ σε άδειο πεδίο (Δ8) —
      // ό,τι έγραψε ο χρήστης ΔΕΝ σβήνεται ποτέ.
      if (_quantityController.text.isEmpty) {
        _quantityController.text = QuantityTextField.formatQuantity(
          AppConstants.defaultReceiptQuantity,
        );
        _quantityNotice = null;
        return;
      }
      // Integer-only μονάδα + δεκαδικό κείμενο → αυτόματη περικοπή +
      // ειδοποίηση (§2.2:218, απόφαση Δ). Το αντίστροφο (επιστροφή σε
      // δεκαδική μονάδα) καθαρίζει την ειδοποίηση.
      if (!unit.allowsDecimal) {
        final current = QuantityTextField.parseQuantity(
          _quantityController.text,
          allowsDecimal: true,
        );
        if (current != null && current != current.truncateToDouble()) {
          _quantityController.text = QuantityTextField.formatQuantity(
            current.truncateToDouble(),
          );
          _quantityNotice = AppStrings.quantityTruncatedForUnit;
          return;
        }
      }
      _quantityNotice = null;
    });
  }

  /// Έγκυρη ποσότητα (> 0, εντός ορίων — αποκλειστικά όρια §2.2:217).
  double? get _quantity {
    final unit = _unit;
    if (unit == null) return null;
    final value = QuantityTextField.parseQuantity(
      _quantityController.text,
      allowsDecimal: unit.allowsDecimal,
    );
    if (value == null || value <= AppConstants.validationMinQuantity) {
      return null;
    }
    return value;
  }

  /// Έγκυρη τιμή σε cents (> 0 — αποκλειστικό όριο §2.2:217).
  int? get _priceCents {
    final cents = CurrencyTextField.parseCents(_priceController.text);
    if (cents == null || cents <= AppConstants.validationMinPrice) return null;
    return cents;
  }

  /// Κουμπί ενεργό ΜΟΝΟ με μονάδα + έγκυρη ποσότητα + έγκυρη τιμή (OR).
  bool get _canAdd => _unit != null && _quantity != null && _priceCents != null;

  /// «Προσθήκη γραμμής» → draft + επιστροφή search σε IDLE (§2.2:206).
  void _addLine() {
    final unit = _unit;
    final quantity = _quantity;
    final priceCents = _priceCents;
    if (unit == null || quantity == null || priceCents == null) return;
    ref.read(receiptFormControllerProvider.notifier).addDraftLine(
          DraftReceiptLine(
            itemId: widget.item.id,
            unitId: unit.id,
            quantity: quantity,
            priceCents: priceCents,
            itemName: widget.item.name,
            unitAbbreviation: unit.abbreviation,
          ),
        );
    // Το search field καθαρίζει (clear-on-drop fix) και επιστρέφει σε IDLE —
    // έτοιμο για το επόμενο είδος. Η ενότητα αποσυναρμολογείται (selected null)
    // οπότε η κατάστασή της μηδενίζεται αυτόματα.
    ref.read(itemSearchControllerProvider.notifier).clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    // ΜΟΝΗ ανάγνωση λίστας units: για την προεπιλογή default (user action =
    // η επιλογή είδους, §2.0.1). Το ίδιο το dropdown κάνει δικό του gated
    // watch (πληκτρολόγηση/focus) — όχι διπλό άνοιγμα βάσης στο launch.
    final units = ref.watch(unitsStreamProvider).value;
    if (units != null && !_defaultResolved) {
      _defaultResolved = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _applyDefaultUnit(units);
      });
    }

    final allowsDecimal = _unit?.allowsDecimal ?? true;
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SearchableDropdownField<Unit>(
              labelText: AppStrings.fieldUnit,
              hintText: AppStrings.unitSearchHint,
              searchProvider: unitSearchProvider.call,
              labelOf: (unit) => unit.name,
              // Χωρίς «+»: οι μονάδες διαχειρίζονται από τις Ρυθμίσεις (Φάση 4/6).
              onSelected: _onUnitSelected,
              showAllWhenEmpty: true,
              allOptionsProvider: () => unitsStreamProvider,
              initialValue: _unit,
              prefixIcon: const Icon(Icons.straighten_outlined),
              resultLeadingIcon: const Icon(Icons.straighten_outlined),
            ),
            const SizedBox(height: AppConstants.spacingM),
            QuantityTextField(
              controller: _quantityController,
              labelText: AppStrings.fieldQuantity,
              suffixText: _unit?.abbreviation,
              allowsDecimal: allowsDecimal,
              onChanged: (_) => setState(() {}),
              prefixIcon: const Icon(Icons.scale_outlined),
            ),
            if (_quantityNotice != null)
              Padding(
                padding: const EdgeInsets.only(top: AppConstants.spacingS),
                child: Text(
                  _quantityNotice!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: AppConstants.spacingM),
            CurrencyTextField(
              controller: _priceController,
              labelText: AppStrings.fieldPrice,
              suffixText: AppStrings.currencySymbol,
              onChanged: (_) => setState(() {}),
              prefixIcon: const Icon(Icons.euro_outlined),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppConstants.spacingM),
            FilledButton.icon(
              onPressed: _canAdd ? _addLine : null,
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.addReceiptLine),
            ),
          ],
        ),
      ),
    );
  }
}
