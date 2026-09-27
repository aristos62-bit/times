/// Widget tests — `ItemEditDialog` (§2.3 · ενότητα Ειδών · 4 επίπεδα 27-09-2026).
///
/// Το dialog παίρνει έτοιμα entities (χωρίς DB lookups — lookup ευθύνη του
/// καλούντος): τα entities χτίζονται χειροκίνητα ως drift data classes, αλλά
/// το PUMP γίνεται με live in-memory βάση (οι dropdowns διαβάζουν providers
/// ΜΟΝΟ σε user action — focus/πληκτρολόγηση). Prefill · 3 dropdowns με
/// ValueKey chain (sub keyed ανά κατηγορία, group keyed ανά υποκατηγορία) ·
/// validation κενού (inline, χωρίς pop) · submit → record `(name, itemGroupId,
/// defaultUnitId)` · μετακίνηση σε άλλο τμήμα (show-all + επιλογή) · unit
/// touch (clear → `Value(null)`).
library;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/core/utils/greek_text_normalizer.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/item_group_dao.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/presentation/settings/widgets/item_edit_dialog.dart';

import '../../../data/local/helpers/in_memory_db.dart';

void main() {
  /// Χειροκίνητα entities (drift data classes — ίδια με seed).
  Item testItem() => Item(
        id: 1,
        itemGroupId: 11,
        name: 'Γάλα',
        normalizedName: 'γαλα',
        defaultUnitId: 100,
      );

  ItemGroup testGroup() => const ItemGroup(
        id: 11,
        subCategoryId: 10,
        name: 'Φρέσκα',
        normalizedName: 'φρεσκα',
      );

  SubCategory testSub() => const SubCategory(
        id: 10,
        categoryId: 20,
        name: 'Γαλακτοκομικά',
        normalizedName: 'γαλακτοκομικα',
      );

  Category testCategory() => Category(
        id: 20,
        name: 'ΤΡΟΦΙΜΑ',
        normalizedName: 'τροφιμα',
        createdAt: DateTime(2026, 1, 1),
      );

  Unit testUnit() => const Unit(
        id: 100,
        name: 'Τεμάχιο',
        abbreviation: 'τεμ',
        allowsDecimal: false,
      );

  /// Σπέρνει τον κατάλογο με ΡΗΤΑ ids που ταιριάζουν στα entities
  /// (20/10/11/12/100): το prefill δεν ελέγχει ids, αλλά η live αναζήτηση
  /// των dropdowns (keyed με τα ids των entities) πρέπει να βρίσκει γραμμές.
  Future<AppDatabase> seedCatalog() async {
    const norm = GreekTextNormalizer.normalize;
    final db = inMemoryDb();
    await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            id: const Value(20),
            name: 'ΤΡΟΦΙΜΑ',
            normalizedName: norm('ΤΡΟΦΙΜΑ'),
          ),
        );
    await db.into(db.subCategories).insert(
          SubCategoriesCompanion.insert(
            id: const Value(10),
            categoryId: 20,
            name: 'Γαλακτοκομικά',
            normalizedName: norm('Γαλακτοκομικά'),
          ),
        );
    await db.into(db.itemGroups).insert(
          ItemGroupsCompanion.insert(
            id: const Value(11),
            subCategoryId: 10,
            name: 'Φρέσκα',
            normalizedName: norm('Φρέσκα'),
          ),
        );
    await db.into(db.itemGroups).insert(
          ItemGroupsCompanion.insert(
            id: const Value(12),
            subCategoryId: 10,
            name: 'Κατεψυγμένα',
            normalizedName: norm('Κατεψυγμένα'),
          ),
        );
    await db.into(db.units).insert(
          UnitsCompanion.insert(
            id: const Value(100),
            name: 'Τεμάχιο',
            abbreviation: 'τεμ',
          ),
        );
    return db;
  }

  /// Ανοίγει το dialog με έτοιμα entities + live βάση.
  ///
  /// Επιστρέφει wrapper-record (ΟΧΙ το dialog future κατευθείαν — σε async
  /// συνάρτηση το `return future` θα το υιοθετούσε (flattening) και το await
  /// θα κρεμούσε όσο το dialog μένει ανοιχτό). Επιστρέφει και τη βάση για
  /// lookups πραγματικών ids (τα entities φέρουν σταθερά εικονικά ids —
  /// το prefill δεν τα ελέγχει, η αναζήτηση όμως επιστρέφει πραγματικά).
  Future<
      ({
        Future<({String name, int itemGroupId, Value<int?> defaultUnitId})?>
            dialog,
        AppDatabase db,
      })>
      openDialog(
    WidgetTester tester, {
    ThemeData? theme,
    Size size = const Size(800, 600),
  }) async {
    final db = await seedCatalog();
    addTearDown(db.close);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late Future<({String name, int itemGroupId, Value<int?> defaultUnitId})?>
        future;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  future = showItemEditDialog(
                    context,
                    item: testItem(),
                    itemGroup: testGroup(),
                    subCategory: testSub(),
                    category: testCategory(),
                    unit: testUnit(),
                  );
                },
                child: const Text('άνοιγμα'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('άνοιγμα'));
    await tester.pumpAndSettle();
    return (dialog: future, db: db);
  }

  /// Περνά debounce + background isolate (idiom new_item_flow_dialog_test):
  /// η NativeDatabase τρέχει σε πραγματικό χρόνο — μετά το debounce
  /// αφήνουμε `runAsync` ώστε να έρθουν τα αποτελέσματα.
  Future<void> settleSearch(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pumpAndSettle();
  }

  group('ItemEditDialog — prefill + δομή', () {
    testWidgets('prefill: όνομα + κατηγορία + υποκατηγορία + τμήμα + μονάδα',
        (tester) async {
      await openDialog(tester);
      expect(find.text('Γάλα'), findsWidgets);
      expect(find.text('ΤΡΟΦΙΜΑ'), findsWidgets);
      expect(find.text('Γαλακτοκομικά'), findsWidgets);
      expect(find.text('Φρέσκα'), findsWidgets);
      expect(find.text('Τεμάχιο'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('3 dropdowns με labels + ValueKey chain', (tester) async {
      await openDialog(tester);
      // Ένα dropdown ανά επίπεδο (labels Κατηγορία/Υποκατηγορία/Τμήμα).
      expect(find.text(AppStrings.fieldCategory), findsWidgets);
      expect(find.text(AppStrings.fieldSubCategory), findsWidgets);
      expect(find.text(AppStrings.fieldItemGroup), findsWidgets);
      // ValueKey chain: το sub-field keyed ανά κατηγορία, το group-field
      // keyed ανά υποκατηγορία — με prefix (αποφυγή duplicate keys όταν τα
      // ids συμπίπτουν, §2.4). Φρέσκο state σε αλλαγή γονέα.
      expect(find.byKey(const ValueKey('sub_20')), findsOneWidget);
      expect(find.byKey(const ValueKey('group_10')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('κενό όνομα → inline σφάλμα, χωρίς pop', (tester) async {
      final dialog = (await openDialog(tester)).dialog;
      final fields = find.byType(TextField);
      await tester.enterText(fields.first, '   ');
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.saveAction));
      await tester.pumpAndSettle();
      expect(find.byType(ItemEditDialog), findsOneWidget);
      expect(dialog, isNotNull);
      expect(tester.takeException(), isNull);
    });
  });

  group('ItemEditDialog — submit', () {
    testWidgets('submit έγκυρου → record (name/group/unit-absent)',
        (tester) async {
      final dialog = (await openDialog(tester)).dialog;
      await tester.enterText(find.byType(TextField).first, 'Γάλα φρέσκο');
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.saveAction));
      await tester.pumpAndSettle();
      final result = await dialog;
      expect(result?.name, 'Γάλα φρέσκο');
      expect(result?.itemGroupId, 11);
      // Μονάδα ανέγγιχτη → absent (no-op).
      expect(result?.defaultUnitId.present, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('μετακίνηση σε άλλο τμήμα → record με νέο itemGroupId',
        (tester) async {
      final opened = await openDialog(tester);
      // Πραγματικό id του «Κατεψυγμένα» (τα entities φέρουν εικονικά ids).
      final target = await ItemGroupDao(opened.db).getByNormalizedName(
        GreekTextNormalizer.normalize('Κατεψυγμένα'),
      );
      expect(target, isNotNull);
      // Πληκτρολόγηση στο 4ο πεδίο (τμήμα — idiom new_item_flow_dialog_test)
      // → overlay → επιλογή «Κατεψυγμένα».
      final groupField = find
          .descendant(
            of: find.byType(ItemEditDialog),
            matching: find.byType(TextField),
          )
          .at(3);
      await tester.enterText(groupField, 'κατεψυγμένα');
      await settleSearch(tester);
      await tester.tap(find.text('Κατεψυγμένα').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.saveAction));
      await tester.pumpAndSettle();
      final result = await opened.dialog;
      expect(result?.name, 'Γάλα');
      expect(result?.itemGroupId, target!.id);
      expect(result?.itemGroupId, isNot(11));
      expect(tester.takeException(), isNull);
    });

    testWidgets('unit touch (σβήσιμο) → Value(null) present', (tester) async {
      final dialog = (await openDialog(tester)).dialog;
      // Πληκτρολόγηση στο πεδίο μονάδας = απώλεια επιλογής → onCleared →
      // _unitTouched (pattern Β5ε-1) — χωρίς καθάρισμα η μονάδα μένει absent.
      await tester.enterText(find.byType(TextField).last, 'zzz');
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.saveAction));
      await tester.pumpAndSettle();
      final result = await dialog;
      expect(result?.itemGroupId, 11);
      expect(result?.defaultUnitId.present, isTrue);
      expect(result?.defaultUnitId.value, isNull);
      expect(tester.takeException(), isNull);
    });
  });

  group('ItemEditDialog — responsive + dark', () {
    for (final size in const [
      Size(320, 568),
      Size(800, 600),
      Size(1200, 800),
    ]) {
      testWidgets('$size — κανένα overflow', (tester) async {
        await openDialog(tester, size: size);
        expect(find.byType(ItemEditDialog), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'overflow σε $size');
      });
    }

    testWidgets('dark + 320px — κανένα overflow', (tester) async {
      await openDialog(
        tester,
        theme: AppTheme.dark,
        size: const Size(320, 568),
      );
      expect(find.byType(ItemEditDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
