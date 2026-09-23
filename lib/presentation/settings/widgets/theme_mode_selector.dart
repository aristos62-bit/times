/// Widget επιλογής θέματος (Light/Dark/Auto) — Φάση 4, Βήμα 1 (DESIGN
/// §2.3:264). Material 3 `SegmentedButton<ThemeMode>`.
///
/// Dumb widget (§2.0): παίρνει το επιλεγμένο mode και επιστρέφει την αλλαγή
/// μέσω callback — ΚΑΝΕΝΑ provider read εδώ (η σύνδεση γίνεται στην
/// SettingsPage). Labels SPoT (AppStrings) — ΧΩΡΙΣ icons: safety net χωρίς
/// overflow στα 320px mobile (§1.4)· τα labels είναι ορατά κείμενα → η
/// προσιτότητα (§1.6) καλύπτεται από τα εγγενή semantics του SegmentedButton.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';

/// Επιλογή ενός από Light/Dark/System σε μοναδική επιλογή (ποτέ κενή).
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// Το τρέχον mode (από τον themeModeProvider, μέσω της σελίδας).
  final ThemeMode selected;

  /// Καλείται με το νέο mode κατά το tap σε segment (§2.0 dumb contract).
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(
          value: ThemeMode.light,
          label: Text(AppStrings.themeModeLight),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          label: Text(AppStrings.themeModeDark),
        ),
        ButtonSegment(
          value: ThemeMode.system,
          label: Text(AppStrings.themeModeSystem),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
      // Καθαρότερο σε 3 τμήματα: το τετράγωνο checkmark δείχνει φόρτο.
      showSelectedIcon: false,
    );
  }
}
