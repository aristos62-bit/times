/// Μονάδες μέτρησης Seed — Φάση 1, Βήμα 3 (§4.1 DESIGN).
///
/// Οι `allowsDecimal` μονάδες δέχονται δεκαδικό πλήθος (π.χ. 1.5 κιλ).
/// Οι αναφορές των ειδών προς αυτές γίνονται με βάση το [UnitSeed.name].
library;

import 'seed_types.dart';

const List<UnitSeed> seedUnits = <UnitSeed>[
  (name: 'Τεμάχιο', abbreviation: 'τεμ', allowsDecimal: false),
  (name: 'Κιλό', abbreviation: 'κιλ', allowsDecimal: true),
  (name: 'Λίτρο', abbreviation: 'λτ', allowsDecimal: true),
];