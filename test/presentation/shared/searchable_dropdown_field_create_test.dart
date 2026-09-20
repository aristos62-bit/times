/// Widget tests — κείμενο πεδίου μετά την επιλογή «+» / αποτελέσματος στο
/// `SearchableDropdownField` (§2.4 · Φάση 3 Βήμα 6ε). Νέο αρχείο: το
/// searchable_dropdown_field_test.dart ξεπερνά ήδη τις 500 γραμμές.
///
/// Regression: το RawAutocomplete γράφει `displayStringForOption(option)` στο
/// πεδίο τη στιγμή της επιλογής. Χωρίς δικό μας displayString έμενε το
/// `toString()` της γραμμής («Instance of '_CreateEntry<String'») όταν το
/// `onCreate` επέστρεφε null.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/presentation/shared/searchable_dropdown_field.dart';

void main() {
  /// Πεδίο με fake search provider που επιστρέφει [results] για κάθε query.
  Future<void> pumpField(
      WidgetTester tester, {
        required FutureOr<String?> Function(String name) onCreate,
        List<String> results = const [],
        ValueChanged<String>? onSelected,
      }) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final family = StreamProvider.family<List<String>, String>(
          (ref, query) async* {
        yield results;
      },
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SearchableDropdownField<String>(
              labelText: 'Test',
              hintText: 'Type',
              searchProvider: family.call,
              labelOf: (value) => value,
              createLabel: (query) => 'Create "$query"',
              onCreate: onCreate,
              onSelected: onSelected,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Περνά πέρα από τον debounce (250ms) + το stream του provider.
  Future<void> settleSearch(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  String fieldText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  group('SearchableDropdownField — κείμενο πεδίου μετά την επιλογή (6ε)', () {
    testWidgets('D1: «+» με onCreate → null → το πεδίο κρατά το query',
            (tester) async {
          await pumpField(tester, onCreate: (name) async => null);

          await tester.enterText(find.byType(TextField), 'ΞΥΝΠΖ');
          await settleSearch(tester);
          await tester.tap(find.text('Create "ΞΥΝΠΖ"'));
          await tester.pumpAndSettle();

          expect(fieldText(tester), isNot(contains('Instance of')));
          expect(fieldText(tester), 'ΞΥΝΠΖ');
          expect(tester.takeException(), isNull);
        });

    testWidgets('D2: «+» σε εξέλιξη → το πεδίο δείχνει το query · μετά την '
        'ολοκλήρωση το label του νέου', (tester) async {
      final completer = Completer<String?>();
      await pumpField(tester, onCreate: (name) => completer.future);

      await tester.enterText(find.byType(TextField), 'ΝΕΟ');
      await settleSearch(tester);
      await tester.tap(find.text('Create "ΝΕΟ"'));
      await tester.pump();

      expect(fieldText(tester), 'ΝΕΟ', reason: 'Όχι toString() της γραμμής');

      completer.complete('ΝΕΟΣ');
      await tester.pumpAndSettle();

      expect(fieldText(tester), 'ΝΕΟΣ');
      expect(tester.takeException(), isNull);
    });

    testWidgets('D3: επιλογή αποτελέσματος → το πεδίο δείχνει το label + '
        'onSelected', (tester) async {
      String? selected;
      await pumpField(
        tester,
        onCreate: (name) async => null,
        results: const ['Γάλα'],
        onSelected: (value) => selected = value,
      );

      await tester.enterText(find.byType(TextField), 'γα');
      await settleSearch(tester);
      await tester.tap(find.text('Γάλα'));
      await tester.pumpAndSettle();

      expect(fieldText(tester), 'Γάλα');
      expect(selected, 'Γάλα');
      expect(tester.takeException(), isNull);
    });
  });
}