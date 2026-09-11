// features/receipt/presentation/bloc/receipt_bloc.dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/debug/app_logger.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/repositories/receipt_repository.dart';
import 'receipt_event.dart';
import 'receipt_state.dart';

/// SPoT: ReceiptBloc — Βήμα 6 (Phase 3, DESIGN §5.1.7).
///
/// Καθαρό presentation-flow πάνω από το [ReceiptRepository] (Route A-Συνεπές).
///
/// Σχεδιαστικές αποφάσεις (από αναθεωρημένη πρόταση Βήμ. 6):
/// - **Reactive χωρίς manual refetch (F2):** `watchAll` / `watchItemsByReceiptId`
///   ενημερώνουν μόνα τους το state μετά από mutations (drift streams). Ο BLoC
///   κάνει ΜΟΝΟ single-shot mutations (create/update/delete) + μήνυμα επιτυχίας.
/// - **Stream bridge (bloc 9 restriction):** στο bloc το `emit` επιτρέπεται μόνο
///   εντός handler. Οι reactive subscriptions ΔΕΝ καλούν `emit` απευθείας —
///   διαβιβάζουν μέσω `bloc.add(_ReceiptsStreamUpdated)` κ.λπ. (εσωτερικά
///   events) και οι handlers δημιουργούν τα states.
/// - **selectedReceipt παράγωγο (F3):** δεν γίνεται `getById` για το detail
///   header — derive-εται από τη λίστα του `watchAll` + `selectedReceiptId`.
/// - **Α-1 (constructor injection):** `repository` είναι required — κανένα
///   lookup του service locator εδώ. Το wiring (`DependencyInjection.get`)
///   γίνεται στο main() / Βήμα 7 (σύμφωνα με το DI docstring).
/// - **Α-2 (0 νέα AppStrings):** όλα τα μηνύματα reuse από το AppStrings.
/// - **Validation (F8):** ΜΟΝΟ `Validators.validateReceipt` πριν το create.
/// - **No-op delete (F2):** διαγραφή ανύπαρκτου id = κανονική ροή, όχι error.
/// - **Debug:** `AppLogger.bloc(...)` gated από `DebugConfig.showBlocLogs`.
/// - **Lifecycle:** guard `if (isClosed) return;` σε κάθε callback + cancel
///   subscriptions στο [close].
class ReceiptBloc extends Bloc<ReceiptEvent, ReceiptsState> {
  ReceiptBloc({required ReceiptRepository repository})
      : super(ReceiptsState.initial()) {
    _repository = repository;
    on<ReceiptsLoadRequested>(_onLoadReceipts);
    on<ReceiptCreateRequested>(_onCreate);
    on<ReceiptDetailLoadRequested>(_onDetailLoad);
    on<ReceiptLineUpdateRequested>(_onUpdateLine);
    on<ReceiptLineDeleteRequested>(_onDeleteLine);
    on<ReceiptDeleteRequested>(_onDeleteReceipt);
    on<ReceiptNextNumberRequested>(_onNextNumber);
    on<ReceiptsStreamUpdated>(_onReceiptsStreamUpdated);
    on<ReceiptItemsStreamUpdated>(_onReceiptItemsStreamUpdated);
    on<ReceiptStreamError>(_onStreamError);
  }

  late final ReceiptRepository _repository;

  StreamSubscription<List<Receipt>>? _receiptsSub;
  StreamSubscription<List<ReceiptItem>>? _itemsSub;

  // ---------------------------------------------------------------------
  //  Events
  // ---------------------------------------------------------------------

  /// Φόρτωση λίστας (reactive). Ακυρώνει προηγούμενα subs, θέτει loading
  /// και subscriber σε `watchAll` με τα φίλτρα του event.
  void _onLoadReceipts(
      ReceiptsLoadRequested event, Emitter<ReceiptsState> emit) {
    AppLogger.bloc('ReceiptBloc: event=${event.runtimeType}');
    _cancelSubscriptions();
    emit(state.copyWith(
      status: ReceiptsStatus.loading,
      receipts: const [],
      items: const [],
      selectedReceiptId: () => null,
      selectedReceipt: () => null,
      error: () => null,
      message: () => null,
      validationErrors: const [],
    ));
    _subscribeReceipts(event);
  }

  /// Άνοιγμα detail: θέτει `selectedReceiptId`, derive-ει το `selectedReceipt`
  /// από τη λίστα (F3) και subscriber σε `watchItemsByReceiptId`.
  /// Αν δεν υπάρχει ενεργό watchAll, ξεκινά ένα χωρίς φίλτρα (για το derive).
  void _onDetailLoad(
      ReceiptDetailLoadRequested event, Emitter<ReceiptsState> emit) {
    AppLogger.bloc('ReceiptBloc: event=${event.runtimeType}');
    _cancelItemsSub();
    emit(state.copyWith(
      selectedReceiptId: () => event.id,
      selectedReceipt: () => _deriveSelected(event.id, state.receipts),
      error: () => null,
      message: () => null,
    ));
    if (_receiptsSub == null) {
      _subscribeReceipts(const ReceiptsLoadRequested());
    }
    _subscribeItems(event.id);
  }

  /// Create: validation ΠΡΩΤΑ (SPoT), αλλιώς create στο repo.
  /// Δεν γίνεται manual refresh — το δραστικό watchAll ενημερώνει τη λίστα.
  Future<void> _onCreate(
      ReceiptCreateRequested event, Emitter<ReceiptsState> emit) async {
    AppLogger.bloc('ReceiptBloc: event=${event.runtimeType}');

    // Validation ΠΡΩΤΑ (SPoT) — αν fail, καμία κλήση repo (F8).
    final result = Validators.validateReceipt(
      date: event.input.date,
      supplierId: event.input.supplierId,
      paymentMethod: event.input.paymentMethod,
      items: event.input.items,
    );
    if (!result.isValid) {
      emit(state.copyWith(
        isSubmitting: false,
        error: () => null,
        message: () => null,
        validationErrors: result.errors,
      ));
      return;
    }

    emit(state.copyWith(
      isSubmitting: true,
      error: () => null,
      message: () => null,
      validationErrors: const [],
    ));

    try {
      final id = await _repository.create(event.input);
      if (isClosed) return;
      emit(state.copyWith(
        isSubmitting: false,
        lastCreatedId: () => id,
        message: () => AppStrings.receiptAdded,
      ));
    } catch (e, st) {
      AppLogger.error('ReceiptBloc: create failed: $e', st);
      if (isClosed) return;
      emit(state.copyWith(
        isSubmitting: false,
        status: ReceiptsStatus.error,
        error: () => AppStrings.databaseError,
      ));
    }
  }

  /// Update γραμμής: single-shot call. Τα totals/stock ενημερώνονται live
  /// από τα reactive streams (F2/F3).
  Future<void> _onUpdateLine(
      ReceiptLineUpdateRequested event, Emitter<ReceiptsState> emit) async {
    AppLogger.bloc('ReceiptBloc: event=${event.runtimeType}');
    emit(state.copyWith(
      isSubmitting: true,
      error: () => null,
      message: () => null,
    ));
    try {
      await _repository.updateItem(
          event.receiptId, event.itemId, event.update);
      if (isClosed) return;
      emit(state.copyWith(
        isSubmitting: false,
        message: () => AppStrings.receiptUpdated,
      ));
    } catch (e, st) {
      AppLogger.error('ReceiptBloc: updateItem failed: $e', st);
      if (isClosed) return;
      emit(state.copyWith(
        isSubmitting: false,
        status: ReceiptsStatus.error,
        error: () => AppStrings.databaseError,
      ));
    }
  }

  /// Delete γραμμής: single-shot call. Reactive ενημέρωση items/totals.
  Future<void> _onDeleteLine(
      ReceiptLineDeleteRequested event, Emitter<ReceiptsState> emit) async {
    AppLogger.bloc('ReceiptBloc: event=${event.runtimeType}');
    emit(state.copyWith(
      isSubmitting: true,
      error: () => null,
      message: () => null,
    ));
    try {
      await _repository.deleteItem(event.receiptId, event.itemId);
      if (isClosed) return;
      emit(state.copyWith(
        isSubmitting: false,
        message: () => AppStrings.receiptDeleted,
      ));
    } catch (e, st) {
      AppLogger.error('ReceiptBloc: deleteItem failed: $e', st);
      if (isClosed) return;
      emit(state.copyWith(
        isSubmitting: false,
        status: ReceiptsStatus.error,
        error: () => AppStrings.databaseError,
      ));
    }
  }

  /// Delete ολόκληρης απόδειξης. Αν ήταν open, καθαρίζει τα selected*.
  /// No-op σε ανύπαρκτο id (F2) — κανονική ροή.
  Future<void> _onDeleteReceipt(
      ReceiptDeleteRequested event, Emitter<ReceiptsState> emit) async {
    AppLogger.bloc('ReceiptBloc: event=${event.runtimeType}');
    emit(state.copyWith(
      isSubmitting: true,
      error: () => null,
      message: () => null,
    ));
    try {
      await _repository.delete(event.id);
      if (isClosed) return;
      final cleared = state.selectedReceiptId == event.id;
      emit(state.copyWith(
        isSubmitting: false,
        message: () => AppStrings.receiptDeleted,
        selectedReceiptId: cleared ? () => null : null,
        selectedReceipt: cleared ? () => null : null,
      ));
    } catch (e, st) {
      AppLogger.error('ReceiptBloc: delete failed: $e', st);
      if (isClosed) return;
      emit(state.copyWith(
        isSubmitting: false,
        status: ReceiptsStatus.error,
        error: () => AppStrings.databaseError,
      ));
    }
  }

  /// Preview επόμενου αριθμού (π.χ. στο form πριν την καταχώρηση).
  Future<void> _onNextNumber(
      ReceiptNextNumberRequested event, Emitter<ReceiptsState> emit) async {
    AppLogger.bloc('ReceiptBloc: event=${event.runtimeType}');
    try {
      final number = await _repository.getNextReceiptNumber();
      if (isClosed) return;
      emit(state.copyWith(nextNumber: () => number));
    } catch (e, st) {
      AppLogger.error('ReceiptBloc: getNextReceiptNumber failed: $e', st);
      if (isClosed) return;
      emit(state.copyWith(
        status: ReceiptsStatus.error,
        error: () => AppStrings.databaseError,
      ));
    }
  }

  // ---------------------------------------------------------------------
  //  Bridge handlers (εσωτερικά events από reactive streams)
  // ---------------------------------------------------------------------

  /// Reactive λίστα → loaded + derive selectedReceipt + empty-state message.
  void _onReceiptsStreamUpdated(
      ReceiptsStreamUpdated event, Emitter<ReceiptsState> emit) {
    emit(state.copyWith(
      status: ReceiptsStatus.loaded,
      receipts: event.receipts,
      selectedReceipt: () => _deriveSelected(state.selectedReceiptId, event.receipts),
      message: () => event.receipts.isEmpty ? AppStrings.noReceipts : null,
    ));
  }

  /// Reactive γραμμές του selected receipt → items.
  void _onReceiptItemsStreamUpdated(
      ReceiptItemsStreamUpdated event, Emitter<ReceiptsState> emit) {
    emit(state.copyWith(items: event.items));
  }

  /// Error από reactive stream → status error + genericError.
  void _onStreamError(ReceiptStreamError event, Emitter<ReceiptsState> emit) {
    emit(state.copyWith(
      status: ReceiptsStatus.error,
      error: () => AppStrings.genericError,
    ));
  }

  // ---------------------------------------------------------------------
  //  Private helpers
  // ---------------------------------------------------------------------

  /// Subscriber στο watchAll — προωθεί δεδομένα μέσω εσωτερικών events
  /// (stream bridge, βλ. docstring της κλάσης).
  void _subscribeReceipts(ReceiptsLoadRequested event) {
    _receiptsSub = _repository
        .watchAll(
          startDate: event.startDate,
          endDate: event.endDate,
          supplierId: event.supplierId,
          paymentStatus: event.paymentStatus,
        )
        .listen(
      (receipts) {
        if (isClosed) return;
        add(ReceiptsStreamUpdated(receipts));
      },
      onError: (Object e) {
        if (isClosed) return;
        AppLogger.error('ReceiptBloc: watchAll error: $e');
        add(const ReceiptStreamError());
      },
      onDone: () {
        if (isClosed) return;
        AppLogger.bloc('ReceiptBloc: watchAll done');
      },
    );
  }

  /// Subscriber στο watchItemsByReceiptId — ίδιο bridge pattern.
  void _subscribeItems(int receiptId) {
    _itemsSub = _repository.watchItemsByReceiptId(receiptId).listen(
      (items) {
        if (isClosed) return;
        add(ReceiptItemsStreamUpdated(items));
      },
      onError: (Object e) {
        if (isClosed) return;
        AppLogger.error('ReceiptBloc: watchItemsByReceiptId error: $e');
        add(const ReceiptStreamError());
      },
      onDone: () {
        if (isClosed) return;
        AppLogger.bloc('ReceiptBloc: watchItemsByReceiptId done');
      },
    );
  }

  /// Derive selected receipt από τη λίστα (F3) — null αν id κενό/ανύπαρκτο.
  Receipt? _deriveSelected(int? id, List<Receipt> receipts) {
    if (id == null) return null;
    for (final receipt in receipts) {
      if (receipt.id == id) return receipt;
    }
    return null;
  }

  void _cancelSubscriptions() {
    _cancelItemsSub();
    final receiptsSub = _receiptsSub;
    _receiptsSub = null;
    receiptsSub?.cancel();
  }

  void _cancelItemsSub() {
    final itemsSub = _itemsSub;
    _itemsSub = null;
    itemsSub?.cancel();
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}