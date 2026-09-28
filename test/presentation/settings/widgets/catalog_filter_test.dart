/// Widget tests — `CatalogFilterField` (§2.3 · 29-09-2026 — φίλτρο καταλόγου).
///
/// Αρχικό state (3 πεδία, 2 disabled) · επιλογή κατηγορίας → emit + enable
/// υποκατηγορίας · καθάρισμα γονέα → reset παιδιών · κουμπί «Όλες» → null-ids.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_strings.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/item_group_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/presentation/settings/widgets/catalog_filter.dart';

import '../../../data/local/helpers/in_memory_db.dart';

void main() {
  /// Seed: ΤΡΟΦΙΜΑ → Γαλακτοκομικά → Φρέσκα (+ Γάλα για πληρότητα).
  Future<({int catId, int subId, int groupId})> seedCatalog(
    AppDatabase db,
  ) async {
    final kiloId = await UnitDao(db).insert(
      name: 'Κιλό',
      abbreviation: 'κιλ',
      allowsDecimal: true,
    );
    final catId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    final subId = await SubCategoryDao(db)
        .insert(categoryId: catId, name: 'Γαλακτοκομικά');
    final groupId =
        await ItemGroupDao(db).insert(subCategoryId: subId, name: 'Φρέσκα');
    await ItemDao(db).insert(
      itemGroupId: groupId,
      name: 'Γάλα',
      defaultUnitId: kiloId,
    );
    return (catId: catId, subId: subId, groupId: groupId);
  }

  /// Βρίσκει το TextField με το δοσμένο label.
  Finder fieldByLabel(String label) => find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == label,
      );

  group('CatalogFilterField (§2.3 · 29-09-2026)', () {
    testWidgets('αρχικό: κατηγορία ενεργή, παιδιά disabled', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedCatalog(db);
      CatalogFilterSelection? last;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: Scaffold(
              body: CatalogFilterField(
                onChanged: (selection) => last = selection,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 3 labels παρόντα (κατηγορία + 2 disabled placeholders).
      expect(fieldByLabel(AppStrings.fieldCategory), findsOneWidget);
      expect(fieldByLabel(AppStrings.fieldSubCategory), findsOneWidget);
      expect(fieldByLabel(AppStrings.fieldItemGroup), findsOneWidget);
      // Disabled παιδιά: enabled == false.
      final subField = tester.widget<TextField>(
        fieldByLabel(AppStrings.fieldSubCategory),
      );
      expect(subField.enabled, isFalse);
      final groupField = tester.widget<TextField>(
        fieldByLabel(AppStrings.fieldItemGroup),
      );
      expect(groupField.enabled, isFalse);
      // Καμία εκπομπή πριν από user action.
      expect(last, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('επιλογή κατηγορίας → emit + enable υποκατηγορίας',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final ids = await seedCatalog(db);
      CatalogFilterSelection? last;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: Scaffold(
              body: CatalogFilterField(
                onChanged: (selection) => last = selection,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        fieldByLabel(AppStrings.fieldCategory),
        'τροφ',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ΤΡΟΦΙΜΑ'));
      await tester.pumpAndSettle();

      expect(last, isNotNull);
      expect(last!.categoryId, ids.catId);
      expect(last!.subCategoryId, isNull);
      expect(last!.itemGroupId, isNull);
      // Υποκατηγορία τώρα ενεργή (SearchableDropdownField: enabled null = true).
      final subField = tester.widget<TextField>(
        fieldByLabel(AppStrings.fieldSubCategory),
      );
      expect(subField.enabled, isNot(isFalse));
      expect(tester.takeException(), isNull);
    });

    testWidgets('κουμπί «Όλες» → null-ids', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedCatalog(db);
      CatalogFilterSelection? last;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: Scaffold(
              body: CatalogFilterField(
                onChanged: (selection) => last = selection,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.clearReceiptFilter));
      await tester.pumpAndSettle();

      expect(last, isNotNull);
      expect(last!.categoryId, isNull);
      expect(last!.subCategoryId, isNull);
      expect(last!.itemGroupId, isNull);
      expect(tester.takeException(), isNull);
    });
  });
}
