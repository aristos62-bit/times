// features/receipt/presentation/bloc/receipt_state.dart
import 'package:equatable/equatable.dart';

import '../../../../core/database/app_database.dart';

/// SPoT: Κατάσταση φόρτωσης λίστας (ανεξάρτητη από submitting/errors).
enum ReceiptsStatus { initial, loading, loaded, error }

/// SPoT: State του [ReceiptBloc] — Βήμα 6 (Phase 3).
///
/// Ένα immutable state με flags αντί για skill-level sealed states — το
/// mutation flow και το list flow μοιράζονται το ίδιο state (σκόπιμα:
/// απλοποιεί το UI που θα καταναλώσει και τα δύο σε Βήμα 7).
///
/// - `selectedReceipt` είναι ΠΑΡΑΓΩΓΟ του `receipts` + `selectedReceiptId`
///   (F3): το derive γίνεται στον BLoC όποτε αλλάζει το watchAll stream,
///   οπότε τα totals του detail header ενημερώνονται live χωρίς `getById`.
/// - Message/error: single-shot events για UI (snackbar/screens), όχι σήματα
///   μόνιμης κατάστασης.
class ReceiptsState extends Equatable {
  const ReceiptsState({
    this.status = ReceiptsStatus.initial,
    this.isSubmitting = false,
    this.receipts = const [],
    this.selectedReceiptId,
    this.selectedReceipt,
    this.items = const [],
    this.nextNumber,
    this.lastCreatedId,
    this.error,
    this.message,
    this.validationErrors = const [],
  });

  factory ReceiptsState.initial() => const ReceiptsState();

  final ReceiptsStatus status;
  final bool isSubmitting;

  /// Reactive λίστα (drift watchAll stream).
  final List<Receipt> receipts;

  final int? selectedReceiptId;

  /// Derive-εται στον BLoC από `receipts` + `selectedReceiptId` (F3).
  final Receipt? selectedReceipt;

  /// Reactive γραμμές του selected receipt (watchItemsByReceiptId).
  final List<ReceiptItem> items;

  /// Preview επόμενου αριθμού (ReceiptNextNumberRequested).
  final int? nextNumber;

  /// Id του τελευταίου επιτυχημένου create.
  final int? lastCreatedId;

  final String? error;
  final String? message;

  /// Λάθη validation (από Validators.validateReceipt) — δείχνονται στο form.
  final List<String> validationErrors;

  /// copyWith με nullable getters (sentinel) — επιτρέπει reset σε null:
  /// π.χ. `copyWith(message: () => null)`.
  ReceiptsState copyWith({
    ReceiptsStatus? status,
    bool? isSubmitting,
    List<Receipt>? receipts,
    int? Function()? selectedReceiptId,
    Receipt? Function()? selectedReceipt,
    List<ReceiptItem>? items,
    int? Function()? nextNumber,
    int? Function()? lastCreatedId,
    String? Function()? error,
    String? Function()? message,
    List<String>? validationErrors,
  }) {
    return ReceiptsState(
      status: status ?? this.status,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      receipts: receipts ?? this.receipts,
      selectedReceiptId: selectedReceiptId != null
          ? selectedReceiptId()
          : this.selectedReceiptId,
      selectedReceipt:
          selectedReceipt != null ? selectedReceipt() : this.selectedReceipt,
      items: items ?? this.items,
      nextNumber: nextNumber != null ? nextNumber() : this.nextNumber,
      lastCreatedId: lastCreatedId != null ? lastCreatedId() : this.lastCreatedId,
      error: error != null ? error() : this.error,
      message: message != null ? message() : this.message,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }

  @override
  List<Object?> get props => [
        status,
        isSubmitting,
        receipts,
        selectedReceiptId,
        selectedReceipt,
        items,
        nextNumber,
        lastCreatedId,
        error,
        message,
        validationErrors,
      ];
}