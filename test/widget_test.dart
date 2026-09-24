/// Widget smoke test — Φάση 3, Βήμα 1 (App Shell) + Φάση 4, Βήμα 1 (θέμα).
///
/// Επαληθεύει το ριζικό δέντρο: `ProviderScope` + `TimesApp` με GoRouter
/// (StatefulShellRoute) χωρίς default Flutter template (DESIGN §0).
/// Βήμα 7: η PriceEntryPage (branch «Εισαγωγή») περιέχει πλέον τη λίστα
/// πρόσφατων (`recentReceiptsStreamProvider`) → override με ΚΕΝΗ λίστα
/// (hermetic — το smoke test ΔΕΝ ανοίγει πραγματική βάση, §2.0.1).
/// Βήμα 1: το TimesApp watch-άρει `themeModeProvider` (SharedPreferences) →
/// mock prefs στο setUp + override (πρότυπο database tests).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:times/core/constants/app_constants.dart';
import 'package:times/core/constants/app_strings.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/models/category_tree_node.dart';
import 'package:times/data/models/receipt_summary.dart';
import 'package:times/data/providers/settings_providers.dart';
import 'package:times/data/providers/stream_providers.dart';
import 'package:times/main.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  /// ProviderScope με overrides: λίστα πρόσφατων (κενή ροή) + δέντρο
  /// κατηγοριών (κενή ροή, Βήμα 4 — η SettingsPage βλέπει DB providers)
  /// + λίστα προμηθευτών (κενή ροή, CRUD 24-09-2026) + prefs (Βήμα 1).
  ProviderScope scope() => ProviderScope(
        overrides: [
          recentReceiptsStreamProvider.overrideWith(
            (ref) => Stream.value(const <ReceiptSummary>[]),
          ),
          categoryTreeStreamProvider.overrideWith(
            (ref) => Stream.value(const <CategoryTreeNode>[]),
          ),
          suppliersStreamProvider.overrideWith(
            (ref) => Stream.value(const <Supplier>[]),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const TimesApp(),
      );

  testWidgets(
      'TimesApp εμφανίζει Home (AppBar «Τιμές») + NavigationBar με 3 tabs — '
      'κανένα στοιχείο Flutter template', (WidgetTester tester) async {
    await tester.pumpWidget(scope());
    await tester.pumpAndSettle();

    // Αρχική branch: Home placeholder — AppBar με τον τίτλο «Τιμές»
    // (§2.1) + placeholder text στατιστικών. Ο τίτλος υπάρχει ΜΟΝΟ μια
    // φορά (AppBar) — το σώμα πλέον δείχνει το statsComingSoon.
    expect(find.text(AppStrings.appTitle), findsOneWidget);
    expect(find.text(AppStrings.statsComingSoon), findsOneWidget);
    // App Shell: NavigationBar (Material 3) με 3 destinations.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(3));
    // Κανένα widget του default counter template.
    expect(find.text('0'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('αλλαγή tab στο PriceEntry φέρνει «Εισαγωγή Τιμών»',
      (WidgetTester tester) async {
    await tester.pumpWidget(scope());
    await tester.pumpAndSettle();

    // Εύρεση του destination «Εισαγωγή» στο NavigationBar (SPoT label §1.1).
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(AppStrings.navPriceEntry),
    ));
    await tester.pumpAndSettle();

    // Πλέον βλέπουμε τη PriceEntry (AppBar «Εισαγωγή Τιμών» + κενό «καλάθι»
    // + κουμπί αποθήκευσης + Βήμα 7: read-only λίστα πρόσφατων — κενή).
    expect(find.text(AppStrings.titlePriceEntry), findsOneWidget);
    expect(find.text(AppStrings.draftLinesEmpty), findsOneWidget);
    expect(find.text(AppStrings.saveReceipt), findsOneWidget);
    expect(find.text(AppStrings.recentReceiptsTitle), findsOneWidget);
    expect(find.text(AppStrings.recentReceiptsEmpty), findsOneWidget);
  });

  testWidgets('αλλαγή θέματος από τα Ρυθμίσεις αλλάζει MaterialApp.themeMode',
      (WidgetTester tester) async {
    await tester.pumpWidget(scope());
    await tester.pumpAndSettle();

    // Μετάβαση στο tab «Ρυθμίσεις» (SPoT label §1.1).
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(AppStrings.navSettings),
    ));
    await tester.pumpAndSettle();

    // Επιλογή «Σκοτεινό» → ο themeModeProvider αλλάζει + MaterialApp.themeMode
    // ακολουθεί (wiring §2.3:270: main ↔ settings).
    await tester.tap(find.text(AppStrings.themeModeDark));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    // Το save έφτασε στα prefs (persistence through the whole flow).
    expect(prefs.getString(AppConstants.themeModeKey), 'dark');
    expect(tester.takeException(), isNull);
  });
}