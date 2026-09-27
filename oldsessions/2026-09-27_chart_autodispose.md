# Κεφάλαιο 59 — Chart families `autoDispose` (27-09-2026)

> Τα 5 chart `StreamProvider.family` ήταν NON-autoDispose: κάθε νέο query
> (custom range/rollover) έμενε με ζωντανό DB watch (leak). Αλλαγή μόνο
> στις 5 families — repos/static streams/controllers άθικτα.

## Αλλαγές (lib)

- `stream_providers`: `StreamProvider.family` →
  `StreamProvider.autoDispose.family` ×5 + σχόλια (header scoped εξαίρεση,
  επίλυση σημείωσης follow-up κεφ. 55).

## Tests (+1 → 1259/1259)

- Νέο `chart_disposal_test`: build-counter override + mount/unmount/re-mount
  (builds 1→2). Σημ.: `container.listen` επιστρέφει void (Riverpod 3) —
  εξ ου το widget-pump design.
- Υπόλοιπη σουίτα αμετάβλητη (overrides/listen/retry ατόφια).
- DESIGN αμετάβλητο (καμία global σύμβαση — μόνο per-provider).
- Backup `backups/2026-09-27_chart_autodispose/`.
