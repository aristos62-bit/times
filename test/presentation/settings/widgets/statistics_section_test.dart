/// Widget tests — `StatisticsSection` (§2.3 · 28-09-2026 — 1η ανάλυση).
///
/// Idle (dropdown + hint, όχι DB) · search-flow επιλογή (in-memory DB +
/// debounce) · empty/error+retry/data+totals · export Excel/PDF (fake picker
/// + snackbars) · period selector · responsive 3 μεγέθη · dark · semantics.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:times/core/constants/app_constants.dart';
import 'package:times/core/constants/app_errors.dart';
import 'package:times/core/constants/app_messages.dart';
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
import 'package:times/data/models/chart_totals.dart';
import 'package:times/data/providers/backup_file_picker.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/providers/settings_providers.dart';
import 'package:times/data/providers/stream_providers.dart';
import 'package:times/presentation/settings/widgets/statistics_section.dart';
import 'package:times/presentation/settings/widgets/statistics_table.dart';

import '../../../data/local/helpers/in_memory_db.dart';

/// Fake picker — καταγράφει (όχι δίσκος).
class FakeStatsPicker implements BackupFilePicker {
  String? savedName;
  List<int>? savedBytes;
  bool cancel = false;

  @override
  Future<bool> saveBytes({
    required String fileName,
    required List<int> bytes,
  }) async {
    if (cancel) return false;
    savedName = fileName;
    savedBytes = bytes;
    return true;
  }

  @override
  Future<String?> pickSingleFile() => throw UnimplementedError();
}

void main() {
  late SharedPreferences prefs;
  late FakeStatsPicker picker;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    picker = FakeStatsPicker();
  });

  /// Seed: αλυσίδα + Κιλό + Γάλα (default) + Μάρκος + γραμμή.
  /// [lineDate] default = σήμερα (εντός τρέχοντος μήνα).
  Future<({int itemId, int kiloId})> seedDb(
    AppDatabase db, {
    DateTime? lineDate,
  }) async {
    final kiloId = await UnitDao(db).insert(
      name: 'Κιλό',
      abbreviation: 'κιλ',
      allowsDecimal: true,
    );
    final categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    final subId = await SubCategoryDao(db)
        .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
    final groupId =
        await ItemGroupDao(db).insert(subCategoryId: subId, name: 'Φρέσκα');
    final itemId = await ItemDao(db).insert(
      itemGroupId: groupId,
      name: 'Γάλα',
      defaultUnitId: kiloId,
    );
    final supplierId = await SupplierDao(db).insert(name: 'Μάρκος');
    final receiptId = await ReceiptDao(db).insert(
      date: lineDate ?? DateTime.now(),
      supplierId: supplierId,
    );
    await ReceiptLineDao(db).insert(
      receiptId: receiptId,
      itemId: itemId,
      unitId: kiloId,
      quantity: 2,
      priceCents: 250,
      discountCents: 50,
    );
    return (itemId: itemId, kiloId: kiloId);
  }

  /// Wrap: prefs + picker (+ προαιρετικά DB) · MaterialApp ελληνικά.
  Widget wrap({AppDatabase? db, ThemeData? theme}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        backupFilePickerProvider.overrideWithValue(picker),
        if (db != null) appDatabaseProvider.overrideWithValue(db),
      ],
      child: MaterialApp(
        theme: theme,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('el')],
        locale: const Locale('el'),
        home: const Scaffold(body: StatisticsSection()),
      ),
    );
  }

  Future<void> pumpSized(
    WidgetTester tester,
    Widget widget,
    Size size, {
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  /// Πεδίο αναζήτησης (το DropdownMenu περιόδου έχει δικό του TextField).
  Finder searchField() => find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == AppStrings.fieldItemName,
      );

  /// Ανοίγει την 1η ανάλυση από το μενού (tap γραμμής).
  Future<void> openLedger(WidgetTester tester) async {
    await tester.tap(find.text(AppStrings.statsLedgerTitle));
    await tester.pumpAndSettle();
  }

  /// Πλήρης ροή επιλογής μέσω αναζήτησης (DB + debounce).
  Future<void> selectViaSearch(WidgetTester tester) async {
    await tester.enterText(searchField(), 'γαλ');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Γάλα'));
    await tester.pumpAndSettle();
  }

  group('StatisticsSection', () {
    testWidgets('μενού: 1 γραμμή («Ιστορικό αγορών είδους») + περιγραφή',
        (tester) async {
      await pumpSized(tester, wrap(), const Size(800, 600));
      expect(find.text(AppStrings.statsLedgerTitle), findsOneWidget);
      expect(find.text(AppStrings.statsLedgerDescription), findsOneWidget);
      // Detail κρυμμένο (ούτε dropdown ούτε πίνακας).
      expect(find.text(AppStrings.trendItemSearchHint), findsNothing);
      expect(find.byType(StatisticsTable), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('πίσω → επιστροφή στο μενού', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedDb(db);
      await pumpSized(tester, wrap(db: db), const Size(800, 600));
      await openLedger(tester);
      expect(find.text(AppStrings.trendItemSearchHint), findsOneWidget);

      await tester.tap(find.byTooltip(AppStrings.statsBackAction));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.statsLedgerTitle), findsOneWidget);
      expect(find.text(AppStrings.trendItemSearchHint), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('detail idle: dropdown + hint, όχι πίνακας', (tester) async {
      await pumpSized(tester, wrap(), const Size(800, 600));
      await openLedger(tester);
      expect(find.text(AppStrings.trendItemSearchHint), findsOneWidget);
      expect(find.text(AppStrings.trendNoItemSelected), findsOneWidget);
      expect(find.byType(StatisticsTable), findsNothing);
      expect(find.text(AppStrings.statsExportExcelAction), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('search → επιλογή → banner + πίνακας + totals', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedDb(db);
      await pumpSized(tester, wrap(db: db), const Size(800, 600));
      await openLedger(tester);
      await selectViaSearch(tester);

      expect(find.text('Γάλα'), findsOneWidget);
      expect(find.byType(StatisticsTable), findsOneWidget);
      expect(find.text('Μάρκος'), findsOneWidget);
      // (250−50)×2 = 400 → footer «18... » — εδώ 1 γραμμή: «4,00 €».
      expect(find.text('Σύνολο (1)'), findsOneWidget);
      expect(find.text(AppStrings.statsExportExcelAction), findsOneWidget);
      expect(find.text(AppStrings.statsExportPdfAction), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('«Αλλαγή» → αποεπιλογή (idle ξανά)', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedDb(db);
      await pumpSized(tester, wrap(db: db), const Size(800, 600));
      await openLedger(tester);
      await selectViaSearch(tester);
      expect(find.byType(StatisticsTable), findsOneWidget);

      await tester.tap(find.text(AppStrings.changeItem));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.trendNoItemSelected), findsOneWidget);
      expect(find.byType(StatisticsTable), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('είδος χωρίς γραμμές → noPricesForPeriod', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      // Μόνο κατάλογος (χωρίς γραμμές).
      final kiloId = await UnitDao(db).insert(
        name: 'Κιλό',
        abbreviation: 'κιλ',
        allowsDecimal: true,
      );
      final categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
      final subId = await SubCategoryDao(db)
          .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
      final groupId =
          await ItemGroupDao(db).insert(subCategoryId: subId, name: 'Φρέσκα');
      await ItemDao(db).insert(
        itemGroupId: groupId,
        name: 'Γάλα',
        defaultUnitId: kiloId,
      );
      await pumpSized(tester, wrap(db: db), const Size(800, 600));
      await openLedger(tester);
      await selectViaSearch(tester);

      expect(find.text(AppStrings.noPricesForPeriod), findsOneWidget);
      expect(find.byType(StatisticsTable), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ledger error → loadDataFailed + Επανάληψη', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      // Σταθερή ημέρα (όχι flake μεσονυχτίου) + γραμμή στον ίδιο μήνα.
      final today = DateTime(2026, 9, 15);
      final seeded = await seedDb(db, lineDate: DateTime(2026, 9, 9));
      final query = (
        itemId: seeded.itemId,
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 10, 1),
      );
      await pumpSized(
        tester,
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            backupFilePickerProvider.overrideWithValue(picker),
            appDatabaseProvider.overrideWithValue(db),
            todayProvider.overrideWithBuild((ref, self) => today),
            itemLedgerProvider(query)
                .overrideWith((ref) => Stream.error(Exception('test'))),
          ],
          child: MaterialApp(
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [Locale('el')],
            locale: const Locale('el'),
            home: const Scaffold(body: StatisticsSection()),
          ),
        ),
        const Size(800, 600),
      );
      await openLedger(tester);
      await selectViaSearch(tester);

      expect(find.text(AppErrors.loadDataFailed), findsOneWidget);
      expect(find.text(AppStrings.retryButton), findsOneWidget);
      await tester.tap(find.text(AppStrings.retryButton));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('export Excel → .xlsx + success snackbar', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedDb(db);
      await pumpSized(tester, wrap(db: db), const Size(800, 600));
      await openLedger(tester);
      await selectViaSearch(tester);

      await tester.tap(find.text(AppStrings.statsExportExcelAction));
      await tester.pumpAndSettle();
      expect(picker.savedName, endsWith('.xlsx'));
      expect(picker.savedBytes, isNotNull);
      expect(find.text(AppMessages.statsExported), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('export PDF → .pdf + success snackbar', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedDb(db);
      await pumpSized(tester, wrap(db: db), const Size(800, 600));
      await openLedger(tester);
      await selectViaSearch(tester);

      await tester.tap(find.text(AppStrings.statsExportPdfAction));
      await tester.pumpAndSettle();
      expect(picker.savedName, endsWith('.pdf'));
      expect(picker.savedBytes, isNotNull);
      expect(find.text(AppMessages.statsExported), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('cancel picker → no-op (χωρίς snackbar)', (tester) async {
      picker.cancel = true;
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedDb(db);
      await pumpSized(tester, wrap(db: db), const Size(800, 600));
      await openLedger(tester);
      await selectViaSearch(tester);

      await tester.tap(find.text(AppStrings.statsExportExcelAction));
      await tester.pumpAndSettle();
      expect(picker.savedBytes, isNull);
      expect(find.text(AppMessages.statsExported), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('selector: Έτος → πίνακας παραμένει', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedDb(db);
      await pumpSized(tester, wrap(db: db), const Size(800, 600));
      await openLedger(tester);
      await selectViaSearch(tester);
      expect(find.byType(StatisticsTable), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_drop_down).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.periodYear).last);
      await tester.pumpAndSettle();
      // Η γραμμή (τρέχον έτος) παραμένει ορατή.
      expect(find.text('Μάρκος'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('responsive 320/800/1200 — κανένα overflow', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedDb(db);
      for (final size in const [
        Size(320, 568),
        Size(800, 600),
        Size(1200, 800),
      ]) {
        await pumpSized(tester, wrap(db: db), size);
        await openLedger(tester);
      await selectViaSearch(tester);
        expect(tester.takeException(), isNull, reason: 'overflow σε $size');
        // Επαναφορά σε idle για το επόμενο μέγεθος (τοπικό state).
        await tester.tap(find.text(AppStrings.changeItem));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('dark + semantics (§1.5/§1.6)', (tester) async {
      final handle = tester.ensureSemantics();
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedDb(db);
      await pumpSized(
        tester,
        wrap(db: db, theme: AppTheme.dark),
        const Size(800, 600),
      );
      await openLedger(tester);
      await selectViaSearch(tester);
      expect(find.byType(StatisticsTable), findsOneWidget);
      expect(
        find.bySemanticsLabel(AppStrings.titleStatisticsSection),
        findsWidgets,
      );
      handle.dispose();
      expect(tester.takeException(), isNull);
    });
  });

  group('StatisticsSection — αγορές (2η ανάλυση · 29-09-2026)', () {
    /// Seed 2 ειδών/προμηθευτών/κατηγοριών + γραμμές (τρέχων μήνας).
    Future<void> seedTwo(WidgetTester tester, AppDatabase db) async {
      final kiloId = await UnitDao(db).insert(
        name: 'Κιλό',
        abbreviation: 'κιλ',
        allowsDecimal: true,
      );
      final pieceId = await UnitDao(db).insert(
        name: 'Τεμάχιο',
        abbreviation: 'τεμ',
      );
      final foodId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
      final dairyId = await SubCategoryDao(db)
          .insert(categoryId: foodId, name: 'Γαλακτοκομικά');
      final freshId =
          await ItemGroupDao(db).insert(subCategoryId: dairyId, name: 'Φρέσκα');
      final milkId = await ItemDao(db).insert(
        itemGroupId: freshId,
        name: 'Γάλα',
        defaultUnitId: kiloId,
      );
      final bakeryId = await CategoryDao(db).insert(name: 'ΑΡΤΟΣΚΕΥΑΣΜΑΤΑ');
      final breadSubId = await SubCategoryDao(db)
          .insert(categoryId: bakeryId, name: 'Ψωμιά');
      final breadGroupId = await ItemGroupDao(db)
          .insert(subCategoryId: breadSubId, name: 'Φραντζόλες');
      final breadId = await ItemDao(db).insert(
        itemGroupId: breadGroupId,
        name: 'Ψωμί',
        defaultUnitId: pieceId,
      );
      final markosId = await SupplierDao(db).insert(name: 'Μάρκος');
      final ermisId = await SupplierDao(db).insert(name: 'Ερμής');
      final now = DateTime.now();
      for (final (itemId, unitId, supplierId) in [
        (milkId, kiloId, markosId),
        (breadId, pieceId, ermisId),
      ]) {
        final receiptId = await ReceiptDao(db).insert(
          date: now,
          supplierId: supplierId,
        );
        await ReceiptLineDao(db).insert(
          receiptId: receiptId,
          itemId: itemId,
          unitId: unitId,
          quantity: 1,
          priceCents: 100,
        );
      }
    }

    /// Ανοίγει τη 2η ανάλυση από το μενού.
    Future<void> openPurchases(WidgetTester tester) async {
      await tester.tap(find.text(AppStrings.statsPurchasesTitle));
      await tester.pumpAndSettle();
    }

    testWidgets('μενού: 2 γραμμές · back από detail', (tester) async {
      // Canned streams (χωρίς DB — το detail κάνει watch με το άνοιγμα).
      const today = [2026, 9, 15];
      final query = (
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 10, 1),
        sort: PurchasesSort.dateAsc,
      );
      await pumpSized(
        tester,
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            backupFilePickerProvider.overrideWithValue(picker),
            todayProvider.overrideWithBuild(
              (ref, self) => DateTime(today[0], today[1], today[2]),
            ),
            unitsStreamProvider.overrideWith(
              (ref) => Stream.value(const <Unit>[]),
            ),
            periodPurchasesProvider(query).overrideWith(
              (ref) => Stream.value((rows: const [], truncated: false)),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [Locale('el')],
            locale: const Locale('el'),
            home: const Scaffold(body: StatisticsSection()),
          ),
        ),
        const Size(800, 600),
      );
      expect(find.text(AppStrings.statsLedgerTitle), findsOneWidget);
      expect(find.text(AppStrings.statsPurchasesTitle), findsOneWidget);
      expect(
        find.text(AppStrings.statsPurchasesDescription),
        findsOneWidget,
      );
      await openPurchases(tester);
      expect(find.text(AppStrings.statsSortLabel), findsWidgets);
      await tester.tap(find.byTooltip(AppStrings.statsBackAction));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.statsPurchasesTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('πίνακας + footer + export κουμπιά', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedTwo(tester, db);
      await pumpSized(tester, wrap(db: db), const Size(800, 600));
      await openPurchases(tester);

      expect(find.text('Γάλα'), findsOneWidget);
      expect(find.text('Ψωμί'), findsOneWidget);
      expect(find.text('Κιλό'), findsOneWidget);
      expect(find.text('Τεμάχιο'), findsOneWidget);
      // Σπάσιμο ανά μονάδα στη γραμμή Σύνολο (29-09).
      expect(find.text('Σύνολο: (Κιλ: 1 / Τεμ: 1)'), findsOneWidget);
      expect(find.text(AppStrings.statsExportExcelAction), findsOneWidget);
      expect(find.text(AppStrings.statsExportPdfAction), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sort: Προμηθευτής → πίνακας ξαναχτίζεται', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedTwo(tester, db);
      await pumpSized(tester, wrap(db: db), const Size(800, 600));
      await openPurchases(tester);
      expect(find.text('Μάρκος'), findsOneWidget);

      // Άνοιγμα sort menu από το εμφανιζόμενο κείμενο (Text, όχι το
      // readOnly EditableText — pattern DropdownMenu).
      await tester.tap(
        find
            .byWidgetPredicate(
              (widget) =>
                  widget is Text &&
                  widget.data == AppStrings.statsSortDateAsc,
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.statsSortSupplier).last);
      await tester.pumpAndSettle();
      // Ερμής < Μάρκος — και οι δύο παρόντες, χωρίς crash.
      expect(find.text('Ερμής'), findsOneWidget);
      expect(find.text('Μάρκος'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('truncated → σημείωση (canned)', (tester) async {
      const today = [2026, 9, 15];
      final query = (
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 10, 1),
        sort: PurchasesSort.dateAsc,
      );
      await pumpSized(
        tester,
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            backupFilePickerProvider.overrideWithValue(picker),
            todayProvider.overrideWithBuild(
              (ref, self) => DateTime(today[0], today[1], today[2]),
            ),
            periodPurchasesProvider(query).overrideWith(
              (ref) => Stream.value((
                rows: [
                  (
                    receiptId: 1,
                    date: DateTime(2026, 9, 9),
                    itemName: 'Γάλα',
                    categoryName: 'ΤΡΟΦΙΜΑ',
                    supplierName: 'Μάρκος',
                    quantity: 1.0,
                    unitId: 1,
                    unitAbbreviation: 'κιλ',
                    priceCents: 100,
                    discountCents: 0,
                  ),
                ],
                truncated: true,
              )),
            ),
            unitsStreamProvider.overrideWith(
              (ref) => Stream.value([
                Unit(
                  id: 1,
                  name: 'Κιλό',
                  abbreviation: 'κιλ',
                  allowsDecimal: true,
                ),
              ]),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [Locale('el')],
            locale: const Locale('el'),
            home: const Scaffold(body: StatisticsSection()),
          ),
        ),
        const Size(800, 600),
      );
      await openPurchases(tester);
      expect(
        find.text(AppMessages.statsTruncatedNote(AppConstants.statsTableMaxRows)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('export Excel → _synola.xlsx + snackbar', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedTwo(tester, db);
      await pumpSized(tester, wrap(db: db), const Size(800, 600));
      await openPurchases(tester);

      await tester.tap(find.text(AppStrings.statsExportExcelAction));
      await tester.pumpAndSettle();
      expect(picker.savedName, endsWith('_synola.xlsx'));
      expect(find.text(AppMessages.statsExported), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('export PDF → _synola.pdf + snackbar', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedTwo(tester, db);
      await pumpSized(tester, wrap(db: db), const Size(800, 600));
      await openPurchases(tester);

      await tester.tap(find.text(AppStrings.statsExportPdfAction));
      await tester.pumpAndSettle();
      expect(picker.savedName, endsWith('_synola.pdf'));
      expect(find.text(AppMessages.statsExported), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('StatisticsSection — ομαδοποιημένη (3η ανάλυση · 29-09-2026)', () {
    /// Seed 2 ειδών/κατηγοριών + γραμμές (τρέχων μήνας).
    Future<void> seedGrouped(AppDatabase db) async {
      final kiloId = await UnitDao(db).insert(
        name: 'Κιλό',
        abbreviation: 'κιλ',
        allowsDecimal: true,
      );
      final foodId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
      final dairyId = await SubCategoryDao(db)
          .insert(categoryId: foodId, name: 'Γαλακτοκομικά');
      final freshId =
          await ItemGroupDao(db).insert(subCategoryId: dairyId, name: 'Φρέσκα');
      final milkId = await ItemDao(db).insert(
        itemGroupId: freshId,
        name: 'Γάλα',
        defaultUnitId: kiloId,
      );
      final markosId = await SupplierDao(db).insert(name: 'Μάρκος');
      final now = DateTime.now();
      final receiptId = await ReceiptDao(db).insert(
        date: now,
        supplierId: markosId,
      );
      await ReceiptLineDao(db).insert(
        receiptId: receiptId,
        itemId: milkId,
        unitId: kiloId,
        quantity: 1,
        priceCents: 100,
      );
    }

    /// Ανοίγει την 3η ανάλυση από το μενού.
    Future<void> openGrouped(WidgetTester tester) async {
      await tester.tap(find.text(AppStrings.statsGroupedTitle));
      await tester.pumpAndSettle();
    }

    testWidgets('μενού: 3 γραμμές', (tester) async {
      await pumpSized(tester, wrap(), const Size(800, 600));
      expect(find.text(AppStrings.statsLedgerTitle), findsOneWidget);
      expect(find.text(AppStrings.statsPurchasesTitle), findsOneWidget);
      expect(find.text(AppStrings.statsGroupedTitle), findsOneWidget);
      expect(
        find.text(AppStrings.statsGroupedDescription),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('προεπισκόπηση → dialog με σύνολο + ομάδες', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedGrouped(db);
      await pumpSized(tester, wrap(db: db), const Size(800, 600));
      await openGrouped(tester);

      await tester.tap(find.text(AppStrings.statsPreviewAction));
      await tester.pumpAndSettle();
      // Dialog: τίτλος ανάλυσης (×2 — header detail από πίσω + dialog).
      expect(find.text(AppStrings.statsGroupedTitle), findsNWidgets(2));
      expect(find.text('ΤΡΟΦΙΜΑ'), findsWidgets);
      expect(find.text(AppMessages.confirmDialogCancel), findsOneWidget);
      await tester.tap(find.text(AppMessages.confirmDialogCancel));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.statsExportExcelAction), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('group selector: Προμηθευτής → ξαναχτίζεται', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedGrouped(db);
      await pumpSized(tester, wrap(db: db), const Size(800, 600));
      await openGrouped(tester);

      await tester.tap(
        find
            .byWidgetPredicate(
              (widget) =>
                  widget is Text &&
                  widget.data == AppStrings.statsGroupCategory,
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.statsGroupSupplier).last);
      await tester.pumpAndSettle();
      // Κουμπί προεπισκόπησης παρόν (ροή OK).
      expect(find.text(AppStrings.statsPreviewAction), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('export από dialog → _grouped.xlsx + snackbar',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await seedGrouped(db);
      await pumpSized(tester, wrap(db: db), const Size(800, 600));
      await openGrouped(tester);

      await tester.tap(find.text(AppStrings.statsPreviewAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.statsExportExcelAction));
      await tester.pumpAndSettle();
      expect(picker.savedName, endsWith('_grouped.xlsx'));
      expect(find.text(AppMessages.statsExported), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
