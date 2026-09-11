// test/widget/features/receipt/presentation/screens/receipt_entry_screen_test.dart
//
// ReceiptEntryScreen: preview next number + form + submit (Βήμα 7).
// Pattern: mocktail mock repository + bloc. State-driven όπου γίνεται,
// real events μόνο για nextNumber/create (με addTearDown close — αλλιώς
// το flutter_tester δεν τερματίζει).
import 'package:expense_tracker/core/constants/app_constants.dart';
import 'package:expense_tracker/core/strings/app_strings.dart';
import 'package:expense_tracker/features/receipt/domain/models/receipt_input.dart';
import 'package:expense_tracker/features/receipt/domain/repositories/receipt_repository.dart';
import 'package:expense_tracker/features/receipt/presentation/bloc/receipt_bloc.dart';
import 'package:expense_tracker/features/receipt/presentation/bloc/receipt_state.dart';
import 'package:expense_tracker/features/receipt/presentation/screens/receipt_entry_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReceiptRepository extends Mock implements ReceiptRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(ReceiptInput(
      date: DateTime(2026, 9, 11),
      supplierId: 1,
      paymentMethod: 'cash',
      items: const [ReceiptItemInput(itemId: 1, quantity: 1, unitPrice: 1)],
    ));
  });

  ReceiptBloc blocWith(MockReceiptRepository repo, ReceiptsState state,
      {int nextNumber = 1}) {
    when(() => repo.watchAll(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            supplierId: any(named: 'supplierId'),
            paymentStatus: any(named: 'paymentStatus')))
        .thenAnswer((_) => Stream.value([]));
    // Το screen κάνει πάντα postFrame ReceiptNextNumberRequested — default stub.
    when(() => repo.getNextReceiptNumber())
        .thenAnswer((_) async => nextNumber);
    final bloc = ReceiptBloc(repository: repo);
    addTearDown(bloc.close);
    bloc.emit(state);
    return bloc;
  }

  Future<void> pumpEntry(
    WidgetTester tester, {
    required ReceiptBloc bloc,
    ValueChanged<ReceiptInput>? onInputChanged,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BlocProvider<ReceiptBloc>.value(
          value: bloc,
          child: ReceiptEntryScreen(onInputChanged: onInputChanged),
        ),
      ),
    ));
    await tester.pump();
  }

  group('ReceiptEntryScreen', () {
    testWidgets('δείχνει τίτλο + φόρμα + κουμπί αποθήκευσης', (tester) async {
      final repo = MockReceiptRepository();
      final bloc = blocWith(repo, ReceiptsState.initial());
      await pumpEntry(tester, bloc: bloc);
      expect(find.text(AppStrings.addReceiptTitle), findsOneWidget);
      expect(find.text(AppStrings.receiptDate), findsOneWidget);
      expect(find.text(AppStrings.supplier), findsOneWidget);
      expect(find.text(AppStrings.paymentMethod), findsOneWidget);
      expect(find.text(AppStrings.save), findsOneWidget);
    });

    testWidgets('submitting → LoadingIndicator', (tester) async {
      final repo = MockReceiptRepository();
      final bloc = blocWith(
          repo, const ReceiptsState(isSubmitting: true));
      await pumpEntry(tester, bloc: bloc);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error → AppErrorWidget', (tester) async {
      final repo = MockReceiptRepository();
      final bloc = blocWith(
          repo,
          const ReceiptsState(
            status: ReceiptsStatus.error,
            error: AppStrings.databaseError,
          ));
      await pumpEntry(tester, bloc: bloc);
      expect(find.text(AppStrings.databaseError), findsOneWidget);
      expect(find.text(AppStrings.retry), findsOneWidget);
    });

    testWidgets('preview επόμενου αριθμού μετά το load', (tester) async {
      final repo = MockReceiptRepository();
      final bloc = blocWith(repo, ReceiptsState.initial(), nextNumber: 7);
      await pumpEntry(tester, bloc: bloc);
      // postFrame dispatch → nextNumber → preview (χρειάζονται pumps).
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(
          find.text('${AppStrings.receiptNextNumber}: #7'), findsOneWidget);
    });

    testWidgets('onInputChanged καλείται με νέο supplierId', (tester) async {
      final repo = MockReceiptRepository();
      final bloc = blocWith(repo, ReceiptsState.initial());
      ReceiptInput? captured;
      await pumpEntry(tester,
          bloc: bloc, onInputChanged: (input) => captured = input);
      await tester.pump();
      await tester.pump();
      await tester.enterText(
          find.widgetWithText(TextField, AppStrings.supplier), '2');
      await tester.pump();
      expect(captured, isNotNull);
      expect(captured!.supplierId, 2);
    });

    testWidgets('έγκυρο submit → create καλείται μία φορά', (tester) async {
      final repo = MockReceiptRepository();
      when(() => repo.create(any())).thenAnswer((_) async => 42);
      final bloc = blocWith(repo, ReceiptsState.initial());
      await pumpEntry(tester, bloc: bloc);
      await tester.pump();
      await tester.pump();

      // Συμπλήρωση: supplier + 1 γραμμή (item/qty/price).
      await tester.enterText(
          find.widgetWithText(TextField, AppStrings.supplier), '2');
      await tester.tap(find.text(AppStrings.addLine));
      await tester.pump();
      await tester.enterText(
          find.widgetWithText(TextField, AppStrings.item), '1');
      await tester.enterText(
          find.widgetWithText(TextField, AppStrings.quantity), '2');
      await tester.enterText(
          find.widgetWithText(TextField, AppStrings.unitPrice), '10');
      await tester.pump();

      // Το save είναι κάτω από το fold (lazy ListView) → scroll στο outer.
      await tester.scrollUntilVisible(
        find.text(AppStrings.save),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(AppStrings.save));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      final captured =
          verify(() => repo.create(captureAny())).captured.single
              as ReceiptInput;
      expect(captured.supplierId, 2);
      expect(captured.items, hasLength(1));
      expect(captured.items.single.itemId, 1);
      expect(captured.paymentMethod, AppConstants.paymentMethods.first);
    });

    testWidgets('άδειο submit → validation snackbar, ΟΧΙ create',
        (tester) async {
      final repo = MockReceiptRepository();
      when(() => repo.create(any())).thenAnswer((_) async => 42);
      final bloc = blocWith(repo, ReceiptsState.initial());
      await pumpEntry(tester, bloc: bloc);
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text(AppStrings.save));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      verifyNever(() => repo.create(any()));
      // Snackbar με supplierRequired (supplierId 0 + άδεια items).
      expect(find.textContaining(AppStrings.supplierRequired), findsWidgets);
      await tester.pump(const Duration(seconds: 3));
    });
  });
}