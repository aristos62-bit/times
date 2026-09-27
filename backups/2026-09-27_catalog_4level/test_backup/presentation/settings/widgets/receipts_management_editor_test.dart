/// Widget tests — `ReceiptsManagementEditor` (§2.3 · Φάση Β 24-09-2026).
///
/// Φίλτρο ημέρας (date-picker + «Όλες») + ζωντανή λίστα + edit/delete.
/// Ζωντανή in-memory βάση (όχι stubs): day-filter + auto-refresh.
/// Οι ημερομηνίες δένονται στο ΣΗΜΕΡΑ (dateOnly) ώστε ο picker (ανοίγει στο
/// σήμερα) να είναι ντετερμινιστικός. Edit-success + πλοήγηση ελέγχονται με
/// ΠΡΑΓΜΑΤΙΚΟ router (precedent exit-confirm group)· εδώ (standalone, χωρίς
/// router) το goNamed θα έριχνε — καλύπτεται μόνο ο guard-Ακύρωσης.
/// Κανένα watch-`.first` στο σώμα (μάθημα Ε3 Φάσης Α): one-shot + UI asserts.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:times/core/constants/app_messages.dart';
import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/router/app_router.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/providers/settings_providers.dart';
import 'package:times/data/providers/stream_providers.dart';
import 'package:times/presentation/price_entry/controllers/receipt_form_controller.dart';
import 'package:times/presentation/price_entry/state/receipt_form_state.dart';
import 'package:times/presentation/settings/widgets/receipts_management_editor.dart';

import '../../../data/local/helpers/in_memory_db.dart';

void main() {
  /// Seed: 1 είδος/μονάδα/προμηθευτής + απόδειξη ΣΗΜΕΡΑ + απόδειξη ΧΘΕΣ.
  /// Επιστρέφει (todayId, yesterdayId).
  Future<({int todayId, int yesterdayId})> seedTwoDays(
    ProviderContainer container,
  ) async {
    final db = container.read(appDatabaseProvider);
    final unitId = await UnitDao(db).insert(
      name: 'Κιλό',
      abbreviation: 'κιλ',
      allowsDecimal: true,
    );
    final categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    final subId = await SubCategoryDao(db)
        .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
    final itemId = await ItemDao(db).insert(subCategoryId: subId, name: 'Γάλα');
    final supplierId =
        await container.read(supplierRepositoryProvider).insert(name: 'Μάρκος');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final repo = container.read(receiptRepositoryProvider);
    Future<int> one(DateTime date) => repo.insertReceiptWithLines(
          date: date,
          supplierId: supplierId,
          lines: [
            (itemId: itemId, unitId: unitId, quantity: 2, priceCents: 199, discountCents: 0),
          ],
        );
    return (todayId: await one(today), yesterdayId: await one(yesterday));
  }

  /// Standalone pump του editor (χωρίς router — όπως τα sibling editors).
  Future<ProviderContainer> pumpEditor(WidgetTester tester) async {
    final db = inMemoryDb();
    addTearDown(db.close);
    final container = ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await seedTwoDays(container);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const Scaffold(body: ReceiptsManagementEditor()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Finder filterTile() =>
      find.widgetWithText(ListTile, AppStrings.fieldDate);

  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(filterTile());
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
  }

  Future<void> pressOk(WidgetTester tester) async {
    final ctx = tester.element(filterTile());
    await tester.tap(
      find.text(MaterialLocalizations.of(ctx).okButtonLabel),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsNothing);
  }

  group('ReceiptsManagementEditor — φίλτρο (Φάση Β)', () {
    testWidgets('default: όλες ορατές + tile δείχνει «Όλες»', (tester) async {
      await pumpEditor(tester);

      expect(find.text(AppStrings.fieldDate), findsOneWidget);
      // Subtitle «Όλες» (καθαρό φίλτρο) + καμία «Όλες»-κουμπί.
      expect(find.text(AppStrings.clearReceiptFilter), findsOneWidget);
      expect(find.textContaining('Μάρκος'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap φίλτρου → ανοίγει DatePickerDialog', (tester) async {
      await pumpEditor(tester);
      await openPicker(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('OK στο σήμερα → μόνο σημερινή + κουμπί «Όλες»',
        (tester) async {
      final container = await pumpEditor(tester);
      await openPicker(tester);
      await pressOk(tester);

      expect(
        container.read(selectedReceiptDayProvider),
        isNotNull,
        reason: 'το φίλτρο ορίστηκε στο σήμερα',
      );
      expect(find.textContaining('Μάρκος'), findsOneWidget);
      // Κουμπί καθαρισμού (το subtitle δείχνει πια την ημερομηνία).
      expect(
        find.widgetWithText(TextButton, AppStrings.clearReceiptFilter),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('«Όλες» → καθαρισμός, ξαναφαίνονται όλες', (tester) async {
      final container = await pumpEditor(tester);
      await openPicker(tester);
      await pressOk(tester);
      expect(find.textContaining('Μάρκος'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, AppStrings.clearReceiptFilter));
      await tester.pumpAndSettle();

      expect(container.read(selectedReceiptDayProvider), isNull);
      expect(find.textContaining('Μάρκος'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('άλλη ημέρα χωρίς αποδείξεις → noReceiptsForDay',
        (tester) async {
      await pumpEditor(tester);
      await openPicker(tester);

      // Άλλη ημέρα του τρέχοντος μήνα (πάντα εντός bounds — idiom header).
      final now = DateTime.now();
      final altDay = now.day == 15 ? 16 : 15;
      await tester.tap(
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.text('$altDay'),
        ),
      );
      await tester.pump();
      await pressOk(tester);

      expect(find.text(AppStrings.noReceiptsForDay), findsOneWidget);
      expect(find.textContaining('Μάρκος'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('ReceiptsManagementEditor — actions (Φάση Β)', () {
    testWidgets('διαγραφή: Ναι → snackbar + φεύγει από τη λίστα',
        (tester) async {
      final container = await pumpEditor(tester);
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text(AppMessages.confirmDialogConfirm));
      await tester.pumpAndSettle();

      expect(find.text(AppMessages.receiptDeleted), findsOneWidget);
      expect(find.textContaining('Μάρκος'), findsOneWidget);
      expect(
        await container.read(receiptRepositoryProvider).getById(1),
        isNull,
        reason: 'one-shot (όχι watch — Ε3)',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('διαγραφή: Ακύρωση → καμία αλλαγή', (tester) async {
      await pumpEditor(tester);

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppMessages.confirmDialogCancel));
      await tester.pumpAndSettle();

      expect(find.textContaining('Μάρκος'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('μολύβι με drafts → Ακύρωση κρατά drafts (χωρίς router)',
        (tester) async {
      final container = await pumpEditor(tester);
      container.read(receiptFormControllerProvider.notifier).addDraftLine(
            const DraftReceiptLine(
              itemId: 999,
              unitId: 999,
              quantity: 1,
              priceCents: 100,
              itemName: 'Προσωρινό',
              unitAbbreviation: 'κιλ',
            ),
          );

      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();
      expect(
        find.text(AppMessages.editDiscardDraftsConfirm),
        findsOneWidget,
      );
      await tester.tap(find.text(AppMessages.confirmDialogCancel));
      await tester.pumpAndSettle();

      expect(
        container.read(receiptFormControllerProvider).editingId,
        isNull,
      );
      expect(
        container.read(receiptFormControllerProvider).draftLines.length,
        1,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('responsive 360/800/1280 + dark — κανένα overflow',
        (tester) async {
      for (final size in const [Size(360, 740), Size(800, 1024), Size(1280, 800)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await pumpEditor(tester);
        expect(tester.takeException(), isNull, reason: 'overflow στο $size');
      }
      expect(find.byIcon(Icons.edit_outlined), findsWidgets);
    });
  });

  group('ReceiptsManagementEditor — edit + πλοήγηση (real router)', () {
    /// Πλήρης εφαρμογή με live DB + prefs (precedent exit-confirm group).
    Future<ProviderContainer> pumpApp(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = inMemoryDb();
      addTearDown(db.close);
      final container = ProviderContainer.test(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);
      await seedTwoDays(container);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: buildAppRouter()),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    Future<void> goToSettings(WidgetTester tester) async {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(AppStrings.navSettings),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('μολύβι → φόρμα φορτωμένη + άλμα στο tab Εισαγωγή',
        (tester) async {
      final container = await pumpApp(tester);
      await goToSettings(tester);
      // Section κλειστό by default → expand πρώτα.
      await tester.tap(find.text(AppStrings.titleReceiptsSection));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.fieldDate), findsOneWidget);

      // Scroll σε ορατό (η section είναι χαμηλά στη λίστα) + tap μολύβι.
      await tester.ensureVisible(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();

      // Άλμα στο tab + banner επεξεργασίας (Φάση Α).
      expect(find.text(AppStrings.titlePriceEntry), findsOneWidget);
      expect(
        container.read(receiptFormControllerProvider).editingId,
        isNotNull,
      );
      expect(find.textContaining('Απόδειξη #'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
