/// Widget tests — `ItemSearchField` (Φάση 3, Βήμα 4 · §2.4 DESIGN).
///
/// Inline panel αναζήτησης — status-driven rendering. Τα interactive tests
/// τρέχουν πάνω σε πραγματική in-memory Drift βάση (όχι fakeAsync — η
/// NativeDatabase τρέχει σε background isolate, απόφαση Βήμα 4). Debounce:
/// πραγματικά delays (300ms > searchDebounceMillis=250).
///
/// Καλύπτονται: idle (no-DB), found+select→banner, «Αλλαγή»→clear,
/// notFound + «+», ΑΝΟΙΓΜΑ dialog + πλήρης δημιουργία μέσω dialog (append
/// created → snackbar itemAdded + banner), ακύρωση (χωρίς side-effects),
/// DB error → retry panel, responsive §1.4.
library;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_errors.dart';
import 'package:times/core/constants/app_messages.dart';
import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/core/logging/app_logger.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/repositories/item_repository.dart';
import 'package:times/presentation/price_entry/controllers/item_search_controller.dart';
import 'package:times/presentation/price_entry/state/item_search_state.dart';
import 'package:times/presentation/price_entry/widgets/item_search_field.dart';
import 'package:times/presentation/price_entry/widgets/new_item_flow_dialog.dart';

import '../../../data/local/helpers/in_memory_db.dart';

/// Shared wrap: ProviderScope (με προαιρετικό in-memory DB) + MaterialApp με
/// ελληνικά locale (όπως στο main) + Scaffold (SnackBar). Για no-DB tests το
/// [db] παραλείπεται (η βάση παραμένει ακόμα κλειστή — §2.0.1).
Widget wrap(Size size, {AppDatabase? db, List<dynamic> extra = const []}) {
  return ProviderScope(
    overrides: [
      if (db != null) appDatabaseProvider.overrideWithValue(db),
      ...extra,
    ],
    child: MaterialApp(
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('el')],
      locale: const Locale('el'),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: const ItemSearchField(),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    AppLogger.resetTestSink();
  });
  tearDown(() {
    AppLogger.resetTestSink();
  });

  Future<void> pumpAt(WidgetTester tester, Size size,
      {AppDatabase? db, List<dynamic> extra = const []}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap(size, db: db, extra: extra));
    await tester.pumpAndSettle();
  }

  /// Περνά πέρα από τον debounce (250ms) + το stream του provider.
  ///
  /// TO SPECIFIC: όσο το status είναι `searching` το panel δείχνει
  /// `LinearProgressIndicator` (infinite animation) → το `pumpAndSettle`
  /// πριν φτάσει το αποτέλεσμα ΔΕΝ συγκλίνει ποτέ. Η NativeDatabase τρέχει
  /// σε background isolate (πραγματικός χρόνος) — γι' αυτό μετά το debounce
  /// αφήνουμε πραγματικό χρόνο (`runAsync`) ώστε να έρθει το found/notFound,
  /// και ΜΟΝΟ ΤΟΤΕ `pumpAndSettle` (καμία infinite animation).
  Future<void> settleSearch(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pumpAndSettle();
  }

  /// Διαβάζει το state μέσα από το δέντρο.
  ItemSearchState stateOf(WidgetTester tester) {
    final container =
        ProviderScope.containerOf(tester.element(find.byType(ItemSearchField)));
    return container.read(itemSearchControllerProvider).value!;
  }

  /// Seed: κατηγορία → υποκατηγορία → (προαιρετικό) είδος (μέσω DAOs — τα
  /// Repositories είναι abstract interfaces).
  Future<void> seedChain(AppDatabase db,
      {String category = 'ΤΡΟΦΙΜΑ',
      String sub = 'Γαλακτοκομικά',
      String? itemName}) async {
    final categoryId = await CategoryDao(db).insert(name: category);
    final subId = await SubCategoryDao(db)
        .insert(categoryId: categoryId, name: sub);
    if (itemName != null) {
      await ItemDao(db).insert(subCategoryId: subId, name: itemName);
    }
  }

  group('ItemSearchField', () {
    // ─── idle / no-DB ─────────────────────────────────────────────────────────
    testWidgets('idle (χωρίς DB): label + hint + idle μήνυμα, κανένα crash',
        (tester) async {
      await pumpAt(tester, const Size(800, 600));
      expect(find.text(AppStrings.fieldItemName), findsOneWidget);
      expect(find.text(AppStrings.itemSearchHint), findsOneWidget);
      expect(find.text(AppStrings.itemSearchIdle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ─── found → select → banner ──────────────────────────────────────────────
    testWidgets('search βρίσκει «Γάλα» → found → tap → banner + «Αλλαγή»',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedChain(db, itemName: 'Γάλα');
      await pumpAt(tester, const Size(800, 600), db: db);

      await tester.enterText(find.byType(TextField), 'γάλα');
      await settleSearch(tester);

      expect(find.text('Γάλα'), findsOneWidget);
      await tester.tap(find.text('Γάλα'));
      await tester.pumpAndSettle();

      final state = stateOf(tester);
      expect(state.selectedItem?.name, 'Γάλα');
      // Banner: είδος + κουμπί «Αλλαγή»· search panel κρυμμένο.
      expect(find.text(AppStrings.changeItem), findsOneWidget);
      expect(find.text('Γάλα'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('select → clear-on-drop: το πεδίο καθαρίζει (Βήμα 5γ)',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedChain(db, itemName: 'Γάλα');
      await pumpAt(tester, const Size(800, 600), db: db);

      await tester.enterText(find.byType(TextField), 'γάλα');
      await settleSearch(tester);
      await tester.tap(find.text('Γάλα'));
      await tester.pumpAndSettle();

      // Το όνομα φαίνεται ΜΟΝΟ στο banner — το πεδίο άδειασε.
      expect(stateOf(tester).selectedItem?.name, 'Γάλα');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.text(AppStrings.changeItem), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('«Αλλαγή» → clearSelection: πίσω σε idle, πεδίο καθαρό',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedChain(db, itemName: 'Γάλα');
      await pumpAt(tester, const Size(800, 600), db: db);

      await tester.enterText(find.byType(TextField), 'γάλα');
      await settleSearch(tester);
      await tester.tap(find.text('Γάλα'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.changeItem));
      await tester.pumpAndSettle();

      final state = stateOf(tester);
      expect(state.selectedItem, isNull);
      expect(find.text(AppStrings.itemSearchIdle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ─── notFound + «+» ───────────────────────────────────────────────────────
    testWidgets('χωρίς αποτέλεσμα → itemNotFound(query) + «+» ανοίγει dialog',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedChain(db, itemName: 'Γάλα');
      await pumpAt(tester, const Size(800, 600), db: db);

      await tester.enterText(find.byType(TextField), 'Ζαμπόν');
      await settleSearch(tester);

      expect(find.text(AppMessages.itemNotFound('Ζαμπόν')), findsOneWidget);
      await tester.tap(find.text(AppStrings.addNewItem));
      await tester.pumpAndSettle();

      expect(find.byType(NewItemFlowDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ─── dialog → created / cancelled ────────────────────────────────────────
    testWidgets(
        'δημιουργία μέσω dialog (category+sub+name) → itemAdded snackbar + '
        'είδος εμφανίζεται στο banner', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      // Κατηγορία + υποκατηγορία υπάρχουν· το είδος δεν υπάρχει ακόμα.
      await seedChain(db);
      await pumpAt(tester, const Size(800, 600), db: db);

      // notFound → «+» → dialog με prefill το query.
      await tester.enterText(find.byType(TextField), 'Κριτσίνια');
      await settleSearch(tester);
      await tester.tap(find.text(AppStrings.addNewItem));
      await tester.pumpAndSettle();

      // Βήμα 1: επιλογή κατηγορίας.
      await tester.enterText(
          find.descendant(
              of: find.byType(NewItemFlowDialog),
              matching: find.byType(TextField)).first,
          'τρόφιμα');
      await settleSearch(tester);
      await tester.tap(find.text('ΤΡΟΦΙΜΑ'));
      await tester.pumpAndSettle();

      // Βήμα 2: επιλογή υποκατηγορίας (index 1 — το πεδίο κατηγορίας
      // «κλειδώθηκε» με label μετά το βήμα 1).
      await tester.enterText(
          find
              .descendant(
                  of: find.byType(NewItemFlowDialog),
                  matching: find.byType(TextField))
              .at(1),
          'γαλακτοκομικά');
      await settleSearch(tester);
      await tester.tap(find.text('Γαλακτοκομικά'));
      await tester.pumpAndSettle();

      // Βήμα 3: prefill «Κριτσίνια» + «Προσθήκη».
      expect(
          find.descendant(
              of: find.byType(NewItemFlowDialog),
              matching: find.text('Κριτσίνια')),
          findsOneWidget);
      await tester.tap(find.widgetWithText(
          FilledButton, AppStrings.newItemSave));
      await tester.pumpAndSettle();

      // After-pop: selectItem + snackbar itemAdded + banner.
      final state = stateOf(tester);
      expect(state.selectedItem?.name, 'Κριτσίνια');
      expect(find.text(AppMessages.itemAdded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ακύρωση dialog → καμία αλλαγή (κανένα snackbar, κενό select)',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedChain(db, itemName: 'Γάλα');
      await pumpAt(tester, const Size(800, 600), db: db);

      await tester.enterText(find.byType(TextField), 'Ζαμπόν');
      await settleSearch(tester);
      await tester.tap(find.text(AppStrings.addNewItem));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppMessages.confirmDialogCancel));
      await tester.pumpAndSettle();

      expect(find.byType(NewItemFlowDialog), findsNothing);
      expect(stateOf(tester).selectedItem, isNull);
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    });

    // ─── error → retry ────────────────────────────────────────────────────────
    testWidgets('DB error → retry panel (loadDataFailed + «Δοκιμή ξανά»⟩',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedChain(db);

      await pumpAt(tester, const Size(800, 600),
          db: db,
          extra: [itemRepositoryProvider.overrideWithValue(_FailingItemRepo())]);

      await tester.enterText(find.byType(TextField), 'γάλα');
      await settleSearch(tester);

      expect(find.text(AppErrors.loadDataFailed), findsOneWidget);
      expect(find.text(AppStrings.itemSearchRetry), findsOneWidget);
      // Retry «δεν σωριάζεται» — μετά από νέο pump παραμένει error panel.
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(AppStrings.itemSearchRetry), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ─── Responsive §1.4 ──────────────────────────────────────────────────────
    testWidgets('mobile (320×568) — κανένα overflow', (tester) async {
      await pumpAt(tester, const Size(320, 568));
      expect(find.text(AppStrings.itemSearchIdle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('desktop (1200×800) — κανένα overflow', (tester) async {
      await pumpAt(tester, const Size(1200, 800));
      expect(find.text(AppStrings.itemSearchIdle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

/// Failing repo: κάθε read/write ρίχνει DataLoadException — προσομοιώνει
/// σφάλμα βάσης (db error path, §2.0.4).
class _FailingItemRepo implements ItemRepository {
  const _FailingItemRepo();

  @override
  Stream<List<Item>> watchAll() => throw const DataLoadException();
  @override
  Stream<List<Item>> watchBySubCategoryId(int subCategoryId) =>
      throw const DataLoadException();
  @override
  Future<Item?> getById(int id) => throw const DataLoadException();
  @override
  Future<Item?> getByNormalizedName(String normalizedName) =>
      throw const DataLoadException();
  @override
  Stream<List<Item>> searchByNormalizedName(String query, {int? limit}) =>
      throw const DataLoadException();
  @override
  Future<int> insert({
    required int subCategoryId,
    required String name,
    int? defaultUnitId,
  }) =>
      throw const DataLoadException();
  @override
  Future<bool> updateById(int id,
      {int? subCategoryId, String? name, Value<int?>? defaultUnitId}) =>
      throw const DataLoadException();
  @override
  Future<bool> deleteById(int id) => throw const DataLoadException();
}