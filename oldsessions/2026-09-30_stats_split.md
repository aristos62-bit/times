# Κεφ. 77 — Split `statistics_section.dart` (30-09-2026)

> 1116 γρ. (2,2× όριο, κανόνας 7) → main + 4 part files. Verbatim, 0 renames, 0 συμπεριφοράς.

## Μέθοδος (byte-exact, όχι αντιγραφή)

- Έλεγχος bytes: UTF-8 no BOM, LF (41299 bytes).
- Εξαγωγή ranges με LF-preserving split + συναρμολόγηση με headers (`write` tool για ελληνικά).
- Πάθημα: mismatch ονομάτων headers (`H_shared` vs `H_statistics_analysis_shared`) → parts γράφτηκαν χωρίς headers· διορθώθηκε με prepend. Μάθημα: verify αμέσως μετά το build.
- Επαλήθευση: αθροίσματα γραμμών + analyze + tests (όχι οπτικό console — το mojibake ήταν display-only).

## Αρχεία (όλα <500)

main 134 (library+imports+parts+menu) · shared 167 · ledger 370 · purchases 271 · grouped 266.

## Επαλήθευση (30-09-2026)

- Widget tests **33/33** ✓ (section + report + purchases + filter) · `flutter analyze` No issues ✓.
- `DESIGN.md` tree ενημερώθηκε.
- Backup `backups/2026-09-30_stats_split/` (αρχικό + DESIGN + oldsessions).
- Follow-up (εκτός scope): split του 785-γραμμών `statistics_section_test.dart`.
