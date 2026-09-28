/// Widget tests — `ItemTrendCard` (§2.1 · 28-09-2026 — 6ο γράφημα).
///
/// Idle (dropdown + hint, όχι DB) · επιλογή (banner + γραμμή) · full
/// search-flow (in-memory DB + debounce) · ορφανό · χωρίς μονάδα · states
/// (skeleton/empty/error+retry/data + σημείωση ξένων) · period selector ·
/// responsive 3 μεγέθη · dark · semantics. Canned trend family (override
/// instance — idiom `home_chart_card_test`).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:times/core/constants/app_constants.dart';
import 'package:times/core/constants/app_enums.dart';
import 'package:times/core/constants/app_errors.dart';
import 'package:times/core/constants/app_messages.dart';
import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/item_group_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/models/chart_totals.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/providers/settings_providers.dart';
import 'package:times/data/providers/stream_providers.dart';
import 'package:times/presentation/home/widgets/item_trend_card.dart';
import 'package:times/presentation/home/widgets/item_trend_chart.dart';

import '../../../data/local/helpers/in_memory_db.dart';

/// Σταθερό canned item (χωρίς DB): Γάλα #1, μονάδα #10.
Item cannedItem({int id = 1, int? unitId = 10}) => Item(
      id: id,
      itemGroupId: 1,
      name: 'Γάλα',
      normalizedName: 'γαλα',
      defaultUnitId: unitId,
    );

ItemTrendData sampleData({int others = 0}) => (
      points: [
        (
          date: DateTime(2026, 1, 5),
          netPriceCents: 200,
          quantity: 1.0,
          unitId: 10,
          supplierName: 'Μάρκος',
        ),
        (
          date: DateTime(2026, 1, 20),
          netPriceCents: 300,
          quantity: 2.0,
          unitId: 10,
          supplierName: 'Ερμής',
        ),
      ],
      otherUnitCount: others,
    );

void main() {
  late SharedPreferences prefs;
  final range = (from: DateTime(2026, 1, 1), to: DateTime(2026, 2, 1));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ItemTrendQuery trendQuery() =>
      (itemId: 1, unitId: 10, from: range.from, to: range.to);

  /// Wrap: prefs + items + trend instance (canned) · period recorder.
  Widget wrap({
    List<Item> items = const [],
    ItemTrendData? data,
    Object? trendError,
    bool trendLoading = false,
    List<PeriodType>? periods,
    ThemeData? theme,
  }) {
    final query = trendQuery();
    Stream<ItemTrendData> stream;
    if (trendLoading) {
      stream = StreamController<ItemTrendData>().stream;
    } else if (trendError != null) {
      stream = Stream.error(trendError);
    } else {
      stream = Stream.value(
        data ?? (points: const [], otherUnitCount: 0),
      );
    }
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        itemsStreamProvider.overrideWith((ref) => Stream.value(items)),
        itemTrendProvider(query).overrideWith((ref) => stream),
      ],
      child: MaterialApp(
        theme: theme,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('el')],
        locale: const Locale('el'),
        home: Scaffold(
          body: ItemTrendCard(
            range: range,
            period: PeriodType.month,
            onPeriodChanged: periods?.add ?? (_) {},
          ),
        ),
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

  group('ItemTrendCard', () {
    testWidgets('idle: dropdown + hint, όχι γράφημα, όχι DB σφάλμα',
        (tester) async {
      await pumpSized(tester, wrap(), const Size(800, 600));
      expect(find.text(AppStrings.chartItemTrendTitle), findsOneWidget);
      expect(find.text(AppStrings.trendItemSearchHint), findsOneWidget);
      expect(find.text(AppStrings.trendNoItemSelected), findsOneWidget);
      expect(find.byType(ItemTrendChart), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('επιλογή (prefs) → banner + γραμμή', (tester) async {
      await prefs.setInt(AppConstants.trendSelectedItemKey, 1);
      await pumpSized(
        tester,
        wrap(items: [cannedItem()], data: sampleData()),
        const Size(800, 600),
      );
      expect(find.text('Γάλα'), findsOneWidget);
      expect(find.text(AppStrings.changeItem), findsOneWidget);
      expect(find.byType(ItemTrendChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('«Αλλαγή» → αποεπιλογή + άδειο dropdown', (tester) async {
      await prefs.setInt(AppConstants.trendSelectedItemKey, 1);
      await pumpSized(
        tester,
        wrap(items: [cannedItem()], data: sampleData()),
        const Size(800, 600),
      );
      await tester.tap(find.text(AppStrings.changeItem));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.trendNoItemSelected), findsOneWidget);
      expect(find.byType(ItemTrendChart), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ορφανό id → trendItemRemoved + επαναπιλογή', (tester) async {
      await prefs.setInt(AppConstants.trendSelectedItemKey, 999);
      await pumpSized(
        tester,
        wrap(items: [cannedItem()]),
        const Size(800, 600),
      );
      expect(find.text(AppMessages.trendItemRemoved), findsOneWidget);
      await tester.tap(find.text(AppStrings.changeItem));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.trendNoItemSelected), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('είδος χωρίς μονάδα → unitRequired, όχι γράφημα',
        (tester) async {
      await prefs.setInt(AppConstants.trendSelectedItemKey, 1);
      await pumpSized(
        tester,
        wrap(items: [cannedItem(unitId: null)]),
        const Size(800, 600),
      );
      expect(find.text('Γάλα'), findsOneWidget);
      expect(find.text(AppErrors.unitRequired), findsOneWidget);
      expect(find.byType(ItemTrendChart), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('trend loading → skeleton (όχι spinner)', (tester) async {
      await prefs.setInt(AppConstants.trendSelectedItemKey, 1);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            itemsStreamProvider
                .overrideWith((ref) => Stream.value([cannedItem()])),
            itemTrendProvider(trendQuery())
                .overrideWith((ref) => StreamController<ItemTrendData>().stream),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ItemTrendCard(
                range: range,
                period: PeriodType.month,
                onPeriodChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text(AppStrings.chartItemTrendTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('trend empty → noPricesForPeriod', (tester) async {
      await prefs.setInt(AppConstants.trendSelectedItemKey, 1);
      await pumpSized(
        tester,
        wrap(items: [cannedItem()]),
        const Size(800, 600),
      );
      expect(find.text(AppStrings.noPricesForPeriod), findsOneWidget);
      expect(find.byType(ItemTrendChart), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('trend error → loadDataFailed + Επανάληψη', (tester) async {
      await prefs.setInt(AppConstants.trendSelectedItemKey, 1);
      await pumpSized(
        tester,
        wrap(items: [cannedItem()], trendError: Exception('test')),
        const Size(800, 600),
      );
      expect(find.text(AppErrors.loadDataFailed), findsOneWidget);
      expect(find.text(AppStrings.retryButton), findsOneWidget);
      await tester.tap(find.text(AppStrings.retryButton));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('ξένες μονάδες → σημείωση (όχι φιλτράρισμα σιωπηλό)',
        (tester) async {
      await prefs.setInt(AppConstants.trendSelectedItemKey, 1);
      await pumpSized(
        tester,
        wrap(items: [cannedItem()], data: sampleData(others: 2)),
        const Size(800, 600),
      );
      expect(find.text(AppMessages.trendOtherUnitsNote(2)), findsOneWidget);
      expect(find.byType(ItemTrendChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('selector: Έτος → onPeriodChanged(year)', (tester) async {
      final changed = <PeriodType>[];
      await pumpSized(
        tester,
        wrap(periods: changed),
        const Size(800, 600),
      );
      await tester.tap(find.byIcon(Icons.arrow_drop_down).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.periodYear).last);
      await tester.pumpAndSettle();
      expect(changed, [PeriodType.year]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('responsive 320/800/1200 — κανένα overflow', (tester) async {
      await prefs.setInt(AppConstants.trendSelectedItemKey, 1);
      for (final size in const [
        Size(320, 568),
        Size(800, 600),
        Size(1200, 800),
      ]) {
        await pumpSized(
          tester,
          wrap(items: [cannedItem()], data: sampleData()),
          size,
        );
        expect(tester.takeException(), isNull, reason: 'overflow σε $size');
      }
    });

    testWidgets('dark + semantics (§1.5/§1.6)', (tester) async {
      final handle = tester.ensureSemantics();
      await prefs.setInt(AppConstants.trendSelectedItemKey, 1);
      await pumpSized(
        tester,
        wrap(items: [cannedItem()], data: sampleData(), theme: AppTheme.dark),
        const Size(800, 600),
      );
      expect(find.byType(ItemTrendChart), findsOneWidget);
      expect(
        find.bySemanticsLabel(AppStrings.chartItemTrendTitle),
        findsWidgets,
      );
      handle.dispose();
      expect(tester.takeException(), isNull);
    });
  });

  group('ItemTrendCard — search flow (in-memory DB)', () {
    testWidgets('πληκτρολόγηση → αποτέλεσμα → tap → banner + persist',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
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
      final query = (
        itemId: itemId,
        unitId: kiloId,
        from: range.from,
        to: range.to,
      );
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appDatabaseProvider.overrideWithValue(db),
            itemTrendProvider(query)
                .overrideWith((ref) => Stream.value(sampleData())),
          ],
          child: MaterialApp(
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [Locale('el')],
            locale: const Locale('el'),
            home: Scaffold(
              body: ItemTrendCard(
                range: range,
                period: PeriodType.month,
                onPeriodChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Πληκτρολόγηση → debounce → overlay αποτελέσματος (το DropdownMenu
      // περιόδου έχει δικό του TextField — στόχευση με label).
      final searchField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == AppStrings.fieldItemName,
      );
      await tester.enterText(searchField, 'γαλ');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Γάλα'));
      await tester.pumpAndSettle();

      // Banner + persist (επόμενο launch διαβάζει την επιλογή).
      expect(find.text(AppStrings.changeItem), findsOneWidget);
      expect(prefs.getInt(AppConstants.trendSelectedItemKey), itemId);
      expect(tester.takeException(), isNull);
    });
  });
}
