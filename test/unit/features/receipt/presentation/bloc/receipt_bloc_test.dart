// test/unit/features/receipt/presentation/bloc/receipt_bloc_test.dart
//
// Επαληθεύει τον ReceiptBloc (Βήμα 6). Απόφαση Α-4: κύρια ροή με πραγματικό
// ReceiptDaoFixture + ReceiptRepositoryImpl (pattern reuse), edge cases
// (stream error, exception, lifecycle) με MockReceiptRepository (Mocktail).
//
// Οι προσδοκίες χρησιμοποιούν matchers αντί για ακριβή state instantiation —
// ώστε να μην εξαρτώνται από τον χρόνο των reactive drift emissions. Στα plain
// tests τα `firstWhere` futures γίνονται PRE-ATTACH πριν το add (broadcast
// stream χωρίς replay — bloc 9/bloc_base.dart) → deterministic sequencing.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/strings/app_strings.dart';
import 'package:expense_tracker/features/receipt/data/repositories/receipt_repository_impl.dart';
import 'package:expense_tracker/features/receipt/domain/models/receipt_input.dart';
import 'package:expense_tracker/features/receipt/domain/repositories/receipt_repository.dart';
import 'package:expense_tracker/features/receipt/presentation/bloc/receipt_bloc.dart';
import 'package:expense_tracker/features/receipt/presentation/bloc/receipt_event.dart';
import 'package:expense_tracker/features/receipt/presentation/bloc/receipt_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../core/database/daos/receipt_dao_test_fixture.dart';

class MockReceiptRepository extends Mock implements ReceiptRepository {}

void main() {
  // mocktail: το `any()` για ReceiptInput χρειάζεται fallback value.
  setUpAll(() {
    registerFallbackValue(ReceiptInput(
      date: DateTime(2026, 5, 15),
      supplierId: 1,
      paymentMethod: 'cash',
      items: [ReceiptItemInput(itemId: 1, quantity: 1, unitPrice: 1.0)],
    ));
  });

  group('ReceiptBloc', () {
    late ReceiptDaoFixture fixture;
    late ReceiptRepositoryImpl repo;

    setUp(() async {
      fixture = ReceiptDaoFixture();
      await fixture.setUp();
      repo = ReceiptRepositoryImpl(fixture.dao);
    });

    tearDown(() async {
      await fixture.tearDown();
    });

    /// Valid input, default: 1 γραμμή (itemId, qty 2 @ 10.00, vat 24%, d 0).
    ReceiptInput validInput() => ReceiptInput(
          date: DateTime(2026, 5, 15),
          supplierId: fixture.supplierId,
          paymentMethod: 'cash',
          items: [
            ReceiptItemInput(
                itemId: fixture.itemId, quantity: 2, unitPrice: 10.0),
          ],
        );

    /// Άσχημο input (supplier 0) — validation fail, χωρίς repo call.
    ReceiptInput invalidInput() => ReceiptInput(
          date: DateTime(2026, 5, 15),
          supplierId: 0,
          paymentMethod: 'cash',
          items: [
            ReceiptItemInput(
                itemId: fixture.itemId, quantity: 2, unitPrice: 10.0),
          ],
        );

    /// Input με ανύπαρκτο supplier — FK violation.
    ReceiptInput fkViolationInput() => ReceiptInput(
          date: DateTime(2026, 5, 15),
          supplierId: 99999,
          paymentMethod: 'cash',
          items: [
            ReceiptItemInput(
                itemId: fixture.itemId, quantity: 2, unitPrice: 10.0),
          ],
        );

    group('real repository (fixture)', () {
      test('initial state', () async {
        final bloc = ReceiptBloc(repository: repo);
        expect(bloc.state.status, ReceiptsStatus.initial);
        expect(bloc.state.receipts, isEmpty);
        await bloc.close();
      });

      blocTest<ReceiptBloc, ReceiptsState>(
        'load: empty DB → loading, then loaded + noReceipts message',
        build: () => ReceiptBloc(repository: repo),
        act: (bloc) async {
          final loaded =
              bloc.stream.firstWhere((s) => s.status == ReceiptsStatus.loaded);
          bloc.add(const ReceiptsLoadRequested());
          await loaded;
        },
        expect: () => [
          isA<ReceiptsState>()
              .having((s) => s.status, 'status', ReceiptsStatus.loading),
          isA<ReceiptsState>()
              .having((s) => s.status, 'status', ReceiptsStatus.loaded)
              .having((s) => s.receipts, 'receipts', isEmpty)
              .having((s) => s.message, 'message', AppStrings.noReceipts),
        ],
      );

      blocTest<ReceiptBloc, ReceiptsState>(
        'load: populated DB → loaded with 1 receipt, no empty message',
        build: () => ReceiptBloc(repository: repo),
        act: (bloc) async {
          await fixture.createReceipt();
          final loaded =
              bloc.stream.firstWhere((s) => s.status == ReceiptsStatus.loaded);
          bloc.add(const ReceiptsLoadRequested());
          await loaded;
        },
        expect: () => [
          isA<ReceiptsState>()
              .having((s) => s.status, 'status', ReceiptsStatus.loading),
          isA<ReceiptsState>()
              .having((s) => s.status, 'status', ReceiptsStatus.loaded)
              .having((s) => s.receipts, 'receipts', hasLength(1))
              .having((s) => s.selectedReceipt, 'selectedReceipt', isNull),
        ],
      );

      blocTest<ReceiptBloc, ReceiptsState>(
        'load: paymentStatus paid → empty (filter forwarded)',
        build: () => ReceiptBloc(repository: repo),
        act: (bloc) async {
          await fixture.createReceipt();
          final loaded =
              bloc.stream.firstWhere((s) => s.status == ReceiptsStatus.loaded);
          bloc.add(const ReceiptsLoadRequested(paymentStatus: 'paid'));
          await loaded;
        },
        expect: () => [
          isA<ReceiptsState>()
              .having((s) => s.status, 'status', ReceiptsStatus.loading),
          isA<ReceiptsState>()
              .having((s) => s.receipts, 'receipts', isEmpty)
              .having((s) => s.message, 'message', AppStrings.noReceipts),
        ],
      );

      blocTest<ReceiptBloc, ReceiptsState>(
        'create: success → submitting, then message + lastCreatedId',
        build: () => ReceiptBloc(repository: repo),
        act: (bloc) async {
          final done =
              bloc.stream.firstWhere((s) => !s.isSubmitting && s.lastCreatedId != null);
          bloc.add(ReceiptCreateRequested(input: validInput()));
          await done;
        },
        expect: () => [
          isA<ReceiptsState>()
              .having((s) => s.isSubmitting, 'isSubmitting', isTrue),
          isA<ReceiptsState>()
              .having((s) => s.isSubmitting, 'isSubmitting', isFalse)
              .having((s) => s.message, 'message', AppStrings.receiptAdded)
              .having((s) => s.lastCreatedId, 'lastCreatedId', isNotNull),
        ],
        verify: (_) async {
          expect(await repo.watchAll().first, hasLength(1));
        },
      );

      blocTest<ReceiptBloc, ReceiptsState>(
        'create: invalid supplier → validationErrors only, repo NOT called',
        build: () => ReceiptBloc(repository: repo),
        act: (bloc) async {
          final failed =
              bloc.stream.firstWhere((s) => s.validationErrors.isNotEmpty);
          bloc.add(ReceiptCreateRequested(input: invalidInput()));
          await failed;
        },
        expect: () => [
          isA<ReceiptsState>()
              .having((s) => s.validationErrors, 'validationErrors', isNotEmpty)
              .having((s) => s.isSubmitting, 'isSubmitting', isFalse),
        ],
        verify: (_) async {
          expect(await repo.watchAll().first, isEmpty);
        },
      );

      blocTest<ReceiptBloc, ReceiptsState>(
        'create: supplier 99999 (FK) → error + databaseError',
        build: () => ReceiptBloc(repository: repo),
        act: (bloc) async {
          final failed =
              bloc.stream.firstWhere((s) => s.status == ReceiptsStatus.error);
          bloc.add(ReceiptCreateRequested(input: fkViolationInput()));
          await failed;
        },
        expect: () => [
          isA<ReceiptsState>()
              .having((s) => s.isSubmitting, 'isSubmitting', isTrue),
          isA<ReceiptsState>()
              .having((s) => s.status, 'status', ReceiptsStatus.error)
              .having((s) => s.error, 'error', AppStrings.databaseError),
        ],
      );

      blocTest<ReceiptBloc, ReceiptsState>(
        'nextNumber: seed → 1 (preview before create)',
        build: () => ReceiptBloc(repository: repo),
        act: (bloc) async {
          final done = bloc.stream.firstWhere((s) => s.nextNumber == 1);
          bloc.add(const ReceiptNextNumberRequested());
          await done;
        },
        expect: () => [
          isA<ReceiptsState>().having((s) => s.nextNumber, 'nextNumber', 1),
        ],
      );

      blocTest<ReceiptBloc, ReceiptsState>(
        'updateItem: success → message receiptUpdated + totals recomputed',
        build: () => ReceiptBloc(repository: repo),
        act: (bloc) async {
          await fixture.createReceipt();
          final done = bloc.stream
              .firstWhere((s) => !s.isSubmitting && s.message == AppStrings.receiptUpdated);
          bloc.add(ReceiptLineUpdateRequested(
            receiptId: 1,
            itemId: fixture.itemId,
            update: const ReceiptItemUpdate(
                quantity: 5, unitPrice: 10, vatRate: 24, discount: 0),
          ));
          await done;
        },
        expect: () => [
          isA<ReceiptsState>()
              .having((s) => s.isSubmitting, 'isSubmitting', isTrue),
          isA<ReceiptsState>()
              .having((s) => s.isSubmitting, 'isSubmitting', isFalse)
              .having((s) => s.message, 'message', AppStrings.receiptUpdated),
        ],
        verify: (bloc) async {
          expect((await repo.watchAll().first).single.totalAmount, 50);
        },
      );

      blocTest<ReceiptBloc, ReceiptsState>(
        'deleteItem: success → message receiptDeleted + line removed',
        build: () => ReceiptBloc(repository: repo),
        act: (bloc) async {
          await fixture.createReceipt();
          final done = bloc.stream
              .firstWhere((s) => !s.isSubmitting && s.message == AppStrings.receiptDeleted);
          bloc.add(ReceiptLineDeleteRequested(
            receiptId: 1,
            itemId: fixture.itemId,
          ));
          await done;
        },
        expect: () => [
          isA<ReceiptsState>()
              .having((s) => s.isSubmitting, 'isSubmitting', isTrue),
          isA<ReceiptsState>()
              .having((s) => s.message, 'message', AppStrings.receiptDeleted),
        ],
        verify: (bloc) async {
          final id = (await repo.watchAll().first).single.id;
          expect(await repo.watchItemsByReceiptId(id).first, isEmpty);
        },
      );

      blocTest<ReceiptBloc, ReceiptsState>(
        'delete: success → message receiptDeleted + cascade',
        build: () => ReceiptBloc(repository: repo),
        act: (bloc) async {
          await fixture.createReceipt();
          final done = bloc.stream
              .firstWhere((s) => !s.isSubmitting && s.message == AppStrings.receiptDeleted);
          bloc.add(const ReceiptDeleteRequested(id: 1));
          await done;
        },
        expect: () => [
          isA<ReceiptsState>()
              .having((s) => s.isSubmitting, 'isSubmitting', isTrue),
          isA<ReceiptsState>()
              .having((s) => s.message, 'message', AppStrings.receiptDeleted),
        ],
        verify: (_) async {
          expect(await repo.watchAll().first, isEmpty);
        },
      );

      blocTest<ReceiptBloc, ReceiptsState>(
        'delete: nonexistent id → normal flow, NO error (F2 no-op)',
        build: () => ReceiptBloc(repository: repo),
        act: (bloc) async {
          final done = bloc.stream
              .firstWhere((s) => !s.isSubmitting && s.message == AppStrings.receiptDeleted);
          bloc.add(const ReceiptDeleteRequested(id: 99999));
          await done;
        },
        expect: () => [
          isA<ReceiptsState>()
              .having((s) => s.isSubmitting, 'isSubmitting', isTrue),
          isA<ReceiptsState>()
              .having((s) => s.status, 'status', isNot(ReceiptsStatus.error))
              .having((s) => s.message, 'message', AppStrings.receiptDeleted),
        ],
      );

      test('detail: select + derive selectedReceipt + items stream', () async {
        final id = await fixture.createReceipt();
        final bloc = ReceiptBloc(repository: repo);
        final states = <ReceiptsState>[];
        final sub = bloc.stream.listen(states.add);
        final loaded = bloc.stream.firstWhere(
            (s) => s.status == ReceiptsStatus.loaded && s.selectedReceipt != null);
        final itemsReady = bloc.stream.firstWhere((s) => s.items.length == 1);
        try {
          bloc.add(ReceiptDetailLoadRequested(id: id));
          await loaded;
          await itemsReady;
          final last = states.last;
          expect(last.selectedReceiptId, id);
          expect(last.selectedReceipt?.id, id);
          expect(last.items, hasLength(1));
          expect(last.items.single.itemId, fixture.itemId);
        } finally {
          await sub.cancel();
          await bloc.close();
        }
      });

      test('detail: nonexistent id → no crash, selected null, empty items',
          () async {
        final bloc = ReceiptBloc(repository: repo);
        final states = <ReceiptsState>[];
        final sub = bloc.stream.listen(states.add);
        final loaded =
            bloc.stream.firstWhere((s) => s.status == ReceiptsStatus.loaded);
        try {
          bloc.add(const ReceiptDetailLoadRequested(id: 99999));
          await loaded;
          final last = states.last;
          expect(last.status, ReceiptsStatus.loaded);
          expect(last.selectedReceiptId, 99999);
          expect(last.selectedReceipt, isNull);
          expect(last.items, isEmpty);
        } finally {
          await sub.cancel();
          await bloc.close();
        }
      });

      test('live: create via bloc REFRESHES watchAll list (reactive F2)',
          () async {
        final bloc = ReceiptBloc(repository: repo);
        final states = <ReceiptsState>[];
        final sub = bloc.stream.listen(states.add);
        final loaded = bloc.stream
            .firstWhere((s) => s.status == ReceiptsStatus.loaded && s.receipts.isEmpty);
        final created =
            bloc.stream.firstWhere((s) => s.message == AppStrings.receiptAdded);
        final refreshed = bloc.stream.firstWhere(
            (s) => s.status == ReceiptsStatus.loaded && s.receipts.length == 1);
        try {
          bloc.add(const ReceiptsLoadRequested());
          await loaded;
          bloc.add(ReceiptCreateRequested(input: validInput()));
          await created;
          // Reactive refresh — χωρίς manual refetch (F2):
          await refreshed;
          expect(states.last.receipts, hasLength(1));
          expect(states.last.receipts.single.receiptNumber, 1);
        } finally {
          await sub.cancel();
          await bloc.close();
        }
      });

      test('live: updateItem recomputes totals in state (reactive F2/F3)',
          () async {
        final id = await fixture.createReceipt();
        final bloc = ReceiptBloc(repository: repo);
        final states = <ReceiptsState>[];
        final sub = bloc.stream.listen(states.add);
        final loaded = bloc.stream
            .firstWhere((s) => s.status == ReceiptsStatus.loaded && s.receipts.length == 1);
        final recomputed = bloc.stream.firstWhere(
            (s) => s.receipts.length == 1 && s.receipts.single.totalAmount == 50);
        try {
          bloc.add(const ReceiptsLoadRequested());
          await loaded;
          bloc.add(ReceiptLineUpdateRequested(
            receiptId: id,
            itemId: fixture.itemId,
            update: const ReceiptItemUpdate(
                quantity: 5, unitPrice: 10, vatRate: 24, discount: 0),
          ));
          await recomputed;
          expect(
              states.any((s) => s.message == AppStrings.receiptUpdated), isTrue);
          expect(states.last.receipts.single.totalAmount, 50);
        } finally {
          await sub.cancel();
          await bloc.close();
        }
      });

      test('live: deleteItem removes line + restores totals in state', () async {
        final id = await fixture.createReceipt();
        final bloc = ReceiptBloc(repository: repo);
        final states = <ReceiptsState>[];
        final sub = bloc.stream.listen(states.add);
        final loaded = bloc.stream
            .firstWhere((s) => s.status == ReceiptsStatus.loaded && s.receipts.length == 1);
        final restored = bloc.stream.firstWhere(
            (s) => s.receipts.length == 1 && s.receipts.single.totalAmount == 0);
        try {
          bloc.add(const ReceiptsLoadRequested());
          await loaded;
          bloc.add(
              ReceiptLineDeleteRequested(receiptId: id, itemId: fixture.itemId));
          await restored;
          expect(states.last.receipts.single.totalAmount, 0);
        } finally {
          await sub.cancel();
          await bloc.close();
        }
      });

      test('live: delete receipt clears selected* when it was open', () async {
        final id = await fixture.createReceipt();
        final bloc = ReceiptBloc(repository: repo);
        final states = <ReceiptsState>[];
        final sub = bloc.stream.listen(states.add);
        final loaded = bloc.stream.firstWhere(
            (s) => s.status == ReceiptsStatus.loaded && s.selectedReceipt != null);
        final itemsReady = bloc.stream.firstWhere((s) => s.items.length == 1);
        try {
          bloc.add(ReceiptDetailLoadRequested(id: id));
          await loaded;
          await itemsReady;
          final refreshed =
              bloc.stream.firstWhere((s) => s.receipts.isEmpty);
          bloc.add(ReceiptDeleteRequested(id: id));
          await refreshed;
          expect(states.last.selectedReceiptId, isNull);
          expect(states.last.selectedReceipt, isNull);
        } finally {
          await sub.cancel();
          await bloc.close();
        }
      });
    });

    group('mocktail edge cases', () {
      late MockReceiptRepository mockRepo;

      setUp(() {
        mockRepo = MockReceiptRepository();
      });

      blocTest<ReceiptBloc, ReceiptsState>(
        'watchAll: stream error → error + genericError',
        build: () {
          when(() => mockRepo.watchAll(
                  startDate: null, endDate: null, supplierId: null,
                  paymentStatus: null)).thenAnswer(
              (_) => Stream<List<Receipt>>.error(Exception('boom')));
          return ReceiptBloc(repository: mockRepo);
        },
        act: (bloc) async {
          final failed =
              bloc.stream.firstWhere((s) => s.status == ReceiptsStatus.error);
          bloc.add(const ReceiptsLoadRequested());
          await failed;
        },
        expect: () => [
          isA<ReceiptsState>()
              .having((s) => s.status, 'status', ReceiptsStatus.loading),
          isA<ReceiptsState>()
              .having((s) => s.status, 'status', ReceiptsStatus.error)
              .having((s) => s.error, 'error', AppStrings.genericError),
        ],
      );

      blocTest<ReceiptBloc, ReceiptsState>(
        'create: repository throws → error + databaseError',
        build: () {
          when(() => mockRepo.create(any())).thenThrow(Exception('db boom'));
          return ReceiptBloc(repository: mockRepo);
        },
        act: (bloc) async {
          final failed =
              bloc.stream.firstWhere((s) => s.status == ReceiptsStatus.error);
          bloc.add(ReceiptCreateRequested(input: validInput()));
          await failed;
        },
        expect: () => [
          isA<ReceiptsState>()
              .having((s) => s.isSubmitting, 'isSubmitting', isTrue),
          isA<ReceiptsState>()
              .having((s) => s.status, 'status', ReceiptsStatus.error)
              .having((s) => s.error, 'error', AppStrings.databaseError),
        ],
      );

      test('create resolves AFTER close: guard isClosed → no StateError',
          () async {
        final repository = MockReceiptRepository();
        final completer = Completer<int>();
        when(() => repository.create(any())).thenAnswer((_) => completer.future);
        final bloc = ReceiptBloc(repository: repository);
        final started = bloc.stream.firstWhere((s) => s.isSubmitting);
        bloc.add(ReceiptCreateRequested(input: validInput()));
        await started;
        await bloc.close();
        completer.complete(1);
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
    });
  });
}