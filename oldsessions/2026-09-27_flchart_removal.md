# Κεφάλαιο 57 — Αφαίρεση dependency `fl_chart` (27-09-2026)

> Το `fl_chart` δεν εισάγεται πουθενά (`lib/` 0 imports, `test/` 0) —
> οι πίτες είναι custom `Pie3dPainter` (το package δεν έχει 3D).
> Αφαιρέθηκε από `pubspec.yaml` (+16 γραμμές lock cleanup).

## Αλλαγές

- `pubspec.yaml`: −`fl_chart: ^1.2.0` · `pubspec.lock`: cleanup.
- `DESIGN.md` §4 Φάση 0: αφαίρεση από τη λίστα dependencies.
- Σκόπιμα ΑΘΙΚΤΑ: τα σχόλια rationale (`app_constants:183`,
  `pie_3d_chart:3`, DESIGN §2.1:137/§4:535) — τεκμηριώνουν ΓΙΑΤΙ custom
  painter, όχι χρήση.
- Tests/analyze αμετάβλητα (1254/1254 · No issues — η σουίτα έτρεχε ήδη
  χωρίς το package).
- Backup `backups/2026-09-27_flchart_removal/` (HEAD εκδοχές + pre-edit docs).
