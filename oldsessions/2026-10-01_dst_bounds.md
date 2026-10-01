# Κεφ. 80 — DST-ασφαλή όρια περιόδου (01-10-2026)

> `Duration` σε τοπικά μεσάνυχτα σπάει στις αλλαγές ώρας (αποδείξεις λάθος ημέρας/εβδομάδας). Fix με calendar arithmetic, SPoT.

## Απόδειξη (εκτέλεση, GTB — όχι θεωρία)

- 29-03 +24h → 30-03 01:00 (μπαίνουν 00:00–01:00) · 25-10 +24h → 25-10 23:00 (χάνονται 23:00–24:00) · week-subtract → 23:00 (εύρημα επανελέγχου: η αρχή εβδομάδας έσπαγε κι αυτή).
- CI (UTC) τυφλό — γι' αυτό δεν φαινόταν.

## Αλλαγές (0 συμπεριφοράς εκτός 2 ημερών/χρόνο)

- Νέο `core/utils/dates.dart` (`dayOnly` + `addDays` — layering: το DAO απαγορεύει εξάρτηση προς τα πάνω).
- `chart_helpers`: 4 σημεία + `_dayOnly`→shared · `receipt_dao:98`.
- Tests: `dates_test` (7, παντού πράσινα) + DST group (4, red→green εδώ).

## Επαλήθευση (01-10-2026, από χρήστη)

- 32/32 (dates+helpers) · 21/21 (DAO day) · 18/18 (providers+editor) · `flutter analyze` No issues.
- Backup `backups/2026-10-01_dst_bounds/` · `DESIGN.md` αμετάβλητο (συμπεριφορά §2.1 ίδια).
