# Κεφ. 91 — Διαφοροποίηση ανοιχτών sections Ρυθμίσεων (01-10-2026)

> Τα 6 collapsible sections (`Card` > `ExpansionTile`) είχαν ίδιο φόντο με τη σελίδα όταν ανοίγουν.

## Αλλαγή (μόνο `settings_page.dart`)

- `backgroundColor: scheme.surfaceContainerHigh` στα 6 expanded tiles (2 σκαλιά πάνω από την κάρτα, ορατό σε light/dark)· collapsed άθικτο.
- 0 νέα χρώματα/consts (κανόνας §1.5 — όλα από `ColorScheme`).

## Επαλήθευση

- Settings page 14/14 (expand/collapse, dark, 320/800/1200) · analyze καθαρό.
- Backup `backups/2026-10-01_settings_tint/`.
