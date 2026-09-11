// test/widget/features/receipt/presentation/screens/receipt_list_screen_test.dart
//
// ReceiptListScreen: BlocConsumer + FAB + callbacks (Βήμα 7).
// Pattern: mocktail mock receipt repository + bloc, streams/μηνύματα.
import 'dart:async';

import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/strings/app_strings.dart';
import 'package:expense_tracker/features/receipt/domain/repositories/receipt_repository.dart';
import 'package:expense_tracker/features/receipt/presentation/bloc/receipt_bloc.dart';
import 'package:expense_tracker/features/receipt/presentation/bloc/receipt_event.dart';
import 'package:expense_tracker/features/receipt/presentation/bloc/receipt_state.dart';
import 'package:expense_tracker/features/receipt/presentation/screens/receipt_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReceiptRepository extends Mock implements ReceiptRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const ReceiptsLoadRequested());
  });

  Receipt fakeReceipt({int id = 1}) => Receipt(
        id: id,
        uuid: 'uuid-$id',
        receiptNumber: id,
        receiptDate: DateTime(2026, 9, 1),
        supplierId: 1,
        paymentMethod: 'cash',
        totalAmount: 10,
        vatTotal: 2.4,
        discountTotal: 0,
        paidAmount: 12.4,
        remainingAmount: 0,
        paymentStatus: 'paid',
        isSynced: false,
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
      );

  Future<ReceiptBloc> pumpScreen(
    WidgetTester tester, {
    required ReceiptsState initialState,
    VoidCallback? onCreateRequested,
    ValueChanged<int>? onReceiptSelected,
    ReceiptBloc? bloc,
  }) async {
    final repo = MockReceiptRepository();
    when(() => repo.watchAll(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            supplierId: any(named: 'supplierId'),
            paymentStatus: any(named: 'paymentStatus')))
        .thenAnswer((_) => Stream.value([]));
    final realBloc = bloc ?? ReceiptBloc(repository: repo);
    // Cleanup: κλειστά blocs — αλλιώς το flutter_tester δεν τερματίζει.
    addTearDown(realBloc.close);
    // Θέτουμε αρχικό state μέσω emit, ώστε να μη χρειαστούν εκκινήσεις events.
    realBloc.emit(initialState);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BlocProvider<ReceiptBloc>.value(
          value: realBloc,
          child: ReceiptListScreen(
            onCreateRequested: onCreateRequested ?? () {},
            onReceiptSelected: onReceiptSelected ?? (_) {},
          ),
        ),
      ),
    ));
    await tester.pump();
    return realBloc;
  }

  group('ReceiptListScreen', () {
    testWidgets('initial/loading → LoadingIndicator', (tester) async {
      await pumpScreen(tester,
          initialState: const ReceiptsState(status: ReceiptsStatus.initial));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('loading → LoadingIndicator', (tester) async {
      await pumpScreen(tester,
          initialState: const ReceiptsState(status: ReceiptsStatus.loading));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error → AppErrorWidget + retry', (tester) async {
      await pumpScreen(tester,
          initialState: const ReceiptsState(
            status: ReceiptsStatus.error,
            error: 'Σφάλμα',
          ));
      expect(find.text('Σφάλμα'), findsOneWidget);
      expect(find.text(AppStrings.retry), findsOneWidget);
    });

    testWidgets('error → retry κάνει reload (EmptyState)', (tester) async {
      await pumpScreen(tester,
          initialState: const ReceiptsState(
            status: ReceiptsStatus.error,
            error: 'Σφάλμα',
          ));
      await tester.tap(find.text(AppStrings.retry));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      // Reload με άδειο stream → EmptyState + snackbar noReceipts.
      expect(find.text(AppStrings.noReceipts), findsWidgets);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('loaded + empty → EmptyState + add FAB', (tester) async {
      var tapped = false;
      await pumpScreen(tester,
          initialState: const ReceiptsState(
            status: ReceiptsStatus.loaded,
            receipts: [],
          ),
          onCreateRequested: () => tapped = true);
      expect(find.text(AppStrings.noReceipts), findsOneWidget);
      // FAB (FloatingActionButton) — EmptyState έχει επίσης icon add αλλά δεν FAB.
      expect(find.byType(FloatingActionButton), findsOneWidget);
      // FAB tap → onCreateRequested
      await tester.tap(find.byType(FloatingActionButton));
      expect(tapped, isTrue);
    });

    testWidgets('loaded + 1 receipt → ReceiptCard visible', (tester) async {
      await pumpScreen(tester,
          initialState: ReceiptsState(
            status: ReceiptsStatus.loaded,
            receipts: [fakeReceipt(id: 1)],
          ));
      // ReceiptCard: "Απόδειξη #1"
      expect(find.text('Απόδειξη #1'), findsOneWidget);
    });

    testWidgets('receipt tap → onReceiptSelected(id)', (tester) async {
      int? selectedId;
      await pumpScreen(tester,
          initialState: ReceiptsState(
            status: ReceiptsStatus.loaded,
            receipts: [fakeReceipt(id: 42)],
          ),
          onReceiptSelected: (id) => selectedId = id);
      await tester.tap(find.text('Απόδειξη #42'));
      expect(selectedId, 42);
    });

    testWidgets('message transition → snackbar + auto-clean (bridge)',
        (tester) async {
      final repo = MockReceiptRepository();
      when(() => repo.watchAll(
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
              supplierId: any(named: 'supplierId'),
              paymentStatus: any(named: 'paymentStatus')))
          .thenAnswer((_) => Stream.value([]));
      final bloc = ReceiptBloc(repository: repo);
      addTearDown(bloc.close);

      // State-driven (χωρίς events — fake async): ξεκινάμε loaded χωρίς message.
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BlocProvider<ReceiptBloc>.value(
            value: bloc,
            child: ReceiptListScreen(
              onCreateRequested: () {},
              onReceiptSelected: (_) {},
            ),
          ),
        ),
      ));
      bloc.emit(const ReceiptsState(
        status: ReceiptsStatus.loaded,
        receipts: [],
      ));
      await tester.pump();

      // Now message transition → snackbar εμφανίζεται.
      bloc.emit(const ReceiptsState(
        status: ReceiptsStatus.loaded,
        receipts: [],
        message: AppStrings.noReceipts,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text(AppStrings.noReceipts), findsWidgets);
      // Αφήνουμε το Snackbar να κλείσει μόνο του (δεν κρεμούν timers).
      await tester.pump(const Duration(seconds: 3));
    });
  });
}