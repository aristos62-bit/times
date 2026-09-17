/// SPoT shared widget: «πεδίο με live αναζήτηση + autocomplete» (§2.4 DESIGN ·
/// Φάση 3 Βήμα 3). Επαναχρησιμοποιείται για Προμηθευτή (Βήμα 3), Κατηγορία/
/// Υποκατηγορία/Μονάδα (Βήματα 6+).
///
/// ΓΕΝΙΚΟΤΗΤΑ: `SearchableDropdownField<T>` είναι αγνωστικό του τύπου του
/// αποτελέσματος — κάθε καλούν δίνει `labelOf`, `onSelected` και τη family
/// του `StreamProvider<List<T>, String>` (`searchProvider`).
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
///   * Εσωτερικός sealed wrapper `_Entry<T>`: result rows + «+» row.
///   * «+» (δημιουργία) εμφανίζεται ΠΑΝΤΑ στο τέλος της λίστας όταν
///     `query.isNotEmpty` ΚΑΙ έχει οριστεί `createLabel` — ορατό ακόμα και
///     με 0 αποτελέσματα (wrapper κρατά τη λίστα μη-κενή). Busy-flag του «+»
///     είναι τοπικό (double-tap guard, §2.4).
///   * Μετά από επιλογή/prefill το πεδίο δείχνει το label και το overlay
///     μένει κλειστό (`_selectedLabel` guard): οποιαδήποτε νέα επεξεργασία
///     του κειμένου ενεργοποιεί και πάλι την αναζήτηση.
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
  });

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

  @override
  ConsumerState<SearchableDropdownField<T>> createState() =>
      _SearchableDropdownFieldState<T>();
}

/// Οι «γραμμές» του overlay. Sealed: αποτέλεσμα ή «+» (create). Κρατά τη
/// λίστα του `RawAutocomplete` πάντα μη-κενή όταν υπάρχει query, ώστε το
/// «+» να είναι ορατό ΑΚΟΜΑ με 0 αποτελέσματα (§2.4).
sealed class _Entry<T> {
  const _Entry();
}

final class _ResultEntry<T> extends _Entry<T> {
  const _ResultEntry(this.value);
  final T value;
}

final class _CreateEntry<T> extends _Entry<T> {
  const _CreateEntry(this.query);
  final String query;
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
  List<T> _results() {
    if (_query.length < widget.minChars) return const [];
    final async = ref.watch(widget.searchProvider(_query));
    return async.when(
      data: (data) => data,
      loading: () => const [],
      error: (error, stackTrace) => const [],
    );
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
    if (query.isEmpty) return const [];
    if (query.length < widget.minChars) return _createOnly(query);
    if (query != _query) return const [];
    return _entries;
  }

  /// Μοναδικό «σπρώξιμο» του RawAutocomplete να ξανατρέξει τον builder:
  /// transient αλλαγή κειμένου (append κενού + επαναφορά) — ο εκάστοτε
  /// τελευταίος builder-run χρησιμοποιεί το αρχικό κείμενο (§2.4 TO SPECIFIC).
  void _refreshOptions() {
    final String text = _controller.text;
    if (text.isEmpty) return;
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
    if (value != _selectedLabel) _selectedLabel = null;
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
      if (_query.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _query.isNotEmpty) _refreshOptions();
        });
      }
    }

    return RawAutocomplete<_Entry<T>>(
      textEditingController: _controller,
      focusNode: _focusNode,
      optionsBuilder: _optionsBuilder,
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
            prefixIcon: const Icon(Icons.store_outlined),
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
          leading: const Icon(Icons.business_outlined),
          title: Text(widget.labelOf(value)),
          onTap: () => onSelected(entry),
        ),
      _CreateEntry<T>(query: final query) => ListTile(
          dense: true,
          leading: const Icon(Icons.add_circle_outline),
          title: Text(widget.createLabel!(query)),
          trailing: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : null,
          onTap: () => onSelected(entry),
          enabled: !_isCreating,
        ),
    };
  }
}