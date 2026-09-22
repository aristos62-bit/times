/// Widget tests — `ReceiptHeaderSection` (§2.2 / Φάση 3 Βήμα 3).
///
/// Ελληνικά medium-format (formatMediumDate με el locale, §0). Το picker
/// ελέγχεται σε μεγάλη θύρα (grid mode) — στα responsive tests ΔΕΝ ανοίγει.
/// Αποφυγή DateTime.now() σε asserts: η "σήμερα" παράγεται από το controller
/// (μέσω `MaterialLocalizations.formatMediumDate`). Στο Βήμα 3 προστέθηκε το
/// πεδίο προμηθευτή (SearchableDropdownField, §2.4): τα interactive tests
/// χρειάζονται in-memory DB (override appDatabaseProvider) για live search
/// και inline δημιουργία — ΓΙ' ΑΥΤΟ το wrap δέχεται optional overrides.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_constants.dart';
import 'package:times/core/constants/app_errors.dart';
import 'package:times/core/constants/app_messages.dart';
import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/supplier_dao.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/presentation/price_entry/controllers/receipt_form_controller.dart';
import 'package:times/presentation/price_entry/state/receipt_form_state.dart';
import 'package:times/presentation/price_entry/widgets/receipt_header_section.dart';

import '../../../data/local/helpers/in_memory_db.dart';

/// Shared wrap: ProviderScope (με προαιρετικό in-memory DB override) +
/// MaterialApp με ελληνικά locale (όπως στο main) + Scaffold (SnackBar).
Widget wrap(Size size, {Widget? child, AppDatabase? db, ThemeData? theme}) {
  return ProviderScope(
    overrides: [
      if (db != null) appDatabaseProvider.overrideWithValue(db),
    ],
    child: MaterialApp(
      theme: theme,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('el')],
      locale: const Locale('el'),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: child ?? const ReceiptHeaderSection(),
        ),
      ),
    ),
  );
}

void main() {
  /// Θέτει τη θύρα (logical, dpr=1) και περιμένει το δέντρο.
  Future<void> pumpAt(WidgetTester tester, Size size,
      {AppDatabase? db, ThemeData? theme}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap(size, db: db, theme: theme));
    await tester.pumpAndSettle();
  }

  String mediumNow(WidgetTester tester) {
    final ctx = tester.element(find.byType(ReceiptHeaderSection));
    final today = DateUtils.dateOnly(DateTime.now());
    return MaterialLocalizations.of(ctx).formatMediumDate(today);
  }

  /// Περνά πέρα από τον debounce (250ms) + το stream του provider.
  Future<void> settleSearch(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  /// Διαβάζει το state της φόρμας μέσα από το δέντρο του ProviderScope.
  ReceiptFormState formState(WidgetTester tester) {
    final container =
    ProviderScope.containerOf(tester.element(find.byType(ReceiptHeaderSection)));
    return container.read(receiptFormControllerProvider);
  }

  group('ReceiptHeaderSection', () {
    testWidgets('εμφανίζει label «Ημερομηνία» + formatMediumDate(σήμερα)',
            (tester) async {
          await pumpAt(tester, const Size(800, 600));

          expect(find.text(AppStrings.fieldDate), findsOneWidget);
          expect(find.text(mediumNow(tester)), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

    testWidgets('εμφανίζει το πεδίο προμηθευτή (label + hint, §2.4)',
            (tester) async {
          await pumpAt(tester, const Size(800, 600));

          expect(find.text(AppStrings.fieldSupplier), findsOneWidget);
          expect(find.text(AppStrings.supplierSearchHint), findsOneWidget);
          expect(find.byType(TextField), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

    testWidgets('είναι interactive (tap → ανοίγει DatePickerDialog)',
            (tester) async {
          await pumpAt(tester, const Size(800, 600));

          await tester.tap(find.byType(ListTile));
          await tester.pumpAndSettle();

          expect(find.byType(DatePickerDialog), findsOneWidget);
        });

    testWidgets('OK χωρίς αλλαγή → παραμένει η σημερινή ημερομηνία',
            (tester) async {
          await pumpAt(tester, const Size(800, 600));

          await tester.tap(find.byType(ListTile));
          await tester.pumpAndSettle();
          await tester.tap(find.text(MaterialLocalizations.of(
              tester.element(find.byType(ReceiptHeaderSection)))
              .okButtonLabel));
          await tester.pumpAndSettle();

          expect(find.byType(DatePickerDialog), findsNothing);
          expect(find.text(mediumNow(tester)), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

    testWidgets('επιλογή διαφορετικής ημέρας → ημερομηνία ενημερώνεται',
            (tester) async {
          await pumpAt(tester, const Size(800, 600));

          await tester.tap(find.byType(ListTile));
          await tester.pumpAndSettle();

          // Άλλη ημέρα του τρέχοντος μήνα (πάντα εντός bounds, ≠ σημερινή).
          final now = DateTime.now();
          final altDay = now.day == 15 ? 16 : 15;

          await tester.tap(find.descendant(
            of: find.byType(DatePickerDialog),
            matching: find.text('$altDay'),
          ));
          await tester.pump();
          await tester.tap(find.text(MaterialLocalizations.of(
              tester.element(find.byType(ReceiptHeaderSection)))
              .okButtonLabel));
          await tester.pumpAndSettle();

          final ctx = tester.element(find.byType(ReceiptHeaderSection));
          final expected = MaterialLocalizations.of(ctx)
              .formatMediumDate(DateTime(now.year, now.month, altDay));
          expect(find.text(expected), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

    testWidgets('επιλογή υπάρχοντος προμηθευτή → state.supplier ενημερώνεται',
            (tester) async {
          final db = inMemoryDb();
          addTearDown(db.close);
          await SupplierDao(db).insert(name: 'Μάρκος');
          await pumpAt(tester, const Size(800, 600), db: db);

          await tester.enterText(find.byType(TextField), 'μάρκος');
          await settleSearch(tester);

          expect(find.text('Μάρκος'), findsOneWidget);
          await tester.tap(find.text('Μάρκος'));
          await tester.pumpAndSettle();

          expect(formState(tester).supplier?.name, 'Μάρκος');
          expect(tester.takeException(), isNull);
        });

    testWidgets('«+» νέος προμηθευτής → supplierAdded + πεδίο ενημερώνεται',
            (tester) async {
          final db = inMemoryDb();
          addTearDown(db.close);
          await pumpAt(tester, const Size(800, 600), db: db);

          const name = 'Καθαριστήρια Αστραπή';
          await tester.enterText(find.byType(TextField), name);
          await settleSearch(tester);

          final createRow = find.text('${AppStrings.addNewSupplier} "$name"');
          expect(createRow, findsOneWidget);
          await tester.tap(createRow);
          await tester.pumpAndSettle();

          expect(find.text(AppMessages.supplierAdded), findsOneWidget);
          expect(find.text(name), findsOneWidget);
          expect(formState(tester).supplier?.name, name);
          expect(tester.takeException(), isNull);
        });

    testWidgets('resetForm (μετά από save) → το πεδίο προμηθευτή αδειάζει',
            (tester) async {
          final db = inMemoryDb();
          addTearDown(db.close);
          await SupplierDao(db).insert(name: 'Μάρκος');
          await pumpAt(tester, const Size(800, 600), db: db);

          await tester.enterText(find.byType(TextField), 'μάρκος');
          await settleSearch(tester);
          await tester.tap(find.text('Μάρκος'));
          await tester.pumpAndSettle();
          expect(formState(tester).supplier?.name, 'Μάρκος');
          expect(find.text('Μάρκος'), findsOneWidget);

          ProviderScope.containerOf(tester.element(find.byType(ReceiptHeaderSection)))
              .read(receiptFormControllerProvider.notifier)
              .resetForm();
          await tester.pumpAndSettle();

          expect(formState(tester).supplier, isNull);
          expect(find.text('Μάρκος'), findsNothing);
          expect(find.text(AppStrings.supplierSearchHint), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
    testWidgets('«+» με υπάρχοντα → supplierExists (soft dup-check)',
            (tester) async {
          final db = inMemoryDb();
          addTearDown(db.close);
          await SupplierDao(db).insert(name: 'Μάρκος');
          await pumpAt(tester, const Size(800, 600), db: db);

          // Το «Μάρκος» δίνει BOTH result row ΚΑΙ «+» — tap στη «+» σκόπιμα.
          await tester.enterText(find.byType(TextField), 'Μάρκος');
          await settleSearch(tester);

          final createRow = find.text('${AppStrings.addNewSupplier} "Μάρκος"');
          expect(find.text('Μάρκος'), findsWidgets,
              reason: 'Result row + «+» row μαζί στο overlay');
          await tester.tap(createRow);
          await tester.pumpAndSettle();

          expect(find.text(AppMessages.supplierExists), findsOneWidget);
          expect(formState(tester).supplier?.name, 'Μάρκος');
          expect(tester.takeException(), isNull);
        });

    // ─── Validation ονόματος (Βήμα 6ε) ─────────────────────────────────────────
    testWidgets('HB3: «+» με όνομα > maxItemNameLength → nameTooLong, '
        'καμία εγγραφή', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await pumpAt(tester, const Size(800, 600), db: db);
      final tooLong =
      List.filled(AppConstants.maxItemNameLength + 1, 'α').join();

      await tester.enterText(find.byType(TextField), tooLong);
      await settleSearch(tester);
      await tester.tap(find.text('${AppStrings.addNewSupplier} "$tooLong"'));
      await tester.pumpAndSettle();

      expect(find.text(AppErrors.nameTooLong), findsOneWidget);
      expect(formState(tester).supplier, isNull);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ReceiptHeaderSection)),
      );
      final all = await tester.runAsync(
            () => container.read(supplierRepositoryProvider).watchAll().first,
      );
      expect(all, isEmpty, reason: 'Καμία εγγραφή στη βάση');
      expect(tester.takeException(), isNull);
    });

    testWidgets('HB4: μετά την απόρριψη το πεδίο κρατά ό,τι έγραψε ο χρήστης',
            (tester) async {
          final db = inMemoryDb();
          addTearDown(db.close);
          await pumpAt(tester, const Size(800, 600), db: db);
          final tooLong =
          List.filled(AppConstants.maxItemNameLength + 1, 'α').join();

          await tester.enterText(find.byType(TextField), tooLong);
          await settleSearch(tester);
          await tester.tap(find.text('${AppStrings.addNewSupplier} "$tooLong"'));
          await tester.pumpAndSettle();

          final text =
              tester.widget<TextField>(find.byType(TextField)).controller!.text;
          expect(text, isNot(contains('Instance of')),
              reason: 'Το RawAutocomplete δεν πρέπει να γράψει toString()');
          expect(text, tooLong);
          expect(tester.takeException(), isNull);
        });

    testWidgets('HB5: «+» με όνομα ακριβώς maxItemNameLength → δημιουργείται',
            (tester) async {
          final db = inMemoryDb();
          addTearDown(db.close);
          await pumpAt(tester, const Size(800, 600), db: db);
          final exact = List.filled(AppConstants.maxItemNameLength, 'α').join();

          await tester.enterText(find.byType(TextField), exact);
          await settleSearch(tester);
          await tester.tap(find.text('${AppStrings.addNewSupplier} "$exact"'));
          await tester.pumpAndSettle();

          expect(find.text(AppMessages.supplierAdded), findsOneWidget);
          expect(formState(tester).supplier?.name, exact);
          expect(tester.takeException(), isNull);
        });

    // ─── Responsive §1.4 — κανένα overflow ─────────────────────────────────────
    testWidgets('mobile (320×568) — κανένα overflow', (tester) async {
      await pumpAt(tester, const Size(320, 568));
      expect(find.text(mediumNow(tester)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tablet (800×600) — κανένα overflow', (tester) async {
      await pumpAt(tester, const Size(800, 600));
      expect(find.text(mediumNow(tester)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('desktop (1200×800) — κανένα overflow', (tester) async {
      await pumpAt(tester, const Size(1200, 800));
      expect(find.text(mediumNow(tester)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ─── Dark mode §1.5 ───────────────────────────────────────────────────────
    testWidgets('dark mode: ημερομηνία + πεδίο προμηθευτή χωρίς exception',
        (tester) async {
      await pumpAt(tester, const Size(800, 600), theme: AppTheme.dark);

      expect(find.text(mediumNow(tester)), findsOneWidget);
      expect(find.text(AppStrings.fieldSupplier), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}