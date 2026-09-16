/// Tests για το GreekTextNormalizer (§2.0.4 DESIGN).
///
/// Pure sync, χωρίς fakes/async — ελέγχει public API μόνο.
/// Ο πίνακας case καλύπτει: κεφαλαία, τόνους, διαλυτικά, τελικό «ς»,
/// decomposed combining marks, idempotence, non-Greek pass-through,
/// και την απόφαση «ΔΕΝ κάνει trim».
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:times/core/utils/greek_text_normalizer.dart';

void main() {
  group('GreekTextNormalizer.normalize', () {
    test('κεφαλαίο + τόνος → πεζό άτονο', () {
      expect(GreekTextNormalizer.normalize('Γάλα'), 'γαλα');
    });

    test('μόνο τόνος → άτονο', () {
      expect(GreekTextNormalizer.normalize('γάλα'), 'γαλα');
    });

    test('κεφαλαία → πεζά', () {
      expect(GreekTextNormalizer.normalize('ΓΑΛΑ'), 'γαλα');
    });

    test('ήδη ορθό κείμενο μένει ίδιο', () {
      expect(GreekTextNormalizer.normalize('γαλα'), 'γαλα');
    });

    test('κενό input επιστρέφεται ως έχει', () {
      expect(GreekTextNormalizer.normalize(''), '');
    });

    test('non-Greek pass-through (αριθμοί/σύμβολα)', () {
      expect(GreekTextNormalizer.normalize('123 €'), '123 €');
    });

    test('τελικό ς → σ', () {
      expect(GreekTextNormalizer.normalize('γαλας'), 'γαλασ');
    });

    test('τόνος + τελικό ς μαζί', () {
      expect(GreekTextNormalizer.normalize('Γάλα ς'), 'γαλα σ');
    });

    test('άτονα κεφαλαία ονόματα', () {
      expect(GreekTextNormalizer.normalize('ΙΩΑΝΝΗΣ'), 'ιωαννησ');
    });

    test('όλα τα τονισμένα φωνήεντα αφαιρούνται', () {
      expect(
        GreekTextNormalizer.normalize('ΆΕΗΊΌΎΏ άέήίόύώ'),
        'αεηιουω αεηιουω',
      );
    });

    test('διαλυτικά αφαιρούνται', () {
      expect(GreekTextNormalizer.normalize('ΪΫ ϊϋΐΰ'), 'ιυ ιυιυ');
    });

    test('λατινικά τονισμένα (precomposed) ΔΕΝ αγγίζονται', () {
      expect(GreekTextNormalizer.normalize('CAFÉ'), 'café');
    });

    test('ΔΕΝ κάνει trim (leading/trailing spaces)', () {
      expect(GreekTextNormalizer.normalize('  Γάλα  '), '  γαλα  ');
    });

    test('decomposed τόνος (combining acute) αφαιρείται', () {
      expect(GreekTextNormalizer.normalize('γα\u0301λα'), 'γαλα');
    });

    test('decomposed λατινικός τόνος αφαιρείται', () {
      expect(GreekTextNormalizer.normalize('Cafe\u0301'), 'cafe');
    });

    test('idempotence: normalize(normalize(x)) == normalize(x)', () {
      const input = 'ΓΆΛΑ ςς ΙΙΩΑΝΝΗΣ';
      final once = GreekTextNormalizer.normalize(input);
      final twice = GreekTextNormalizer.normalize(once);
      expect(twice, once);
      expect(twice, 'γαλα σσ ιιωαννησ');
    });
  });
}