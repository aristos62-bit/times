/// Widget tests — actions `RecentReceiptsList` (Φάση Α · 24-09-2026):
/// μολύβι (φόρτωση στη φόρμα) + κόκκινος κάδος (διαγραφή με confirm).
///
/// Ζωντανή in-memory βάση (όχι stream-stub): η λίστα βλέπει τον πραγματικό
/// `recentReceiptsStreamProvider` → επαληθεύεται και το auto-refresh μετά
/// τη διαγραφή. Riverpod `listen+completer` όπου χρειάζεται (όχι `.future`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_messages.dart';
import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/presentation/price_entry/controllers/receipt_form_controller.dart';
import 'package:times/presentation/price_entry/state/receipt_form_state.dart';
import 'package:times/presentation/price_entry/widgets/recent_receipts_list.dart';

import '../../../data/local/helpers/in_memory_db.dart';

void main() {
  /// Seed αλυσίδας (unit → category → sub → item → supplier) + 1 απόδειξη
  /// 1 γραμμής. Επιστρέφει (receiptId, supplierId, itemId, unitId).
  Future<({int receiptId, int supplierId, int itemId, int unitId})>
  seedOneReceipt(ProviderContainer container) async {
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
    final receiptId = await container
        .read(receiptRepositoryProvider)
        .insertReceiptWithLines(
      date: DateTime(2026, 1, 1),
      supplierId: supplierId,
      lines: [
        (itemId: itemId, unitId: unitId, quantity: 2, priceCents: 199),
      ],
    );
    return (
      receiptId: receiptId,
      supplierId: supplierId,
      itemId: itemId,
      unitId: unitId
    );
  }

  /// Pump λίστας με ζωντανή βάση. Επιστρέφει το container για assertions.
  Future<ProviderContainer> pumpList(WidgetTester tester) async {
    final db = inMemoryDb();
    addTearDown(db.close);
    final container = ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await seedOneReceipt(container);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const Scaffold(body: RecentReceiptsList()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  void setSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('RecentReceiptsList actions (Φάση Α)', () {
    testWidgets('γραμμή: σύνολο + μολύβι + κόκκινος κάδος', (tester) async {
      await pumpList(tester);

      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.text('3,98 €'), findsOneWidget);
      // Semantics/tooltips (§1.6).
      expect(find.byTooltip(AppStrings.editAction), findsOneWidget);
      expect(find.byTooltip(AppStrings.deleteAction), findsOneWidget);
    });

    testWidgets('διαγραφή ροή: confirm → Ναι → receiptDeleted + άδεια λίστα',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final container = ProviderContainer.test(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      await seedOneReceipt(container);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: RecentReceiptsList()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppMessages.receiptNumber(1)), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      // Confirm dialog (destructive) με όνομα προμηθευτή.
      expect(
        find.text(AppMessages.deleteReceiptConfirm(1, 'Μάρκος')),
        findsOneWidget,
      );

      await tester.tap(find.text(AppMessages.confirmDialogConfirm));
      await tester.pumpAndSettle();

      expect(find.text(AppMessages.receiptDeleted), findsOneWidget);
      expect(find.text(AppStrings.recentReceiptsEmpty), findsOneWidget);
      // One-shot future (όχι watch-stream — κολλάει στο FakeAsync).
      expect(
        await container.read(receiptRepositoryProvider).getById(1),
        isNull,
      );
    });

    testWidgets('διαγραφή ροή: Ακύρωση → καμία αλλαγή', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final container = ProviderContainer.test(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      final seeded = await seedOneReceipt(container);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: RecentReceiptsList()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text(AppMessages.confirmDialogCancel));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(AppMessages.receiptNumber(1)), findsOneWidget);
      // One-shot future (όχι watch-stream — κολλάει στο FakeAsync).
      expect(
        await container.read(receiptRepositoryProvider).getById(seeded.receiptId),
        isNotNull,
      );
    });

    testWidgets('μολύβι: φορτώνει τη φόρμα (editingId) χωρίς snackbar',
        (tester) async {
      final container = await pumpList(tester);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(
        container.read(receiptFormControllerProvider).editingId,
        1,
      );
      expect(
        container.read(receiptFormControllerProvider).draftLines.length,
        1,
      );
      expect(
        container.read(receiptFormControllerProvider).supplier?.name,
        'Μάρκος',
      );
    });

    testWidgets('μολύβι με drafts: guard απόρριψης (κρατά ή φορτώνει)',
        (tester) async {
      final container = await pumpList(tester);
      // Ημιτελής καταχώρηση άλλου περιεχομένου.
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

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      expect(
        find.text(AppMessages.editDiscardDraftsConfirm),
        findsOneWidget,
      );

      // Ακύρωση → drafts μένουν, editingId null.
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

      // Ναι → φόρτωση (τα drafts αντικαθίστανται).
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppMessages.confirmDialogConfirm));
      await tester.pumpAndSettle();
      expect(
        container.read(receiptFormControllerProvider).editingId,
        1,
      );
      expect(
        container
            .read(receiptFormControllerProvider)
            .draftLines
            .single
            .itemName,
        'Γάλα',
      );
    });

    testWidgets('responsive με actions: 360 · 800 · 1280 χωρίς overflow',
        (tester) async {
      for (final size in const [Size(360, 740), Size(800, 1024), Size(1280, 800)]) {
        setSize(tester, size);
        await pumpList(tester);
        expect(tester.takeException(), isNull, reason: 'overflow στο $size');
        expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      }
    });

    testWidgets('dark mode με actions: ίδιο περιεχόμενο', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final container = ProviderContainer.test(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      await seedOneReceipt(container);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.dark,
            home: const Scaffold(body: RecentReceiptsList()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });
}
