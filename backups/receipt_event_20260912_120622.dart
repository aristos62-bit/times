// features/receipt/presentation/bloc/receipt_event.dart
import 'package:equatable/equatable.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/models/receipt_input.dart';

/// SPoT: Events του [ReceiptBloc] — Βήμα 6 (Phase 3).
///
/// Sealed + Equatable: pattern matching με exhaustive cases (Dart 3) και
/// value-equality για σωστή συμπεριφορά με τον event scheduler του bloc.
/// Κάθε event είναι immutable carrier — καμία λογική, validation ή I/O.
/// Τα `ReceiptsStreamUpdated` / `ReceiptItemsStreamUpdated` / `ReceiptStreamError`
/// είναι ΕΣΩΤΕΡΙΚΑ (bridge): οι reactive subscriptions του BLoC τα διαβιβάζουν
/// πίσω μέσω `bloc.add` — μόνο οι handlers εκτελούν `emit` (bloc 9
/// restriction) — δεν δηλώνονται ποτέ από UI.
///
/// Ημερομηνίες: πάντα LOCAL. Το `.toUtc()` γίνεται ΜΟΝΟ στον DAO (§4.3) —
/// ούτε ο BLoC ούτε το UI κάνουν timezone conversion (εύρημα F6).
sealed class ReceiptEvent extends Equatable {
  const ReceiptEvent();

  @override
  List<Object?> get props => const [];
}

/// ΕΣΩΤΕΡΙΚΟ bridge — reactive δεδομένα από το `watchAll` του repository.
final class ReceiptsStreamUpdated extends ReceiptEvent {
  const ReceiptsStreamUpdated(this.receipts);

  final List<Receipt> receipts;

  @override
  List<Object?> get props => [receipts];
}

/// ΕΣΩΤΕΡΙΚΟ bridge — reactive γραμμές από το `watchItemsByReceiptId`.
final class ReceiptItemsStreamUpdated extends ReceiptEvent {
  const ReceiptItemsStreamUpdated(this.items);

  final List<ReceiptItem> items;

  @override
  List<Object?> get props => [items];
}

/// ΕΣΩΤΕΡΙΚΟ bridge — error από reactive stream → status error + genericError.
final class ReceiptStreamError extends ReceiptEvent {
  const ReceiptStreamError();

  @override
  List<Object?> get props => const [];
}

/// Φόρτωση λίστας αποδείξεων (reactive μέσω του repository stream).
/// Όλα τα φίλτρα είναι προαιρετικά (null = χωρίς φίλτρο).
final class ReceiptsLoadRequested extends ReceiptEvent {
  const ReceiptsLoadRequested({
    this.startDate,
    this.endDate,
    this.supplierId,
    this.paymentStatus,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final int? supplierId;

  /// `AppConstants.paymentStatus*` (SPoT — 'pending' | 'partial' | 'paid').
  final String? paymentStatus;

  @override
  List<Object?> get props => [startDate, endDate, supplierId, paymentStatus];
}

/// Δημιουργία απόδειξης. Ο BLoC τρέχει `Validators.validateReceipt` ΠΡΙΝ
/// καλέσει το repository — αν fail, καμία κλήση repo (F8).
final class ReceiptCreateRequested extends ReceiptEvent {
  const ReceiptCreateRequested({required this.input});

  final ReceiptInput input;

  @override
  List<Object?> get props => [input];
}

/// Άνοιγμα detail: τίθεται `id`, το `selectedReceipt` derives από τη λίστα
/// του ενεργού `watchAll` (F3 — χωρίς υποχρεωτικό `getById`) και ξεκινά
/// το reactive `watchItemsByReceiptId`.
final class ReceiptDetailLoadRequested extends ReceiptEvent {
  const ReceiptDetailLoadRequested({required this.id});

  final int id;

  @override
  List<Object?> get props => [id];
}

/// Ενημέρωση γραμμής απόδειξης — o DAO επανυπολογίζει totals + stock
/// (reactive ενημέρωση χωρίς manual refetch, F2).
final class ReceiptLineUpdateRequested extends ReceiptEvent {
  const ReceiptLineUpdateRequested({
    required this.receiptId,
    required this.itemId,
    required this.update,
  });

  final int receiptId;
  final int itemId;
  final ReceiptItemUpdate update;

  @override
  List<Object?> get props => [receiptId, itemId, update];
}

/// Διαγραφή γραμμής απόδειξης (stock επαναφορά + refresh totals στον DAO).
final class ReceiptLineDeleteRequested extends ReceiptEvent {
  const ReceiptLineDeleteRequested({
    required this.receiptId,
    required this.itemId,
  });

  final int receiptId;
  final int itemId;

  @override
  List<Object?> get props => [receiptId, itemId];
}

/// Διαγραφή ολόκληρης απόδειξης (cascade στον DAO).
/// No-op σε ανύπαρκτο id (F2) — κανονική ροή, όχι error.
final class ReceiptDeleteRequested extends ReceiptEvent {
  const ReceiptDeleteRequested({required this.id});

  final int id;

  @override
  List<Object?> get props => [id];
}

/// Επόμενος αριθμός απόδειξης (counter μέσω SettingDao — preview στο UI).
final class ReceiptNextNumberRequested extends ReceiptEvent {
  const ReceiptNextNumberRequested();

  @override
  List<Object?> get props => const [];
}

/// ΕΣΩΤΕΡΙΚΟ bridge — το UI κατανάλωσε το single-shot `message`/`error`
/// (π.χ. snackbar) και ζητά να μηδενιστούν. Λύνει το race του
/// `_onReceiptsStreamUpdated`: το reactive stream ΔΕΝ σβήνει το μήνυμα —
/// ο καταναλωτής δηλώνει ρητά πότε τελείωσε (Βήμα 7).
final class ReceiptMessageShown extends ReceiptEvent {
  const ReceiptMessageShown();

  @override
  List<Object?> get props => const [];
}