/// Ενότητα μονάδας/ποσότητας/τιμής για το επιλεγμένο είδος (§2.2 DESIGN /
/// Φάση 3 Βήμα 5γ · κλείδωμα μονάδας 28-09-2026).
///
/// Εμφανίζεται ΜΟΝΟ όταν υπάρχει επιλεγμένο είδος (`selectedItem != null`) —
/// η σελίδα την τοποθετεί με `key: ValueKey(item.id)` ώστε κάθε είδος να έχει
/// ΦΡΕΣΚΙΑ κατάσταση (controllers/μονάδα από την αρχή — απόφαση Δ8).
///
/// ΜΟΝΑΔΑ ΚΛΕΙΔΩΜΕΝΗ (28-09-2026): η μονάδα προκύπτει ΑΠΟΚΛΕΙΣΤΙΚΑ από το
/// `Item.defaultUnitId` και εμφανίζεται σε locked banner (pattern προμηθευτή/
/// είδους §2.4) — η αλλαγή μονάδας γίνεται ΜΟΝΟ από Ρυθμίσεις → Είδη
/// (`ItemEditDialog`), ποτέ στη φόρμα. Χωρίς `defaultUnitId` (null —
/// seed/καθαρισμένα είδη) το «Προσθήκη» μένει ανενεργό με `unitRequired`.
///
/// ΡΟΗ (§2.2 state machine):
///   * Κλειδωμένη μονάδα (`Item.defaultUnitId`, §2.2 — δέσμευση, όχι πρόταση).
///   * Ποσότητα (`QuantityTextField`, `allowsDecimal` από `Unit.allowsDecimal`,
///     suffix = συντομογραφία μονάδας) — prefill `defaultReceiptQuantity`
///     στην ανάλυση του default (Δ8).
///   * Τιμή (`CurrencyTextField`, suffix = `currencySymbol`) — SPoT
///     parse/format, ΚΑΝΕΝΑ double ενδιάμεσο (απόφαση Βήμα 5).
///   * «Προσθήκη γραμμής» (ανενεργό ΟΤΑΝ unit null Ή ποσότητα/τιμή άκυρη —
///     OR) → `addDraftLine` + `clearSelection` (το search field καθαρίζει και
///     επιστρέφει σε IDLE, §2.2:206 — έτοιμο για επόμενο είδος).
///
/// Δεκαδική ποσότητα + integer-only μονάδα (§2.2:218): δεκαδική είσοδος σε
/// κλειδωμένη μονάδα χωρίς κλάσματα απορρίπτεται με `quantityMustBeInteger`
/// (απόφαση Δ — validation, όχι περικοπή: η μονάδα δεν αλλάζει πια).
///
/// VALIDATION (Βήμα 6δ): όλοι οι κανόνες (τιμή/ποσότητα/μονάδα) προέρχονται
/// από τον SPoT `ReceiptValidator` — το section δεν έχει δικά του όρια.
/// Inline σφάλμα (`errorText` των fields) ΜΟΝΟ σε μη-κενή, ολοκληρωμένη
/// είσοδο: το κενό πεδίο και ο αριθμός «υπό πληκτρολόγηση» («5,») δεν
/// δείχνουν σφάλμα (το Add μένει απλώς ανενεργό). Hint μονάδας όταν έχει
/// ήδη γραφτεί τιμή χωρίς μονάδα (είδος χωρίς `defaultUnitId`).
///
/// ΣΥΝΟΛΙΚΗ ΤΙΜΗ (24-09-2026): διακόπτης `_isTotal` — ΟΝ = το πεδίο Τιμή
/// είναι το σύνολο της ποσότητας (π.χ. 0,350 κιλ = 12 €) και η μοναδιαία
/// παράγεται `(total/quantity).round()` με guard 0/overflow (ίδια errors)·
/// OFF (default) = τιμή μονάδας. Ισχύει για όλες τις μονάδες· lifecycle από
/// το `ValueKey(item.id)` (φρέσκο ανά είδος, Δ8).
///
/// ΕΚΠΤΩΣΗ (§2.2): πεδίο `DiscountField` (€) μετά την Τιμή — κενό ≡ 0.
/// Σε unit-mode είναι ανά μονάδα· τελικό γραμμής `(τιμή−έκπτωση)×ποσότητα`.
/// Σε `_isTotal` είναι έκπτωση ΣΥΝΟΛΟΥ (εφάπαξ στο πληκτρολογημένο μικτό
/// σύνολο): παράγεται `discUnit=(D/Q).round()` (όπως η μοναδιαία) και
/// αποθηκεύεται `priceCents=grossUnit, discountCents=discUnit` — stored
/// `(gross−disc)×Q ≈ T−D (±2 λεπτά, δύο roundings). Toggle ON/OFF
/// επανερμηνεύει το κείμενο (όπως η Τιμή) — δεν σβήνεται ποτέ.
/// PREFILL (§2.2): είδος με ιστορικό → τιμή+έκπτωση από την τελευταία
/// γραμμή (`latestReceiptLineProvider`) ΜΟΝΟ σε unit-mode, match μονάδας,
/// κενά πεδία και χωρίς πληκτρολόγηση (ατομικά και τα δύο ή τίποτα —
/// mixed provenance απαγορεύεται).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_errors.dart';
import '../../../core/constants/app_messages.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/local/app_database.dart';
import '../../../data/providers/stream_providers.dart';
import '../../../domain/validators/receipt_validator.dart';
import '../../shared/currency_text_field.dart';
import '../../shared/quantity_text_field.dart';
import '../controllers/item_search_controller.dart';
import '../controllers/receipt_form_controller.dart';
import '../state/receipt_form_state.dart';
import 'discount_field.dart';

part 'unit_section_checks.dart';

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
  /// Κλειδωμένη μονάδα του είδους (`Item.defaultUnitId`) — `null` = το είδος
  /// δεν έχει μονάδα (Add ανενεργό + `unitRequired` hint).
  Unit? _unit;

  /// Έγινε η (μία) απόπειρα ανάλυσης του default — δεν ξανατρέχει.
  bool _defaultResolved = false;

  /// Λειτουργία συνολικής τιμής (24-09-2026): false (default) = το πεδίο
  /// Τιμή είναι μοναδιαία· true = το πεδίο Τιμή είναι το σύνολο της
  /// ποσότητας και η μοναδιαία παράγεται `(total/quantity).round()`.
  /// Τοπικό state, φρέσκο ανά είδος μέσω `ValueKey(item.id)` (Δ8) —
  /// κανένας νέος provider/controller.
  bool _isTotal = false;

  /// Έγινε η (μία) απόπειρα prefill τελευταίας τιμής — δεν ξανατρέχει.
  bool _prefillDone = false;

  /// Ο χρήστης πληκτρολόγησε σε Τιμή/Έκπτωση — το prefill δεν γράφει πάνω
  /// του (programmatic γραφές δεν πυροδοτούν `onChanged`, μόνο οι
  /// πληκτρολογήσεις — άρα το flag είναι ασφαλές).
  bool _userTyped = false;

  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  /// Αναλύει την κλειδωμένη μονάδα από το `Item.defaultUnitId` (§2.2 —
  /// δέσμευση 28-09-2026) + prefill ποσότητας (Δ8).
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

  /// Κλειδωμένη μονάδα (28-09-2026): καμία χειροκίνητη επιλογή — η μονάδα
  /// προκύπτει μόνο από το `_applyDefaultUnit` (αλλαγή μόνο από Ρυθμίσεις).

  /// Prefill τιμής/έκπτωσης από την τελευταία γραμμή του είδους (§2.2).
  ///
  /// Πύλη (ΟΛΑ μαζί, αλλιώς skip): unit-mode (σε total η Τιμή έχει άλλη
  /// σημασία) · υπάρχει ιστορικό · μία φορά · κανένα user typing · μονάδα
  /// επιλεγμένη ΚΑΙ ίδια με της τελευταίας γραμμής (cross-unit prefill
  /// απαγορεύεται — παραπλανητικό) · και τα δύο πεδία κενά (ατομικά και τα
  /// δύο ή τίποτα — mixed provenance απαγορεύεται). Η εγγραφή γίνεται
  /// post-frame με `mounted` guard (precedent `_applyDefaultUnit`).
  void _tryApplyPrefill(ReceiptLine? lastLine) {
    if (_isTotal ||
        lastLine == null ||
        _prefillDone ||
        _userTyped ||
        _unit == null ||
        lastLine.unitId != _unit!.id ||
        _priceController.text.isNotEmpty ||
        _discountController.text.isNotEmpty) {
      return;
    }
    _prefillDone = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _priceController.text =
          CurrencyTextField.formatCents(lastLine.priceCents);
      if (lastLine.discountCents > 0) {
        _discountController.text =
            CurrencyTextField.formatCents(lastLine.discountCents);
      }
      setState(() {});
    });
    AppLogger.info(LogTag.ui, 'Prefill τελευταίας τιμής: ${widget.item.name}');
  }

  /// «Προσθήκη γραμμής» → draft + επιστροφή search σε IDLE (§2.2:206).
  /// Συνολική τιμή (24-09-2026): με `_isTotal` η μοναδιαία παράγεται
  /// `(total/quantity).round()` με guard 0/overflow (ίδια errors — safety-net,
  /// το UI το έχει ήδη αποκλείσει στο `canAdd`)· το πληκτρολογημένο σύνολο
  /// φυλάσσεται ως `enteredTotalCents` snapshot για προβολή (χωρίς
  /// επαν-υπολογισμό στο draft list).
  /// Έκπτωση (§2.2): ανά μονάδα πάνω στην τελική μοναδιαία (πληκτρολογημένη
  /// ή παραγόμενη)· σε `_isTotal` είναι έκπτωση συνόλου και παράγεται
  /// `discUnit=(D/Q).round()` με guard `0≤disc≤gross` (ίδια errors).
  void _addLine() {
    final unit = _unit;
    final quantity = _quantityCheck(
      _quantityController,
      allowsDecimal: _unit?.allowsDecimal ?? true,
    ).value;
    final entered = _priceCheck(_priceController).value;
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
    // Έκπτωση συνόλου σε total-mode: παράγεται ανά μονάδα από το
    // πληκτρολογημένο μικτό σύνολο (όπως η μοναδιαία από το σύνολο) —
    // `validateDiscountCents` ξαναχρησιμοποιείται και για τα δύο επίπεδα.
    final int discount;
    if (!_isTotal) {
      final d = _discountCheck(_discountController, unitPriceCents).value;
      if (d == null) return;
      discount = d;
    } else {
      final totalDiscount = _discountCheck(_discountController, entered).value;
      if (totalDiscount == null) return;
      final derivedDiscount = (totalDiscount / quantity).round();
      if (ReceiptValidator.validateDiscountCents(
            derivedDiscount,
            unitPriceCents,
          ) !=
          null) {
        return;
      }
      discount = derivedDiscount;
    }
    ref.read(receiptFormControllerProvider.notifier).addDraftLine(
      DraftReceiptLine(
        itemId: widget.item.id,
        unitId: unit.id,
        quantity: quantity,
        priceCents: unitPriceCents,
        discountCents: discount,
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
    // ΜΟΝΗ ανάγνωση λίστας units: για την ανάλυση της κλειδωμένης μονάδας
    // (user action = η επιλογή είδους, §2.0.1). Η βάση δεν ανοίγει στο launch
    // για τη μονάδα — μόνο με επιλεγμένο είδος.
    final units = ref.watch(unitsStreamProvider).value;
    if (units != null && !_defaultResolved) {
      _defaultResolved = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _applyDefaultUnit(units);
      });
    }
    // Prefill τελευταίας τιμής (§2.2): ΑΝΕΥ ΟΡΩΝ watch (το mount έγινε από
    // επιλογή είδους = user action, §2.0.1 — ίδιο σκεπτικό με τα units)· η
    // πύλη εφαρμογής (mode/match/κενά/typing) είναι στο `_tryApplyPrefill`.
    // `.valueOrNull`: loading/error → null → σιωπηλό no-prefill (η φόρμα δεν
    // μπλοκάρεται ποτέ από αποτυχία prefill).
    final lastLine =
        ref.watch(latestReceiptLineProvider(widget.item.id)).value;
    _tryApplyPrefill(lastLine);

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
    final quantity = _quantityCheck(
      _quantityController,
      allowsDecimal: _unit?.allowsDecimal ?? true,
    );
    final entered = _priceCheck(_priceController);
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
    // Έκπτωση συνόλου σε total-mode: ο ίδιος έλεγχος πάνω στο μικτό σύνολο
    // (`0≤D≤T`, ίδια μηνύματα) + guard παραγόμενης (στρογγυλοποίηση —
    // μαθηματικά πλεονασμός λόγω μονοτονίας του round, safety-net όπως η τιμή).
    final ({int? value, String? error}) discount;
    if (!_isTotal) {
      discount = _discountCheck(_discountController, unitPriceCents);
    } else {
      final t = entered.value;
      final q = quantity.value;
      final totalD = _discountCheck(_discountController, t);
      if (t == null || q == null || totalD.value == null) {
        discount = (value: null, error: totalD.error);
      } else {
        final derived = (totalD.value! / q).round();
        final guardError = unitPriceCents == null
            ? null
            : ReceiptValidator.validateDiscountCents(derived, unitPriceCents);
        discount = guardError != null
            ? (value: null, error: guardError)
            : (value: derived, error: null);
      }
    }
    final canAdd = _unit != null &&
        quantity.value != null &&
        unitPriceCents != null &&
        discount.value != null;
    // Hint μονάδας (κλειδωμένη 28-09-2026): μόνο όταν ο χρήστης έχει ήδη
    // αρχίσει να γράφει τιμή και το είδος δεν έχει `defaultUnitId` —
    // η μονάδα ορίζεται από Ρυθμίσεις → Είδη.
    final unitHint = _priceController.text.isNotEmpty
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
            // Κλειδωμένη μονάδα είδους (28-09-2026, pattern locked banner
            // προμηθευτή/είδους §2.4): προβολή μόνο — αλλαγή από Ρυθμίσεις.
            // Χωρίς `defaultUnitId` → κενό + `unitRequired` hint (βλ. unitHint).
            if (_unit != null)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.straighten_outlined),
                title: Text(
                  '${AppStrings.fieldUnit}: ${_unit!.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              const SizedBox.shrink(),
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
            const SizedBox(height: AppConstants.spacingM),
            CurrencyTextField(
              controller: _priceController,
              labelText: AppStrings.fieldPrice,
              suffixText: AppStrings.currencySymbol,
              errorText: priceError,
              onChanged: (_) => setState(() => _userTyped = true),
              prefixIcon: const Icon(Icons.euro_outlined),
              textInputAction: TextInputAction.next,
            ),
            // Έκπτωση (§2.2): ανά μονάδα σε unit-mode, έκπτωση ΣΥΝΟΛΟΥ σε
            // total-mode (παράγεται ανά μονάδα — βλ. `_addLine`). Πάντα ορατό.
            const SizedBox(height: AppConstants.spacingM),
            DiscountField(
              controller: _discountController,
              errorText: discount.error,
              onChanged: (_) => setState(() => _userTyped = true),
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