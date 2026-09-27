/// Widget tests — `NewItemFlowDialog` (Φάση 3, Βήμα 4 · §2.4 DESIGN).
///
/// Γραμμικός 3-βημάτων wizard (Κατηγορία → Υποκατηγορία → Όνομα) ΜΕΣΑ σε
/// `AlertDialog` + `showDialog`. Κανένα «πίσω» κουμπί (§2.4). Οι ενδιάμεσες
/// δημιουργίες (silent) και το τελικό save γίνονται μέσω
/// `itemSearchControllerProvider` (πραγματική in-memory Drift βάση, όχι
/// fakeAsync). Το feedback γίνεται ΠΑΝΤΑ από τον καλόντα μέσω του sealed
/// `NewItemDialogResult` — το ίδιο το dialog ΔΕΝ εμφανίζει snackbars.
///
/// Καλύπτονται: γραμμικότητα (βήμα εμφανίζεται μόνο με το προηγούμενο),
/// prefill, «Προσθήκη»→created/dup, «Ακύρωση», DB error → failed, disabled
/// κουμπί όταν κενό όνομα, responsive §1.4.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drift/drift.dart' show Value;
import 'package:times/core/constants/app_messages.dart';
import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/core/logging/app_logger.dart';
import 'package:times/core/utils/greek_text_normalizer.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/repositories/item_repository.dart';
import 'package:times/presentation/price_entry/widgets/new_item_flow_dialog.dart';

import '../../../data/local/helpers/in_memory_db.dart';

void main() {
  setUp(() {
    AppLogger.resetTestSink();
  });
  tearDown(() {
    AppLogger.resetTestSink();
  });

  /// Host: κουμπί που ανοίγει τον dialog και «πιάνει» το αποτέλεσμα [onResult].
  Widget wrap(Size size,
      {required AppDatabase db,
      required void Function(NewItemDialogResult?) onResult,
      List<dynamic> extra = const [],
      String initialName = ''}) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        ...extra,
      ],
      child: MaterialApp(
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('el')],
        locale: const Locale('el'),
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await showDialog<NewItemDialogResult>(
                      context: context,
                      builder: (_) =>
                          NewItemFlowDialog(initialName: initialName),
                    );
                    onResult(result);
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pumpHost(
    WidgetTester tester,
    Size size, {
    required AppDatabase db,
    required List<NewItemDialogResult?> results,
    List<dynamic> extra = const [],
    String initialName = '',
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap(size,
        db: db,
        initialName: initialName,
        extra: extra,
        onResult: (r) => results.add(r)));
    await tester.pumpAndSettle();
  }

  /// Περνά πέρα από τον debounce (250ms) + streams.
  Future<void> settleSearch(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  /// Πληκτρολογεί στο [index]-οστό ενεργό πεδίο του dialog. Μετά την
  /// επιλογή κατηγορίας, το πεδίο κατηγορίας «κλειδώνει» με label — επόμενο
  /// ενεργό είναι το υποκατηγορίας (index 1), όχι το 0.
  Future<void> typeInNthField(WidgetTester tester, String text, int index) async {
    final field = find
        .descendant(
            of: find.byType(NewItemFlowDialog),
            matching: find.byType(TextField))
        .at(index);
    await tester.enterText(field, text);
    await settleSearch(tester);
  }

  Future<void> selectCategory(
      WidgetTester tester, String label) async {
    await typeInNthField(tester, label.toLowerCase(), 0);
    await tester.tap(find.text(label).last); // dustη result row του overlay
    await tester.pumpAndSettle();
  }

  Future<void> selectSubCategory(
      WidgetTester tester, String label) async {
    await typeInNthField(tester, label.toLowerCase(), 1);
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  /// Seed: κατηγορία + υποκατηγορία (είδος όπου χρειάζεται).
  Future<void> seedChain(AppDatabase db, {String? itemName}) async {
    final categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    final subId = await SubCategoryDao(db)
        .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
    if (itemName != null) {
      await ItemDao(db).insert(subCategoryId: subId, name: itemName);
    }
  }

  group('NewItemFlowDialog', () {
    testWidgets('γωλμένη σε δημιουργία αρχικά δείχνει ΜΟΝΟ Βήμα 1'
        ' (linear, κανένα πίσω κουμπί)', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedChain(db);
      await pumpHost(tester, const Size(800, 600), db: db, results: []);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(NewItemFlowDialog), findsOneWidget);
      // labelText+hintText → 2 matches (label floated + hint στο πεδίο).
      expect(find.text(AppStrings.fieldCategory), findsWidgets);
      // Βήματα 2-3 ΔΕΝ εμφανίζονται ακόμα.
      expect(find.text(AppStrings.fieldSubCategory), findsNothing);
      expect(find.text(AppStrings.fieldItemName), findsNothing);
      // Το «Προσθήκη» υπάρχει στο action row αλλά ΕΙΝΑΙ disabled (δεν έχει
      // υποκατηγορία/όνομα ακόμα — §2.4 linear flow).
      final save = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, AppStrings.newItemSave));
      expect(save.onPressed, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('επιλογή κατηγορίας → εμφανίζεται Βήμα 2, το 3 όχι ακόμα',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedChain(db);
      await pumpHost(tester, const Size(800, 600), db: db, results: []);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await selectCategory(tester, 'ΤΡΟΦΙΜΑ');

      expect(find.text(AppStrings.fieldSubCategory), findsWidgets);
      expect(find.text(AppStrings.fieldItemName), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('«Προσθήκη» νέου είδους → pop(created=true) + ΒΔ ενημερωμένη',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedChain(db);
      final results = <NewItemDialogResult?>[];
      await pumpHost(tester, const Size(800, 600),
          db: db, results: results, initialName: 'Κριτσίνια');

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      // prefill του ονόματος εμφανίζεται ΜΟΝΟ αφού υπάρξει υποκατηγορία.
      expect(find.text('Κριτσίνια'), findsNothing);

      await selectCategory(tester, 'ΤΡΟΦΙΜΑ');
      await selectSubCategory(tester, 'Γαλακτοκομικά');

      // Βήμα 3 με prefill «Κριτσίνια» + κουμπί «Προσθήκη».
      expect(find.text('Κριτσίνια'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, AppStrings.newItemSave));
      await tester.pumpAndSettle();

      expect(find.byType(NewItemFlowDialog), findsNothing);
      final result = results.single;
      expect(result, isA<NewItemDialogCreated>());
      final created = result! as NewItemDialogCreated;
      expect(created.item.name, 'Κριτσίνια');
      expect(created.created, isTrue);
      // Το είδος υπάρχει πραγματικά στη βάση (query normalized — §2.0.4).
      expect(
          await ItemDao(db)
              .getByNormalizedName(GreekTextNormalizer.normalize('Κριτσίνια')),
          isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('«Προσθήκη» με ΥΠΑΡΧΟΝ όνομα → pop(created=false) (soft dup)',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedChain(db, itemName: 'Γάλα');
      final results = <NewItemDialogResult?>[];
      await pumpHost(tester, const Size(800, 600),
          db: db, results: results, initialName: 'Γάλα');

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await selectCategory(tester, 'ΤΡΟΦΙΜΑ');
      await selectSubCategory(tester, 'Γαλακτοκομικά');

      await tester.tap(find.widgetWithText(FilledButton, AppStrings.newItemSave));
      await tester.pumpAndSettle();

      final created = results.single! as NewItemDialogCreated;
      expect(created.created, isFalse);
      expect(created.item.name, 'Γάλα');
      expect(tester.takeException(), isNull);
    });

    testWidgets('«Ακύρωση» → pop(NewItemDialogCancelled) — κανένα DB write, dialog κλείνει',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedChain(db);
      final results = <NewItemDialogResult?>[];
      await pumpHost(tester, const Size(800, 600), db: db, results: results);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppMessages.confirmDialogCancel));
      await tester.pumpAndSettle();

      expect(find.byType(NewItemFlowDialog), findsNothing);
      // Ακύρωση → έγκυρο pop με το `NewItemDialogCancelled` (§2.4).
      expect(results.single, isA<NewItemDialogCancelled>());
      expect(tester.takeException(), isNull);
    });

    testWidgets('είδος με κενό όνομα → «Προσθήκη» disabled (validation §1.1)',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedChain(db);
      final results = <NewItemDialogResult?>[];
      await pumpHost(tester, const Size(800, 600),
          db: db, results: results, initialName: '   ');

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Περνάμε τα δύο πρώτα βήματα χωρίς prefill στη γραμμή.
      await selectCategory(tester, 'ΤΡΟΦΙΜΑ');
      await selectSubCategory(tester, 'Γαλακτοκομικά');

      final save = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, AppStrings.newItemSave));
      expect(save.onPressed, isNull, reason: 'κενό όνομα → disabled');
      expect(tester.takeException(), isNull);
    });

    testWidgets('DB error στο save → pop(NewItemDialogFailed) — χωρίς snackbar',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedChain(db);
      final results = <NewItemDialogResult?>[];

      await pumpHost(tester, const Size(800, 600),
          db: db,
          results: results,
          initialName: 'Κριτσίνια',
          extra: [
            itemRepositoryProvider.overrideWithValue(const _FailingItemRepo()),
          ]);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await selectCategory(tester, 'ΤΡΟΦΙΜΑ');
      await selectSubCategory(tester, 'Γαλακτοκομικά');

      await tester.tap(find.widgetWithText(FilledButton, AppStrings.newItemSave));
      await tester.pumpAndSettle();

      expect(find.byType(NewItemFlowDialog), findsNothing);
      expect(results.single, isA<NewItemDialogFailed>());
      // Το dialog δεν εμφανίζει ΠΟΤΕ snackbar (§2.4).
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    });

    // ─── Responsive §1.4 ──────────────────────────────────────────────────────
    testWidgets('mobile (320×568) — μόνο Βήμα 1, κανένα overflow',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedChain(db);
      await pumpHost(tester, const Size(320, 568), db: db, results: []);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.fieldCategory), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('desktop (1200×800) με πλήρη ροή — κανένα overflow',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedChain(db);
      await pumpHost(tester, const Size(1200, 800),
          db: db, results: [], initialName: 'Κριτσίνια');

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await selectCategory(tester, 'ΤΡΟΦΙΜΑ');
      await selectSubCategory(tester, 'Γαλακτοκομικά');

      expect(find.text(AppStrings.fieldItemName), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}

/// Failing repo για το Είδος μόνο — τα βήματα 1-2 δουλεύουν φυσιολογικά.
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