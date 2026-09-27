/// Widget tests — `SearchableDropdownField` (§2.4 DESIGN / Φάση 3 Βήμα 3).
///
/// Μέρος 1/2 — pure/gated συμπεριφορά ΧΩΡΙΣ βάση: μετρητής
/// `StreamProvider.family`, GATED watch (§2.0.1: μηδενικά reads στο launch,
/// ταιριάζει minChars), Debouncer (ένα μόνο trigger από πολλές γρήγορες
/// πληκτρολογήσεις), «+»/onCreate/double-tap guard. Το μέρος 2/2 (custom
/// icons, integration με πραγματικό `supplierSearchProvider` + in-memory DB,
/// responsive §1.4) ζει στο `searchable_dropdown_field_integration_test.dart`.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/presentation/shared/searchable_dropdown_field.dart';

void main() {
  /// Θέτει τη θύρα (logical, dpr=1) και κάνει pump του [widget].
  Future<void> pumpAt(WidgetTester tester, Widget widget, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  /// Περνά πέρα από τον debounce + το stream του provider.
  Future<void> settleSearch(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  group('Gated watch + Debouncer (pure family, χωρίς DB)', () {
    testWidgets('no query → κανένα read του provider (η βάση δεν ανοίγει)',
        (tester) async {
      var reads = 0;
      final family = StreamProvider.family<List<String>, String>(
        (ref, query) async* {
          reads++;
          yield [query];
        },
      );

      await pumpAt(
        tester,
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SearchableDropdownField<String>(
                labelText: 'Test',
                hintText: 'Type',
                searchProvider: family.call,
                labelOf: (value) => value,
                createLabel: (query) => 'Create "$query"',
                onCreate: (name) async => null,
              ),
            ),
          ),
        ),
        const Size(800, 600),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(reads, 0, reason: 'Gated watch (§2.0.1): κανένα read στο launch');
    });

    testWidgets('πληκτρολόγηση → ένα trigger μετά τον debounce', (tester) async {
      var reads = 0;
      final family = StreamProvider.family<List<String>, String>(
        (ref, query) async* {
          reads++;
          yield [query];
        },
      );

      await pumpAt(
        tester,
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SearchableDropdownField<String>(
                labelText: 'Test',
                hintText: 'Type',
                searchProvider: family.call,
                labelOf: (value) => value,
                createLabel: (query) => 'Create "$query"',
                onCreate: (name) async => null,
              ),
            ),
          ),
        ),
        const Size(800, 600),
      );

      await tester.enterText(find.byType(TextField), 'Μ');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'Μα');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'Μαρ');
      await settleSearch(tester);

      expect(
        reads,
        1,
        reason: 'Μόνο η ΤΕΛΕΥΤΑΙΑ πληκτρολόγηση τρέχει μετά τον debounce',
      );
      expect(
        find.descendant(
          of: find.byType(ListTile),
          matching: find.text('Μαρ'),
        ),
        findsOneWidget,
        reason: 'Αποτέλεσμα του τελικού query — result row στο overlay',
      );
    });

    testWidgets('minChars: κάτω από το όριο → κανένα read', (tester) async {
      var reads = 0;
      final family = StreamProvider.family<List<String>, String>(
        (ref, query) async* {
          reads++;
          yield [query];
        },
      );

      await pumpAt(
        tester,
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SearchableDropdownField<String>(
                labelText: 'Test',
                hintText: 'Type',
                searchProvider: family.call,
                labelOf: (value) => value,
                createLabel: (query) => 'Create "$query"',
                onCreate: (name) async => null,
                minChars: 2,
              ),
            ),
          ),
        ),
        const Size(800, 600),
      );

      await tester.enterText(find.byType(TextField), 'Μ');
      await settleSearch(tester);
      expect(reads, 0, reason: '1 γράμμα < minChars=2 → χωρίς watch');

      await tester.enterText(find.byType(TextField), 'Μα');
      await settleSearch(tester);
      expect(reads, 1, reason: '2 γράμματα ≥ minChars=2 → watch');
    });

    testWidgets('«+» ορατό και με 0 αποτελέσματα — onCreate καλείται', (tester) async {
      String? createdName;
      final family = StreamProvider.family<List<String>, String>(
        (ref, query) async* {
          yield const [];
        },
      );

      await pumpAt(
        tester,
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SearchableDropdownField<String>(
                labelText: 'Test',
                hintText: 'Type',
                searchProvider: family.call,
                labelOf: (value) => value,
                createLabel: (query) => 'Create "$query"',
                onCreate: (name) async {
                  createdName = name;
                  return null;
                },
              ),
            ),
          ),
        ),
        const Size(800, 600),
      );

      await tester.enterText(find.byType(TextField), 'ΞΥΝΠΖ');
      await settleSearch(tester);

      expect(find.text('Create "ΞΥΝΠΖ"'), findsOneWidget,
          reason: '«+» στο τέλος της λίστας ΑΚΟΜΑ με 0 αποτελέσματα (§2.4)');

      await tester.tap(find.text('Create "ΞΥΝΠΖ"'));
      await tester.pumpAndSettle();

      expect(createdName, 'ΞΥΝΠΖ');
    });

    testWidgets('onCreate επιστρέφει T → το πεδίο δείχνει το label του νέου',
        (tester) async {
      const created = 'Αστραπή';
      final family = StreamProvider.family<List<String>, String>(
        (ref, query) async* {
          yield const [];
        },
      );

      await pumpAt(
        tester,
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SearchableDropdownField<String>(
                labelText: 'Test',
                hintText: 'Type',
                searchProvider: family.call,
                labelOf: (value) => value,
                createLabel: (query) => 'Create "$query"',
                onCreate: (name) async => created,
              ),
            ),
          ),
        ),
        const Size(800, 600),
      );

      await tester.enterText(find.byType(TextField), 'Αστραπή');
      await settleSearch(tester);
      await tester.tap(find.textContaining('Create "'));
      await tester.pumpAndSettle();

      // Το overlay κλείνει (query cleared) και το πεδίο δείχνει το label.
      expect(find.textContaining('Create "'), findsNothing);
      expect(find.text('Αστραπή'), findsOneWidget);
    });

    testWidgets('double-tap guard: onCreate ΔΕΝ καλείται δεύτερη φορά',
        (tester) async {
      var calls = 0;
      final completer = Completer<String?>();
      final family = StreamProvider.family<List<String>, String>(
        (ref, query) async* {
          yield const [];
        },
      );

      await pumpAt(
        tester,
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SearchableDropdownField<String>(
                labelText: 'Test',
                hintText: 'Type',
                searchProvider: family.call,
                labelOf: (value) => value,
                createLabel: (query) => 'Create "$query"',
                onCreate: (name) {
                  calls++;
                  return completer.future;
                },
              ),
            ),
          ),
        ),
        const Size(800, 600),
      );

      await tester.enterText(find.byType(TextField), 'ΝΕΟ');
      await settleSearch(tester);
      final createTile = find.textContaining('Create "');

      await tester.tap(createTile);
      // Χωρίς pump ενδιάμεσα: το overlay είναι ακόμα ανοιχτό, άρα ο δεύτερος
      // tap "προλαβαίνει" να χτυπήσει την ίδια σειρά πριν κλείσει.
      await tester.tap(createTile, warnIfMissed: false);
      await tester.pump();

      expect(calls, 1, reason: 'Busy-flag τοπικό (§2.4): double-tap guard');

      completer.complete(null);
      await tester.pumpAndSettle();
      expect(calls, 1);
    });
  });
}