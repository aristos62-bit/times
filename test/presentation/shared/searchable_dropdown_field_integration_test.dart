/// Widget tests — `SearchableDropdownField` (§2.4 DESIGN / Φάση 3 Βήμα 3).
///
/// Μέρος 2/2 — custom icons (§2.4 · Βήμα 4), integration με πραγματικό
/// `supplierSearchProvider` + in-memory DB (live results, επιλογή, «+» χωρίς
/// results) και responsive χωρίς overflow (§1.4). Το μέρος 1/2 (gated watch,
/// debouncer, «+»/onCreate, double-tap guard — χωρίς DB) ζει στο
/// `searchable_dropdown_field_test.dart`.
library;

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