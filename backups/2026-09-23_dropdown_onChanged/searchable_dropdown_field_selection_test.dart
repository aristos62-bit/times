/// Widget tests — `SearchableDropdownField`: `initialValue` + `onCleared`
/// (Φάση 3, Βήμα 5ε-1 · §2.4). Pure family χωρίς DB.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/presentation/shared/searchable_dropdown_field.dart';

void main() {
  final family = StreamProvider.family<List<String>, String>(
        (ref, query) async* {
      yield [query];
    },
  );

  Future<void> pumpField(
      WidgetTester tester, {
        String? initialValue,
        VoidCallback? onCleared,
        ValueChanged<String>? onSelected,
      }) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SearchableDropdownField<String>(
              labelText: 'Test',
              hintText: 'Type',
              searchProvider: family.call,
              labelOf: (value) => value,
              initialValue: initialValue,
              onCleared: onCleared,
              onSelected: onSelected,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Περνά πέρα από τον debounce + το stream του provider.
  Future<void> settleSearch(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  Finder row(String text) => find.descendant(
    of: find.byType(ListTile),
    matching: find.text(text),
  );

  group('initialValue + onCleared (Β5ε-1)', () {
    testWidgets('initialValue: εμφανίζεται, χωρίς onSelected/onCleared',
            (tester) async {
          final selected = <String>[];
          var cleared = 0;
          await pumpField(
            tester,
            initialValue: 'Κιλό',
            onSelected: selected.add,
            onCleared: () => cleared++,
          );
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller!.text,
            'Κιλό',
          );
          expect(selected, isEmpty);
          expect(cleared, 0);
        });

    testWidgets('αλλαγή προεπιλογής → onCleared ΜΙΑ φορά (fire-once)',
            (tester) async {
          var cleared = 0;
          await pumpField(
            tester,
            initialValue: 'Κιλό',
            onCleared: () => cleared++,
          );
          await tester.enterText(find.byType(TextField), 'Κιλ');
          await settleSearch(tester);
          expect(cleared, 1);
          await tester.enterText(find.byType(TextField), 'Κ');
          await settleSearch(tester);
          expect(cleared, 1, reason: 'Fire-once: όχι ξανά χωρίς νέα επιλογή');
        });

    testWidgets('πλήρες σβήσιμο προεπιλογής → onCleared', (tester) async {
      var cleared = 0;
      await pumpField(
        tester,
        initialValue: 'Κιλό',
        onCleared: () => cleared++,
      );
      await tester.enterText(find.byType(TextField), '');
      await settleSearch(tester);
      expect(cleared, 1);
    });

    testWidgets('πληκτρολόγηση χωρίς επιλογή → ΟΧΙ onCleared',
            (tester) async {
          var cleared = 0;
          await pumpField(tester, onCleared: () => cleared++);
          await tester.enterText(find.byType(TextField), 'Μαρ');
          await settleSearch(tester);
          expect(cleared, 0);
        });

    testWidgets('επιλογή από overlay → edit → onCleared· νέα επιλογή '
        're-arm', (tester) async {
      final selected = <String>[];
      var cleared = 0;
      await pumpField(
        tester,
        onSelected: selected.add,
        onCleared: () => cleared++,
      );
      await tester.enterText(find.byType(TextField), 'Μαρ');
      await settleSearch(tester);
      await tester.tap(row('Μαρ'));
      await tester.pumpAndSettle();
      expect(selected, ['Μαρ']);
      expect(cleared, 0, reason: 'Η επιλογή ΔΕΝ είναι «clear»');

      await tester.enterText(find.byType(TextField), 'Μαρκ');
      await settleSearch(tester);
      expect(cleared, 1);

      await tester.tap(row('Μαρκ'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Μ');
      await settleSearch(tester);
      expect(cleared, 2, reason: 'Νέα επιλογή → το callback οπλίζει ξανά');
      expect(tester.takeException(), isNull);
    });
  });
}