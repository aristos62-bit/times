/// Widget smoke test — Φάση 3, Βήμα 1 (App Shell).
///
/// Επαληθεύει το ριζικό δέντρο: `ProviderScope` + `TimesApp` με GoRouter
/// (StatefulShellRoute) χωρίς default Flutter template (DESIGN §0).
/// Οι placeholder σελίδες ΔΕΝ «βλέπουν» data providers → δεν χρειάζεται
/// override του `appDatabaseProvider` σε αυτό το widget test.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_strings.dart';
import 'package:times/main.dart';

void main() {
  testWidgets(
      'TimesApp εμφανίζει Home (AppBar «Τιμές») + NavigationBar με 3 tabs — '
      'κανένα στοιχείο Flutter template', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TimesApp()));
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
    await tester.pumpWidget(const ProviderScope(child: TimesApp()));
    await tester.pumpAndSettle();

    // Εύρεση του destination «Εισαγωγή» στο NavigationBar (SPoT label §1.1).
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(AppStrings.navPriceEntry),
    ));
    await tester.pumpAndSettle();

    // Πλέον βλέπουμε τη PriceEntry (AppBar «Εισαγωγή Τιμών» + κενό «καλάθι»).
    expect(find.text(AppStrings.titlePriceEntry), findsOneWidget);
    expect(find.text(AppStrings.draftLinesEmpty), findsOneWidget);
  });
}