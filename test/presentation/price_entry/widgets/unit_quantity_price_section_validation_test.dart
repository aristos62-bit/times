/// Widget tests — inline validation του `UnitQuantityPriceSection`
/// (§2.2 · Φάση 3 Βήμα 6δ). Νέο αρχείο (το section test έχει ήδη 359 γρ.).
///
/// Καλύπτει: σφάλματα τιμής/ποσότητας (0, πάνω από όριο) · καμία ειδοποίηση
/// σε κενό πεδίο ή αριθμό «υπό πληκτρολόγηση» («5,») · hint μονάδας όταν
/// το είδος δεν έχει default (κλειδωμένο 28-09-2026 — δεν επιλέγεται) ·
/// `unitAllowsDecimal` στη draft γραμμή · δεκαδικά σε κλειδωμένη
/// integer-only μονάδα → σφάλμα · responsive
/// (3 μεγέθη) και dark theme χωρίς overflow. Πραγματική in-memory Drift βάση
/// (μοτίβο Βημάτων 4/5).
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_errors.dart';
import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/item_group_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/presentation/price_entry/controllers/receipt_form_controller.dart';
import 'package:times/presentation/price_entry/widgets/unit_quantity_price_section.dart';

import '../../../data/local/helpers/in_memory_db.dart';

/// Shared wrap: ProviderScope (in-memory DB) + MaterialApp ελληνικά + Scaffold.
Widget wrap(Item item, AppDatabase db, {ThemeData? theme}) {
  return ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
    child: MaterialApp(
      theme: theme,
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
  Future<void> pumpAt(
      WidgetTester tester,
      Item item,
      AppDatabase db, {
        Size size = const Size(800, 600),
        ThemeData? theme,
      }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap(item, db, theme: theme));
    await tester.pumpAndSettle();
  }

  /// Βρίσκει το TextField με το δοσμένο label (unit/qty/price).
  TextField fieldByLabel(WidgetTester tester, String label) {
    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      if (field.decoration?.labelText == label) return field;
    }
    fail('Δεν βρέθηκε TextField με label «$label»');
  }

  String textOf(WidgetTester tester, String label) =>
      fieldByLabel(tester, label).controller!.text;

  /// Πληκτρολογεί [text] στο πεδίο με label [label] και κάνει settle.
  Future<void> enter(WidgetTester tester, String label, String text) async {
    await tester.enterText(find.byWidget(fieldByLabel(tester, label)), text);
    await tester.pumpAndSettle();
  }

  bool addEnabled(WidgetTester tester) => tester
      .widget<FilledButton>(
    find.widgetWithText(FilledButton, AppStrings.addReceiptLine),
  )
      .enabled;

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(
        tester.element(find.byType(UnitQuantityPriceSection)),
      );

  /// Seed: κατηγορία → υποκατηγορία → τμήμα → μονάδες → είδος.
  /// Αλυσίδα 4 επιπέδων (§3 · 27-09-2026). Επιστρέφει record
  /// `{ item, kiloId, pieceId, groupId }` (το groupId για είδη με άλλη
  /// κλειδωμένη μονάδα — π.χ. Τεμάχιο).
  Future<({Item item, int kiloId, int pieceId, int groupId})> seed(
      AppDatabase db, {
        bool withDefaultUnit = true,
      }) async {
    final categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    final subId = await SubCategoryDao(db)
        .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
    final groupId = await ItemGroupDao(db)
        .insert(subCategoryId: subId, name: 'Φρέσκα');
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
      itemGroupId: groupId,
      name: 'Γάλα',
      defaultUnitId: withDefaultUnit ? kiloId : null,
    );
    final item = await ItemDao(db).getById(itemId);
    return (item: item!, kiloId: kiloId, pieceId: pieceId, groupId: groupId);
  }

  group('UnitQuantityPriceSection — validation (Βήμα 6δ)', () {
    testWidgets('V1: τιμή «0» → priceMustBePositive + Add ανενεργό · '
        'διόρθωση → μήνυμα φεύγει', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seed(db);
      await pumpAt(tester, seeded.item, db);
      expect(find.text(AppErrors.priceMustBePositive), findsNothing);

      await enter(tester, AppStrings.fieldPrice, '0');
      expect(find.text(AppErrors.priceMustBePositive), findsOneWidget);
      expect(addEnabled(tester), isFalse);

      await enter(tester, AppStrings.fieldPrice, '2,50');
      expect(find.text(AppErrors.priceMustBePositive), findsNothing);
      expect(addEnabled(tester), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('V2: κενά πεδία → κανένα μήνυμα σφάλματος', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seed(db);
      await pumpAt(tester, seeded.item, db);

      await enter(tester, AppStrings.fieldQuantity, '');

      for (final message in [
        AppErrors.priceMustBePositive,
        AppErrors.priceTooLarge,
        AppErrors.quantityMustBePositive,
        AppErrors.quantityTooLarge,
      ]) {
        expect(find.text(message), findsNothing, reason: message);
      }
      expect(addEnabled(tester), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('V3: «5,» (υπό πληκτρολόγηση) → κανένα σφάλμα · «5,5» → '
        'Add ενεργό', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seed(db);
      await pumpAt(tester, seeded.item, db);

      await enter(tester, AppStrings.fieldPrice, '5,');
      expect(find.text(AppErrors.priceMustBePositive), findsNothing);
      expect(find.text(AppErrors.priceTooLarge), findsNothing);
      expect(addEnabled(tester), isFalse);

      await enter(tester, AppStrings.fieldPrice, '5,5');
      expect(addEnabled(tester), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('V4: τιμή πάνω από το όριο → priceTooLarge', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seed(db);
      await pumpAt(tester, seeded.item, db);

      await enter(tester, AppStrings.fieldPrice, '100000');

      expect(find.text(AppErrors.priceTooLarge), findsOneWidget);
      expect(addEnabled(tester), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('V5: ποσότητα «0» → quantityMustBePositive · σβήσιμο → '
        'μήνυμα φεύγει', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seed(db);
      await pumpAt(tester, seeded.item, db);

      await enter(tester, AppStrings.fieldQuantity, '0');
      expect(find.text(AppErrors.quantityMustBePositive), findsOneWidget);

      await enter(tester, AppStrings.fieldQuantity, '');
      expect(find.text(AppErrors.quantityMustBePositive), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('V6: ποσότητα πάνω από το όριο → quantityTooLarge',
            (tester) async {
          final db = inMemoryDb();
          addTearDown(db.close);
          final seeded = await seed(db);
          await pumpAt(tester, seeded.item, db);

          await enter(tester, AppStrings.fieldQuantity, '1000001');
          await enter(tester, AppStrings.fieldPrice, '2,50');

          expect(find.text(AppErrors.quantityTooLarge), findsOneWidget);
          expect(addEnabled(tester), isFalse);
          expect(tester.takeException(), isNull);
        });

    testWidgets('V7: χωρίς μονάδα + τιμή → hint unitRequired · παραμένει '
        '(μονάδα μόνο από Ρυθμίσεις)', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seed(db, withDefaultUnit: false);
      await pumpAt(tester, seeded.item, db);

      await enter(tester, AppStrings.fieldPrice, '2,50');
      expect(find.text(AppErrors.unitRequired), findsOneWidget);
      expect(addEnabled(tester), isFalse);

      // Κλείδωμα (28-09-2026): δεν υπάρχει πεδίο μονάδας για επιλογή —
      // το hint παραμένει και το Add μένει ανενεργό.
      final unitFields = tester
          .widgetList<TextField>(find.byType(TextField))
          .where((f) => f.decoration?.labelText == AppStrings.fieldUnit);
      expect(unitFields, isEmpty, reason: 'Καμία επεξεργάσιμη μονάδα');
      expect(find.text(AppErrors.unitRequired), findsOneWidget);
      expect(addEnabled(tester), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('V8: χωρίς μονάδα και χωρίς τιμή → κανένα hint',
            (tester) async {
          final db = inMemoryDb();
          addTearDown(db.close);
          final seeded = await seed(db, withDefaultUnit: false);
          await pumpAt(tester, seeded.item, db);

          expect(find.text(AppErrors.unitRequired), findsNothing);
          expect(tester.takeException(), isNull);
        });

    testWidgets('V9a: μονάδα με δεκαδικά (Κιλό) → draft unitAllowsDecimal '
        'true', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seed(db);
      await pumpAt(tester, seeded.item, db);

      await enter(tester, AppStrings.fieldPrice, '2,50');
      await tester.tap(
        find.widgetWithText(FilledButton, AppStrings.addReceiptLine),
      );
      await tester.pumpAndSettle();

      final lines =
          containerOf(tester).read(receiptFormControllerProvider).draftLines;
      expect(lines, hasLength(1));
      expect(lines[0].unitAllowsDecimal, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('V9b: κλειδωμένη integer-only μονάδα (Τεμάχιο) → draft '
        'unitAllowsDecimal false', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seed(db);
      // Είδος με κλειδωμένο Τεμάχιο (αλλαγή μόνο από Ρυθμίσεις).
      final pieceItemId = await ItemDao(db).insert(
        itemGroupId: seeded.groupId,
        name: 'Ψωμί',
        defaultUnitId: seeded.pieceId,
      );
      final pieceItem = await ItemDao(db).getById(pieceItemId);
      await pumpAt(tester, pieceItem!, db);

      expect(find.text('${AppStrings.fieldUnit}: Τεμάχιο'), findsOneWidget);
      await enter(tester, AppStrings.fieldQuantity, '3');
      await enter(tester, AppStrings.fieldPrice, '1,20');
      await tester.tap(
        find.widgetWithText(FilledButton, AppStrings.addReceiptLine),
      );
      await tester.pumpAndSettle();

      final lines =
          containerOf(tester).read(receiptFormControllerProvider).draftLines;
      expect(lines, hasLength(1));
      expect(lines[0].unitId, seeded.pieceId);
      expect(lines[0].unitAllowsDecimal, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('V10: «0,5» σε κλειδωμένη integer-only μονάδα → '
        'ο formatter κόβει το κόμμα («05»), χωρίς περικοπή', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seed(db);
      // Είδος με κλειδωμένο Τεμάχιο (αλλαγή μόνο από Ρυθμίσεις).
      final pieceItemId = await ItemDao(db).insert(
        itemGroupId: seeded.groupId,
        name: 'Ψωμί',
        defaultUnitId: seeded.pieceId,
      );
      final pieceItem = await ItemDao(db).getById(pieceItemId);
      await pumpAt(tester, pieceItem!, db);

      await enter(tester, AppStrings.fieldQuantity, '0,5');

      // Κλείδωμα (28-09-2026): καμία αλλαγή μονάδας → καμία περικοπή·
      // ο formatter (allowDecimal=false) κόβει το κόμμα («05» = 5, έγκυρο).
      expect(textOf(tester, AppStrings.fieldQuantity), '05');
      expect(find.text(AppStrings.quantityTruncatedForUnit), findsNothing);
      expect(find.text(AppErrors.quantityMustBePositive), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('V13: χωρίς μονάδα + τιμή → unitRequired · παραμένει '
        '(28-09-2026: κανένα πεδίο μονάδας)', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seed(db, withDefaultUnit: false);
      await pumpAt(tester, seeded.item, db);

      await enter(tester, AppStrings.fieldPrice, '2,50');
      expect(find.text(AppErrors.unitRequired), findsOneWidget);
      expect(addEnabled(tester), isFalse);

      // Κλείδωμα (28-09-2026): δεν υπάρχει πεδίο μονάδας για πληκτρολόγηση —
      // το hint παραμένει και το Add μένει ανενεργό.
      final unitFields = tester
          .widgetList<TextField>(find.byType(TextField))
          .where((f) => f.decoration?.labelText == AppStrings.fieldUnit);
      expect(unitFields, isEmpty, reason: 'Καμία επεξεργάσιμη μονάδα');
      expect(find.text(AppErrors.unitRequired), findsOneWidget);
      expect(addEnabled(tester), isFalse,
          reason: 'Καμία μονάδα επιλεγμένη — το Add παραμένει ανενεργό');
      expect(tester.takeException(), isNull);
    });
  });

  group('UnitQuantityPriceSection — συνολική τιμή (24-09-2026)', () {
    testWidgets('T1: 0,350 κιλ + σύνολο 12 € → μοναδιαία 3429 + snapshot',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seed(db); // default = Κιλό
      await pumpAt(tester, seeded.item, db);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await enter(tester, AppStrings.fieldQuantity, '0,350');
      await enter(tester, AppStrings.fieldPrice, '12');
      await tester.tap(
        find.widgetWithText(FilledButton, AppStrings.addReceiptLine),
      );
      await tester.pumpAndSettle();

      final lines =
          containerOf(tester).read(receiptFormControllerProvider).draftLines;
      expect(lines, hasLength(1));
      // 1200 / 0.35 = 3428.57 → 3429 μοναδιαία, snapshot το 1200.
      // (Η προβολή συνόλου ελέγχεται στο draft_lines_list_test.)
      expect(lines[0].priceCents, 3429);
      expect(lines[0].enteredTotalCents, 1200);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T2: toggle OFF (default) → μοναδιαία, χωρίς snapshot',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seed(db);
      await pumpAt(tester, seeded.item, db);

      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
      await enter(tester, AppStrings.fieldPrice, '2,50');
      await tester.tap(
        find.widgetWithText(FilledButton, AppStrings.addReceiptLine),
      );
      await tester.pumpAndSettle();

      final lines =
          containerOf(tester).read(receiptFormControllerProvider).draftLines;
      expect(lines, hasLength(1));
      expect(lines[0].priceCents, 250);
      expect(lines[0].enteredTotalCents, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T3: παραγόμενη πάνω από το όριο → priceTooLarge + Add ανενεργό',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seed(db);
      await pumpAt(tester, seeded.item, db);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await enter(tester, AppStrings.fieldQuantity, '0,001');
      await enter(tester, AppStrings.fieldPrice, '99999,99');

      // 9999999 / 0.001 → υπέρβαση maxPriceCents.
      expect(find.text(AppErrors.priceTooLarge), findsOneWidget);
      expect(addEnabled(tester), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T4: παραγόμενη μηδενική → priceMustBePositive + Add ανενεργό',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seed(db);
      await pumpAt(tester, seeded.item, db);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await enter(tester, AppStrings.fieldQuantity, '1000000');
      await enter(tester, AppStrings.fieldPrice, '0,01');

      // 1 / 1000000 → round 0.
      expect(find.text(AppErrors.priceMustBePositive), findsOneWidget);
      expect(addEnabled(tester), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T5: φέτα 0,634 + μικτά 6,91 + έκπτωση 1,08 → 1090/170/691',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seed(db);
      await pumpAt(tester, seeded.item, db);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await enter(tester, AppStrings.fieldQuantity, '0,634');
      await enter(tester, AppStrings.fieldPrice, '6,91');
      await enter(tester, AppStrings.fieldDiscount, '1,08');
      expect(addEnabled(tester), isTrue);
      await tester.tap(
        find.widgetWithText(FilledButton, AppStrings.addReceiptLine),
      );
      await tester.pumpAndSettle();

      final lines =
          containerOf(tester).read(receiptFormControllerProvider).draftLines;
      expect(lines, hasLength(1));
      // 691 / 0.634 = 1089.9 → 1090 μικτά· 108 / 0.634 = 170.3 → 170 έκπτωση·
      // stored (1090−170)×0.634 = 583 (5,83 € = 6,91 − 1,08 ακριβώς).
      expect(lines[0].priceCents, 1090);
      expect(lines[0].discountCents, 170);
      expect(lines[0].enteredTotalCents, 691);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T6: έκπτωση πάνω από το σύνολο → discountTooLarge',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seed(db);
      await pumpAt(tester, seeded.item, db);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await enter(tester, AppStrings.fieldQuantity, '1');
      await enter(tester, AppStrings.fieldPrice, '5');
      await enter(tester, AppStrings.fieldDiscount, '6');

      expect(find.text(AppErrors.discountTooLarge), findsOneWidget);
      expect(addEnabled(tester), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T7: κενή έκπτωση σε total → 0 (όπως πριν)',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seed(db);
      await pumpAt(tester, seeded.item, db);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await enter(tester, AppStrings.fieldQuantity, '1');
      await enter(tester, AppStrings.fieldPrice, '5');
      await tester.tap(
        find.widgetWithText(FilledButton, AppStrings.addReceiptLine),
      );
      await tester.pumpAndSettle();

      final lines =
          containerOf(tester).read(receiptFormControllerProvider).draftLines;
      expect(lines, hasLength(1));
      expect(lines[0].discountCents, 0);
      expect(lines[0].enteredTotalCents, 500);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T8: toggle κρατά το κείμενο έκπτωσης (επανερμηνεία)',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seed(db);
      await pumpAt(tester, seeded.item, db);

      await enter(tester, AppStrings.fieldDiscount, '1,08');
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      // Το πεδίο μένει ορατό σε total-mode με το ίδιο κείμενο (νέο νόημα:
      // έκπτωση συνόλου — βλ. T5).
      expect(textOf(tester, AppStrings.fieldDiscount), '1,08');
      expect(tester.takeException(), isNull);
    });
  });

  group('UnitQuantityPriceSection — responsive + dark (Βήμα 6δ, §1.4)', () {
    for (final size in const [
      Size(320, 568),
      Size(800, 600),
      Size(1200, 800),
    ]) {
      testWidgets(
          'V11: σφάλματα ορατά — κανένα overflow σε '
              '${size.width.toInt()}×${size.height.toInt()}', (tester) async {
        final db = inMemoryDb();
        addTearDown(db.close);
        final seeded = await seed(db);
        await pumpAt(tester, seeded.item, db, size: size);

        await enter(tester, AppStrings.fieldQuantity, '0');
        await enter(tester, AppStrings.fieldPrice, '0');

        expect(find.text(AppErrors.quantityMustBePositive), findsOneWidget);
        expect(find.text(AppErrors.priceMustBePositive), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('V12: dark theme — σφάλματα ορατά χωρίς exception',
            (tester) async {
          final db = inMemoryDb();
          addTearDown(db.close);
          final seeded = await seed(db);
          await pumpAt(tester, seeded.item, db, theme: AppTheme.dark);

          await enter(tester, AppStrings.fieldPrice, '0');

          expect(find.text(AppErrors.priceMustBePositive), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
  });
}