# Κεφ. 76 — SPoT hardcoded μεγεθών (30-09-2026)

> 3 αναφερμένα + 1 εύρημα (icon 64): όλα σε SPoT, τιμές πανομοιότυπες.

## Αλλαγές (0 συμπεριφοράς)

- `catalog_filter:102,145` → `AppConstants.spacingM` (+ import που έλειπε).
- Overlay 127 → `AppConstants.appLockButtonHeight = 48.0` (σταθερό anti-jump §1.4).
- Overlay 112 → `AppConstants.appLockIconSize = 64.0` (εύρημα επανελέγχου, incl. με έγκριση).
- `DESIGN.md` αμετάβλητο (§1.1).

## Επαλήθευση (30-09-2026)

- Widget tests **28/28** ✓ (filter + overlay + section + watcher) · `flutter analyze` No issues ✓.
- Backup `backups/2026-09-30_spot_sizes/` (const + 2 widgets + oldsessions).
