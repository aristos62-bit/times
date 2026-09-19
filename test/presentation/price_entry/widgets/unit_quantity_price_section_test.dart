/// Widget tests — `UnitQuantityPriceSection` (§2.2 · Φάση 3 Βήμα 5γ).
///
/// Ενότητα μονάδας/ποσότητας/τιμής για επιλεγμένο είδος + «Προσθήκη γραμμής»
/// → draft + επιστροφή search σε IDLE. Τα interactive tests τρέχουν πάνω σε
/// πραγματική in-memory Drift βάση (μοτίβο Βήματος 4 — NativeDatabase σε
/// background isolate, πραγματικά delays, όχι fakeAsync).
///
/// Καλύπτονται: prefill defaultUnitId + ποσότητας (Δ8) · Add disabled OR ·
/// add → draft + clearSelection (§2.2:206) · χειροκίνητη επιλογή μονάδας
/// (show-all) · περικοπή δεκαδικών σε integer-only μονάδα (§2.2:218).
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_strings.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/presentation/price_entry/controllers/item_search_controller.dart';
import 'package:times/presentation/price_entry/controllers/receipt_form_controller.dart';
import 'package:times/presentation/price_entry/widgets/unit_quantity_price_section.dart';

import '../../../data/local/helpers/in_memory_db.dart';

/// Shared wrap: ProviderScope (in-memory DB) + MaterialApp ελληνικά +
/// Scaffold. Η ενότητα παίρνει `key: ValueKey(item.id)` όπως η σελίδα (Δ8).
Widget wrap(Item item, AppDatabase db) {
  return ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
    child: MaterialApp(
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('el')],
      locale: const Locale('el'),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: UnitQuantityPriceSection(
              key: ValueKey(item.id),
              item: item,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  Future<void> pumpAt(WidgetTester tester, Item item, AppDatabase db) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap(item, db));
    await tester.pumpAndSettle();
  }

  /// Βρίσκει το TextField με το δοσμένο label (unit/qty/price).
  TextField fieldByLabel(WidgetTester tester, String label) {
    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      if (field.decoration?.labelText == label) return field;
    }
    fail('Δεν βρέθηκε TextField με label «$label»');
  }

  /// Κείμενο του πεδίου με το δοσμένο label.
  String textOf(WidgetTester tester, String label) =>
      fieldByLabel(tester, label).controller!.text;

  /// Το κουμπί «Προσθήκη γραμμής» είναι ενεργό;
  bool addEnabled(WidgetTester tester) => tester
      .widget<FilledButton>(
        find.widgetWithText(FilledButton, AppStrings.addReceiptLine),
      )
      .enabled;

  /// Seed: κατηγορία → υποκατηγορία → μονάδες → είδος. Επιστρέφει record
  /// `{ item, kiloId, pieceId }`.
  Future<({Item item, int kiloId, int pieceId})> seed(
    AppDatabase db, {
    bool withDefaultUnit = true,
  }) async {
    final categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    final subId = await SubCategoryDao(db)
        .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
    final pieceId = await UnitDao(db).insert(
      name: 'Τεμάχιο',
      abbreviation: 'τεμ',
    );
    final kiloId = await UnitDao(db).insert(
      name: 'Κιλό',
      abbreviation: 'κιλ',
      allowsDecimal: true,
    );
    final itemId = await ItemDao(db).insert(
      subCategoryId: subId,
      name: 'Γάλα',
      defaultUnitId: withDefaultUnit ? kiloId : null,
    );
    final item = await ItemDao(db).getById(itemId);
    return (item: item!, kiloId: kiloId, pieceId: pieceId);
  }

  group('UnitQuantityPriceSection (Βήμα 5γ)', () {
    testWidgets('S1: defaultUnitId → προεπιλογή μονάδας + prefill «1» · '
        'Add ανενεργό χωρίς τιμή', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seed(db);
      await pumpAt(tester, seeded.item, db);

      // Προεπιλογή: το dropdown δείχνει «Κιλό», η ποσότητα «1» (Δ8).
      expect(textOf(tester, AppStrings.fieldUnit), 'Κιλό');
      expect(textOf(tester, AppStrings.fieldQuantity), '1');
      // Suffix μονάδας + suffix € παρόντα.
      expect(find.text('κιλ'), findsOneWidget);
      expect(find.text(AppStrings.currencySymbol), findsOneWidget);
      // Χωρίς τιμή → Add ανενεργό (OR gate).
      expect(addEnabled(tester), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('S2: τιμή → Add ενεργό → tap → draft + clearSelection '
        '(§2.2:206)', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seed(db);
      await pumpAt(tester, seeded.item, db);

      // Επιλογή μέσω search controller (όπως η σελίδα — ITEM_SELECTED).
      final container = ProviderScope.containerOf(
        tester.element(find.byType(UnitQuantityPriceSection)),
      );
      container
          .read(itemSearchControllerProvider.notifier)
          .selectItem(seeded.item);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidget(fieldByLabel(tester, AppStrings.fieldPrice)),
        '2,50',
      );
      await tester.pumpAndSettle();
      expect(addEnabled(tester), isTrue);

      await tester.tap(
        find.widgetWithText(FilledButton, AppStrings.addReceiptLine),
      );
      await tester.pumpAndSettle();

      final lines =
          container.read(receiptFormControllerProvider).draftLines;
      expect(lines.length, 1);
      expect(lines[0].itemId, seeded.item.id);
      expect(lines[0].unitId, seeded.kiloId);
      expect(lines[0].quantity, 1.0);
      expect(lines[0].priceCents, 250);
      expect(lines[0].itemName, 'Γάλα');
      expect(lines[0].unitAbbreviation, 'κιλ');
      // Το search επέστρεψε σε IDLE — έτοιμο για επόμενο είδος.
      expect(
        container.read(itemSearchControllerProvider).value?.selectedItem,
        isNull,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('S3: χωρίς default → κενό dropdown · χειροκίνητη επιλογή '
        'μέσω show-all', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seed(db, withDefaultUnit: false);
      await pumpAt(tester, seeded.item, db);

      expect(textOf(tester, AppStrings.fieldUnit), isEmpty);
      expect(addEnabled(tester), isFalse);

      // Εστίαση → show-all (Δ1) → επιλογή «Τεμάχιο».
      await tester.tap(find.byWidget(fieldByLabel(tester, AppStrings.fieldUnit)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Τεμάχιο'));
      await tester.pumpAndSettle();

      expect(textOf(tester, AppStrings.fieldUnit), 'Τεμάχιο');
      expect(textOf(tester, AppStrings.fieldQuantity), '1',
          reason: 'Prefill στην πρώτη επιλογή (Δ8)');
      expect(find.text('τεμ'), findsOneWidget);

      await tester.enterText(
        find.byWidget(fieldByLabel(tester, AppStrings.fieldQuantity)),
        '3',
      );
      await tester.enterText(
        find.byWidget(fieldByLabel(tester, AppStrings.fieldPrice)),
        '1,20',
      );
      await tester.pumpAndSettle();
      expect(addEnabled(tester), isTrue);

      await tester.tap(
        find.widgetWithText(FilledButton, AppStrings.addReceiptLine),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(UnitQuantityPriceSection)),
      );
      final lines =
          container.read(receiptFormControllerProvider).draftLines;
      expect(lines.length, 1);
      expect(lines[0].unitId, seeded.pieceId);
      expect(lines[0].quantity, 3.0);
      expect(lines[0].priceCents, 120);
      expect(tester.takeException(), isNull);
    });

    testWidgets('S4: δεκαδική ποσότητα + integer-only μονάδα → περικοπή + '
        'ειδοποίηση (§2.2:218)', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seed(db); // default = Κιλό (δεκαδική)
      await pumpAt(tester, seeded.item, db);

      await tester.enterText(
        find.byWidget(fieldByLabel(tester, AppStrings.fieldQuantity)),
        '2,5',
      );
      await tester.pumpAndSettle();

      // Αλλαγή σε Τεμάχιο (integer-only): το πεδίο δείχνει «Κιλό» (prefill,
      // `_selectedLabel` guard — όπως στο SA4) → πληκτρολόγηση φιλτράρει.
      await tester.enterText(
        find.byWidget(fieldByLabel(tester, AppStrings.fieldUnit)),
        'τεμ',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Τεμάχιο'));
      await tester.pumpAndSettle();

      expect(textOf(tester, AppStrings.fieldQuantity), '2',
          reason: 'Αυτόματη περικοπή στο ακέραιο μέρος');
      expect(find.text(AppStrings.quantityTruncatedForUnit), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('S5: validation — τιμή «0» ή κενή ποσότητα → Add ανενεργό',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seed(db);
      await pumpAt(tester, seeded.item, db);

      await tester.enterText(
        find.byWidget(fieldByLabel(tester, AppStrings.fieldQuantity)),
        '1',
      );
      await tester.enterText(
        find.byWidget(fieldByLabel(tester, AppStrings.fieldPrice)),
        '0',
      );
      await tester.pumpAndSettle();
      expect(addEnabled(tester), isFalse,
          reason: 'Τιμή 0 → κάτω από το αποκλειστικό όριο');

      await tester.enterText(
        find.byWidget(fieldByLabel(tester, AppStrings.fieldQuantity)),
        '',
      );
      await tester.enterText(
        find.byWidget(fieldByLabel(tester, AppStrings.fieldPrice)),
        '2,50',
      );
      await tester.pumpAndSettle();
      expect(addEnabled(tester), isFalse, reason: 'Κενή ποσότητα → άκυρη');
      expect(tester.takeException(), isNull);
    });
  });
}
