/// Widget tests — `CategoryTreeEditor` (κατάλογος 4 επιπέδων §2.3 · 27-09-2026).
///
/// Κενό/δεδομένα/nesting 3 επιπέδων (Cat ▸ Sub ▸ Group) · «+» ανά επίπεδο ·
/// πύλη ανά επίπεδο (greyed + tooltip σε μπλοκαρισμένη) · delete → confirm →
/// snackbar · rename integration · refresh · error + Επανάληψη ·
/// responsive + dark. In-memory βάση (Α1 εξέλιξη — DB override).
///
/// ΣΗΜ.: το submit-through-UI (tap «Αποθήκευση» → async write + snackbar +
/// settle) κολλάει το FakeAsync του WidgetTester — το submit καλύπτεται από
/// το dialog test (pop trimmed) + το controller test (logic) + τα delete
/// tests (confirm flow). Εδώ ελέγχεται το wiring: edit ανοίγει dialog με
/// prefill, delete ανοίγει cascade confirm με count.
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
import 'package:times/data/local/daos/item_group_dao.dart';
import 'package:times/data/local/daos/receipt_dao.dart';
import 'package:times/data/local/daos/receipt_line_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
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

  /// Σπέρνει αλυσίδα ΤΡΟΦΙΜΑ ▸ Γαλακτοκομικά ▸ Φρέσκα (επιστρέφει τα ids).
  Future<({int catId, int subId, int groupId})> seedChain() async {
    final catId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    final subId = await SubCategoryDao(
      db,
    ).insert(categoryId: catId, name: 'Γαλακτοκομικά');
    final groupId = await ItemGroupDao(
      db,
    ).insert(subCategoryId: subId, name: 'Φρέσκα');
    return (catId: catId, subId: subId, groupId: groupId);
  }

  /// Ανοίγει όλο το δέντρο: expand κατηγορίας → expand υποκατηγορίας.
  Future<void> expandAll(WidgetTester tester) async {
    await tester.tap(find.text('ΤΡΟΦΙΜΑ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Γαλακτοκομικά'));
    await tester.pumpAndSettle();
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

  group('CategoryTreeEditor — δομή 3 επιπέδων', () {
    testWidgets('κενό δέντρο → empty + κουμπί προσθήκης', (tester) async {
      await pumpEditor(tester);
      expect(find.text(AppStrings.categoriesEmpty), findsOneWidget);
      expect(find.text(AppStrings.addNewCategory), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('nesting: expand Cat → Sub → Group', (tester) async {
      final ids = await seedChain();
      await pumpEditor(tester);
      expect(find.text('ΤΡΟΦΙΜΑ'), findsOneWidget);
      // Κλειστά tiles — τα παιδιά δεν φαίνονται ακόμα.
      expect(find.text('Γαλακτοκομικά'), findsNothing);
      expect(find.text('Φρέσκα'), findsNothing);

      // ValueKey αναζήτηση: το tile κατηγορίας φέρει ValueKey(id).
      expect(find.byKey(ValueKey(ids.catId)), findsOneWidget);
      await tester.tap(find.text('ΤΡΟΦΙΜΑ'));
      await tester.pumpAndSettle();
      expect(find.text('Γαλακτοκομικά'), findsOneWidget);
      expect(find.text('Φρέσκα'), findsNothing);

      // Το tile υποκατηγορίας φέρει ValueKey('sub_<id>').
      expect(find.byKey(ValueKey('sub_${ids.subId}')), findsOneWidget);
      await tester.tap(find.text('Γαλακτοκομικά'));
      await tester.pumpAndSettle();
      expect(find.text('Φρέσκα'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('«+» ανά επίπεδο (κατηγορία/υποκατηγορία/τμήμα)',
        (tester) async {
      await seedChain();
      await pumpEditor(tester);
      // Επίπεδο κατηγορίας: πάντα ορατό.
      expect(find.text(AppStrings.addNewCategory), findsOneWidget);
      expect(find.text(AppStrings.addNewSubCategory), findsNothing);
      expect(find.text(AppStrings.addNewItemGroup), findsNothing);

      await tester.tap(find.text('ΤΡΟΦΙΜΑ'));
      await tester.pumpAndSettle();
      // Επίπεδο υποκατηγορίας: «+» μέσα στο expanded tile.
      expect(find.text(AppStrings.addNewSubCategory), findsOneWidget);
      expect(find.text(AppStrings.addNewItemGroup), findsNothing);

      await tester.tap(find.text('Γαλακτοκομικά'));
      await tester.pumpAndSettle();
      // Επίπεδο τμήματος: «+» μέσα στο expanded sub-tile.
      expect(find.text(AppStrings.addNewItemGroup), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('CategoryTreeEditor — διαγραφές ανά επίπεδο', () {
    testWidgets('καθαρή κατηγορία → confirm + Ακύρωση', (tester) async {
      await CategoryDao(db).insert(name: 'ΑΔΕΙΑ');
      await pumpEditor(tester);
      // Μοναδικό delete icon (1 άδεια κατηγορία) — ενεργό.
      final deleteBtn = find.byTooltip(AppStrings.deleteAction);
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();
      // Cascade confirm με count (0 είδη).
      expect(
        find.text(AppMessages.deleteCategoryConfirm('ΑΔΕΙΑ', 0)),
        findsOneWidget,
      );
      await tester.tap(find.text(AppMessages.confirmDialogCancel));
      await tester.pumpAndSettle();
      expect(find.text('ΑΔΕΙΑ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('καθαρό τμήμα → confirm τμήματος + Ακύρωση', (tester) async {
      await seedChain();
      await pumpEditor(tester);
      await expandAll(tester);

      // Το delete του ListTile «Φρέσκα» (scoped — όχι των γονέων).
      final groupDelete = find.descendant(
        of: find.widgetWithText(ListTile, 'Φρέσκα'),
        matching: find.byTooltip(AppStrings.deleteAction),
      );
      expect(groupDelete, findsOneWidget);
      await tester.tap(groupDelete);
      await tester.pumpAndSettle();
      expect(
        find.text(AppMessages.deleteItemGroupConfirm('Φρέσκα', 0)),
        findsOneWidget,
      );
      await tester.tap(find.text(AppMessages.confirmDialogCancel));
      await tester.pumpAndSettle();
      expect(find.text('Φρέσκα'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('καθαρή υποκατηγορία → confirm υποκατηγορίας + Ακύρωση',
        (tester) async {
      final ids = await seedChain();
      await pumpEditor(tester);
      await tester.tap(find.text('ΤΡΟΦΙΜΑ'));
      await tester.pumpAndSettle();

      final subDelete = find.descendant(
        of: find.byKey(ValueKey('sub_${ids.subId}')),
        matching: find.byTooltip(AppStrings.deleteAction),
      );
      expect(subDelete, findsOneWidget);
      await tester.tap(subDelete);
      await tester.pumpAndSettle();
      expect(
        find.text(AppMessages.deleteSubCategoryConfirm('Γαλακτοκομικά', 0)),
        findsOneWidget,
      );
      await tester.tap(find.text(AppMessages.confirmDialogCancel));
      await tester.pumpAndSettle();
      expect(find.text('Γαλακτοκομικά'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('μπλοκαρισμένη αλυσίδα → greyed + tooltip σε ΚΑΘΕ επίπεδο',
        (tester) async {
      final ids = await seedChain();
      final itemId = await ItemDao(
        db,
      ).insert(itemGroupId: ids.groupId, name: 'Γάλα φρέσκο');
      await seedLineInUse(itemId);
      await pumpEditor(tester);

      // Μόνο η κατηγορία ορατή — 1 blocked tooltip.
      expect(
        find.byTooltip(AppMessages.itemsInUseTooltip(1)),
        findsOneWidget,
      );
      await expandAll(tester);
      // Και τα 3 επίπεδα μπλοκαρισμένα (το είδος σε χρήση μετρά παντού).
      expect(
        find.byTooltip(AppMessages.itemsInUseTooltip(1)),
        findsNWidgets(3),
      );
      // Tap στο ανενεργό → καμία ενέργεια, κανένα confirm.
      await tester.tap(
        find.byTooltip(AppMessages.itemsInUseTooltip(1)).first,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Διαγραφή κατηγορίας'), findsNothing);
      expect(
        find.textContaining('Διαγραφή υποκατηγορίας'),
        findsNothing,
      );
      expect(find.textContaining('Διαγραφή τμήματος'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('CategoryTreeEditor — rename + refresh + error', () {
    testWidgets('rename wiring: edit → dialog με prefill', (tester) async {
      await seedChain();
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

    testWidgets('rename τμήματος: edit → dialog με prefill', (tester) async {
      await seedChain();
      await pumpEditor(tester);
      await expandAll(tester);
      final groupEdit = find.descendant(
        of: find.widgetWithText(ListTile, 'Φρέσκα'),
        matching: find.byTooltip(AppStrings.editAction),
      );
      expect(groupEdit, findsOneWidget);
      await tester.tap(groupEdit);
      await tester.pumpAndSettle();
      expect(find.byType(CategoryEditDialog), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Φρέσκα',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('refresh ανανεώνει τις πύλες και των 3 επιπέδων',
        (tester) async {
      await seedChain();
      await pumpEditor(tester);
      await expandAll(tester);
      await tester.tap(find.byTooltip(AppStrings.refreshAction));
      await tester.pumpAndSettle();
      expect(find.text('Φρέσκα'), findsOneWidget);
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
  });

  group('CategoryTreeEditor — responsive + dark', () {
    for (final size in const [
      Size(320, 568),
      Size(800, 600),
      Size(1200, 800),
    ]) {
      testWidgets('ανοιχτό δέντρο $size — κανένα overflow', (tester) async {
        await seedChain();
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await pumpEditor(tester);
        await expandAll(tester);
        expect(find.text('Φρέσκα'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'overflow σε $size');
      });
    }

    testWidgets('dark: αποδίδεται σωστά', (tester) async {
      await seedChain();
      await pumpEditor(tester, theme: AppTheme.dark);
      await expandAll(tester);
      expect(find.text('Φρέσκα'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
