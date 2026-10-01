# Κεφ. 89 — Confirm διαγραφής γραμμής καλαθιού (01-10-2026)

> Κάδος draft γραμμής (νέα + επεξεργασία) → destructive confirm, ομοιόμορφα με τις υπόλοιπες διαγραφές.

## Υλοποίηση

- `app_messages.dart` → `deleteDraftLineConfirm(name)` (pattern supplier/item).
- `draft_lines_list.dart` → `_removeLine` (showConfirmDialog destructive + mounted) · controller άθικτος.
- `DESIGN.md:231` → μία γραμμή (αφαίρεση με destructive confirm).

## Απορρίφθηκαν (επανέλεγχος)

- `runControllerOp` (θέλει record+snackbar) · `DeleteGateButton` (θέλει πύλες) · success snackbar (θόρυβος) · νέο widget/controller/exception.

## Επαλήθευση

- Draft list 12/12 (+2 νέα: Ακύρωση/dismiss) · messages 35/35 (+1 exact, όχι λίστα) · full 1575/1575 · analyze καθαρό.
- Backup `backups/2026-10-01_draft_confirm/`.
