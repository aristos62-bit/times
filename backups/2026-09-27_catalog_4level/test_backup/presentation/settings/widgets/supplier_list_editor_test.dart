/// Widget tests — `SupplierListEditor` (§2.3 / CRUD 24-09-2026).
///
/// Κενό/δεδομένα · προσθήκη/μετονομασία μέσω dialog · πύλη (greyed + tooltip
/// σε μπλοκαρισμένο) · delete → confirm → snackbar · error + Επανάληψη ·
/// responsive + dark. In-memory βάση (Α1 εξέλιξη — DB override).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_errors.dart';
import 'package:times/core/constants/app_messages.dart';
import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/receipt_dao.dart';
import 'package:times/data/local/daos/supplier_dao.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/providers/stream_providers.dart';
import 'package:times/presentation/settings/widgets/supplier_list_editor.dart';

import '../../../data/local/helpers/in_memory_db.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = inMemoryDb();
  });

  tearDown(() async => await db.close());

  Widget wrap({ThemeData? theme, List<dynamic>? extra}) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        ...?extra,
      ],
      child: MaterialApp(
        theme: theme,
        home: const Scaffold(body: SupplierListEditor()),
      ),
    );
  }

  Future<void> pumpEditor(WidgetTester tester, {ThemeData? theme}) async {
    await tester.pumpWidget(wrap(theme: theme));
    await tester.pumpAndSettle();
  }

  Future<int> seedSupplier([String name = 'Μάρκος']) =>
      SupplierDao(db).insert(name: name);

  Future<void> seedReceipt(int supplierId) => ReceiptDao(db).insert(
        date: DateTime(2026, 1, 1),
        supplierId: supplierId,
      );

  /// Συμπληρώνει το dialog ονόματος και πατά επιβεβαίωση.
  Future<void> submitDialog(WidgetTester tester, String text, String confirm) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, confirm));
    await tester.pumpAndSettle();
  }

  group('SupplierListEditor', () {
    testWidgets('κενή λίστα → empty + κουμπί προσθήκης', (tester) async {
      await pumpEditor(tester);
      expect(find.text(AppStrings.suppliersEmpty), findsOneWidget);
      expect(find.text(AppStrings.addNewSupplier), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('δεδομένα → γραμμές με ονόματα', (tester) async {
      await seedSupplier('Μάρκος');
      await seedSupplier('Σκλαβενίτης');
      await pumpEditor(tester);
      expect(find.text('Μάρκος'), findsOneWidget);
      expect(find.text('Σκλαβενίτης'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('προσθήκη → dialog → snackbar + γραμμή', (tester) async {
      await pumpEditor(tester);
      await tester.tap(find.text(AppStrings.addNewSupplier));
      await tester.pumpAndSettle();
      await submitDialog(tester, 'Μάρκος', AppStrings.newItemSave);
      expect(find.text(AppMessages.supplierAdded), findsOneWidget);
      expect(find.text('Μάρκος'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('προσθήκη διπλότυπου → nameExists, χωρίς νέα γραμμή',
        (tester) async {
      await seedSupplier('Μάρκος');
      await pumpEditor(tester);
      await tester.tap(find.text(AppStrings.addNewSupplier));
      await tester.pumpAndSettle();
      await submitDialog(tester, 'μαρκος', AppStrings.newItemSave);
      expect(find.text(AppErrors.nameExists), findsOneWidget);
      // Μία γραμμή (η seed) — κανένα διπλότυπο.
      expect(find.text('Μάρκος'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('μετονομασία → edit → snackbar + νέο όνομα', (tester) async {
      await seedSupplier('Μάρκος');
      await pumpEditor(tester);
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await submitDialog(tester, 'Νέος', AppStrings.saveAction);
      expect(find.text(AppMessages.supplierUpdated), findsOneWidget);
      expect(find.text('Νέος'), findsOneWidget);
      expect(find.text('Μάρκος'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('διαγραφή καθαρού → confirm Ναι → snackbar + φεύγει',
        (tester) async {
      await seedSupplier('Μάρκος');
      await pumpEditor(tester);
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(
        find.text(AppMessages.deleteSupplierConfirm('Μάρκος')),
        findsOneWidget,
      );
      await tester.tap(find.text(AppMessages.confirmDialogConfirm));
      await tester.pumpAndSettle();
      expect(find.text(AppMessages.supplierDeleted), findsOneWidget);
      expect(find.text('Μάρκος'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('διαγραφή → Ακύρωση → γραμμή μένει', (tester) async {
      await seedSupplier('Μάρκος');
      await pumpEditor(tester);
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppMessages.confirmDialogCancel));
      await tester.pumpAndSettle();
      expect(find.text('Μάρκος'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('μπλοκαρισμένος → greyed + tooltip με πλήθος', (tester) async {
      final id = await seedSupplier('Μάρκος');
      await seedReceipt(id);
      await pumpEditor(tester);
      final button = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.delete_outline),
      );
      expect(button.onPressed, isNull);
      expect(
        button.tooltip,
        AppMessages.supplierReceiptsTooltip(1),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('error stream → loadDataFailed + Επανάληψη', (tester) async {
      await tester.pumpWidget(
        wrap(
          extra: [
            suppliersStreamProvider.overrideWith(
              (ref) => Stream.error(const DataLoadException()),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppErrors.loadDataFailed), findsOneWidget);
      expect(find.text(AppStrings.retryButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ανανέωση πυλών → χωρίς exception', (tester) async {
      final id = await seedSupplier('Μάρκος');
      await seedReceipt(id);
      await pumpEditor(tester);
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();
      expect(find.text('Μάρκος'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ─── Responsive §1.4 ────────────────────────────────────────────────
    testWidgets('mobile (320×568) — κανένα overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await seedSupplier('Μάρκος');
      await pumpEditor(tester);
      expect(find.text('Μάρκος'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('desktop (1200×800) — κανένα overflow', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await seedSupplier('Μάρκος');
      await pumpEditor(tester);
      expect(find.text('Μάρκος'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ─── Dark mode §1.5 ─────────────────────────────────────────────────
    testWidgets('dark mode: λίστα ορατή χωρίς exception', (tester) async {
      await seedSupplier('Μάρκος');
      await pumpEditor(tester, theme: AppTheme.dark);
      expect(find.text('Μάρκος'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
