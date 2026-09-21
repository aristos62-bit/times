/// Widget tests — `SearchableDropdownField` (§2.4 DESIGN / Φάση 3 Βήμα 3).
///
/// Δύο ομάδες:
///  * "pure" — μετρητής `StreamProvider.family` χωρίς DB: επαληθεύει το GATED
///    watch (§2.0.1: μηδενικά reads στο launch, ταιριάζει minChars) και τον
///    Debouncer (ένα μόνο trigger από πολλές γρήγορες πληκτρολογήσεις).
///  * "integration" — πραγματικός `supplierSearchProvider` + in-memory DB:
///    live results στο overlay, επιλογή, «+» με 0 αποτελέσματα, onCreate,
///    double-tap guard, responsive χωρίς overflow (§1.4).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/supplier_dao.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/providers/stream_providers.dart';
import 'package:times/presentation/shared/searchable_dropdown_field.dart';

import '../../data/local/helpers/in_memory_db.dart';

void main() {
  /// Shared wrap: ProviderScope (με προαιρετικά overrides) + MaterialApp +
  /// Scaffold, σε logική θύρα [size] (dpr=1).
  Widget wrap(
    Size size, {
    required StreamProvider<List<Supplier>> Function(String query) family,
    Object? extra,
  }) {
    return ProviderScope(
      overrides: [
        if (extra is AppDatabase)
          appDatabaseProvider.overrideWithValue(extra),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Scaffold(
            body: SearchableDropdownField<Supplier>(
              labelText: 'Προμηθευτής',
              hintText: 'Αναζήτηση',
              searchProvider: family.call,
              labelOf: (supplier) => supplier.name,
              createLabel: (query) => 'Νέος προμηθευτής "$query"',
              onCreate: (name) async => null,
            ),
          ),
        ),
      ),
    );
  }

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

  group('Custom icons (§2.4 · Φάση 3 Βήμα 4)', () {
    testWidgets('prefixIcon + resultLeadingIcon εμφανίζονται αντί των default',
        (tester) async {
      final family = StreamProvider.family<List<String>, String>(
        (ref, query) async* {
          yield ['Γάλα'];
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
                prefixIcon: const Icon(Icons.category_outlined),
                resultLeadingIcon: const Icon(Icons.fastfood_outlined),
              ),
            ),
          ),
        ),
        const Size(800, 600),
      );

      // Custom prefixIcon στο πεδίο (default store_outlined αντικαταστάθηκε).
      expect(find.byIcon(Icons.category_outlined), findsOneWidget);
      expect(find.byIcon(Icons.store_outlined), findsNothing);

      await tester.enterText(find.byType(TextField), 'Γάλα');
      await settleSearch(tester);

      // Custom resultLeadingIcon στη γραμμή αποτελέσματος.
      expect(find.byIcon(Icons.fastfood_outlined), findsOneWidget);
      expect(find.byIcon(Icons.business_outlined), findsNothing);
    });

    testWidgets('defaults: store_outlined + business_outlined (regression)',
        (tester) async {
      final family = StreamProvider.family<List<String>, String>(
        (ref, query) async* {
          yield ['Γάλα'];
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

      expect(find.byIcon(Icons.store_outlined), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Γάλα');
      await settleSearch(tester);

      expect(find.byIcon(Icons.business_outlined), findsOneWidget);
    });
  });

  group('Integration με supplierSearchProvider + in-memory DB', () {
    testWidgets('live αποτελέσματα στο overlay + επιλογή', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await SupplierDao(db).insert(name: 'Μάρκος');

      final picked = <Supplier>[];
      await pumpAt(
        tester,
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: Scaffold(
              body: SearchableDropdownField<Supplier>(
                labelText: 'Προμηθευτής',
                hintText: 'Αναζήτηση',
                searchProvider: supplierSearchProvider.call,
                labelOf: (supplier) => supplier.name,
                createLabel: (query) => 'Νέος προμηθευτής "$query"',
                onCreate: (name) async => null,
                onSelected: (supplier) => picked.add(supplier),
              ),
            ),
          ),
        ),
        const Size(800, 600),
      );

      // «μάρκος» → normalize «μαρκοσ» LIKE — ταιριάζει το seeded «Μάρκος».
      await tester.enterText(find.byType(TextField), 'μάρκος');
      await settleSearch(tester);

      expect(find.text('Μάρκος'), findsOneWidget,
          reason: 'Αποτέλεσμα στην ουρά του overlay');
      expect(find.text('Νέος προμηθευτής "μάρκος"'), findsOneWidget);

      await tester.tap(find.text('Μάρκος'));
      await tester.pumpAndSettle();

      expect(picked.single.name, 'Μάρκος');
      expect(find.text('Νέος προμηθευτής "μάρκος"'), findsNothing,
          reason: 'Overlay κλειστό μετά την επιλογή');
      expect(tester.takeException(), isNull);
    });

    testWidgets('query χωρίς match → «+» μόνο, χωρίς results', (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);

      await pumpAt(
        tester,
        wrap(const Size(800, 600), family: supplierSearchProvider.call, extra: db),
        const Size(800, 600),
      );

      await tester.enterText(find.byType(TextField), 'ΞΥΝΠΖ');
      await settleSearch(tester);

      expect(find.text('Νέος προμηθευτής "ΞΥΝΠΖ"'), findsOneWidget);
      expect(find.byIcon(Icons.business_outlined), findsNothing,
          reason: 'Κανένα result row — μόνο η «+» γραμμή');
      expect(tester.takeException(), isNull);
    });
  });

  group('Responsive §1.4 — κανένα overflow', () {
    testWidgets('mobile 320×568: overlay «+» χωρίς overflow', (tester) async {
      await pumpAt(
        tester,
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SearchableDropdownField<String>(
                labelText: 'Test',
                hintText: 'Type',
                searchProvider: StreamProvider.family<List<String>, String>(
                  (ref, query) async* {
                    yield const [];
                  },
                ).call,
                labelOf: (value) => value,
                createLabel: (query) => 'Create "$query"',
                onCreate: (name) async => null,
              ),
            ),
          ),
        ),
        const Size(320, 568),
      );

      await tester.enterText(find.byType(TextField), 'ΑΒΓ');
      await settleSearch(tester);
      expect(find.text('Create "ΑΒΓ"'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('desktop 1200×800: overlay «+» χωρίς overflow', (tester) async {
      await pumpAt(
        tester,
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SearchableDropdownField<String>(
                labelText: 'Test',
                hintText: 'Type',
                searchProvider: StreamProvider.family<List<String>, String>(
                  (ref, query) async* {
                    yield const [];
                  },
                ).call,
                labelOf: (value) => value,
                createLabel: (query) => 'Create "$query"',
                onCreate: (name) async => null,
              ),
            ),
          ),
        ),
        const Size(1200, 800),
      );

      await tester.enterText(find.byType(TextField), 'ΑΒΓ');
      await settleSearch(tester);
      expect(find.text('Create "ΑΒΓ"'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}