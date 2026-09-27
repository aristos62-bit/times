/// Widget tests — `ItemListEditor` (§2.3 · ενότητα Ειδών).
///
/// Forked αναζήτηση (ίδια με απόδειξης) + tile επεξεργασίας/πύλης +
/// responsive/dark + isolation (η επιλογή εδώ ΔΕΝ αγγίζει τη φόρμα).
/// Timing idiom `item_search_field_test` (debounce 300ms + runAsync 150ms).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_messages.dart';
import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/presentation/price_entry/controllers/item_search_controller.dart';
import 'package:times/presentation/price_entry/widgets/item_search_field.dart';
import 'package:times/presentation/settings/widgets/item_list_editor.dart';

import '../../../data/local/helpers/in_memory_db.dart';

void main() {
  /// Wrap: DB override (το fork φτιάχνεται μέσα στο section).
  Widget wrap(
    AppDatabase db, {
    Size size = const Size(800, 600),
    TextScaler textScaler = TextScaler.noScaling,
    ThemeData? theme,
  }) {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: theme,
        home: MediaQuery(
          data: MediaQueryData(size: size, textScaler: textScaler),
          child: const Scaffold(body: ItemListEditor()),
        ),
      ),
    );
  }

  Future<void> pumpAt(
    WidgetTester tester,
    AppDatabase db,
    Size size, {
    TextScaler textScaler = TextScaler.noScaling,
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap(db, size: size, textScaler: textScaler, theme: theme));
    await tester.pumpAndSettle();
  }

  /// Περνά debounce + background isolate (idiom item_search_field_test).
  Future<void> settleSearch(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pumpAndSettle();
  }

  Future<int> seedGala(AppDatabase db) async {
    // Μονάδα seed (μελλοντική χρήση tiles) — το id αγνοείται σκόπιμα.
    await UnitDao(db).insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
    final categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    final subId = await SubCategoryDao(db)
        .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
    return ItemDao(db).insert(subCategoryId: subId, name: 'Γάλα');
  }

  group('ItemListEditor', () {
    testWidgets('idle: πεδίο αναζήτησης + hint, κανένα crash', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await pumpAt(tester, db, const Size(800, 600));
      expect(find.text(AppStrings.fieldItemName), findsOneWidget);
      expect(find.text(AppStrings.itemSearchIdle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('search → tap → tile με edit + πύλη', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedGala(db);
      await pumpAt(tester, db, const Size(800, 600));

      await tester.enterText(find.byType(TextField), 'γάλα');
      await settleSearch(tester);

      await tester.tap(find.text('Γάλα'));
      await tester.pumpAndSettle();

      expect(
        find.byTooltip(AppStrings.editAction, skipOffstage: false),
        findsWidgets,
      );
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('isolation: η επιλογή ΔΕΝ περνά στο root search',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedGala(db);
      await pumpAt(tester, db, const Size(800, 600));

      await tester.enterText(find.byType(TextField), 'γάλα');
      await settleSearch(tester);
      await tester.tap(find.text('Γάλα'));
      await tester.pumpAndSettle();

      // Το fork διαβάζεται μέσα από το subtree (ItemSearchField), το root
      // από το MaterialApp — η επιλογή μένει ΜΟΝΟ στο fork.
      final forkContainer = ProviderScope.containerOf(
        tester.element(find.byType(ItemSearchField)),
      );
      expect(
        forkContainer.read(itemSearchControllerProvider).value?.selectedItem,
        isNotNull,
      );
      final rootContainer = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      expect(
        rootContainer.read(itemSearchControllerProvider).value?.selectedItem,
        isNull,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('320/800/1200 + dark — κανένα overflow', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      for (final size in const [
        Size(320, 568),
        Size(800, 600),
        Size(1200, 800),
      ]) {
        await pumpAt(tester, db, size);
        expect(tester.takeException(), isNull, reason: 'overflow σε $size');
      }
      await pumpAt(
        tester,
        db,
        const Size(320, 568),
        textScaler: const TextScaler.linear(2.0),
        theme: AppTheme.dark,
      );
      expect(find.byType(ItemListEditor), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ItemListEditor messages', () {
    test('deleteItemConfirm — όνομα χωρίς cascade (§2.3)', () {
      expect(
        AppMessages.deleteItemConfirm('Γάλα'),
        'Διαγραφή είδους "Γάλα";',
      );
    });
  });
}
