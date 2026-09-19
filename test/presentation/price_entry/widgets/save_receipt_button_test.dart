/// Widget tests — `SaveReceiptButton` (§2.2 · Φάση 3 Βήμα 5δ).
///
/// Κουμπί αποθήκευσης με disabled-OR (κενό «καλάθι» ∨ κανένας προμηθευτής ∨
/// `isSaving`) + feedback (dinner party rule — snackbars ΜΟΝΟ εδώ).
/// DB tests με πραγματική in-memory βάση (μοτίβο Βήματος 4) + failing double
/// για το error path (μοτίβο `_FailingItemRepo`).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_errors.dart';
import 'package:times/core/constants/app_messages.dart';
import 'package:times/core/constants/app_strings.dart';
import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/receipt_dao.dart';
import 'package:times/data/local/daos/receipt_line_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/repositories/receipt_repository.dart';
import 'package:times/data/repositories/receipt_repository_impl.dart';
import 'package:times/presentation/price_entry/controllers/item_search_controller.dart';
import 'package:times/presentation/price_entry/controllers/receipt_form_controller.dart';
import 'package:times/presentation/price_entry/state/receipt_form_state.dart';
import 'package:times/presentation/price_entry/widgets/save_receipt_button.dart';

import '../../../data/local/helpers/in_memory_db.dart';

/// Shared wrap: ProviderScope (προαιρετικό in-memory DB + extras) +
/// MaterialApp ελληνικά + Scaffold (SnackBar).
Widget wrap({AppDatabase? db, List<dynamic> extra = const []}) {
  return ProviderScope(
    overrides: [
      if (db != null) appDatabaseProvider.overrideWithValue(db),
      ...extra,
    ],
    child: MaterialApp(
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('el')],
      locale: const Locale('el'),
      home: const Scaffold(
        body: Center(child: SaveReceiptButton()),
      ),
    ),
  );
}

void main() {
  Future<void> pumpIt(
    WidgetTester tester, {
    AppDatabase? db,
    List<dynamic> extra = const [],
  }) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap(db: db, extra: extra));
    await tester.pumpAndSettle();
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(SaveReceiptButton)));

  /// Το κουμπί είναι ενεργό;
  bool buttonEnabled(WidgetTester tester) => tester
      .widget<FilledButton>(
        find.widgetWithText(FilledButton, AppStrings.saveReceipt),
      )
      .enabled;

  /// Seed FK-safe κατάστασης: προμηθευτής + μονάδα + είδος, επιλεγμένα στη
  /// φόρμα + 1 draft γραμμή. Επιστρέφει το είδος (για το item search).
  Future<Item> seedReadyForm(ProviderContainer container) async {
    final db = container.read(appDatabaseProvider);
    final supplierId =
        await container.read(supplierRepositoryProvider).insert(name: 'Μάρκος');
    final supplier =
        await container.read(supplierRepositoryProvider).getById(supplierId);
    final unitId = await UnitDao(db).insert(
      name: 'Κιλό',
      abbreviation: 'κιλ',
      allowsDecimal: true,
    );
    final categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    final subId = await SubCategoryDao(db)
        .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
    final itemId = await ItemDao(db).insert(subCategoryId: subId, name: 'Γάλα');
    final item = await ItemDao(db).getById(itemId);

    final form = container.read(receiptFormControllerProvider.notifier);
    form.setSupplier(supplier);
    form.addDraftLine(
      DraftReceiptLine(
        itemId: itemId,
        unitId: unitId,
        quantity: 1.5,
        priceCents: 250,
        itemName: 'Γάλα',
        unitAbbreviation: 'κιλ',
      ),
    );
    container.read(itemSearchControllerProvider.notifier).selectItem(item!);
    return item;
  }

  group('SaveReceiptButton (Βήμα 5δ)', () {
    testWidgets('κενό «καλάθι» (χωρίς DB) → ανενεργό, κανένα crash',
        (tester) async {
      await pumpIt(tester);

      expect(find.text(AppStrings.saveReceipt), findsOneWidget);
      expect(buttonEnabled(tester), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('έτοιμη φόρμα → ενεργό → tap → success + καθάρισμα',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      await pumpIt(tester, db: db);
      final container = containerOf(tester);
      await seedReadyForm(container);
      await tester.pumpAndSettle();
      expect(buttonEnabled(tester), isTrue);

      await tester.tap(
        find.widgetWithText(FilledButton, AppStrings.saveReceipt),
      );
      await tester.pumpAndSettle();

      // SnackBar επιτυχίας + φόρμα καθάρισε + επιλογή είδους καθάρισε.
      expect(find.text(AppMessages.savedReceipt), findsOneWidget);
      final form = container.read(receiptFormControllerProvider);
      expect(form.draftLines, isEmpty);
      expect(form.supplier, isNull);
      expect(
        container.read(itemSearchControllerProvider).value?.selectedItem,
        isNull,
      );
      // Βάση: η απόδειξη γράφτηκε (refresh λίστας μέσω stream, §2.2:212).
      // Το drift stream χρειάζεται πραγματικό χρόνο → `runAsync` (όπως στο
      // settleSearch του item_search_field_test).
      final receipts = await tester.runAsync(
            () => container.read(receiptRepositoryProvider).watchAll().first,
      );
      expect(receipts?.length, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('σφάλμα DB → error snackbar + drafts ΠΑΡΑΜΕΝΟΥΝ',
        (tester) async {
      await pumpIt(
        tester,
        extra: [
          receiptRepositoryProvider.overrideWithValue(
            const _FailingReceiptRepo(),
          ),
        ],
      );
      final container = containerOf(tester);
      final form = container.read(receiptFormControllerProvider.notifier);
      form
        ..setSupplier(
          Supplier(
            id: 1,
            name: 'Μάρκος',
            normalizedName: 'μαρκοσ',
            createdAt: DateTime(2026, 9, 17),
          ),
        )
        ..addDraftLine(
          const DraftReceiptLine(
            itemId: 1,
            unitId: 2,
            quantity: 1.0,
            priceCents: 100,
            itemName: 'Γάλα',
            unitAbbreviation: 'κιλ',
          ),
        );
      await tester.pumpAndSettle();
      expect(buttonEnabled(tester), isTrue);

      await tester.tap(
        find.widgetWithText(FilledButton, AppStrings.saveReceipt),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppErrors.saveFailed), findsOneWidget);
      expect(
        container.read(receiptFormControllerProvider).draftLines.length,
        1,
        reason: 'Αποτυχία → τα drafts ΠΑΡΑΜΕΝΟΥΝ (§2.2:213)',
      );
      expect(tester.takeException(), isNull);
    });
    testWidgets('απρόβλεπτο σφάλμα → γενικό error snackbar + κουμπί ξανά ενεργό',
            (tester) async {
          await pumpIt(
            tester,
            extra: [
              receiptRepositoryProvider.overrideWithValue(
                _FailingReceiptRepo(StateError('boom')),
              ),
            ],
          );
          final container = containerOf(tester);
          final form = container.read(receiptFormControllerProvider.notifier);
          form
            ..setSupplier(
              Supplier(
                id: 1,
                name: 'Μάρκος',
                normalizedName: 'μαρκοσ',
                createdAt: DateTime(2026, 9, 17),
              ),
            )
            ..addDraftLine(
              const DraftReceiptLine(
                itemId: 1,
                unitId: 2,
                quantity: 1.0,
                priceCents: 100,
                itemName: 'Γάλα',
                unitAbbreviation: 'κιλ',
              ),
            );
          await tester.pumpAndSettle();

          await tester.tap(
            find.widgetWithText(FilledButton, AppStrings.saveReceipt),
          );
          await tester.pumpAndSettle();

          expect(find.text(AppErrors.saveFailed), findsOneWidget);
          expect(container.read(receiptFormControllerProvider).isSaving, isFalse);
          expect(
            container.read(receiptFormControllerProvider).draftLines.length,
            1,
          );
          expect(buttonEnabled(tester), isTrue,
              reason: 'Το κουμπί δεν κολλάει μετά από απρόβλεπτο σφάλμα');
          expect(tester.takeException(), isNull);
        });

    testWidgets('isSaving → spinner + ανενεργό (double-tap guard)',
        (tester) async {
      final db = inMemoryDb();
      addTearDown(db.close);
      final gate = Completer<void>();
      late _BlockingReceiptRepo blocking;
      await pumpIt(
        tester,
        db: db,
        extra: [
          receiptRepositoryProvider.overrideWith((ref) {
            blocking = _BlockingReceiptRepo(
              ReceiptRepositoryImpl(
                ReceiptDao(ref.watch(appDatabaseProvider)),
                ReceiptLineDao(ref.watch(appDatabaseProvider)),
              ),
              gate,
            );
            return blocking;
          }),
        ],
      );
      final container = containerOf(tester);
      await seedReadyForm(container);
      await tester.pumpAndSettle();

      // Πάτημα χωρίς αναμονή → το save κολλάει στην πύλη.
      await tester.tap(
        find.widgetWithText(FilledButton, AppStrings.saveReceipt),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(buttonEnabled(tester), isFalse);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text(AppMessages.savedReceipt), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

/// Σκόπιμα αποτυγχάνων receipt repository — `insertReceiptWithLines` ρίχνει
/// `SaveReceiptException` (μοτίβο `_FailingItemRepo` Βήματος 4).
class _FailingReceiptRepo implements ReceiptRepository {
  /// [error] = τι ρίχνει το `insertReceiptWithLines` (default: το mapped
  /// `SaveReceiptException`· π.χ. `StateError` προσομοιώνει μη-mapped σφάλμα).
  const _FailingReceiptRepo([this.error = const SaveReceiptException()]);

  final Object error;

  @override
  Stream<List<Receipt>> watchAll() => throw const DataLoadException();
  @override
  Future<Receipt?> getById(int id) => throw const DataLoadException();
  @override
  Future<int> insert({required DateTime date, required int supplierId}) =>
      throw const DataLoadException();
  @override
  Future<bool> updateById(int id, {DateTime? date, int? supplierId}) =>
      throw const DataLoadException();
  @override
  Future<bool> deleteById(int id) => throw const DataLoadException();
  @override
  Stream<List<ReceiptLine>> watchLines(int receiptId) =>
      throw const DataLoadException();
  @override
  Future<int> insertReceiptWithLines({
    required DateTime date,
    required int supplierId,
    required List<ReceiptLineInput> lines,
  }) =>
      throw error;
}

/// Receipt repository με πύλη (Completer) πριν το πραγματικό insert.
class _BlockingReceiptRepo implements ReceiptRepository {
  _BlockingReceiptRepo(this.inner, this.gate);

  final ReceiptRepository inner;
  final Completer<void> gate;

  @override
  Stream<List<Receipt>> watchAll() => inner.watchAll();
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
