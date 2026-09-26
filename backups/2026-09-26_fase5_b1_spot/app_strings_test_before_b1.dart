/// Unit tests για το SPoT `AppStrings` (core/constants/app_strings.dart) — §1.1.
///
/// Μόνο απλές σταθερές → plain `test()`, χωρίς widget pump (ίδιο στυλ με
/// debug_config_test/app_logger_test). Τιμές επαληθευμένες λέξη-προς-λέξη
/// με το DESIGN.md (§0, §2.1, §2.2) κατά την υλοποίηση.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_strings.dart';

void main() {
  group('AppStrings', () {
    // ─── App identity (§0) ───────────────────────────────────────────────────
    test('appTitle = «Τιμές» (branding §0)', () {
      expect(AppStrings.appTitle, 'Τιμές');
    });

    // ─── Navigation / App shell (Φάση 3 Βήμα 1) ─────────────────────────────
    test('nav labels — αρχική/εισαγωγή/ρυθμίσεις (Φάση 3 Βήμα 1)', () {
      expect(AppStrings.navHome, 'Αρχική');
      expect(AppStrings.navPriceEntry, 'Εισαγωγή');
      expect(AppStrings.navSettings, 'Ρυθμίσεις');
    });

    // ─── Home / Stats (§2.1) ─────────────────────────────────────────────────
    test('noPricesForPeriod — ακριβές κείμενο (§2.1)', () {
      expect(
        AppStrings.noPricesForPeriod,
        'Δεν υπάρχουν καταχωρημένες τιμές για αυτή την περίοδο',
      );
    });

    test('retryButton = «Επανάληψη» (§2.1)', () {
      expect(AppStrings.retryButton, 'Επανάληψη');
    });

    test('statsComingSoon — placeholder στατιστικών (§2.1 · Φάση 5)', () {
      expect(AppStrings.statsComingSoon, 'Τα στατιστικά θα εμφανιστούν σύντομα');
    });

    // ─── Price entry (§2.2) ──────────────────────────────────────────────────
    test('titlePriceEntry = «Εισαγωγή Τιμών» (§2.2)', () {
      expect(AppStrings.titlePriceEntry, 'Εισαγωγή Τιμών');
    });

    test('saveReceipt = «Αποθήκευση Απόδειξης» (§2.2)', () {
      expect(AppStrings.saveReceipt, 'Αποθήκευση Απόδειξης');
    });

    test('updateReceipt = «Ενημέρωση Απόδειξης» (§2.2 · Φάση Α)', () {
      expect(AppStrings.updateReceipt, 'Ενημέρωση Απόδειξης');
    });

    test('addReceiptLine = «Προσθήκη γραμμής» (§2.2)', () {
      expect(AppStrings.addReceiptLine, 'Προσθήκη γραμμής');
    });

    test('field labels — ημερομηνία/προμηθευτής/ποσότητα/τιμή/μονάδα (§2.2)', () {
      expect(AppStrings.fieldDate, 'Ημερομηνία');
      expect(AppStrings.fieldSupplier, 'Προμηθευτής');
      expect(AppStrings.fieldQuantity, 'Ποσότητα');
      expect(AppStrings.fieldPrice, 'Τιμή');
      expect(AppStrings.fieldUnit, 'Μονάδα');
    });

    test('fieldDiscount = «Έκπτωση» (§2.2 · έκπτωση γραμμής)', () {
      expect(AppStrings.fieldDiscount, 'Έκπτωση');
    });

    test('unit/price section — hint μονάδας + σύμβολο € (§2.2 · Βήμα 5γ)', () {
      expect(AppStrings.unitSearchHint, 'Αναζήτηση μονάδας');
      expect(AppStrings.currencySymbol, '€');
    });

    test('συνολική τιμή — διακόπτης + label συνόλου (§2.2 · 24-09-2026)', () {
      expect(AppStrings.priceTotalMode, 'Συνολική τιμή');
      expect(AppStrings.lineTotalLabel, 'σύνολο');
    });

    test('draft lines — τίτλος + κενή κατάσταση + αφαίρεση (§2.2)', () {
      expect(AppStrings.draftLinesTitle, 'Γραμμές απόδειξης');
      expect(AppStrings.draftLinesEmpty, 'Δεν υπάρχουν γραμμές ακόμα');
      expect(AppStrings.removeDraftLine, 'Αφαίρεση γραμμής');
    });

    test('recent receipts — τίτλος + κενή κατάσταση (§2.2 · Βήμα 7)', () {
      expect(AppStrings.recentReceiptsTitle, 'Πρόσφατες αποδείξεις');
      expect(
        AppStrings.recentReceiptsEmpty,
        'Δεν υπάρχουν αποθηκευμένες αποδείξεις ακόμα',
      );
    });

    test('quantityTruncatedForUnit — ειδοποίηση περικοπής (§2.2:218)', () {
      expect(
        AppStrings.quantityTruncatedForUnit,
        'Η ποσότητα κόπηκε σε ακέραια (η μονάδα δεν δέχεται δεκαδικά)',
      );
    });

    test('supplierSearchHint = «Αναζήτηση προμηθευτή» (§2.4)', () {
      expect(AppStrings.supplierSearchHint, 'Αναζήτηση προμηθευτή');
    });

    test('addNewSupplier = «Νέος προμηθευτής» (§2.4)', () {
      expect(AppStrings.addNewSupplier, 'Νέος προμηθευτής');
    });

    // ─── Item search / new-item dialog (§2.4 · Φάση 3 Βήμα 4) ──────────────
    test('itemSearchHint = «Αναζήτηση είδους» (§2.4)', () {
      expect(AppStrings.itemSearchHint, 'Αναζήτηση είδους');
    });

    test('itemSearchIdle — μήνυμα idle panel (§2.4)', () {
      expect(
        AppStrings.itemSearchIdle,
        'Πληκτρολογήστε για αναζήτηση είδους',
      );
    });

    test('labels inline «+» — κατηγορία/υποκατηγορία/είδος (§2.4)', () {
      expect(AppStrings.addNewCategory, 'Νέα κατηγορία');
      expect(AppStrings.addNewSubCategory, 'Νέα υποκατηγορία');
      expect(AppStrings.addNewItem, 'Νέο είδος');
    });

    test('changeItem = «Αλλαγή» + itemSearchRetry = «Δοκιμή ξανά» (§2.4)', () {
      expect(AppStrings.changeItem, 'Αλλαγή');
      expect(AppStrings.itemSearchRetry, 'Δοκιμή ξανά');
    });

    test('labels νέου είδους dialog — κατηγορία/υποκατηγορία/όνομα (§2.4)', () {
      expect(AppStrings.fieldCategory, 'Κατηγορία');
      expect(AppStrings.fieldSubCategory, 'Υποκατηγορία');
      expect(AppStrings.fieldItemName, 'Όνομα είδους');
    });

    test('newItemDialogTitle = «Νέο είδος» + newItemSave = «Προσθήκη» (§2.4)', () {
      expect(AppStrings.newItemDialogTitle, 'Νέο είδος');
      expect(AppStrings.newItemSave, 'Προσθήκη');
    });

    test('newItemNextStep = «Επόμενο» (§2.4)', () {
      expect(AppStrings.newItemNextStep, 'Επόμενο');
    });

    // ─── Settings (§2.3 · Φάση 4 Βήμα 1) ─────────────────────────────────────
    test('titleSettings = «Ρυθμίσεις» + section «Θέμα» + 3 labels (§2.3:270)', () {
      expect(AppStrings.titleSettings, 'Ρυθμίσεις');
      expect(AppStrings.titleThemeSection, 'Θέμα');
      expect(AppStrings.themeModeLight, 'Φωτεινό');
      expect(AppStrings.themeModeDark, 'Σκοτεινό');
      expect(AppStrings.themeModeSystem, 'Αυτόματο');
    });

    // ─── Categories section (§2.3 · Φάση 4 Βήμα 4) ───────────────────────────
    test('titleCategoriesSection = «Κατηγορίες» + empty (§2.3 · Βήμα 4)', () {
      expect(AppStrings.titleCategoriesSection, 'Κατηγορίες');
      expect(
        AppStrings.categoriesEmpty,
        'Δεν υπάρχουν κατηγορίες ακόμα',
      );
    });

    test('edit/delete/refresh/save actions (§2.3 · Βήμα 4)', () {
      expect(AppStrings.editAction, 'Επεξεργασία');
      expect(AppStrings.deleteAction, 'Διαγραφή');
      expect(AppStrings.refreshAction, 'Ανανέωση');
      expect(AppStrings.saveAction, 'Αποθήκευση');
    });

    // ─── Suppliers section (§2.3 · CRUD 24-09-2026) ──────────────────────────
    test('titleSuppliersSection + suppliersEmpty (§2.3)', () {
      expect(AppStrings.titleSuppliersSection, 'Προμηθευτές');
      expect(AppStrings.suppliersEmpty, 'Δεν υπάρχουν προμηθευτές ακόμα');
    });

    // ─── Receipts section (§2.3 · Φάση Β 24-09-2026) ─────────────────────────
    test('titleReceiptsSection + clearReceiptFilter + noReceiptsForDay (§2.3)', () {
      expect(AppStrings.titleReceiptsSection, 'Αποδείξεις');
      expect(AppStrings.clearReceiptFilter, 'Όλες');
      expect(
        AppStrings.noReceiptsForDay,
        'Δεν υπάρχουν αποδείξεις αυτή την ημέρα',
      );
    });

    // ─── Backup section (§2.3 · Φάση 4 Βήμα 5) ─────────────────────────────
    test('titleBackupSection + export/restore actions (§2.3 · Βήμα 5)', () {
      expect(AppStrings.titleBackupSection, 'Αντίγραφα ασφαλείας');
      expect(AppStrings.backupExportAction, 'Εξαγωγή αντιγράφου');
      expect(AppStrings.backupRestoreAction, 'Επαναφορά αντιγράφου');
    });

    // ─── Καθολικές εγγυήσεις (όλα τα strings) ────────────────────────────────
    test('κανένα string μη-κενό, χωρίς whitespace στα άκρα, χωρίς αλλαγή γραμμής', () {
      for (final text in _allStrings) {
        expect(text, isNotEmpty, reason: 'Βρέθηκε κενό string');
        expect(
          text,
          text.trim(),
          reason: 'String με αρχικό/τελικό whitespace: «$text»',
        );
        expect(text.contains('\n'), isFalse, reason: 'String με αλλαγή γραμμής: «$text»');
      }
    });
  });
}

/// Διατηρείται χειροκίνητα — προστίθεται κάθε νέο AppStrings μέλος εδώ.
/// Χρησιμοποιείται μόνο από τον καθολικό έλεγχο ποιότητας (κανένα string
/// κενό / με whitespace / με νέα γραμμή).
const List<String> _allStrings = [
  AppStrings.appTitle,
  AppStrings.navHome,
  AppStrings.navPriceEntry,
  AppStrings.navSettings,
  AppStrings.noPricesForPeriod,
  AppStrings.retryButton,
  AppStrings.statsComingSoon,
  AppStrings.titlePriceEntry,
  AppStrings.saveReceipt,
  AppStrings.updateReceipt,
  AppStrings.addReceiptLine,
  AppStrings.fieldDate,
  AppStrings.fieldSupplier,
  AppStrings.fieldQuantity,
  AppStrings.fieldPrice,
  AppStrings.fieldDiscount,
  AppStrings.priceTotalMode,
  AppStrings.lineTotalLabel,
  AppStrings.fieldUnit,
  AppStrings.unitSearchHint,
  AppStrings.currencySymbol,
  AppStrings.draftLinesTitle,
  AppStrings.draftLinesEmpty,
  AppStrings.removeDraftLine,
  AppStrings.recentReceiptsTitle,
  AppStrings.recentReceiptsEmpty,
  AppStrings.quantityTruncatedForUnit,
  AppStrings.supplierSearchHint,
  AppStrings.addNewSupplier,
  AppStrings.itemSearchHint,
  AppStrings.itemSearchIdle,
  AppStrings.addNewCategory,
  AppStrings.addNewSubCategory,
  AppStrings.addNewItem,
  AppStrings.changeItem,
  AppStrings.itemSearchRetry,
  AppStrings.fieldCategory,
  AppStrings.fieldSubCategory,
  AppStrings.fieldItemName,
  AppStrings.newItemDialogTitle,
  AppStrings.newItemNextStep,
  AppStrings.newItemSave,
  AppStrings.titleSettings,
  AppStrings.titleThemeSection,
  AppStrings.themeModeLight,
  AppStrings.themeModeDark,
  AppStrings.themeModeSystem,
  AppStrings.titleCategoriesSection,
  AppStrings.categoriesEmpty,
  AppStrings.editAction,
  AppStrings.deleteAction,
  AppStrings.refreshAction,
  AppStrings.saveAction,
  AppStrings.titleSuppliersSection,
  AppStrings.suppliersEmpty,
  AppStrings.titleReceiptsSection,
  AppStrings.clearReceiptFilter,
  AppStrings.noReceiptsForDay,
  AppStrings.titleBackupSection,
  AppStrings.backupExportAction,
  AppStrings.backupRestoreAction,
];