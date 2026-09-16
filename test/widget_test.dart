/// Widget smoke test — Φάση 2, Βήμα 3.
///
/// Επαληθεύει το ριζικό δέντρο: `ProviderScope` + `TimesApp` χωρίς default
/// Flutter template (DESIGN §0). Η placeholder σελίδα ΔΕΝ ανοίγει βάση
/// (δεν «βλέπει» data providers) → δεν χρειάζεται override του
/// `appDatabaseProvider` σε αυτό το widget test.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_strings.dart';
import 'package:times/main.dart';

void main() {
  testWidgets(
      'TimesApp εμφανίζει το brand «Τιμές» — κανένα στοιχείο Flutter template',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TimesApp()));

    // AppBar + σώμα placeholder με τον τίτλο της εφαρμογής.
    expect(find.text(AppStrings.appTitle), findsNWidgets(2));
    // Κανένα widget του default counter template.
    expect(find.text('0'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });
}