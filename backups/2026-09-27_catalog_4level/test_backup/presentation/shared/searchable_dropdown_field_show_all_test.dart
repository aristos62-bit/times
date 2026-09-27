/// Widget tests — show-all-on-focus (Δ1 · Φάση 3 Βήμα 5β) του
/// `SearchableDropdownField` (§2.4.1 DESIGN). Ξεχωριστό αρχείο από το
/// `searchable_dropdown_field_test.dart` ώστε κανένα test αρχείο να μην
/// ξεπερνά τις 500 γραμμές (κανόνας 7 AGENTS).
///
/// Ομάδες:
///  * "pure" — fake `StreamProvider` χωρίς DB: verify gating (§2.0.1),
///    show-all-on-focus, φιλτράρισμα/άδειασμα, guard μετά από επιλογή,
///    invariant constructor (assert).
///  * "integration" — πραγματικό `unitsStreamProvider` + `unitSearchProvider`
///    + in-memory DB: εστίαση → όλες οι μονάδες, πληκτρολόγηση → φιλτράρισμα,
///    επιλογή → κλείσιμο overlay.
///
/// Test IDs: B5β-SA1..7.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/data/local/app_database.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/providers/stream_providers.dart';
import 'package:times/presentation/shared/searchable_dropdown_field.dart';

import '../../data/local/helpers/in_memory_db.dart';

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

  Widget wrap({
    required StreamProvider<List<String>> Function(String query) search,
    required StreamProvider<List<String>> Function() all,
    bool showAllWhenEmpty = false,
    ValueChanged<String>? onSelected,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SearchableDropdownField<String>(
            labelText: 'Μονάδα',
            hintText: 'Επιλογή',
            searchProvider: search,
            labelOf: (value) => value,
            showAllWhenEmpty: showAllWhenEmpty,
            allOptionsProvider: all,
            onSelected: onSelected,
          ),
        ),
      ),
    );
  }

  // ─── Pure — fake providers χωρίς DB ────────────────────────────────────────

  group('Show-all-on-focus (pure · Β5β)', () {
    const allUnits = ['Κιλό', 'Τεμάχιο', 'Λίτρο'];

    testWidgets(
        'SA1: εστίαση σε κενό πεδίο → ΟΛΕΣ οι επιλογές · gated (§2.0.1)',
        (tester) async {
      var allReads = 0;
      var searchReads = 0;
      final all = StreamProvider<List<String>>(
        (ref) {
          allReads++;
          return Stream.value(allUnits);
        },
      );
      final search = StreamProvider.family<List<String>, String>(
        (ref, query) async* {
          searchReads++;
          yield allUnits
              .where((u) => u.toLowerCase().contains(query.toLowerCase()))
              .toList();
        },
      );

      await pumpAt(
        tester,
        wrap(search: search.call, all: () => all, showAllWhenEmpty: true),
        const Size(800, 600),
      );

      expect(allReads, 0,
          reason: 'Gated (§2.0.1): κανένα read στο launch — η DB δεν ανοίγει');

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      expect(allReads, greaterThan(0), reason: 'Focus = user action → watch');
      expect(searchReads, 0, reason: 'Κανένα filtered search στο focus');
      expect(find.text('Κιλό'), findsOneWidget);
      expect(find.text('Τεμάχιο'), findsOneWidget);
      expect(find.text('Λίτρο'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SA2: showAllWhenEmpty=false → εστίαση χωρίς overlay (regression)',
        (tester) async {
      var allReads = 0;
      var searchReads = 0;
      final all = StreamProvider<List<String>>(
        (ref) {
          allReads++;
          return Stream.value(allUnits);
        },
      );
      final search = StreamProvider.family<List<String>, String>(
        (ref, query) async* {
          searchReads++;
          yield allUnits;
        },
      );

      await pumpAt(
        tester,
        wrap(search: search.call, all: () => all, showAllWhenEmpty: false),
        const Size(800, 600),
      );

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      expect(allReads, 0, reason: 'Κλασική συμπεριφορά: χωρίς query → χωρίς read');
      expect(searchReads, 0);
      expect(find.text('Κιλό'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SA3: πληκτρολόγηση φιλτράρει από τα «όλα» → clear → όλα πάλι',
        (tester) async {
      final all = StreamProvider<List<String>>(
        (ref) => Stream.value(allUnits),
      );
      final search = StreamProvider.family<List<String>, String>(
        (ref, query) async* {
          yield allUnits
              .where((u) => u.toLowerCase().contains(query.toLowerCase()))
              .toList();
        },
      );

      await pumpAt(
        tester,
        wrap(search: search.call, all: () => all, showAllWhenEmpty: true),
        const Size(800, 600),
      );

      // Εστίαση → όλες εμφανίζονται.
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(find.text('Κιλό'), findsOneWidget);
      expect(find.text('Τεμάχιο'), findsOneWidget);

      // Πληκτρολόγηση «κι» → μόνο Κιλό.
      await tester.enterText(find.byType(TextField), 'κι');
      await settleSearch(tester);
      expect(find.text('Κιλό'), findsOneWidget);
      expect(find.text('Τεμάχιο'), findsNothing);

      // Άδειασμα → όλες ξανά (show-all-on-focus).
      await tester.enterText(find.byType(TextField), '');
      await settleSearch(tester);
      expect(find.text('Κιλό'), findsOneWidget);
      expect(find.text('Τεμάχιο'), findsOneWidget);
      expect(find.text('Λίτρο'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SA4: επιλογή → overlay κλείνει · re-focus → ΔΕΝ ξανανοίγει',
        (tester) async {
      final all = StreamProvider<List<String>>(
        (ref) => Stream.value(allUnits),
      );
      final search = StreamProvider.family<List<String>, String>(
        (ref, query) async* {
          yield allUnits;
        },
      );
      final picked = <String>[];

      await pumpAt(
        tester,
        wrap(
          search: search.call,
          all: () => all,
          showAllWhenEmpty: true,
          onSelected: picked.add,
        ),
        const Size(800, 600),
      );

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Κιλό'));
      await tester.pumpAndSettle();

      expect(picked, ['Κιλό']);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'Κιλό');
      expect(find.text('Τεμάχιο'), findsNothing, reason: 'Overlay κλειστό');

      // Re-focus: το κείμενο ταυτίζεται με το label → overlay ΔΕΝ ξανανοίγει.
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(find.text('Τεμάχιο'), findsNothing,
          reason: 'Guard `_selectedLabel`: όσο text == label, overlay κλειστό');
      expect(tester.takeException(), isNull);
    });

    testWidgets('SA5: invariant — showAllWhenEmpty χωρίς allOptionsProvider → assert',
        (tester) async {
      final search = StreamProvider.family<List<String>, String>(
        (ref, query) async* {
          yield const [];
        },
      );

      expect(
        () => SearchableDropdownField<String>(
          labelText: 'Μονάδα',
          hintText: 'Επιλογή',
          searchProvider: search.call,
          labelOf: (value) => value,
          showAllWhenEmpty: true,
        ),
        throwsAssertionError,
      );
    });
  });

  // ─── Integration — πραγματικοί providers + in-memory DB ───────────────────

  group('Integration με unitsStreamProvider + unitSearchProvider (Β5β)', () {
    testWidgets(
        'SA7: εστίαση → όλες οι μονάδες · πληκτρολόγηση → φιλτράρισμα · επιλογή',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      // Μοναδική μονάδα για ξεκάθαρο match — το underlay των seeded μονάδων
      // δεν περιέχει «Δωδεκάδα».
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      await container
          .read(unitRepositoryProvider)
          .insert(name: 'Δωδεκάδα', abbreviation: 'δωδ');

      final picked = <Unit>[];
      await pumpAt(
        tester,
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: Scaffold(
              body: SearchableDropdownField<Unit>(
                labelText: 'Μονάδα',
                hintText: 'Επιλογή',
                searchProvider: unitSearchProvider.call,
                labelOf: (unit) => unit.name,
                showAllWhenEmpty: true,
                allOptionsProvider: () => unitsStreamProvider,
                onSelected: picked.add,
              ),
            ),
          ),
        ),
        const Size(800, 600),
      );

      // Εστίαση → όλες οι μονάδες (real drag από τη βάση), συμπ. της «Δωδεκάδα».
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(find.text('Δωδεκάδα'), findsOneWidget);

      // Πληκτρολόγηση → μόνο η Δωδεκάδα (normalize internals).
      await tester.enterText(find.byType(TextField), 'δωδ');
      await settleSearch(tester);
      expect(find.text('Δωδεκάδα'), findsOneWidget);

      await tester.tap(find.text('Δωδεκάδα'));
      await tester.pumpAndSettle();

      expect(picked.single.name, 'Δωδεκάδα');
      expect(find.text('Δωδεκάδα'), findsOneWidget,
          reason: 'Το πεδίο δείχνει το label της επιλογής');
      expect(tester.takeException(), isNull);
    });
  });
}