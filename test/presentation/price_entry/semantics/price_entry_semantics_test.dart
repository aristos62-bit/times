/// Widget tests — Semantics στη φόρμα εισαγωγής τιμών (§1.6 DESIGN: «Semantics
/// labels σε όλα τα interactive στοιχεία, ιδίως στη φόρμα εισαγωγής τιμών»).
///
/// Κάλυψη Βήματος 8 — Υποβήμα 4 (semantics gap-fill): τα τρία σημεία με
/// `Semantics(liveRegion: true)` στο lib (dynamic error hints που πρέπει να
/// ανακοινώνονται σε screen readers) + έλεγχος ότι η σελίδα δουλεύει με
/// semantics-enabled χωρίς crash:
///   * `save_receipt_button` — hint `supplierRequired` (γραμμές χωρίς προμηθευτή)
///   * `unit_quantity_price_section` — hint `unitRequired` (τιμή χωρίς μονάδα)
///   * `new_item_flow_dialog` — inline `nameExists` στο «+» (liveRegion)
///   * `PriceEntryPage` — semantics-enabled render χωρίς exception (Α1 override)
/// Όλα πάνω σε πραγματική in-memory Drift βάση όπου χρειάζεται (μοτίβο
/// Βημάτων 4/5). Tests-only: καμία αλλαγή σε `lib/`.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_errors.dart';
import 'package:times/core/constants/app_strings.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/models/receipt_summary.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/providers/stream_providers.dart';
import 'package:times/presentation/price_entry/controllers/receipt_form_controller.dart';
import 'package:times/presentation/price_entry/price_entry_page.dart';
import 'package:times/presentation/price_entry/state/receipt_form_state.dart';
import 'package:times/presentation/price_entry/widgets/new_item_flow_dialog.dart';
import 'package:times/presentation/price_entry/widgets/save_receipt_button.dart';
import 'package:times/presentation/price_entry/widgets/unit_quantity_price_section.dart';

import '../../../data/local/helpers/in_memory_db.dart';

/// Γενικό wrap: ProviderScope (προαιρετικό in-memory DB) + MaterialApp με
/// ελληνικά locale (όπως στο main) + Scaffold.
Widget wrap({AppDatabase? db, required Widget child}) {
  return ProviderScope(
    overrides: [
      if (db != null) appDatabaseProvider.overrideWithValue(db),
    ],
    child: MaterialApp(
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('el')],
      locale: const Locale('el'),
      home: Scaffold(body: child),
    ),
  );
}

/// Θέτει τη θύρα 800×600 (logical, dpr=1) και ενεργοποιεί τα semantics.
/// Επιστρέφει το handle — ο καλών πρέπει να το κλείσει (`dispose`) ΠΡΙΝ το
/// τέλος του test (ο ελεγκτής semantics-handles τρέχει πριν τα tearDowns).
Future<SemanticsHandle> pumpWithSemantics(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final handle = tester.ensureSemantics();
  await tester.pumpWidget(wrap(child: child));
  await tester.pumpAndSettle();
  return handle;
}

/// Η ένδειξη [text] είναι μέσα σε `Semantics(liveRegion: true)`;
bool hasLiveRegion(WidgetTester tester, String text) {
  final node = tester.getSemantics(find.text(text).first);
  expect(node, isNotNull, reason: 'Ενεργά semantics για «$text»');
  return node.getSemanticsData().flagsCollection.isLiveRegion;
}

void main() {
  /// Seed: κατηγορία → υποκατηγορία → μονάδα (Κιλό) → είδος. Επιστρέφει
  /// record `{ item, kiloId }` — default unit προαιρετικό (§2.2 Δ8).
  Future<({Item item, int kiloId})> seedItem(
    AppDatabase db, {
    bool withDefaultUnit = true,
  }) async {
    final categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    final subId = await SubCategoryDao(db)
        .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
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
    return (item: item!, kiloId: kiloId);
  }

  /// Βρίσκει το TextField με το δοσμένο label (unit/qty/price).
  TextField fieldByLabel(WidgetTester tester, String label) {
    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      if (field.decoration?.labelText == label) return field;
    }
    fail('Δεν βρέθηκε TextField με label «$label»');
  }

  group('PriceEntry semantics (§1.6)', () {
    // ─── S1: σελίδα με semantics-enabled ────────────────────────────────────
    testWidgets('S1: PriceEntryPage semantics-enabled — κανένα crash '
        '(Α1 override)', (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          // Α1: read-only λίστα πρόσφατων — κενή ροή (χωρίς DB access).
          recentReceiptsStreamProvider.overrideWith(
            (ref) => Stream.value(const <ReceiptSummary>[]),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('el')],
          locale: const Locale('el'),
          home: MediaQuery(
            data: MediaQueryData(size: const Size(800, 1600)),
            child: const PriceEntryPage(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.titlePriceEntry), findsOneWidget);
      // Το save button έχει δικό του semantics node (button + enabled state).
      expect(
        tester.getSemantics(
          find.widgetWithText(FilledButton, AppStrings.saveReceipt),
        ),
        isNotNull,
      );
      expect(tester.takeException(), isNull);
      handle.dispose();
    });

    // ─── S2: hint προμηθευτή (liveRegion) ───────────────────────────────────
    testWidgets('S2: supplierRequired hint — liveRegion (§1.6)',
        (tester) async {
      final handle = await pumpWithSemantics(tester, const SaveReceiptButton());

      // Γραμμές χωρίς προμηθευτή → hint κάτω από το κουμπί (H2, Βήμα 6ε).
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SaveReceiptButton)),
      );
      container.read(receiptFormControllerProvider.notifier).addDraftLine(
            const DraftReceiptLine(
              itemId: 1,
              unitId: 2,
              quantity: 1.0,
              priceCents: 100,
              itemName: 'Γάλα',
              unitAbbreviation: 'κιλ',
            ),
          );
      await tester.pumpAndSettle();

      expect(find.text(AppErrors.supplierRequired), findsOneWidget);
      expect(hasLiveRegion(tester, AppErrors.supplierRequired), isTrue);
      expect(tester.takeException(), isNull);
      handle.dispose();
    });

    // ─── S3: hint μονάδας (liveRegion) ──────────────────────────────────────
    testWidgets('S3: unitRequired hint — liveRegion (§1.6)',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      // Χωρίς default unit → κενό dropdown → η τιμή χωρίς μονάδα δίνει hint.
      final seeded = await seedItem(db, withDefaultUnit: false);
      final handle = await pumpWithSemantics(
        tester,
        UnitQuantityPriceSection(
          key: ValueKey(seeded.item.id),
          item: seeded.item,
        ),
      );

      await tester.enterText(
        find.byWidget(fieldByLabel(tester, AppStrings.fieldPrice)),
        '1,20',
      );
      await tester.pumpAndSettle();

      expect(find.text(AppErrors.unitRequired), findsOneWidget);
      expect(hasLiveRegion(tester, AppErrors.unitRequired), isTrue);
      expect(tester.takeException(), isNull);
      handle.dispose();
    });

    // ─── S4: inline error dialog (liveRegion) ───────────────────────────────
    testWidgets('S4: dialog nameExists inline error — liveRegion (§1.6)',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');

      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
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
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(NewItemFlowDialog), findsOneWidget);

      // Βήμα 1: πληκτρολόγηση υπάρχουσας κατηγορίας → «+» → duplicate →
      // inline `nameExists` (κανένα snackbar μέσα στο dialog, §2.4).
      final categoryField = find
          .descendant(
            of: find.byType(NewItemFlowDialog),
            matching: find.byType(TextField),
          )
          .first;
      await tester.enterText(categoryField, 'τροφιμα');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('${AppStrings.addNewCategory} "τροφιμα"'));
      // Το duplicate-check τρέχει στο background isolate του drift → δίνει
      // πραγματικό χρόνο μέσω runAsync (idiom item_search_field_test).
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppErrors.nameExists), findsOneWidget);
      expect(hasLiveRegion(tester, AppErrors.nameExists), isTrue);
      expect(tester.takeException(), isNull);
      handle.dispose();
    });
  });
}