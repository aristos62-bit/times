# Φάση 3 — post-closure: επεξεργασία + διαγραφή αποδείξης (24-09-2026)

> Κατάσταση: **ΟΛΟΚΛΗΡΩΘΗΚΕ** 24-09-2026 (Φάση Α). Η read-only λίστα (§2.2 Βήμα 7)
> αποκτά μολύβι (φόρτωση στη φόρμα, `editingId`) + κόκκινο κάδο (διαγραφή με
> confirm, CASCADE). Η Φάση Β (Ρυθμίσεις «Διαχείριση αποδείξεων» με αναζήτηση
> ανά ημερομηνία) μένει μελλοντική και θα ξαναχρησιμοποιήσει το `editingId`.

---

## 1. Απόφαση

- **Edit = φόρτωση στην υπάρχουσα φόρμα PriceEntry** (`editingId` στο
  `ReceiptFormState`), ΟΧΙ νέα route/dialog — η φόρμα (header/search/section/
  drafts/validation/save/exit-confirm/responsive, ~1500 γρ. σε 7 αρχεία) δεν
  διπλασιάζεται· καμία αλλαγή `AppRoutes/app_router` (§1.2).
- **Update = αντικατάσταση ΟΛΩΝ των γραμμών σε μία transaction** (όχι per-line
  update — απλό, ατομικό· τα line-ids αλλάζουν, αποδεκτό: SUM §3, καμία
  εξωτερική αναφορά).
- `DeleteGateButton` απορρίφθηκε (νεκρό gate — αποδείξεις πάντα διαγράψιμες)·
  `CategoryEditDialog` απορρίφθηκε (απόδειξη ≠ ένα όνομα)· νέο AppErrors
  απορρίφθηκε (το sealed mapping επαρκεί).

## 2. Αλλαγές

| Αρχείο | Αλλαγή |
|---|---|
| `app_strings.dart` | +`updateReceipt` («Ενημέρωση Απόδειξης») |
| `app_messages.dart` | +`receiptUpdated`/`receiptDeleted`/`deleteReceiptConfirm(id,s)`/`editDiscardDraftsConfirm` |
| `receipt_repository.dart` + `..._impl.dart` | +`updateReceiptWithLines` (`_receiptDao.db.transaction`: update κεφαλίδας + delete παλιών + insert νέων· ανύπαρκτο id→`DataLoadException`, FK→`SaveReceiptException`) — σύνθεση από υπάρχοντα DAO methods, κανένα DAO δεν άλλαξε |
| `receipt_form_state.dart` (+freezed regen) | +`int? editingId` (null = δημιουργία· `resetForm` το μηδενίζει) |
| `receipt_form_controller.dart` (239→~370) | +`loadReceiptForEdit` (getById+getLines one-shot+ανάλυση ονομάτων via item/unit/supplier repos· `enteredTotalCents=null`) +`cancelEdit` +`deleteReceipt` (`(ok,error)` για `runControllerOp`)· `saveReceipt`: update-branch όταν `editingId!=null` |
| `recent_receipts_list.dart` (141→~260) | trailing `Row(min)`: σύνολο + μολύβι + κόκκινος κάδος (`colorScheme.error`)· disabled όσο `isSaving`· `_delete` (confirm→runControllerOp)· `_edit` (drafts→confirm απόρριψης→load+clearSelection) |
| `save_receipt_button.dart` | label `updateReceipt` σε edit mode· success `receiptUpdated` (αλλιώς `savedReceipt`) |
| `price_entry_page.dart` | banner `receiptNumber(editingId)` + «Ακύρωση» (reuse `confirmDialogCancel`) → `cancelEdit`+`clearSelection` |
| tests | 6 fakes +`updateReceiptWithLines`· SPoT tests +5 asserts· 3 νέα αρχεία (βλ. §4) |

## 3. Ευρήματα (bugs που έπιασαν τα tests)

- **Ε1 — `isSaving` κολλούσε σε μη-mapped σφάλμα.** Τα νέα `load/delete`
  έσβηναν το flag μόνο σε `DataLoadException` (κλειστή βάση ρίχνει StateError
  → κουμπιά νεκρά για πάντα). Διόρθωση: catch-all reset (pattern
  `saveReceipt`). Το test κλειστής-βάσης το επαληθεύει.
- **Ε2 — `package:drift/native.dart` εξάγει ήδη το drift API.** Το έξτρα
  `drift/drift.dart` import ήταν unused (warning) → αφαιρέθηκε.
- **Ε3 — watch-stream `.first` κολλάει στο widget-test FakeAsync.**
  Διάγνωση: unit tests (real async) περνούσαν· widget dialog-ροές κρέμονταν
  10 λεπτά (επιβεβαιώθηκε με απομόνωση ανά test — το `watchAll().first` στο
  σώμα + το `watchLines().first` στον controller· καθιερωμένο runAsync-idiom
  Βήματος 6). Διόρθωση ρίζας (αντί runAsync-delays): νέο one-shot
  `ReceiptLineDao.getByReceiptId` + passthrough `ReceiptRepository.getLines`
  — ο controller φορτώνει ντετερμινιστικά· τα widget tests έγιναν 7/7.
  Παράπλευρο: τα `watchAll().first` asserts έγιναν `getById`.

## 4. Tests

- `receipt_repository_update_test` (7): αντικατάσταση (όχι προσθήκη)· κενές
  γραμμές· ανύπαρκτο id→`DataLoadException`· FK item/supplier→
  `SaveReceiptException`+rollback (κεφαλίδα+παλιές γραμμές άθικτες)·
  `getLines` one-shot (2 tests, βλ. Ε3).
- `receipt_form_controller_edit_delete_test` (9): load (ονόματα/current,
  `enteredTotalCents` null, log)· ανύπαρκτο→`(ok:false,loadDataFailed)`·
  no-op επί isSaving· cancelEdit· delete CASCADE· delete ανύπαρκτο· delete
  υπό-επεξεργασία→cancel· κλειστή βάση (Ε1)· save-update-branch (2 γραμμές,
  log «Ενημέρωση», reset editingId).
- `recent_receipts_list_actions_test` (7): icons+tooltips+σύνολο· delete
  Ναι→snackbar+άδεια λίστα· Ακύρωση→καμία αλλαγή· edit→editingId+drafts+
  supplier· drafts-guard (Ακύρωση κρατά/Ναι φορτώνει)· responsive 3 μεγέθη·
  dark.
- SPoT: +1 strings test (+gate)· +4 messages tests (+gate).

## 5. Verification

- `flutter analyze`: **No issues** ✓
- Suite: **924/924** ✓ (βάση 896 +28: repo 7 + controller 9 + actions 7 + SPoT 5)
- `flutter build` δεν χρειάστηκε (καμία native αλλαγή)· backup
  `backups/2026-09-24_receipt_edit_delete/` (13 αρχεία) · DESIGN §2.2+§5.
