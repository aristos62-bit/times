# Κεφάλαιο 31 — Editors: rename-fix, keys/βέλος, shared, dialog, docs-cleanup

**Ημερομηνία έναρξης:** 24-09-2026 · **Κατάσταση:** Κλειστό

## Αφορμή

Εξωτερικό review 10 σημείων (λειτουργικά + ποιότητα) στους editors
καταλόγου/προμηθευτών — αξιολογήθηκε ένα-ένα απέναντι στον κώδικα.

## Αποφάσεις

Συμφωνία σε 7, διαφωνία σε 3 (πληθυντικά Δ3 · ellipsis §1.4 · UI tests —
υπάρχουν wiring/through-UI) · watch-πύλες απορρίφθηκαν (124 μόνιμες
συνδρομές vs ακίνδυνο staleness + defense + refresh).

## Αλλαγές

- **Rename exact-match (bug)**: no-op ΜΟΝΟ σε ίδιο κείμενο (2 controllers) +
  `clash.id != id` (self-clash, δικό μου) + ξαναγράψιμο 2 tests.
- **ExpansionTile**: `ValueKey(category.id)` + `controlAffinity: leading`
  ΧΩΡΙΣ leading icon (εύρημα SDK: `leading ?? arrow` — με icon χάνεται το
  βέλος· έπεσε το category icon).
- **Shared**: `controller_op_runner.dart` (32γρ.) + `delete_gate_button.dart`
  (65γρ.) — υιοθετήθηκαν και από τους 2 editors (editor 422→366).
  Per-row split: εκτός (κόστος αμελητέο, one-shot).
- **Dialog**: `labelText` param (reuse field* — 0 νέα SPoT) + 6 call sites +
  αφαίρεση `maxLength` (διπλό + counter) + 2×`const` στη σελίδα.
- **SPoT/docs**: διαγραφή νεκρού `itemCountTooltip` + ξαναγράψιμο 5 tests +
  DESIGN §1.2:49 + §2.3:288/gates/dialog/TreeNode/supplier + §4 (Βήματα 1–4
  ✓ + supplier CRUD + units) + §5 + κλείσιμο tooltip-conflict.

## Tests

- Full suite: **896/896** ✓ (897 −3 νεκρά +2 rename) · `--timeout 60s` ·
  `flutter analyze` **No issues** ✓ · κανένα `.dart` >500 γρ. ✓ (editor 366).

## Backup

- `backups/2026-09-24_editor_fixes/` — 12 αρχεία (πριν τις αλλαγές).
