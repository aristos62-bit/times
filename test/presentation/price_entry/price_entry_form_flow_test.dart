/// Widget tests — πλήρης ροή φόρμας εισαγωγής τιμών (§2.2 · Φάση 3 Βήμα 8).
///
/// F1 (full-flow): ολόκληρη η ροή στη σελίδα — προμηθευτής μέσω live search
/// (SearchableDropdownField overlay · ΔΕΝ δημιουργούμε μέσω «+», καλύπτεται
/// από το receipt_header_section_test), 2 είδη με προεπιλεγμένη μονάδα
/// (defaultUnitId, §2.2:236), αποθήκευση → SnackBar → read-only λίστα
/// πρόσφατων ανανεωμένη μόνη της (§2.2:212).
/// F2 (double-save): το κουμπί γίνεται disabled-όσο-σώζει (§2.2:235) και ένα
/// δεύτερο tap δεν δημιουργεί δεύτερη απόδειξη — blocking repo με gate.
///
/// Α1: αυτό το αρχείο είναι η **ΜΟΝΗ εξαίρεση** στον κανόνα «override
/// `recentReceiptsStreamProvider` σε κάθε widget test που pump-άρει
/// PriceEntryPage» — εδώ override γίνεται ΜΟΝΟ στο `appDatabaseProvider`;
/// η λίστα πρόσφατων ζει στην ίδια in-memory βάση και ανανεώνεται μόνη της.
///
/// Μοτίβα (σύμφωνα με το project): πραγματική in-memory Drift βάση
/// (inMemoryDb, μοτίβο Βημάτων 4/5), ελληνικό locale, προσέγγιση «enterText +
/// pump(300ms) debounce + pumpAndSettle» για τα overlays, και
/// `runAsync` μόνο για τα `.first` των drift streams (idiom stream_providers_test).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_messages.dart';
import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/models/receipt_summary.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/repositories/receipt_repository.dart';
import 'package:times/presentation/price_entry/price_entry_page.dart';

import '../../data/local/helpers/in_memory_db.dart';

void main() {
  /// Seed της in-memory βάσης (skipSeed): προμηθευτής «Μάρκος» + 2 μονάδες
  /// («Κιλό» δεκαδική / «Τεμάχιο» ακέραια) + κατηγορία/υποκατηγορία + είδη
  /// «Γάλα» (defaultUnit=κιλό) και «Ψωμί» (defaultUnit=τεμ). Επιστρέφει τη
  /// βάση για overrides και assertions.
  Future<AppDatabase> seedDb() async {
    final db = inMemoryDb();
    addTearDown(db.close);

    // Προμηθευτής μέσω repository (soft dup-check + normalizedName, §2.0.4).
    final seedContainer = ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(seedContainer.dispose);
    await seedContainer.read(supplierRepositoryProvider).insert(name: 'Μάρκος');

    // Λοιπά seed data μέσω DAO (μοτίβο unit_quantity_price_section_validation_test).
    final kiloId = await UnitDao(db).insert(
      name: 'Κιλό',
      abbreviation: 'κιλ',
      allowsDecimal: true,
    );
    final pieceId = await UnitDao(db).insert(
      name: 'Τεμάχιο',
      abbreviation: 'τεμ',
    );
    final categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    final subId = await SubCategoryDao(db)
        .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
    await ItemDao(db).insert(
      subCategoryId: subId,
      name: 'Γάλα',
      defaultUnitId: kiloId,
    );
    await ItemDao(db).insert(
      subCategoryId: subId,
      name: 'Ψωμί',
      defaultUnitId: pieceId,
    );
    return db;
  }

  /// Wrap σελίδας: ProviderScope (in-memory DB, Α1 — χωρίς override του
  /// recentReceiptsStreamProvider) + MaterialApp ελληνικά (σελιδικά blocks
  /// χρειάζονται MaterialLocalizations για formatShortDate/formatMediumDate).
  Widget wrap(AppDatabase db) {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('el')],
        locale: const Locale('el'),
        home: const PriceEntryPage(),
      ),
    );
  }

  /// Ίδιο wrap με επιπλέον override του receipt repository (F2: blocking).
  Widget wrapBlocking(AppDatabase db, ReceiptRepository blocking) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        receiptRepositoryProvider.overrideWithValue(blocking),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('el')],
        locale: const Locale('el'),
        home: const PriceEntryPage(),
      ),
    );
  }

  /// Μεγάλη θύρα (800×1600): όλα τα blocks της σελίδας ορατά χωρίς scroll,
  /// ώστε τα taps/overlays του flow test να είναι ντετερμινιστικά. Το
  /// responsive εξετάζεται στα επί μέρους widget tests (Υποβήματα 3+).
  void setSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// Βρίσκει το TextField με το δοσμένο label (idiom validation test).
  TextField fieldByLabel(WidgetTester tester, String label) {
    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      if (field.decoration?.labelText == label) return field;
    }
    fail('Δεν βρέθηκε TextField με label «$label»');
  }

  /// Πληκτρολόγηση σε πεδίο + pass από debounce (250ms) + settle.
  ///
  /// TO-SPECIFIC (idiom item_search_field_test): όσο το search εκκρεμεί το
  /// panel δείχνει LinearProgressIndicator (infinite animation) και το drift
  /// stream τρέχει σε background isolate (πραγματικός χρόνος) — το
  /// `pumpAndSettle` ΜΟΝΟ του δεν συγκλίνει. Γι' αυτό: pump πέρα από τον
  /// debounce → `runAsync` πραγματικού χρόνου για το stream → ΜΟΝΟ ΤΟΤΕ
  /// pumpAndSettle (καμία infinite animation κατά το settle).
  Future<void> enterInField(
      WidgetTester tester, String label, String text) async {
    await tester.enterText(find.byWidget(fieldByLabel(tester, label)), text);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pumpAndSettle();
  }

  /// Επιλογή αποτελέσματος από overlay/λίστα αποτελεσμάτων — στοχεύει το
  /// ListTile (όχι το κείμενο του πεδίου, αποφυγή διπλών matches).
  Future<void> pickResult(WidgetTester tester, String name) async {
    await tester.tap(find.widgetWithText(ListTile, name));
    await tester.pumpAndSettle();
  }

  /// Πλήρης ροή προμηθευτή: live search «Μάρκος» → tap στο overlay.
  Future<void> pickSupplier(WidgetTester tester) async {
    await enterInField(tester, AppStrings.fieldSupplier, 'Μάρκος');
    await pickResult(tester, 'Μάρκος');
  }

  /// Πλήρης ροή είδους: live search [name] → tap αποτελέσματος → banner.
  Future<void> pickItem(WidgetTester tester, String name) async {
    await enterInField(tester, AppStrings.fieldItemName, name);
    await pickResult(tester, name);
    // Banner επιλεγμένου είδους (§2.4) — η ενότητα μονάδας/τιμής φάνηκε.
    expect(find.text(AppStrings.changeItem), findsOneWidget);
  }

  /// Εισαγωγή τιμής + «Προσθήκη γραμμής». Η μονάδα/ποσότητα είναι ήδη
  /// προ-επιλεγμένες από το defaultUnitId + prefill (Δ8), οπότε αρκεί η τιμή.
  Future<void> addLine(WidgetTester tester, String price) async {
    await enterInField(tester, AppStrings.fieldPrice, price);
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.addReceiptLine),
    );
    await tester.pumpAndSettle();
  }

  group('F1 — πλήρης ροή (§2.2)', () {
    testWidgets(
        'προμηθευτής + 2 είδη → αποθήκευση → snackbar + φόρμα καθαρίστηκε '
        '→ πρόσφατες αποδείξεις + βάση', (tester) async {
      final db = await seedDb();
      setSize(tester);
      await tester.pumpWidget(wrap(db));
      await tester.pumpAndSettle();

      // ─── Επιλογή προμηθευτή μέσω live search (όχι «+»). ─────────────
      await pickSupplier(tester);

      // ─── Είδος 1: «Γάλα» (default μονάδα Κιλό, qty=1) + τιμή 2,50. ───
      await pickItem(tester, 'Γάλα');
      await addLine(tester, '2,50');

      // ─── Είδος 2: «Ψωμί» (default μονάδα Τεμάχιο, qty=1) + τιμή 1,20. ─
      await pickItem(tester, 'Ψωμί');
      await addLine(tester, '1,20');

      // ─── Αποθήκευση. ────────────────────────────────────────────────
      await tester.tap(
        find.widgetWithText(FilledButton, AppStrings.saveReceipt),
      );
      // TO-SPECIFIC: όσο το save εκκρεμεί το κουμπί δείχνει spinner
      // (infinite animation) και το insert γράφει σε background isolate —
      // αφήνουμε πραγματικό χρόνο πριν το pumpAndSettle.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();

      // SnackBar επιτυχίας (§2.2:211-212).
      expect(find.text(AppMessages.savedReceipt), findsOneWidget);

      // Φόρμα καθάρισε (§2.2:212): κενό «καλάθι» + search idle.
      expect(find.text(AppStrings.draftLinesEmpty), findsOneWidget);
      expect(find.text(AppStrings.itemSearchIdle), findsOneWidget);

      // Read-only λίστα πρόσφατων ανανεώθηκε ΜΟΝΗ της (§2.2:212, Α1).
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PriceEntryPage)),
      );

      // Ας αφήσουμε τον drift stream της λίστας να κάνει re-emit (idiom
      // runAsync για drift streams) και μετά φαίνεται το Data state.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppMessages.receiptNumber(1)), findsOneWidget);
      expect(find.textContaining('Μάρκος'), findsOneWidget);
      expect(find.textContaining('2 γραμμές'), findsOneWidget);
      // Σύνολο: 1×2,50 + 1×1,20 = 3,70 € (formatCents).
      expect(find.text('3,70 €'), findsOneWidget);

      // Επιβεβαίωση βάσης (transaction, §2.2:211): 1 απόδειξη + 2 γραμμές.
      await tester.runAsync(() async {
        final receipts = await container
            .read(receiptRepositoryProvider)
            .watchAll()
            .first;
        expect(receipts, hasLength(1));
        final lines = await container
            .read(receiptRepositoryProvider)
            .watchLines(receipts.first.id)
            .first;
        expect(lines, hasLength(2));
        // SPoT lineTotalCents: price × quantity (1×250 / 1×120).
        expect(
          lines.fold<int>(0, (sum, l) => sum + l.lineTotalCents),
          370,
        );
      });

      expect(tester.takeException(), isNull);
    });
  });

  group('F2 — double-save guard (§2.2:235)', () {
    testWidgets(
        'ενώ σώζει: κουμπί disabled · δεύτερο tap αγνοείται · μία απόδειξη',
        (tester) async {
      final db = await seedDb();
      final gate = Completer<void>();

      // Blocking repository: το insertReceiptWithLines κολλάει στην πύλη
      // (ίδιο idiom με receipt_form_controller_test double-save).
      final seedContainer = ProviderContainer.test(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(seedContainer.dispose);
      final inner = seedContainer.read(receiptRepositoryProvider);

      setSize(tester);
      await tester.pumpWidget(wrapBlocking(db, _BlockingReceiptRepo(
        inner,
        gate,
      )));
      await tester.pumpAndSettle();

      // Συμπληρώνουμε τη φόρμα (προμηθευτής + 1 είδος — αρκεί για save).
      await pickSupplier(tester);
      await pickItem(tester, 'Γάλα');
      await addLine(tester, '2,50');

      // Πρώτο tap save — κολλάει στην πύλη: isSaving=true → button disabled
      // + spinner (δεν κάνουμε pumpAndSettle: infinite animation του spinner).
      await tester.tap(
        find.widgetWithText(FilledButton, AppStrings.saveReceipt),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final saveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, AppStrings.saveReceipt),
      );
      expect(saveButton.enabled, isFalse, reason: 'isSaving → disabled-OR');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Δεύτερο tap σε disabled button → καμία επίπτωση (double-tap guard).
      await tester.tap(
        find.widgetWithText(FilledButton, AppStrings.saveReceipt),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Ανοίγει η πύλη → το save ολοκληρώνεται (πραγματικός χρόνος για το
      // insert στον background isolate· το spinner είναι infinite animation).
      gate.complete();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppMessages.savedReceipt), findsOneWidget);
      expect(find.text(AppStrings.draftLinesEmpty), findsOneWidget);

      // ΜΟΝΟ 1 απόδειξη παρά τα 2 taps.
      await tester.runAsync(() async {
        final receipts = await inner.watchAll().first;
        expect(receipts, hasLength(1));
      });

      expect(tester.takeException(), isNull);
    });
  });
}

/// Blocking receipt repository — το `insertReceiptWithLines` περιμένει την
/// [gate] πριν προχωρήσει. Όλες οι υπόλοιπες μέθοδοι διαβιβάζονται στο inner.
/// (Τοπικό αντίγραφο του idiom receipt_form_controller_test — τα test αρχεία
/// είναι ανεξάρτητα, χωρίς κοινόχρηστα private helpers.)
class _BlockingReceiptRepo implements ReceiptRepository {
  _BlockingReceiptRepo(this.inner, this.gate);

  final ReceiptRepository inner;
  final Completer<void> gate;

  @override
  Stream<List<Receipt>> watchAll() => inner.watchAll();

  @override
  Stream<List<ReceiptSummary>> watchRecentSummaries({required int limit}) =>
      inner.watchRecentSummaries(limit: limit);

  @override
  Future<Receipt?> getById(int id) => inner.getById(id);

  @override
  Future<int> insert({required DateTime date, required int supplierId}) =>
      inner.insert(date: date, supplierId: supplierId);

  @override
  Future<bool> updateById(int id, {DateTime? date, int? supplierId}) =>
      inner.updateById(id, date: date, supplierId: supplierId);

  @override
  Future<bool> deleteById(int id) => inner.deleteById(id);

  @override
  Stream<List<ReceiptLine>> watchLines(int receiptId) =>
      inner.watchLines(receiptId);

  @override
  Future<int> insertReceiptWithLines({
    required DateTime date,
    required int supplierId,
    required List<ReceiptLineInput> lines,
  }) async {
    await gate.future;
    return inner.insertReceiptWithLines(
      date: date,
      supplierId: supplierId,
      lines: lines,
    );
  }
}