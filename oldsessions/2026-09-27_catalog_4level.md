# Κεφάλαιο 52 — Refactor καταλόγου 4 επιπέδων (27-09-2026)

> Κατηγορία ▸ Υποκατηγορία ▸ Τμήμα (ItemGroup) ▸ Είδος. Wipe+fresh (schema v4).
> Αποφάσεις χρήστη: global UNIQUE (καμία επανάληψη) · όρος UI «Τμήμα» ·
> nested tree · edit 3 dropdowns · composite seed keys · v4+throw.

## Αποφάσεις (Q&A κλειδωμένα)

| # | Ερώτηση | Απόφαση |
|---|---|---|
| 1 | Μοναδικότητα Cat/Sub/Group | Global UNIQUE `normalizedName` (όπως Item/Supplier) |
| 2 | Όρος UI | «Τμήμα» (field/add/chart/messages) |
| 3 | Tree | Nested Cat▸Sub▸Group ExpansionTiles |
| 4 | Edit dialog | 3 dropdowns (ValueKey chain) |
| 5 | Seed keys | Composite `cat\|sub\|group` fail-fast |
| 6 | Βάση | Wipe+fresh, schemaVersion 4, onUpgrade=throw |

## Σχήμα (§3)

- `ItemGroups(id, subCategoryId→RESTRICT, name, normalizedName UNIQUE)` νέο.
- `Items.subCategoryId` → `itemGroupId→RESTRICT`.
- `normalizedName UNIQUE` +σε Categories/SubCategories (ήταν μόνο Item/Supplier).
- Διαγραφή `migration_v1_to_v2.dart` + 12 seed αρχείων (cats/subs/9×items).
- `BackupService.expectedTables` 7→8.

## Αρχεία (lib, 41 backed up σε `backups/2026-09-27_catalog_4level/`)

- ΝΕΑ: `daos/item_group_dao.dart`, `repositories/item_group_repository(+impl).dart`, `test/.../item_group_dao_test.dart`, `test/.../item_group_repository_impl_test.dart`, `test/.../item_search_controller_error_test.dart` (split <500).
- Αλλαγμένα: tables, app_database (v4), category/sub/item/receipt DAOs, 5 repos+impls, settings_repository_impl (JSON `itemGroup`+legacy fallback), 3 providers, tree_node (nested), chart_totals (`ItemGroupTotal`), backup_service, name_validator doc, app_strings (+3/−1), app_messages (+4), item_search_controller (+createItemGroup, exact-match), receipt_form_controller (2-hop guards), category/item_management_controller, new_item_flow_dialog (4 βήματα), category_tree_editor (3 επίπεδα), item_edit_dialog (3 dropdowns), item_list_editor (3 lookups), home_chart_config (ChartId.itemGroup+freezed), home_page.
- Σβησμένα: migration + migration test + 12 seeds.

## Εύρημα Ε1 — Duplicate-Key crash (διορθωμένο)

`ItemEditDialog`: sub-field `ValueKey(categoryId)` + group-field `ValueKey(subCategoryId)` → crash όταν ids ίσα (1/1 στη φρέσκια βάση). Fix: `ValueKey('sub_$id')`/`ValueKey('group_$id')` (pattern tree editor). Test ενημερώθηκε.

## Επαλήθευση

- `flutter analyze` — No issues (lib+test).
- `flutter test --timeout 60s` — **1246/1246** ✓ (4 παράλληλες ομάδες διόρθωσης + Ε1).
- Προϋπάρχουσα παραβίαση (εκτός scope): `save_receipt_button_test`/`unit_quantity_price_section_validation_test` >500 γρ. (ήταν ήδη).
- Seed: μονάδες 3 + άδειος κατάλογος (δεδομένα από νέο `.md` χρήστη — Β4β εκκρεμεί).
