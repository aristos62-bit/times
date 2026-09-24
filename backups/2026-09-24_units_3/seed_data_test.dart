/// Data validation tests για το seed — Φάση 1, Βήμα 3.
///
/// Επαληθεύει τα δεδομένα στανταλόν (χωρίς DB): μοναδικότητα, αναφορές,
/// counts, normalization. Χρειάζεται μόνο `package:flutter_test` + οι seed files.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:times/core/utils/greek_text_normalizer.dart';
import 'package:times/data/local/seed/seed_categories.dart';
import 'package:times/data/local/seed/seed_items_brefika.dart';
import 'package:times/data/local/seed/seed_items_hlektrika.dart';
import 'package:times/data/local/seed/seed_items_kapnika.dart';
import 'package:times/data/local/seed/seed_items_katharistika.dart';
import 'package:times/data/local/seed/seed_items_katikidia.dart';
import 'package:times/data/local/seed/seed_items_pota.dart';
import 'package:times/data/local/seed/seed_items_prwswpiki_ygieini.dart';
import 'package:times/data/local/seed/seed_items_trofima.dart';
import 'package:times/data/local/seed/seed_items_xartika.dart';
import 'package:times/data/local/seed/seed_runner.dart';
import 'package:times/data/local/seed/seed_sub_categories.dart';
import 'package:times/data/local/seed/seed_units.dart';

void main() {
  // ── Μονάδες ─────────────────────────────────────────────────────────────

  group('Μονάδες μέτρησης', () {
    test('ακριβώς 5 μονάδες', () {
      expect(seedUnits.length, 5);
    });

    test('μοναδικά ονόματα', () {
      final names = seedUnits.map((u) => u.name).toSet();
      expect(names.length, seedUnits.length);
    });

    test('μοναδικές συντομογραφίες', () {
      final abbrs = seedUnits.map((u) => u.abbreviation).toSet();
      expect(abbrs.length, seedUnits.length);
    });
  });

  // ── Κατηγορίες ───────────────────────────────────────────────────────────

  group('Κατηγορίες', () {
    test('ακριβώς 9 κατηγορίες', () {
      expect(seedCategories.length, 9);
    });

    test('μοναδικά ονόματα', () {
      final names = seedCategories.map((c) => c.name).toSet();
      expect(names.length, seedCategories.length);
    });
  });

  // ── Υποκατηγορίες ─────────────────────────────────────────────────────────

  group('Υποκατηγορίες', () {
    test('ακριβώς 53 υποκατηγορίες', () {
      expect(seedSubCategories.length, 53);
    });

    test('μοναδικά ονόματα', () {
      final names = seedSubCategories.map((s) => s.name).toSet();
      expect(names.length, seedSubCategories.length);
    });

    test('κάθε υποκατηγορία αναφέρεται σε υπάρχουσα κατηγορία', () {
      final categoryNames = seedCategories.map((c) => c.name).toSet();
      for (final s in seedSubCategories) {
        expect(
          categoryNames,
          contains(s.categoryName),
          reason: 'Υποκατηγορία "${s.name}" αναφέρεται στη '
              'κατηγορία "${s.categoryName}" που δεν υπάρχει',
        );
      }
    });
  });

  // ── Είδη ──────────────────────────────────────────────────────────────────

  group('Είδη', () {
    test('συνολικός αριθμός: ακριβώς 535 είδη', () {
      expect(seedItems.length, 535);
    });

    test('μοναδικά ονόματα (raw)', () {
      final names = seedItems.map((i) => i.name).toSet();
      expect(names.length, seedItems.length);
    });

    test('κάθε είδος αναφέρεται σε υπάρχουσα υποκατηγορία', () {
      final subCategoryNames = seedSubCategories.map((s) => s.name).toSet();
      for (final item in seedItems) {
        expect(
          subCategoryNames,
          contains(item.subCategoryName),
          reason: 'Είδος "${item.name}" αναφέρεται στη '
              'υποκατηγορία "${item.subCategoryName}" που δεν υπάρχει',
        );
      }
    });

    test('κάθε defaultUnitName (όταν υπάρχει) αναφέρεται σε υπάρχουσα μονάδα', () {
      final unitNames = seedUnits.map((u) => u.name).toSet();
      for (final item in seedItems) {
        if (item.defaultUnitName != null) {
          expect(
            unitNames,
            contains(item.defaultUnitName),
            reason: 'Είδος "${item.name}" αναφέρεται στη μονάδα '
                '"${item.defaultUnitName}" που δεν υπάρχει',
          );
        }
      }
    });

    test('τα normalizedName είναι μοναδικά (zero normalization collisions)', () {
      final normalizedNames = <String, String>{};
      final duplicates = <String>[];
      for (final item in seedItems) {
        final normalized = GreekTextNormalizer.normalize(item.name);
        if (normalizedNames.containsKey(normalized)) {
          duplicates.add(
            '"${item.name}" → "$normalized" '
            '(το ίδιο με "${normalizedNames[normalized]}")',
          );
        }
        normalizedNames[normalized] = item.name;
      }
      expect(duplicates, isEmpty, reason: 'Normalization collisions: $duplicates');
    });

    test('μακρύτερο όνομα είδους < 100 χαρακτήρες (maxItemNameLength)', () {
      final maxLength = seedItems.map((i) => i.name.length).reduce(
        (a, b) => a > b ? a : b,
      );
      expect(maxLength, lessThan(100));
    });
  });

  // ── Κατανομή ανά κατηγορία ───────────────────────────────────────────────

  group('Κατανομή ειδών ανά κατηγορία', () {
    test('ΤΡΟΦΙΜΑ: 155 είδη', () {
      expect(seedItemsTrofima.length, 155);
    });

    test('ΠΟΤΑ & ΡΟΦΗΜΑΤΑ: 60 είδη', () {
      expect(seedItemsPota.length, 60);
    });

    test('ΠΡΟΣΩΠΙΚΗ ΥΓΙΕΙΝΗ & ΠΕΡΙΠΟΙΗΣΗ: 80 είδη', () {
      expect(seedItemsPrwswpikiYgieini.length, 80);
    });

    test('ΚΑΘΑΡΙΣΤΙΚΑ & ΟΙΚΙΑΚΑ: 80 είδη', () {
      expect(seedItemsKatharistika.length, 80);
    });

    test('ΧΑΡΤΙΚΑ & ΑΝΑΛΩΣΙΜΑ: 30 είδη', () {
      expect(seedItemsXartika.length, 30);
    });

    test('ΒΡΕΦΙΚΑ ΠΡΟΪΟΝΤΑ: 50 είδη', () {
      expect(seedItemsBrefika.length, 50);
    });

    test('ΚΑΤΟΙΚΙΔΙΑ: 30 είδη', () {
      expect(seedItemsKatikidia.length, 30);
    });

    test('ΗΛΕΚΤΡΙΚΑ & ΛΟΙΠΑ: 30 είδη', () {
      expect(seedItemsHlektrika.length, 30);
    });

    test('ΚΑΠΝΙΚΑ: 20 είδη', () {
      expect(seedItemsKapnika.length, 20);
    });

    test('συνολικό άθροισμα = 535', () {
      expect(seedItems.length, 535);
    });
  });
}