/// Unit tests — `ItemSearchState` (Freezed) + `ItemSearchStatus` (§2.4).
///
/// Plain `test()` χωρίς widget — Freezed immutable state (defaults, equality,
/// copyWith). Τα status transitions τα δοκιμάζει ο controller test — εδώ
/// μόνο το σχήμα του data-class.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:times/data/local/app_database.dart';
import 'package:times/presentation/price_entry/state/item_search_state.dart';

void main() {
  Item item({int id = 1, String name = 'Γάλα'}) => Item(
        id: id,
        subCategoryId: 1,
        name: name,
        normalizedName: 'γαλα',
      );

  group('ItemSearchState', () {
    test('defaults — idle, κενό query, κανένα αποτέλεσμα, χωρίς επιλογή', () {
      const s = ItemSearchState();
      expect(s.query, '');
      expect(s.status, ItemSearchStatus.idle);
      expect(s.results, isEmpty);
      expect(s.selectedItem, isNull);
      expect(s.errorOccurred, isFalse);
    });

    test('equality: ίδιες τιμές → ίσα, copyWith αποκλίσεις → διαφορετικά', () {
      const a = ItemSearchState();
      const b = ItemSearchState();
      expect(a, b);

      expect(
        a.copyWith(status: ItemSearchStatus.searching),
        isNot(a),
        reason: 'copyWith αλλάζει το status με fresh equality',
      );
    });

    test('copyWith(query) ενημερώνει μόνο το query (rest κρατιούνται)', () {
      const s = ItemSearchState();
      final updated = s.copyWith(query: 'γα', status: ItemSearchStatus.searching);
      expect(updated.query, 'γα');
      expect(updated.status, ItemSearchStatus.searching);
      expect(updated.results, isEmpty);
      expect(updated.selectedItem, isNull);
    });

    test('copyWith(results + selectedItem) — found/banner σχήμα', () {
      const s = ItemSearchState();
      final it = item(id: 7, name: 'Μήλο');
      final updated = s.copyWith(
        status: ItemSearchStatus.found,
        results: [it],
        selectedItem: it,
      );
      expect(updated.status, ItemSearchStatus.found);
      expect(updated.results.single.name, 'Μήλο');
      expect(updated.selectedItem?.id, 7);
    });
  });
}