/// Widget tests — inline validation του `NewItemFlowDialog` στο «+»
/// Κατηγορίας/Υποκατηγορίας (§2.2/§2.4 · Φάση 3 Βήμα 6ζ). Νέο αρχείο: το
/// new_item_flow_dialog_test.dart έχει ήδη 380 γραμμές.
///
/// Καλύπτει: όνομα > maxItemNameLength (nameTooLong) · διπλότυπο (nameExists)
/// · σβήσιμο του μηνύματος σε επιλογή / επόμενη επιτυχία · υποκατηγορία ·
/// responsive (320×568) και dark theme. Πραγματική in-memory Drift βάση.
/// Προϋπόθεση: το fix του `SearchableDropdownField` (displayStringForOption,
/// Βήμα 6ε) — το πεδίο κρατά το query μετά από απόρριψη του «+».
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_constants.dart';
import 'package:times/core/constants/app_errors.dart';
import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/presentation/price_entry/widgets/new_item_flow_dialog.dart';
import 'package:times/presentation/shared/searchable_dropdown_field.dart';

import '../../../data/local/helpers/in_memory_db.dart';

void main() {
  /// Host: κουμπί «open» που ανοίγει το dialog (in-memory DB override).
  Widget wrap(AppDatabase db, {ThemeData? theme}) {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: theme,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('el')],
        locale: const Locale('el'),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showDialog<NewItemDialogResult>(
                  context: context,
                  builder: (_) => const NewItemFlowDialog(),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openDialog(
      WidgetTester tester,
      AppDatabase db, {
        Size size = const Size(800, 600),
        ThemeData? theme,
      }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap(db, theme: theme));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// Περνά πέρα από τον debounce (250ms) + streams.
  Future<void> settleSearch(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  Finder dialogFields() => find.descendant(
    of: find.byType(NewItemFlowDialog),
    matching: find.byType(TextField),
  );

  Future<void> typeInNthField(
      WidgetTester tester,
      String text,
      int index,
      ) async {
    await tester.enterText(dialogFields().at(index), text);
    await settleSearch(tester);
  }

  String fieldText(WidgetTester tester, int index) =>
      tester.widget<TextField>(dialogFields().at(index)).controller!.text;

  /// Tap στη γραμμή «+». Το dup-check/insert τρέχει σε πραγματικό χρόνο
  /// (NativeDatabase σε background isolate) → `runAsync` πριν το settle
  /// (ίδιο μοτίβο με το settleSearch του item_search_field_test).
  Future<void> tapCreate(
      WidgetTester tester,
      String createLabel,
      String query,
      ) async {
    await tester.tap(find.text('$createLabel "$query"'));
    await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pumpAndSettle();
  }

  /// Επιλογή υπάρχουσας κατηγορίας από το overlay (βήμα 1).
  Future<void> selectCategory(WidgetTester tester, String label) async {
    await typeInNthField(tester, label.toLowerCase(), 0);
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<List<Category>> allCategories(WidgetTester tester) async {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NewItemFlowDialog)),
    );
    final result = await tester.runAsync(
          () => container.read(categoryRepositoryProvider).watchAll().first,
    );
    return result!;
  }

  final tooLong = List.filled(AppConstants.maxItemNameLength + 1, 'α').join();

  group('NewItemFlowDialog — validation «+» (Βήμα 6ζ)', () {
    testWidgets('Z1: κατηγορία > maxItemNameLength → nameTooLong, καμία '
        'εγγραφή, το πεδίο κρατά το query', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await openDialog(tester, db);

      await typeInNthField(tester, tooLong, 0);
      await tapCreate(tester, AppStrings.addNewCategory, tooLong);

      expect(find.text(AppErrors.nameTooLong), findsOneWidget);
      expect(find.byType(SearchableDropdownField<SubCategory>), findsNothing);
      expect(fieldText(tester, 0), tooLong);
      expect(await allCategories(tester), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Z2: διπλότυπη κατηγορία → nameExists, χωρίς νέα εγγραφή '
        'και χωρίς βήμα 2', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
      await openDialog(tester, db);

      await typeInNthField(tester, 'τροφιμα', 0);
      await tapCreate(tester, AppStrings.addNewCategory, 'τροφιμα');

      expect(find.text(AppErrors.nameExists), findsOneWidget);
      expect(find.byType(SearchableDropdownField<SubCategory>), findsNothing);
      expect(await allCategories(tester), hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Z3: μετά το σφάλμα, επιλογή της υπάρχουσας → το μήνυμα '
        'φεύγει και εμφανίζεται το βήμα 2', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
      await openDialog(tester, db);
      await typeInNthField(tester, 'τροφιμα', 0);
      await tapCreate(tester, AppStrings.addNewCategory, 'τροφιμα');
      expect(find.text(AppErrors.nameExists), findsOneWidget);

      // Το πεδίο κρατά ήδη «τροφιμα» και το overlay είναι κλειστό: αλλάζω το
      // κείμενο (όπως θα έκανε ο χρήστης) ώστε να ξανανοίξει η λίστα.
      await typeInNthField(tester, 'τροφ', 0);
      await tester.tap(find.text('ΤΡΟΦΙΜΑ').last);
      await tester.pumpAndSettle();

      expect(find.text(AppErrors.nameExists), findsNothing);
      expect(find.byType(SearchableDropdownField<SubCategory>), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Z4: διπλότυπη υποκατηγορία → nameExists κάτω από το βήμα 2',
            (tester) async {
          final db = inMemoryDb();
          addTearDown(db.close);
          final categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
          await SubCategoryDao(db)
              .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
          await openDialog(tester, db);
          await selectCategory(tester, 'ΤΡΟΦΙΜΑ');

          await typeInNthField(tester, 'γαλακτοκομικα', 1);
          await tapCreate(tester, AppStrings.addNewSubCategory, 'γαλακτοκομικα');

          expect(find.text(AppErrors.nameExists), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

    testWidgets('Z5: υποκατηγορία > maxItemNameLength → nameTooLong',
            (tester) async {
          final db = inMemoryDb();
          addTearDown(db.close);
          await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
          await openDialog(tester, db);
          await selectCategory(tester, 'ΤΡΟΦΙΜΑ');

          await typeInNthField(tester, tooLong, 1);
          await tapCreate(tester, AppStrings.addNewSubCategory, tooLong);

          expect(find.text(AppErrors.nameTooLong), findsOneWidget);
          expect(fieldText(tester, 1), tooLong);
          expect(tester.takeException(), isNull);
        });

    testWidgets('Z6: σφάλμα και μετά έγκυρο νέο όνομα → δημιουργείται, το '
        'μήνυμα φεύγει, εμφανίζεται το βήμα 2', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
      await openDialog(tester, db);
      await typeInNthField(tester, 'τροφιμα', 0);
      await tapCreate(tester, AppStrings.addNewCategory, 'τροφιμα');
      expect(find.text(AppErrors.nameExists), findsOneWidget);

      await typeInNthField(tester, 'ΝΕΑ ΚΑΤΗΓΟΡΙΑ', 0);
      await tapCreate(tester, AppStrings.addNewCategory, 'ΝΕΑ ΚΑΤΗΓΟΡΙΑ');

      expect(find.text(AppErrors.nameExists), findsNothing);
      expect(find.byType(SearchableDropdownField<SubCategory>), findsOneWidget);
      expect(await allCategories(tester), hasLength(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Z7: μήνυμα ορατό σε στενή οθόνη (320×568) χωρίς overflow',
            (tester) async {
          final db = inMemoryDb();
          addTearDown(db.close);
          await openDialog(tester, db, size: const Size(320, 568));

          await typeInNthField(tester, tooLong, 0);
          await tapCreate(tester, AppStrings.addNewCategory, tooLong);

          expect(find.text(AppErrors.nameTooLong), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

    testWidgets('Z8: dark theme — μήνυμα ορατό χωρίς exception',
            (tester) async {
          final db = inMemoryDb();
          addTearDown(db.close);
          await openDialog(tester, db, theme: AppTheme.dark);

          await typeInNthField(tester, tooLong, 0);
          await tapCreate(tester, AppStrings.addNewCategory, tooLong);

          expect(find.text(AppErrors.nameTooLong), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
  });
}