/// SPoT shared widget: «πεδίο με live αναζήτηση + autocomplete» (§2.4 DESIGN ·
/// Φάση 3 Βήμα 3). Επαναχρησιμοποιείται για Προμηθευτή (Βήμα 3), Κατηγορία/
/// Υποκατηγορία/Μονάδα (Βήματα 6+).
///
/// ΓΕΝΙΚΟΤΗΤΑ: `SearchableDropdownField<T>` είναι αγνωστικό του τύπου του
/// αποτελέσματος — κάθε καλούν δίνει `labelOf`, `onSelected` και τη family
/// του `StreamProvider<List<T>, String>` (`searchProvider`). Για οπτική
/// διάκριση ανά τύπο δίνει προαιρετικά [prefixIcon] (χρώμα/εικόνα του πεδίου)
/// και [resultLeadingIcon] (εικόνα κάθε αποτελέσματος στη λίστα).
///
/// ΡΟΗ (σύμφωνα με DESIGN §2.4):
///   * Πληκτρολόγηση → `Debouncer` (searchDebounceMillis) → gated watch:
///     `searchProvider(query)` ΜΟΝΟ όταν `query.length >= minChars`.
///   * Τα αποτελέσματα διαβάζονται ΑΠΟΚΛΕΙΣΤΙΚΑ με
///     `ref.watch(provider(query)).when(data:, loading:, error:)` — ΚΑΝΕΝΑ
///     χειροκίνητο `isLoading` (απόφαση §2.0.1).
///   * Overlay = `RawAutocomplete` (native Flutter, keyboard/accessibility).
///     TO SPECIFIC: ο `RawAutocomplete` υπολογίζει τις options ΜΟΝΟ με αλλαγή
///     κειμένου/focus — ΔΕΝ ξανακαλεί το `optionsBuilder` όταν αλλάζει μόνο
///     το state του widget. Γι' αυτό μετά από κάθε αλλαγή που επηρεάζει τις
///     γραμμές (debounce που «κλειδώνει» query, άφιξη δεδομένων) γίνεται μια
///     ΕΛΕΓΧΟΜΕΝΗ αλλαγή τιμής του controller (`_refreshOptions`, append/restore
///     κενού) ώστε ο RawAutocomplete να ξανατρέξει τον builder και να δείξει
///     τις φρέσκες γραμμές.
///   * Εσωτερικός sealed wrapper `_Entry<T>` (part αρχείο
///     `searchable_dropdown_entry.dart`): result rows + «+» row.
///   * «+» (δημιουργία) εμφανίζεται ΠΑΝΤΑ στο τέλος της λίστας όταν
///     `query.isNotEmpty` ΚΑΙ έχει οριστεί `createLabel` — ορατό ακόμα και
///     με 0 αποτελέσματα (wrapper κρατά τη λίστα μη-κενή). Busy-flag του «+»
///     είναι τοπικό (double-tap guard, §2.4).
///   * Μετά από επιλογή/prefill το πεδίο δείχνει το label και το overlay
///     μένει κλειστό (`_selectedLabel` guard): οποιαδήποτε νέα επεξεργασία
///     του κειμένου ενεργοποιεί και πάλι την αναζήτηση.
///   * Show-all-on-focus (Β5β · Δ1, π.χ. Unit dropdown): όταν [showAllWhenEmpty]
///     = true και το πεδίο ΕΣΤΙΑΣΤΕΙ με κενό κείμενο, εμφανίζονται ΟΛΕΣ οι
///     επιλογές από το [allOptionsProvider] χωρίς πληκτρολόγηση· η πληκτρολόγηση
///     φιλτράρει κανονικά, το άδειασμα επιστρέφει στα «όλα». Gated (§2.0.1):
///     το all-options provider στιγμιογράφεται ΜΟΝΟ κατόπιν εστίασης.
///
/// IMPORTANT: τη στιγμή της εκκίνησης (κενό πεδίο) ΔΕΝ γίνεται watch του
/// `searchProvider` → η βάση ΔΕΝ ανοίγει ούτε το provider στιγμιογράφεται
/// χωρίς user action (κανόνας DESIGN §2.0.1). Η μόνη repo πρόσβαση γίνεται
/// με user action (πληκτρολόγηση / «+» → `onCreate`).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/debouncer.dart';

part 'searchable_dropdown_entry.dart';

/// Generic autocomplete field με live search + inline «+» δημιουργία.
///
/// [searchProvider]: callable family — κλήση με το raw query επιστρέφει
/// `StreamProvider<List<T>>` (π.χ. `supplierSearchProvider` του καλούντος).
/// [labelOf]: label για κάθε αποτέλεσμα.
/// [createLabel]: αν ΟΡΙΣΤΕΙ → εμφανίζεται η «+» γραμμή όταν υπάρχει query
/// (label = `createLabel(query)`)· αν `null` → καθόλου δημιουργία για αυτό
/// το field. [onCreate]: INVARIANT — αν δίνεται `createLabel`, ο καλών ΟΦΕΙΛΕΙ
/// να δίνει και `onCreate`· η κλήση επιστρέφει το δημιουργημένο `T` (ή null)
/// και πρέπει να ΔΙΑΧΕΙΡΙΖΕΤΑΙ το feedback (AppFeedback) — το widget ΔΕΝ
/// εμφανίζει snackbars. [onSelected]: καλείται με το επιλεγμένο αποτέλεσμα.
class SearchableDropdownField<T> extends ConsumerStatefulWidget {
  const SearchableDropdownField({
    super.key,
    required this.labelText,
    required this.hintText,
    required this.searchProvider,
    required this.labelOf,
    this.createLabel,
    this.onCreate,
    this.onSelected,
    this.minChars = AppConstants.searchMinChars,
    this.prefixIcon = const Icon(Icons.store_outlined),
    this.resultLeadingIcon = const Icon(Icons.business_outlined),
    this.showAllWhenEmpty = false,
    this.allOptionsProvider,
    this.initialValue,
    this.onCleared,
  }) : assert(
          !showAllWhenEmpty || allOptionsProvider != null,
          'showAllWhenEmpty == true απαιτεί allOptionsProvider',
        );

  /// Label του πεδίου (SPoT app_strings, π.χ. `AppStrings.fieldSupplier`).
  final String labelText;

  /// Hint του πεδίου (SPoT app_strings, π.χ. `AppStrings.supplierSearchHint`).
  final String hintText;

  /// Callable family StreamProvider που κάνει την αναζήτηση (SPoT
  /// stream_providers) — τυπικά `StreamProvider.family<List<T>, String>`.
  final StreamProvider<List<T>> Function(String query) searchProvider;

  /// Label ενός αποτελέσματος για εμφάνιση σε λίστα & πεδίο.
  final String Function(T value) labelOf;

  /// Αν οριστεί → «+» γραμμή στο τέλος της λίστας με/χωρίς αποτελέσματα.
  final String Function(String query)? createLabel;

  /// Δημιουργία από το «+» · επιστρέφει το νέο `T` (ή null) + feedback του
  /// καλούντος (βλ. doc του widget).
  final FutureOr<T?> Function(String name)? onCreate;

  /// Προαιρετική ενημέρωση του καλούντος με το επιλεγμένο αποτέλεσμα.
  final ValueChanged<T>? onSelected;

  /// Ελάχιστοι χαρακτήρες για ενεργοποίηση αναζήτησης (default 1).
  final int minChars;

  /// Εικόνα αριστερά στο πεδίο (label/hint) — default store icon (§2.4).
  final Icon prefixIcon;

  /// Εικόνα αριστερά σε κάθε αποτέλεσμα της λίστας — default business icon (§2.4).
  final Icon resultLeadingIcon;

  /// Αν `true`: εστίαση σε ΚΕΝΟ πεδίο → εμφανίζονται ΟΛΕΣ οι επιλογές από το
  /// [allOptionsProvider] (show-all-on-focus, Β5β · Δ1). Πληκτρολόγηση →
  /// φιλτράρισμα κανονικά. Default `false` = κλασική συμπεριφορά (overlay
  /// μόνο με query ≥ minChars).
  final bool showAllWhenEmpty;

  /// Πηγή «όλων των επιλογών» για το show-all — callable χωρίς όρισμα που
  /// επιστρέφει `StreamProvider<List<T>>` (π.χ. `() => unitsStreamProvider`).
  /// Gated watch (§2.0.1): καλείται/στιγμιογράφεται ΜΟΝΟ όταν
  /// [showAllWhenEmpty] && field-focused && κενό query. INVARIANT: αν
  /// [showAllWhenEmpty]=true ΟΦΕΙΛΕΤΑΙ (assert στον constructor).
  final StreamProvider<List<T>> Function()? allOptionsProvider;

  /// Προαιρετική αρχική τιμή — ΜΟΝΟ εμφάνιση (π.χ. προεπιλογή
  /// `Item.defaultUnitId` στο Unit dropdown, §2.2 · Βήμα 5γ). Εφαρμόζεται μία
  /// φορά (initState ή πρώτη μετάβαση null → τιμή) και ΜΟΝΟ όσο ο χρήστης δεν
  /// έχει διαλέξει ο ίδιος (`_selectedLabel == null`). ΔΕΝ καλεί το
  /// [onSelected] — ο καλών συγχρονίζει το δικό του state μόνος του (π.χ. το
  /// section διαβάζει την ίδια λίστα units).
  final T? initialValue;

  /// Καλείται ΜΙΑ φορά όταν μια επιλογή/προεπιλογή ([onSelected], [initialValue])
  /// παύει να ισχύει επειδή ο χρήστης άλλαξε το κείμενο (και πλήρες σβήσιμο).
  /// Ο καλών μηδενίζει το δικό του state — αλλιώς το πεδίο φαίνεται άδειο ενώ
  /// κρατά παλιά τιμή. Ξανακαλείται μόνο μετά από νέα επιλογή (Β5ε-1).
  final VoidCallback? onCleared;

  @override
  ConsumerState<SearchableDropdownField<T>> createState() =>
      _SearchableDropdownFieldState<T>();
}

class _SearchableDropdownFieldState<T>
    extends ConsumerState<SearchableDropdownField<T>> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final Debouncer _debouncer;

  /// To debounced trim query που πυροδοτεί την αναζήτηση (όχι το raw text).
  String _query = '';

  /// Τοπικός busy-flag του «+» — double-tap guard (§2.4 ερωτήματα χρήστη).
  bool _isCreating = false;

  /// Label που δείχνει το πεδίο μετά από επιλογή/prefill — όσο το κείμενο
  /// ταυτίζεται με αυτό, το overlay παραμένει κλειστό (guard, §2.4).
  String? _selectedLabel;

  /// Οι γραμμές overlay που υπολογίστηκαν στην τελευταία build
  /// (ο sync `optionsBuilder` επιστρέφει ΑΥΤΕΣ — βλ. TO SPECIFIC στο doc).
  List<_Entry<T>> _entries = const [];

  /// Τελευταία λίστα αποτελεσμάτων — guard για το refresh μετά από άφιξη
  /// δεδομένων (loading → data) χωρίς νέα πληκτρολόγηση.
  List<T> _lastResults = const [];

  @override
  void initState() {
    super.initState();
    _debouncer = Debouncer(
      delay: Duration(milliseconds: AppConstants.searchDebounceMillis),
    );
    _focusNode.addListener(_onFocusChanged);
    _applyInitialValue(widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant SearchableDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Καθυστερημένη άφιξη της αρχικής τιμής (π.χ. default unit μόλις ήρθαν
    // τα units) — εφαρμόζεται ΜΟΝΟ αν ο χρήστης δεν έχει διαλέξει ο ίδιος.
    if (oldWidget.initialValue == null &&
        widget.initialValue != null &&
        _selectedLabel == null) {
      _applyInitialValue(widget.initialValue);
    }
  }

  /// Εμφανίζει την αρχική τιμή στο πεδίο (label + κλειστό overlay μέσω
  /// `_selectedLabel` guard) — χωρίς `onSelected` (βλ. doc του [initialValue]).
  void _applyInitialValue(T? value) {
    if (value == null) return;
    final label = widget.labelOf(value);
    _selectedLabel = label;
    _controller.value = TextEditingValue(
      text: label,
      selection: TextSelection.collapsed(offset: label.length),
    );
  }

  /// Focus listener — ΜΟΝΟ για show-all (Β5β): σε εστίαση ξανατρέχει η build
  /// (gated watch του `allOptionsProvider`, §2.0.1) και το post-frame refresh
  /// «σπρώχνει» το RawAutocomplete (append/restore κενού) να δείξει όλες τις
  /// επιλογές — το internal `_options` του γεμίζει ΜΟΝΟ μέσω αλλαγής controller
  /// (SDK autocomplete.dart `_onChangedField`). Σε blur: μόνο rebuild ώστε τα
  /// entries να αδειάσουν (χωρίς focus κανένα overlay). Για τα υπόλοιπα fields
  /// (`showAllWhenEmpty=false`) δεν γίνεται τίποτα — μηδενικό κόστος.
  void _onFocusChanged() {
    if (!widget.showAllWhenEmpty || !mounted) return;
    setState(() {});
    if (_focusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focusNode.hasFocus) _refreshOptions();
      });
    }
  }

  @override
  void dispose() {
    _debouncer.dispose(); // ακύρωση pending timer — edge case §2.2
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// GATED watch (§2.0.1): ο provider στιγμιογράφεται ΜΟΝΟ όταν το query
  /// πληροί το minChars. Κάτω από το όριο δεν υπάρχει εξάρτηση → η βάση
  /// δεν ανοίγει χωρίς user action. Τα αποτελέσματα διαβάζονται μόνο μέσω
  /// `.when(data:, loading:, error:)` — όχι χειροκίνητο bool (§2.0.1).
  ///
  /// Show-all-on-focus (Β5β): κενό query + εστιασμένο πεδίο → όλες οι επιλογές
  /// από το `allOptionsProvider`. Gated ΑΚΟΜΑ: η εστίαση είναι user action,
  /// άρα στο launch δεν ανοίγει τίποτα.
  List<T> _results() {
    if (_query.length >= widget.minChars) {
      final async = ref.watch(widget.searchProvider(_query));
      return async.when(
        data: (data) => data,
        loading: () => const [],
        error: (error, stackTrace) => const [],
      );
    }
    if (widget.showAllWhenEmpty && _focusNode.hasFocus && _query.isEmpty) {
      final allProvider = widget.allOptionsProvider!();
      final async = ref.watch(allProvider);
      return async.when(
        data: (data) => data,
        loading: () => const [],
        error: (error, stackTrace) => const [],
      );
    }
    return const [];
  }

  /// Ελάχιστη γραμμή «+» (χωρίς read του provider) — όταν δεν οριστεί
  /// `createLabel` επιστρέφει κενή λίστα.
  Iterable<_Entry<T>> _createOnly(String query) {
    if (widget.createLabel == null || query.isEmpty) return const [];
    return <_Entry<T>>[_CreateEntry<T>(query)];
  }

  /// Γραμμές overlay από τα δεδομένα του provider: results + «+» στο τέλος.
  List<_Entry<T>> _entriesFor(String query, List<T> results) {
    return <_Entry<T>>[
      for (final result in results) _ResultEntry<T>(result),
      ..._createOnly(query),
    ];
  }

  /// optionsBuilder του RawAutocomplete — ΣΥΓΧΡΟΝΟ, επιστρέφει τις γραμμές
  /// της τελευταίας build. Κανένα read του provider ΕΔΩ: τα δεδομένα
  /// έρχονται αποκλειστικά από το gated watch στο build. Αν το κείμενο δεν
  /// ταυτίζεται με το debounce-key (`_query`) → κενή λίστα (ακόμα σε debounce
  /// ή αλλαγμένο κείμενο — θα ξανακαλεστεί μετά το refresh).
  Iterable<_Entry<T>> _optionsBuilder(TextEditingValue value) {
    final String text = value.text;
    final String query = text.trim();
    if (text == _selectedLabel) return const [];
    // Show-all-on-focus (Β5β): κενό query + focus → οι «όλες» επιλογές της
    // τελευταίας build. Διαφορετικά κενό κείμενο = κανένα overlay.
    if (query.isEmpty) {
      if (widget.showAllWhenEmpty && _focusNode.hasFocus) return _entries;
      return const [];
    }
    if (query.length < widget.minChars) return _createOnly(query);
    if (query != _query) return const [];
    return _entries;
  }

  /// Μοναδικό «σπρώξιμο» του RawAutocomplete να ξανατρέξει τον builder:
  /// transient αλλαγή κειμένου (append κενού + επαναφορά) — ο εκάστοτε
  /// τελευταίος builder-run χρησιμοποιεί το αρχικό κείμενο (§2.4 TO SPECIFIC).
  void _refreshOptions() {
    final String text = _controller.text;
    // Κλασική ροή (search): κενό κείμενο δε χρειάζεται refresh. Show-all
    // (Β5β): το «σπρώξιμο» με κενό θέλει να εμφανιστούν ΟΛΕΣ οι επιλογές.
    if (text.isEmpty && !widget.showAllWhenEmpty) return;
    final base = _controller.value;
    _controller.value = TextEditingValue(
      text: '$text ',
      selection: TextSelection.collapsed(offset: text.length + 1),
    );
    _controller.value = base;
  }

  /// Πληκτρολόγηση → debounce → update του `_query` (η αναζήτηση ξεκινά
  /// μετά το delay, μόνο η ΤΕΛΕΥΤΑΙΑ ενεργοποίηση «μετράει»). Μετά το
  /// setState, reflex για το overlay (βλ. `_refreshOptions`).
  void _onChanged(String value) {
    final lost = _selectedLabel != null && value != _selectedLabel;
    if (value != _selectedLabel) _selectedLabel = null;
    if (lost) widget.onCleared?.call(); // fire-once (Β5ε-1)
    _debouncer.run(() {
      if (!mounted) return;
      setState(() => _query = value.trim());
      if (_query.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _query.isNotEmpty) _refreshOptions();
        });
      }
    });
  }

  /// Επιλογή από RawAutocomplete: dispatch ανά τύπο γραμμής.
  void _handleSelected(_Entry<T> entry) {
    switch (entry) {
      case _ResultEntry(value: final value):
        _select(value);
      case _CreateEntry(query: final query):
        _create(query);
    }
  }

  /// Επιλογή αποτελέσματος: το πεδίο δείχνει το label, το overlay κλείνει
  /// (guard `_selectedLabel`) και ο καλών ενημερώνεται.
  void _select(T value) {
    final label = widget.labelOf(value);
    _selectedLabel = label;
    setState(() => _query = '');
    _controller.value = TextEditingValue(
      text: label,
      selection: TextSelection.collapsed(offset: label.length),
    );
    widget.onSelected?.call(value);
  }

  /// «+»: καλεί τον `onCreate` του καλούντος (ο ίδιος διαχειρίζεται το
  /// feedback). Αν επιστρέψει `T`, το πεδίο δείχνει το label του νέου και
  /// το overlay κλείνει. Double-tap guard: όσο `_isCreating` οι νέες κλήσεις
  /// αγνοούνται (§2.4).
  Future<void> _create(String name) async {
    final onCreate = widget.onCreate;
    if (onCreate == null || _isCreating) return;
    setState(() => _isCreating = true);
    try {
      final created = await onCreate(name);
      if (!mounted) return;
      if (created != null) {
        final label = widget.labelOf(created);
        _selectedLabel = label;
        setState(() => _query = '');
        _controller.value = TextEditingValue(
          text: label,
          selection: TextSelection.collapsed(offset: label.length),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = _results();
    _entries = _entriesFor(_query, results);
    if (results != _lastResults) {
      _lastResults = results;
      // Άφιξη δεδομένων (loading → data) χωρίς νέα πληκτρολόγηση → refresh.
      // Ισχύει και για το show-all με κενό query (Β5β): το want-the-overlay
      // ορίζει είτε query ≥ minChars είτε show-all με focus.
      final bool wantsOverlay = _query.isNotEmpty ||
          (widget.showAllWhenEmpty && _focusNode.hasFocus);
      if (wantsOverlay) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final bool stillWantsOverlay = _query.isNotEmpty ||
              (widget.showAllWhenEmpty && _focusNode.hasFocus);
          if (stillWantsOverlay) _refreshOptions();
        });
      }
    }

    return RawAutocomplete<_Entry<T>>(
      textEditingController: _controller,
      focusNode: _focusNode,
      optionsBuilder: _optionsBuilder,
      // Κείμενο πεδίου ΤΗ ΣΤΙΓΜΗ της επιλογής: αποτέλεσμα → label, «+» → το
      // query του χρήστη. Αλλιώς το RawAutocomplete γράφει το toString() της
      // γραμμής («Instance of '_CreateEntry<...>'») και το πεδίο το κρατά
      // όταν το onCreate επιστρέψει null (άκυρο όνομα / σφάλμα DB).
      displayStringForOption: (entry) => switch (entry) {
        _ResultEntry<T>(value: final value) => widget.labelOf(value),
        _CreateEntry<T>(query: final query) => query,
      },
      onSelected: _handleSelected,
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: AppConstants.spacingS,
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              // MAX height (όχι fixed) — scrollable πέρα από αυτό (§1.4).
              constraints: BoxConstraints(
                maxHeight: AppConstants.searchDropdownMaxHeight,
              ),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  for (final entry in options)
                    _buildEntryTile(context, entry, onSelected),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Μία γραμμή του overlay (result ή «+»). Accessibility §1.6: ListTile
  /// συνθέτει το semantic label του από title (label του αποτελέσματος /
  /// «Νέος προμηθευτής "x"») + onTap — δεν χρειάζεται επιπλέον Semantics.
  Widget _buildEntryTile(
    BuildContext context,
    _Entry<T> entry,
    ValueChanged<_Entry<T>> onSelected,
  ) {
    return switch (entry) {
      _ResultEntry<T>(value: final value) => ListTile(
          dense: true,
          leading: widget.resultLeadingIcon,
          title: Text(widget.labelOf(value)),
          onTap: () => onSelected(entry),
        ),
      _CreateEntry<T>(query: final query) => ListTile(
          dense: true,
          leading: const Icon(Icons.add_circle_outline),
          title: Text(widget.createLabel!(query)),
          trailing: _isCreating
              ? SizedBox(
                  width: AppConstants.smallSpinnerSize,
                  height: AppConstants.smallSpinnerSize,
                  child: const CircularProgressIndicator(
                    strokeWidth: AppConstants.spinnerStrokeWidth,
                  ),
                )
              : null,
          onTap: () => onSelected(entry),
          enabled: !_isCreating,
        ),
    };
  }
}