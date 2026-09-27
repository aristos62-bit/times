/// Data validation tests για το seed (Refactor 4 επιπέδων 27-09-2026).
///
/// Επαληθεύει τα seed δεδομένα στανταλόν (χωρίς DB): μονάδες (3, μοναδικά
/// ονόματα/συντομογραφίες, allowsDecimal flags), ΑΔΕΙΟΣ κατάλογος default
/// (seedCategories/SubCategories/ItemGroups = [] — τα είδη χτίζονται από το
/// UI, απόφαση 27-09-2026), σχήμα seed records, normalization sanity.
/// Χρειάζεται μόνο `package:flutter_test` + τα seed files — καμία αναφορά
/// σε σβησμένα seed αρχεία (9/53/535).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:times/core/utils/greek_text_normalizer.dart';
import 'package:times/data/local/seed/seed_runner.dart';
import 'package:times/data/local/seed/seed_types.dart';
import 'package:times/data/local/seed/seed_units.dart';

void main() {
  // ── Μονάδες ─────────────────────────────────────────────────────────────

  group('Μονάδες μέτρησης', () {
    test('ακριβώς 3 μονάδες', () {
      expect(seedUnits.length, 3);
    });

    test('Τεμάχιο/Κιλό/Λίτρο με σωστές συντομογραφίες', () {
      final byName = <String, UnitSeed>{
        for (final u in seedUnits) u.name: u,
      };
      expect(byName['Τεμάχιο']!.abbreviation, 'τεμ');
      expect(byName['Κιλό']!.abbreviation, 'κιλ');
      expect(byName['Λίτρο']!.abbreviation, 'λτ');
    });

    test('allowsDecimal: μόνο Κιλό/Λίτρο (όχι Τεμάχιο)', () {
      final byName = <String, UnitSeed>{
        for (final u in seedUnits) u.name: u,
      };
      expect(byName['Τεμάχιο']!.allowsDecimal, isFalse);
      expect(byName['Κιλό']!.allowsDecimal, isTrue);
      expect(byName['Λίτρο']!.allowsDecimal, isTrue);
    });

    test('μοναδικά ονόματα', () {
      final names = seedUnits.map((u) => u.name).toSet();
      expect(names.length, seedUnits.length);
    });

    test('μοναδικές συντομογραφίες', () {
      final abbrs = seedUnits.map((u) => u.abbreviation).toSet();
      expect(abbrs.length, seedUnits.length);
    });

    test('ονόματα/συντομογραφίες μη κενά + normalized μοναδικά', () {
      final normalized = <String>{};
      for (final u in seedUnits) {
        expect(u.name.trim(), isNotEmpty);
        expect(u.abbreviation.trim(), isNotEmpty);
        normalized.add(GreekTextNormalizer.normalize(u.name));
      }
      expect(normalized.length, seedUnits.length);
    });
  });

  // ── Κατάλογος: άδειος by default ─────────────────────────────────────────

  group('Κατάλογος (άδειος — χτίζεται από το UI)', () {
    test('καμία seed κατηγορία', () {
      expect(seedCategories, isEmpty);
    });

    test('καμία seed υποκατηγορία', () {
      expect(seedSubCategories, isEmpty);
    });

    test('κανένα seed τμήμα', () {
      expect(seedItemGroups, isEmpty);
    });

    test('κανένα seed είδος (απόφαση 27-09-2026)', () {
      // Το runSeed δεν αναφέρει είδη πουθενά: ο κατάλογος ξεκινά άδειος
      // (μόνο μονάδες) και χτίζεται από το UI.
      expect(seedCategories, isEmpty);
      expect(seedSubCategories, isEmpty);
      expect(seedItemGroups, isEmpty);
    });
  });

  // ── Σχήμα seed records ───────────────────────────────────────────────────

  group('Σχήμα seed records (seed_types)', () {
    test('CategorySeed/SubCategorySeed/ItemGroupSeed κατασκευάζονται', () {
      const CategorySeed c = (name: 'ΤΡΟΦΙΜΑ');
      const SubCategorySeed s = (
        name: 'Γαλακτοκομικά',
        categoryName: 'ΤΡΟΦΙΜΑ',
      );
      const ItemGroupSeed g = (
        name: 'Φέτα',
        subCategoryName: 'Γαλακτοκομικά',
      );

      expect(c.name, 'ΤΡΟΦΙΜΑ');
      expect(s.categoryName, 'ΤΡΟΦΙΜΑ');
      expect(g.subCategoryName, 'Γαλακτοκομικά');
    });
  });
}
