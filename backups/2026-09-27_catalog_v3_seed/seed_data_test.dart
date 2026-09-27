/// Data validation tests για το seed — πηγή `supermarket_categories_v3.md`.
///
/// Επαληθεύει τα seed δεδομένα στανταλόν (χωρίς DB): μονάδες (3, μοναδικά
/// ονόματα/συντομογραφίες, allowsDecimal flags), κατάλογος v3 (6 κατηγορίες ·
/// 28 υποκατηγορίες · 183 τμήματα · 0 είδη), μοναδικά normalized ονόματα ανά
/// επίπεδο (UNIQUE §3), έγκυρες αναφορές (sub→cat, group→sub), σχήμα records.
/// Χρειάζεται μόνο `package:flutter_test` + τα seed files.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:times/core/utils/greek_text_normalizer.dart';
import 'package:times/data/local/seed/seed_categories.dart';
import 'package:times/data/local/seed/seed_item_groups.dart';
import 'package:times/data/local/seed/seed_sub_categories.dart';
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

  // ── Κατάλογος v3 (6/28/183, 0 είδη) ─────────────────────────────────────

  group('Κατάλογος v3 (`supermarket_categories_v3.md`)', () {
    test('6 κατηγορίες · 28 υποκατηγορίες · 183 τμήματα', () {
      expect(seedCategories.length, 6);
      expect(seedSubCategories.length, 28);
      expect(seedItemGroups.length, 183);
    });

    test('μοναδικά normalized ονόματα ανά επίπεδο (UNIQUE §3)', () {
      String norm(String s) => GreekTextNormalizer.normalize(s);
      final cats = seedCategories.map((c) => norm(c.name)).toSet();
      expect(cats.length, seedCategories.length);
      final subs = seedSubCategories.map((s) => norm(s.name)).toSet();
      expect(subs.length, seedSubCategories.length);
      final groups = seedItemGroups.map((g) => norm(g.name)).toSet();
      expect(groups.length, seedItemGroups.length);
    });

    test('ονόματα μη κενά (trimmed)', () {
      for (final c in seedCategories) {
        expect(c.name.trim(), isNotEmpty);
        expect(c.name, c.name.trim());
      }
      for (final s in seedSubCategories) {
        expect(s.name.trim(), isNotEmpty);
        expect(s.name, s.name.trim());
        expect(s.categoryName.trim(), isNotEmpty);
      }
      for (final g in seedItemGroups) {
        expect(g.name.trim(), isNotEmpty);
        expect(g.name, g.name.trim());
        expect(g.subCategoryName.trim(), isNotEmpty);
      }
    });

    test('κάθε υποκατηγορία δείχνει σε υπάρχουσα κατηγορία', () {
      final cats = {for (final c in seedCategories) c.name};
      for (final s in seedSubCategories) {
        expect(cats, contains(s.categoryName),
            reason: 'Ορφανή υποκατηγορία "${s.name}"');
      }
    });

    test('κάθε τμήμα δείχνει σε υπάρχουσα υποκατηγορία', () {
      final subs = {for (final s in seedSubCategories) s.name};
      for (final g in seedItemGroups) {
        expect(subs, contains(g.subCategoryName),
            reason: 'Ορφανό τμήμα "${g.name}"');
      }
    });

    test('spot checks: Φέτα, Γαλοπούλα, Τόνος κομμάτι', () {
      final groups = <String, ItemGroupSeed>{
        for (final g in seedItemGroups) g.name: g,
      };
      expect(groups['Φέτα']!.subCategoryName, 'Γαλακτοκομικά & Ψυγείου');
      expect(groups['Γαλοπούλα']!.subCategoryName, 'Αλλαντικά');
      expect(groups['Τόνος κομμάτι']!.subCategoryName, 'Θαλασσινά');
      expect(groups['Τόνος']!.subCategoryName, 'Κονσέρβες');
      expect(groups['Σοκολάτα']!.subCategoryName, 'Γλυκά');
      expect(groups['Σαμπουάν Μαλιών']!.subCategoryName, 'Σαπούνια');
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
