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
///
/// VALIDATION (Βήμα 6δ): όλοι οι κανόνες (τιμή/ποσότητα/μονάδα) προέρχονται
/// από τον SPoT `ReceiptValidator` — το section δεν έχει δικά του όρια.
/// Inline σφάλμα (`errorText` των fields) ΜΟΝΟ σε μη-κενή, ολοκληρωμένη
/// είσοδο: το κενό πεδίο και ο αριθμός «υπό πληκτρολόγηση» («5,») δεν
/// δείχνουν σφάλμα (το Add μένει απλώς ανενεργό). Hint μονάδας όταν έχει
/// ήδη γραφτεί τιμή χωρίς μονάδα — κρύβεται μόλις αρχίσει πληκτρολόγηση στο
/// unit dropdown (onChanged · Βήμα 21).
///
/// ΣΥΝΟΛΙΚΗ ΤΙΜΗ (24-09-2026): διακόπτης `_isTotal` — ΟΝ = το πεδίο Τιμή
/// είναι το σύνολο της ποσότητας (π.χ. 0,350 κιλ = 12 €) και η μοναδιαία
/// παράγεται `(total/quantity).round()` με guard 0/overflow (ίδια errors)·
/// OFF (default) = τιμή μονάδας. Ισχύει για όλες τις μονάδες· lifecycle από
/// το `ValueKey(item.id)` (φρέσκο ανά είδος, Δ8).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_errors.dart';
import '../../../core/constants/app_messages.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/local/app_database.dart';
import '../../../data/providers/stream_providers.dart';
import '../../../domain/validators/receipt_validator.dart';
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

  /// Κρύβει το hint `unitRequired` μόλις ο χρήστης πληκτρολογήσει στο unit
  /// dropdown (Βήμα 21) — η σύσταση εξυπηρετήθηκε. Δεν ξανασβήνει: φρέσκια
  /// κατάσταση ανά είδος μέσω `ValueKey(item.id)` (Δ8).
  bool _unitTyping = false;

  /// Λειτουργία συνολικής τιμής (24-09-2026): false (default) = το πεδίο
  /// Τιμή είναι μοναδιαία· true = το πεδίο Τιμή είναι το σύνολο της
  /// ποσότητας και η μοναδιαία παράγεται `(total/quantity).round()`.
  /// Τοπικό state, φρέσκο ανά είδος μέσω `ValueKey(item.id)` (Δ8) —
  /// κανένας νέος provider/controller.
  bool _isTotal = false;

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

  /// Ποσότητα του πεδίου (Βήμα 6δ): `value` = η τιμή ΜΟΝΟ όταν είναι έγκυρη
  /// (`ReceiptValidator.validateQuantity`, §2.2:217-218), `error` = inline
  /// μήνυμα (AppErrors) ή `null`. Κενό πεδίο και αριθμός «υπό πληκτρολόγηση»
  /// («2,») δεν δείχνουν σφάλμα. Το parse γίνεται πάντα με δεκαδικά — ο
  /// κανόνας ακεραιότητας ανήκει στον validator. `null` από το parse σε
  /// μη-κενό, ολοκληρωμένο κείμενο σημαίνει πάνω από το όριο.
  ({double? value, String? error}) _quantityCheck() {
    final text = _quantityController.text;
    if (text.trim().isEmpty) return (value: null, error: null);
    final parsed = QuantityTextField.parseQuantity(text, allowsDecimal: true);
    if (parsed == null) {
      return (
      value: null,
      error: ReceiptValidator.isIncompleteNumber(text)
          ? null
          : AppErrors.quantityTooLarge,
      );
    }
    final error = ReceiptValidator.validateQuantity(
      parsed,
      allowsDecimal: _unit?.allowsDecimal ?? true,
    );
    return (value: error == null ? parsed : null, error: error);
  }

  /// Τιμή του πεδίου σε cents (Βήμα 6δ) — ίδιο contract με το
  /// `_quantityCheck` (`ReceiptValidator.validatePriceCents`, §2.2:217).
  ({int? value, String? error}) _priceCheck() {
    final text = _priceController.text;
    if (text.trim().isEmpty) return (value: null, error: null);
    final cents = CurrencyTextField.parseCents(text);
    if (cents == null) {
      return (
      value: null,
      error: ReceiptValidator.isIncompleteNumber(text)
          ? null
          : AppErrors.priceTooLarge,
      );
    }
    final error = ReceiptValidator.validatePriceCents(cents);
    return (value: error == null ? cents : null, error: error);
  }

  /// «Προσθήκη γραμμής» → draft + επιστροφή search σε IDLE (§2.2:206).
  /// Συνολική τιμή (24-09-2026): με `_isTotal` η μοναδιαία παράγεται
  /// `(total/quantity).round()` με guard 0/overflow (ίδια errors — safety-net,
  /// το UI το έχει ήδη αποκλείσει στο `canAdd`)· το πληκτρολογημένο σύνολο
  /// φυλάσσεται ως `enteredTotalCents` snapshot για προβολή (χωρίς
  /// επαν-υπολογισμό στο draft list).
  void _addLine() {
    final unit = _unit;
    final quantity = _quantityCheck().value;
    final entered = _priceCheck().value;
    if (unit == null || quantity == null || entered == null) return;
    final int unitPriceCents;
    final int? enteredTotal;
    if (!_isTotal) {
      unitPriceCents = entered;
      enteredTotal = null;
    } else {
      final derived = (entered / quantity).round();
      if (ReceiptValidator.validatePriceCents(derived) != null) return;
      unitPriceCents = derived;
      enteredTotal = entered;
    }
    ref.read(receiptFormControllerProvider.notifier).addDraftLine(
      DraftReceiptLine(
        itemId: widget.item.id,
        unitId: unit.id,
        quantity: quantity,
        priceCents: unitPriceCents,
        itemName: widget.item.name,
        unitAbbreviation: unit.abbreviation,
        unitAllowsDecimal: unit.allowsDecimal,
        enteredTotalCents: enteredTotal,
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
    // Β5ε-2: το καλάθι έφτασε το όριο; `select` → rebuild μόνο στη μετάβαση.
    final atLimit = ref.watch(
      receiptFormControllerProvider.select(
            (s) => s.draftLines.length >= AppConstants.maxReceiptLines,
      ),
    );
    // Βήμα 6δ: validation μέσω ReceiptValidator (SPoT) — value + inline error.
    // Συνολική τιμή (24-09-2026): με `_isTotal` η μοναδιαία παράγεται
    // `(total/quantity).round()` — τα ίδια `_quantityCheck`/`_priceCheck`
    // (parse+validator) + guard παραγόμενης (0/overflow, ίδια errors).
    // Διαίρεση ΜΟΝΟ με έγκυρη qty>0 (gated — ποτέ διαίρεση με μηδέν).
    final quantity = _quantityCheck();
    final entered = _priceCheck();
    int? unitPriceCents;
    String? priceError;
    if (!_isTotal) {
      unitPriceCents = entered.value;
      priceError = entered.error;
    } else {
      final q = quantity.value;
      final t = entered.value;
      if (q == null || t == null) {
        unitPriceCents = null;
        priceError = entered.error;
      } else {
        final derived = (t / q).round();
        final derivedError = ReceiptValidator.validatePriceCents(derived);
        if (derivedError != null) {
          unitPriceCents = null;
          priceError = derivedError;
        } else {
          unitPriceCents = derived;
          priceError = null;
        }
      }
    }
    final canAdd =
        _unit != null && quantity.value != null && unitPriceCents != null;
    // Hint μονάδας: μόνο όταν ο χρήστης έχει ήδη αρχίσει να γράφει τιμή ΚΑΙ
    // δεν έχει αρχίσει να πληκτρολογεί στο unit dropdown (Βήμα 21).
    final unitHint = !_unitTyping && _priceController.text.isNotEmpty
        ? ReceiptValidator.validateUnit(_unit != null)
        : null;

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
              // Β5ε-1: σβήσιμο/αλλαγή κειμένου → μονάδα null (Add ανενεργό).
              onCleared: () => setState(() => _unit = null),
              // Βήμα 21: πληκτρολόγηση → κρύβεται το hint unitRequired.
              onChanged: (_) => setState(() => _unitTyping = true),
              showAllWhenEmpty: true,
              allOptionsProvider: () => unitsStreamProvider,
              initialValue: _unit,
              prefixIcon: const Icon(Icons.straighten_outlined),
              resultLeadingIcon: const Icon(Icons.straighten_outlined),
            ),
            if (unitHint != null)
              Padding(
                padding: const EdgeInsets.only(top: AppConstants.spacingS),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    unitHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppConstants.spacingM),
            QuantityTextField(
              controller: _quantityController,
              labelText: AppStrings.fieldQuantity,
              suffixText: _unit?.abbreviation,
              allowsDecimal: allowsDecimal,
              errorText: quantity.error,
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
              errorText: priceError,
              onChanged: (_) => setState(() {}),
              prefixIcon: const Icon(Icons.euro_outlined),
              textInputAction: TextInputAction.done,
            ),
            // Συνολική τιμή (24-09-2026, όλες οι μονάδες): ΟΝ = το πεδίο
            // Τιμή είναι το σύνολο της ποσότητας· η μοναδιαία παράγεται.
            // SwitchListTile (built-in semantics, theme/responsive δωρεάν).
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.priceTotalMode),
              value: _isTotal,
              onChanged: (value) => setState(() => _isTotal = value),
            ),
            const SizedBox(height: AppConstants.spacingM),
            FilledButton.icon(
              onPressed: canAdd && !atLimit ? _addLine : null,
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.addReceiptLine),
            ),
            if (atLimit)
              Padding(
                padding: const EdgeInsets.only(top: AppConstants.spacingS),
                child: Text(
                  AppMessages.receiptLinesLimitReached(
                    AppConstants.maxReceiptLines,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}