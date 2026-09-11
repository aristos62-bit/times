// test/widget/features/receipt/presentation/screens/receipt_detail_screen_test.dart
//
// ReceiptDetailScreen: header + notes + items + totals footer (Βήμα 7).
// Pattern: mocktail mock repository + bloc, state-driven (emit) + ένα
// real-dispatch test για το derive path (addTearDown close παντού).
import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/strings/app_strings.dart';
import 'package:expense_tracker/features/receipt/domain/repositories/receipt_repository.dart';
import 'package:expense_tracker/features/receipt/presentation/bloc/receipt_bloc.dart';
import 'package:expense_tracker/features/receipt/presentation/bloc/receipt_state.dart';
import 'package:expense_tracker/features/receipt/presentation/screens/receipt_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReceiptRepository extends Mock implements ReceiptRepository {}

void main() {
  final receipt = Receipt(
    id: 1,
    uuid: 'uuid-1',
    receiptNumber: 12,
    receiptDate: DateTime(2026, 9, 1),
    supplierId: 1,
    paymentMethod: 'cash',
    totalAmount: 10,
    vatTotal: 2.4,
    discountTotal: 0,
    paidAmount: 12.4,
    remainingAmount: 0,
    paymentStatus: 'paid',
    notes: 'Σημείωση',
    isSynced: false,
    createdAt: DateTime(2026, 9, 1),
    updatedAt: DateTime(2026, 9, 1),
  );

  final item = ReceiptItem(
    id: 1,
    uuid: 'uuid-item-1',
    receiptId: 1,
    itemId: 5,
    quantity: 2,
    unitPrice: 10,
    vatRate: 24,
    vatAmount: 4.8,
    discount: 0,
    totalPrice: 20,
    totalWithVat: 24.8,
    createdAt: DateTime(2026, 9, 1),
  );

  ReceiptBloc blocWith(MockReceiptRepository repo, ReceiptsState state,
      {bool withData = false, bool withError = false}) {
    // State-driven tests: Stream.empty (καμία εκπομπή — το emitted state μένει).
    // Real-dispatch test: Stream.value (derive path).
    // Error test: Stream.error (πραγματικό reactive error path).
    when(() => repo.watchAll(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            supplierId: any(named: 'supplierId'),
            paymentStatus: any(named: 'paymentStatus')))
        .thenAnswer((_) {
      if (withError) return Stream.error(Exception('boom'));
      return withData ? Stream.value([receipt]) : const Stream.empty();
    });
    when(() => repo.watchItemsByReceiptId(any())).thenAnswer((_) =>
        withData ? Stream.value([item]) : const Stream.empty());
    final bloc = ReceiptBloc(repository: repo);
    addTearDown(bloc.close);
    bloc.emit(state);
    return bloc;
  }

  Future<void> pumpDetail(
    WidgetTester tester, {
    required ReceiptBloc bloc,
    int receiptId = 1,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BlocProvider<ReceiptBloc>.value(
          value: bloc,
          child: ReceiptDetailScreen(receiptId: receiptId),
        ),
      ),
    ));
    await tester.pump();
  }

  group('ReceiptDetailScreen', () {
    testWidgets('initial → LoadingIndicator', (tester) async {
      final repo = MockReceiptRepository();
      final bloc = blocWith(repo, ReceiptsState.initial());
      await pumpDetail(tester, bloc: bloc);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('loaded χωρίς receipt → LoadingIndicator (await stream)',
        (tester) async {
      final repo = MockReceiptRepository();
      final bloc = blocWith(
          repo,
          const ReceiptsState(
            status: ReceiptsStatus.loaded,
            selectedReceiptId: 999,
          ));
      await pumpDetail(tester, bloc: bloc, receiptId: 999);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error → AppErrorWidget', (tester) async {
      final repo = MockReceiptRepository();
      final bloc =
          blocWith(repo, ReceiptsState.initial(), withError: true);
      await pumpDetail(tester, bloc: bloc);
      // postFrame dispatch + stream error → genericError (pumps).
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(find.text(AppStrings.genericError), findsOneWidget);
    });

    testWidgets('loaded → header + ημερομηνία + notes', (tester) async {
      final repo = MockReceiptRepository();
      final bloc = blocWith(
          repo,
          ReceiptsState(
            status: ReceiptsStatus.loaded,
            selectedReceiptId: 1,
            receipts: [receipt],
            selectedReceipt: receipt,
            items: [item],
          ));
      await pumpDetail(tester, bloc: bloc);
      expect(find.text('Απόδειξη #12'), findsOneWidget);
      expect(find.text('01/09/2026'), findsOneWidget);
      expect(find.text('Σημείωση'), findsOneWidget);
    });

    testWidgets('loaded → γραμμή είδους + totals footer', (tester) async {
      final repo = MockReceiptRepository();
      final bloc = blocWith(
          repo,
          ReceiptsState(
            status: ReceiptsStatus.loaded,
            selectedReceiptId: 1,
            receipts: [receipt],
            selectedReceipt: receipt,
            items: [item],
          ));
      await pumpDetail(tester, bloc: bloc);
      // Γραμμή: "Είδος #5" + 24,80€.
      expect(find.text('Είδος #5'), findsOneWidget);
      expect(find.text('24,80€'), findsOneWidget);
      // Footer labels + τιμές.
      expect(find.text(AppStrings.total), findsOneWidget);
      expect(find.text('10,00€'), findsOneWidget);
      expect(find.text(AppStrings.totalVat), findsOneWidget);
      expect(find.text('2,40€'), findsOneWidget);
      expect(find.text(AppStrings.totalWithVat), findsOneWidget);
      expect(find.text('12,40€'), findsWidgets);
      expect(find.text(AppStrings.paidAmount), findsOneWidget);
      expect(find.text(AppStrings.remainingAmount), findsOneWidget);
      expect(find.text('0,00€'), findsOneWidget);
    });

    testWidgets('loaded + άδεια items → noItemsInReceipt', (tester) async {
      final repo = MockReceiptRepository();
      final bloc = blocWith(
          repo,
          ReceiptsState(
            status: ReceiptsStatus.loaded,
            selectedReceiptId: 1,
            receipts: [receipt],
            selectedReceipt: receipt,
            items: const [],
          ));
      await pumpDetail(tester, bloc: bloc);
      expect(find.text(AppStrings.noItemsInReceipt), findsOneWidget);
    });

    testWidgets('real dispatch → derive selected από stream', (tester) async {
      final repo = MockReceiptRepository();
      final bloc = blocWith(repo, ReceiptsState.initial(), withData: true);
      await pumpDetail(tester, bloc: bloc);
      // postFrame ReceiptDetailLoadRequested + reactive derive (pumps).
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(find.text('Απόδειξη #12'), findsOneWidget);
      expect(find.text('Είδος #5'), findsOneWidget);
    });
  });
}
