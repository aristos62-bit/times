/// Widget tests — prefill τελευταίας τιμής/έκπτωσης (§2.2).
///
/// Είδος με ιστορικό → τιμή+έκπτωση από την τελευταία γραμμή
/// (`latestReceiptLineProvider`): ΜΟΝΟ σε unit-mode, match μονάδας, κενά
/// πεδία, χωρίς πληκτρολόγηση (ατομικά και τα δύο ή τίποτα).
/// Πραγματική in-memory Drift βάση (μοτίβο section_test)· P3 με
/// Completer-πύλη για ντετερμινιστικό timing του typed-guard.
/// Νέο αρχείο: το section_test θα ξεπερνούσε τις 500 γρ. (κανόνας 7 —
/// τα test αρχεία είναι ανεξάρτητα, χωρίς κοινόχρηστα private helpers).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/receipt_dao.dart';
import 'package:times/data/local/daos/receipt_line_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/supplier_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/providers/stream_providers.dart';
import 'package:times/presentation/price_entry/widgets/unit_quantity_price_section.dart';

import '../../data/local/helpers/in_memory_db.dart';

/// Shared wrap: ProviderScope (in-memory DB) + MaterialApp ελληνικά +
/// Scaffold · `ValueKey(item.id)` όπως η σελίδα (Δ8).
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
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap(item, db, theme: theme));
    await tester.pumpAndSettle();
  }

  TextField fieldByLabel(WidgetTester tester, String label) {
    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      if (field.decoration?.labelText == label) return field;
    }
    fail('Δεν βρέθηκε TextField με label «$label»');
  }

  String textOf(WidgetTester tester, String label) =>
      fieldByLabel(tester, label).controller!.text;

  /// Seed καταλόγου: κατηγορία → υποκατηγορία → Τεμάχιο/Κιλό → είδος
  /// (default Κιλό). Επιστρέφει record `{ item, kiloId, pieceId }`.
  Future<({Item item, int kiloId, int pieceId})> seedCatalog(
    AppDatabase db,
  ) async {
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
      defaultUnitId: kiloId,
    );
    final item = await ItemDao(db).getById(itemId);
    return (item: item!, kiloId: kiloId, pieceId: pieceId);
  }

  /// Γραμμή ιστορικού: προμηθευτής + απόδειξη (2026-01-01) + γραμμή
  /// (2 × (2,50−0,50) = 4,00 € default).
  Future<void> seedLine(
    AppDatabase db,
    Item item, {
    required int lineUnitId,
    int priceCents = 250,
    int discountCents = 50,
  }) async {
    final supplierId = await SupplierDao(db).insert(name: 'Μάρκος');
    final receiptId = await ReceiptDao(db)
        .insert(date: DateTime(2026, 1, 1), supplierId: supplierId);
    await ReceiptLineDao(db).insert(
      receiptId: receiptId,
      itemId: item.id,
      unitId: lineUnitId,
      quantity: 2,
      priceCents: priceCents,
      discountCents: discountCents,
    );
  }

  group('Line prefill (§2.2)', () {
    testWidgets('P1: ιστορικό → prefill τιμής + έκπτωσης', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seedCatalog(db);
      await seedLine(db, seeded.item, lineUnitId: seeded.kiloId);
      await pumpAt(tester, seeded.item, db);

      expect(textOf(tester, AppStrings.fieldPrice), '2,50');
      expect(textOf(tester, AppStrings.fieldDiscount), '0,50');
      expect(tester.takeException(), isNull);
    });

    testWidgets('P2: τελευταία γραμμή σε άλλη μονάδα → ΚΑΝΕΝΑ prefill',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seedCatalog(db);
      await seedLine(db, seeded.item, lineUnitId: seeded.pieceId);
      await pumpAt(tester, seeded.item, db);

      // Η ενότητα πρότεινε Κιλό (default) ≠ Τεμάχιο ιστορικού.
      expect(textOf(tester, AppStrings.fieldUnit), 'Κιλό');
      expect(textOf(tester, AppStrings.fieldPrice), isEmpty);
      expect(textOf(tester, AppStrings.fieldDiscount), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('P3: πληκτρολόγηση πριν την άφιξη → το prefill ΔΕΝ γράφει '
        'πάνω της', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seedCatalog(db);
      await seedLine(db, seeded.item, lineUnitId: seeded.kiloId);
      final gate = Completer<ReceiptLine?>();
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // Override με Completer-πύλη: το prefetch εκκρεμεί μέχρι το complete.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            latestReceiptLineProvider.overrideWith(
              (ref, itemId) => gate.future,
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [Locale('el')],
            locale: const Locale('el'),
            home: Scaffold(
              body: UnitQuantityPriceSection(
                key: ValueKey(seeded.item.id),
                item: seeded.item,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Πληκτρολόγηση ΕΝΩ το prefill εκκρεμεί → _userTyped.
      await tester.enterText(
        find.byWidget(fieldByLabel(tester, AppStrings.fieldPrice)),
        '9,99',
      );
      gate.complete(
        ReceiptLine(
          id: 1,
          receiptId: 1,
          itemId: seeded.item.id,
          unitId: seeded.kiloId,
          quantity: 2,
          priceCents: 250,
          discountCents: 50,
          lineTotalCents: 400,
        ),
      );
      await tester.pumpAndSettle();

      expect(textOf(tester, AppStrings.fieldPrice), '9,99');
      expect(textOf(tester, AppStrings.fieldDiscount), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('P4: total-mode → ΚΑΝΕΝΑ prefill (άλλη σημασία Τιμής)',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seedCatalog(db);
      await seedLine(db, seeded.item, lineUnitId: seeded.kiloId);
      final gate = Completer<ReceiptLine?>();
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            latestReceiptLineProvider.overrideWith(
              (ref, itemId) => gate.future,
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [Locale('el')],
            locale: const Locale('el'),
            home: Scaffold(
              body: UnitQuantityPriceSection(
                key: ValueKey(seeded.item.id),
                item: seeded.item,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Μετάβαση σε total-mode ΕΝΩ το prefill εκκρεμεί.
      await tester.tap(find.text(AppStrings.priceTotalMode));
      await tester.pump();
      gate.complete(
        ReceiptLine(
          id: 1,
          receiptId: 1,
          itemId: seeded.item.id,
          unitId: seeded.kiloId,
          quantity: 2,
          priceCents: 250,
          discountCents: 50,
          lineTotalCents: 400,
        ),
      );
      await tester.pumpAndSettle();

      expect(textOf(tester, AppStrings.fieldPrice), isEmpty);
      // Total-mode με έκπτωση συνόλου (25-09): το πεδίο ΕΙΝΑΙ ορατό αλλά το
      // prefill δεν το γεμίζει (unit-mode μόνο — πύλη `_tryApplyPrefill`).
      expect(find.text(AppStrings.fieldDiscount), findsOneWidget);
      expect(textOf(tester, AppStrings.fieldDiscount), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('P5: είδος χωρίς ιστορικό → κενά πεδία', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seedCatalog(db);
      await pumpAt(tester, seeded.item, db);

      expect(textOf(tester, AppStrings.fieldPrice), isEmpty);
      expect(textOf(tester, AppStrings.fieldDiscount), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('P6: dark theme — prefill ορατό · χωρίς exception (§1.5)',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final seeded = await seedCatalog(db);
      await seedLine(db, seeded.item, lineUnitId: seeded.kiloId);
      await pumpAt(tester, seeded.item, db, theme: AppTheme.dark);

      expect(textOf(tester, AppStrings.fieldPrice), '2,50');
      expect(textOf(tester, AppStrings.fieldDiscount), '0,50');
      expect(tester.takeException(), isNull);
    });
  });
}
