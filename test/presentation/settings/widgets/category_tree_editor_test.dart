/// Widget tests — `CategoryTreeEditor` (§2.3 / Φάση 4 Βήμα 4).
///
/// Κενό/δεδομένα/nesting · πύλη (greyed + tooltip σε μπλοκαρισμένη) ·
/// delete → confirm → snackbar · rename integration · error + Επανάληψη ·
/// responsive + dark. In-memory βάση (Α1 εξέλιξη — DB override).
library;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_messages.dart';
import 'package:times/core/constants/app_errors.dart';
import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/receipt_dao.dart';
import 'package:times/data/local/daos/receipt_line_dao.dart';
import 'package:times/data/local/daos/supplier_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/repositories/category_repository_impl.dart';
import 'package:times/presentation/settings/widgets/category_tree_editor.dart';
import 'package:times/presentation/settings/widgets/category_edit_dialog.dart';

import '../../../data/local/helpers/in_memory_db.dart';

/// DAO double με σπασμένο stream — error-path του tree.
class _FailingStreamCategoryDao extends CategoryDao {
  _FailingStreamCategoryDao(super.db);

  @override
  Stream<List<Category>> watchAll() =>
      Stream.error(SqliteException(extendedResultCode: 1, message: 'test'));
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = inMemoryDb();
  });

  tearDown(() async => await db.close());

  Widget wrap({ThemeData? theme}) {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: theme,
        home: const Scaffold(body: CategoryTreeEditor()),
      ),
    );
  }

  Future<void> pumpEditor(WidgetTester tester, {ThemeData? theme}) async {
    await tester.pumpWidget(wrap(theme: theme));
    await tester.pumpAndSettle();
  }

  Future<int> seedCategoryWithSub() async {
    final catId = await db
        .into(db.categories)
        .insert(CategoriesCompanion.insert(name: 'ΤΡΟΦΙΜΑ'));
    await db
        .into(db.subCategories)
        .insert(SubCategoriesCompanion.insert(categoryId: catId, name: 'Γάλα'));
    return catId;
  }

  Future<void> seedLineInUse(int itemId) async {
    final unitId = await UnitDao(
      db,
    ).insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
    final supplierId = await SupplierDao(db).insert(name: 'Μάρκος');
    final receiptId = await ReceiptDao(
      db,
    ).insert(date: DateTime(2026, 1, 1), supplierId: supplierId);
    await ReceiptLineDao(db).insert(
      receiptId: receiptId,
      itemId: itemId,
      unitId: unitId,
      quantity: 1,
      priceCents: 100,
    );
  }

  group('CategoryTreeEditor', () {
    testWidgets('κενό δέντρο → empty + κουμπί προσθήκης', (tester) async {
      await pumpEditor(tester);
      expect(find.text(AppStrings.categoriesEmpty), findsOneWidget);
      expect(find.text(AppStrings.addNewCategory), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('δεδομένα + nesting (expand → υποκατηγορία)', (tester) async {
      await seedCategoryWithSub();
      await pumpEditor(tester);
      expect(find.text('ΤΡΟΦΙΜΑ'), findsOneWidget);
      // Κλειστό tile — η υποκατηγορία δεν φαίνεται ακόμα.
      expect(find.text('Γάλα'), findsNothing);
      await tester.tap(find.text('ΤΡΟΦΙΜΑ'));
      await tester.pumpAndSettle();
      expect(find.text('Γάλα'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('καθαρή γραμμή → ενεργή διαγραφή (confirm + Ακύρωση)',
        (tester) async {
      await seedCategoryWithSub();
      await pumpEditor(tester);
      // Μοναδικό delete icon (1 κατηγορία) — ενεργό.
      final deleteBtn = find.byTooltip(AppStrings.deleteAction);
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();
      // Cascade confirm με count (0 είδη — κενή υποκατηγορία).
      expect(
        find.text(AppMessages.deleteCategoryConfirm('ΤΡΟΦΙΜΑ', 0)),
        findsOneWidget,
      );
      await tester.tap(find.text(AppMessages.confirmDialogCancel));
      await tester.pumpAndSettle();
      expect(find.text('ΤΡΟΦΙΜΑ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('μπλοκαρισμένη → greyed + tooltip με πλήθος', (tester) async {
      final catId = await seedCategoryWithSub();
      final subs = await (db.select(
        db.subCategories,
      )..where((t) => t.categoryId.equals(catId))).get();
      final itemId = await ItemDao(
        db,
      ).insert(subCategoryId: subs.single.id, name: 'Γάλα φρέσκο');
      await seedLineInUse(itemId);
      await pumpEditor(tester);

      // Το tooltip της μπλοκαρισμένης φέρει το in-use πλήθος (όχι «περιέχει»).
      expect(
        find.byTooltip(AppMessages.itemsInUseTooltip(1)),
        findsOneWidget,
      );
      expect(
        find.byTooltip(AppMessages.itemCountTooltip(1)),
        findsNothing,
      );
      // Tap στο ανενεργό → καμία ενέργεια, κανένα confirm.
      await tester.tap(find.byTooltip(AppMessages.itemsInUseTooltip(1)));
      await tester.pumpAndSettle();
      expect(find.textContaining('Διαγραφή κατηγορίας'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    // ΣΗΜ.: το submit-through-UI (tap «Αποθήκευση» → async rename σε
    // background isolate + snackbar + settle) κολλάει το FakeAsync του
    // WidgetTester — το submit καλύπτεται από το dialog test (pop trimmed)
    // + το controller test (rename logic) + το delete test (confirm flow).
    // Εδώ ελέγχεται το wiring: το edit ανοίγει dialog με prefill το όνομα.
    testWidgets('rename wiring: edit → dialog με prefill', (tester) async {
      await seedCategoryWithSub();
      await pumpEditor(tester);
      await tester.tap(find.byTooltip(AppStrings.editAction).first);
      await tester.pumpAndSettle();
      expect(find.byType(CategoryEditDialog), findsOneWidget);
      // Prefill: το πεδίο του dialog φέρει το τρέχον όνομα (το δέντρο το
      // δείχνει επίσης — γι' αυτό έλεγχος controller, όχι find.text).
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'ΤΡΟΦΙΜΑ',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('error upstream → loadDataFailed + Επανάληψη', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            categoryRepositoryProvider.overrideWithValue(
              CategoryRepositoryImpl(_FailingStreamCategoryDao(db)),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CategoryTreeEditor()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Το hasError-priority του tree (Βήμα 3) δείχνει σφάλμα, όχι loading.
      expect(find.text(AppErrors.loadDataFailed), findsOneWidget);
      expect(find.text(AppStrings.retryButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mobile 320px — κανένα overflow', (tester) async {
      await seedCategoryWithSub();
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpEditor(tester);
      await tester.tap(find.text('ΤΡΟΦΙΜΑ'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark: αποδίδεται σωστά', (tester) async {
      await seedCategoryWithSub();
      await pumpEditor(tester, theme: AppTheme.dark);
      expect(find.text('ΤΡΟΦΙΜΑ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
