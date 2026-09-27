/// Unit tests — error path του `ItemSearchController` (§2.4).
///
/// Απόσπαση από το `item_search_controller_test.dart` (κανόνας 7: < 500 γρ.
/// ανά αρχείο): εδώ ζει ΜΟΝΟ το group σφάλματος αναζήτησης με το σκόπιμα
/// αποτυγχάνον repository + ο helper αναμονής AsyncError. Τα success-paths
/// (build/search/select/create*) μένουν στο αρχικό αρχείο — τα δύο αρχεία
/// είναι ανεξάρτητα, χωρίς κοινόχρηστα private helpers.
library;

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/core/logging/app_logger.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/repositories/item_repository.dart';
import 'package:times/presentation/price_entry/controllers/item_search_controller.dart';
import 'package:times/presentation/price_entry/state/item_search_state.dart';

void main() {
  setUp(() {
    AppLogger.resetTestSink();
  });
  tearDown(() {
    AppLogger.resetTestSink();
  });

  ItemSearchController notifierOf(ProviderContainer container) =>
      container.read(itemSearchControllerProvider.notifier);

  group('error path (failing repo)', () {
    test('search error → AsyncError(DataLoadException)', () async {
      final container = ProviderContainer.test(
        overrides: [
          itemRepositoryProvider.overrideWithValue(const _FailingItemRepo()),
        ],
      );
      addTearDown(container.dispose);
      final notifier = notifierOf(container);
      notifier.onQueryChanged('Γάλα');
      // Debounce 250ms + stream fail — αρκετός χρόνος για να φτάσει το error.
      final errState = await _waitForError(container);
      expect(errState, isA<DataLoadException>());
    });
  });
}

/// Αναμονή για AsyncError state.
Future<Object> _waitForError(ProviderContainer container) {
  final completer = Completer<Object>();
  container.listen<AsyncValue<ItemSearchState>>(
    itemSearchControllerProvider,
    (previous, next) {
      if (next.hasError && !completer.isCompleted) {
        completer.complete(next.error!);
      }
    },
  );
  return completer.future.timeout(const Duration(seconds: 5));
}

/// Σκόπιμα αποτυγχάνων ItemRepository — δοκιμή propagation σφάλματος.
/// Υπογραφές 4 επιπέδων (§3 · 27-09-2026): `watchByItemGroupId`/`itemGroupId`.
class _FailingItemRepo implements ItemRepository {
  const _FailingItemRepo();

  @override
  Stream<List<Item>> watchAll() => throw const DataLoadException();
  @override
  Stream<List<Item>> watchByItemGroupId(int itemGroupId) =>
      throw const DataLoadException();
  @override
  Future<Item?> getById(int id) => throw const DataLoadException();
  @override
  Future<Item?> getByNormalizedName(String normalizedName) =>
      throw const DataLoadException();
  @override
  Stream<List<Item>> searchByNormalizedName(String query, {int? limit}) async* {
    throw const DataLoadException();
  }
  @override
  Future<int> insert({
    required int itemGroupId,
    required String name,
    int? defaultUnitId,
  }) =>
      throw const DataLoadException();
  @override
  Future<bool> updateById(
    int id, {
    int? itemGroupId,
    String? name,
    Value<int?>? defaultUnitId,
  }) =>
      throw const DataLoadException();
  @override
  Future<bool> deleteById(int id) => throw const DataLoadException();
}
