/// SPoT state — Φόρμα εισαγωγής απόδειξης (§2.2 DESIGN / Φάση 3 Βήματα 3-5).
///
/// Freezed immutable state — επεκτάθηκε στα Βήματα 3-5 (supplier, draftLines[],
/// isSaving) με το ίδιο pattern. Ο αριθμός απόδειξης ΔΕΝ ανήκει εδώ — είναι
/// το internal AUTOINCREMENT id της Receipt (§3: εμφάνιση στη λίστα Βήμα 7).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/local/app_database.dart';

part 'receipt_form_state.freezed.dart';

/// Μία γραμμή του «καλαθιού» (draft) της τρέχουσας απόδειξης (§2.2 · Βήμα 5γ).
///
/// Plain immutable value object (ΟΧΙ Freezed — δεν χρειάζεται copyWith union:
/// οι γραμμές προστίθενται/αφαιρούνται ως σύνολο μέσω `copyWith(draftLines:)`).
/// Καθρέφτης των ορισμάτων του `ReceiptLineDao.insert` (χωρίς `receiptId` /
/// `lineTotalCents` — αυτά υπολογίζονται/εισάγονται στο save, Βήμα 5δ).
/// Ίδιο είδος σε πολλές γραμμές ΕΠΙΤΡΕΠΕΤΑΙ — δεν γίνεται merge (§2.2:237).
/// `enteredTotalCents` (24-09-2026): snapshot του πληκτρολογημένου συνόλου
/// ΜΟΝΟ σε γραμμές «Συνολικής τιμής» (αλλιώς null) — το draft list το δείχνει
/// χωρίς επαν-υπολογισμό (SPoT μαθηματικών το DAO)· το stored σύνολο
/// `(priceCents×quantity).round()` μπορεί να διαφέρει ±1 λεπτό (στρογγυλοποίηση
/// παραγόμενης μοναδιαίας — τεκμηριωμένο, με test).
class DraftReceiptLine {
  const DraftReceiptLine({
    required this.itemId,
    required this.unitId,
    required this.quantity,
    required this.priceCents,
    required this.itemName,
    required this.unitAbbreviation,
    this.unitAllowsDecimal = true,
    this.enteredTotalCents,
  });

  /// Id του είδους (FK → Items).
  final int itemId;

  /// Id της μονάδας της γραμμής (FK → Units, §2.2:236 — ανά γραμμή, όχι
  /// απαραίτητα το `Item.defaultUnitId`).
  final int unitId;

  /// Ποσότητα (REAL στη βάση, §3 — double εδώ, SPoT parse στο
  /// `QuantityTextField.parseQuantity`).
  final double quantity;

  /// Τιμή μονάδας σε λεπτά (ακέραιος, §3 — SPoT parse στο
  /// `CurrencyTextField.parseCents`).
  final int priceCents;

  /// Snapshot ονόματος είδους για εμφάνιση (χωρίς join στο draft list).
  final String itemName;

  /// Snapshot συντομογραφίας μονάδας για εμφάνιση (π.χ. «κιλ»).
  final String unitAbbreviation;

  /// Snapshot του `Unit.allowsDecimal` (Βήμα 6γ) — τροφοδοτεί τον
  /// `ReceiptValidator` (safety-net §2.2:218: ακέραια ποσότητα όταν false).
  /// Προαιρετικό: default `true` = καμία απαίτηση ακεραιότητας (υπάρχοντες
  /// καλούντες άθικτοι)· το section περνά την πραγματική τιμή στο Βήμα 6δ.
  final bool unitAllowsDecimal;

  /// Snapshot πληκτρολογημένου συνόλου (λεπτά) — ΜΟΝΟ γραμμές «Συνολικής
  /// τιμής» (24-09-2026) το έχουν non-null· αλλιώς null (μοναδιαία τιμή).
  /// Nullable με default null = υπάρχοντες καλούντες/tests άθικτοι.
  final int? enteredTotalCents;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is DraftReceiptLine &&
              other.itemId == itemId &&
              other.unitId == unitId &&
              other.quantity == quantity &&
              other.priceCents == priceCents &&
              other.itemName == itemName &&
              other.unitAbbreviation == unitAbbreviation &&
              other.unitAllowsDecimal == unitAllowsDecimal &&
              other.enteredTotalCents == enteredTotalCents;

  @override
  int get hashCode => Object.hash(
    itemId,
    unitId,
    quantity,
    priceCents,
    itemName,
    unitAbbreviation,
    unitAllowsDecimal,
    enteredTotalCents,
  );
}

/// Κατάσταση της φόρμας απόδειξης — ημερομηνία + προμηθευτής + draft γραμμές.
@freezed
abstract class ReceiptFormState with _$ReceiptFormState {
  /// `date` — ημερομηνία της απόδειξης (κανονικοποιημένη σε μέρα, χωρίς ώρα,
  /// μέσω `DateUtils.dateOnly` στο controller — §2.2).
  const factory ReceiptFormState({
    required DateTime date,
    /// `supplier` — ο επιλεγμένος προμηθευτής (Βήμα 3), «null» = κανένας.
    /// Drift data-class (app_database.dart): immutable με value equality —
    /// συμβατό με το Freezed equality/copyWith χωρίς επιπλέον annotations.
    Supplier? supplier,
    /// `draftLines` — το «καλάθι» (§2.2 · Βήμα 5γ): γραμμές ΧΩΡΙΣ εγγραφή
    /// στη βάση (το insert γίνεται ατομικά στο save, Βήμα 5δ). Default κενή.
    @Default(<DraftReceiptLine>[]) List<DraftReceiptLine> draftLines,
    /// `isSaving` — async save σε εξέλιξη (§2.2 · Βήμα 5δ): το state ΠΑΡΑΜΕΝΕΙ
    /// σύγχρονο (plain Notifier) και το flag σημειώνει το async save — ίδιο
    /// pattern με το `_isCreating` των «+» (§2.2:235, double-tap guard).
    @Default(false) bool isSaving,
    /// `editingId` — Φάση Α (24-09-2026): id υπό-επεξεργασία απόδειξης,
    /// `null` = δημιουργία. Το `resetForm` το μηδενίζει.
    int? editingId,
  }) = _ReceiptFormState;
}