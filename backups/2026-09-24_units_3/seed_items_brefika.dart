/// Είδη Seed — Κατηγορία «ΒΡΕΦΙΚΑ ΠΡΟΪΟΝΤΑ» (50 είδη) — Φάση 1, Βήμα 3.
///
/// Προέλευση: `supermarket_categories_v2.md`. Το `subCategoryName` είναι
/// κλειδί προς το `seed_sub_categories.dart`· το `defaultUnitName` (προτάσεις
/// από τη φύση του προϊόντος) είναι κλειδί προς το `seed_units.dart`.
library;

import 'seed_types.dart';

const List<ItemSeed> seedItemsBrefika = <ItemSeed>[
  // ── Βρεφικά Γάλατα (10) ─────────────────────────────────────────────────
  (name: 'Βρεφικό γάλα 1ης ηλικίας (0-6 μηνών)', subCategoryName: 'Βρεφικά Γάλατα', defaultUnitName: 'Γραμμάριο'),
  (name: 'Βρεφικό γάλα 2ης ηλικίας (6-12 μηνών)', subCategoryName: 'Βρεφικά Γάλατα', defaultUnitName: 'Γραμμάριο'),
  (name: 'Βρεφικό γάλα 3ης ηλικίας (1-3 ετών)', subCategoryName: 'Βρεφικά Γάλατα', defaultUnitName: 'Γραμμάριο'),
  (name: 'Βρεφικό γάλα 4ης ηλικίας (3+ ετών)', subCategoryName: 'Βρεφικά Γάλατα', defaultUnitName: 'Γραμμάριο'),
  (name: 'Βρεφικό γάλα χωρίς λακτόζη', subCategoryName: 'Βρεφικά Γάλατα', defaultUnitName: 'Γραμμάριο'),
  (name: 'Βρεφικό γάλα για δυσανεξία', subCategoryName: 'Βρεφικά Γάλατα', defaultUnitName: 'Γραμμάριο'),
  (name: 'Βρεφικό γάλα βιολογικό', subCategoryName: 'Βρεφικά Γάλατα', defaultUnitName: 'Γραμμάριο'),
  (name: 'Βρεφικό γάλα σε σκόνη', subCategoryName: 'Βρεφικά Γάλατα', defaultUnitName: 'Γραμμάριο'),
  (name: 'Βρεφικό γάλα έτοιμο προς χρήση', subCategoryName: 'Βρεφικά Γάλατα', defaultUnitName: 'Χιλιοστόλιτρο'),
  (name: 'Βρεφικό γάλα με DHA', subCategoryName: 'Βρεφικά Γάλατα', defaultUnitName: 'Γραμμάριο'),

  // ── Πάνες (10) ───────────────────────────────────────────────────────────
  (name: 'Πάνες Νο.1 (2-5 kg)', subCategoryName: 'Πάνες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Πάνες Νο.2 (3-6 kg)', subCategoryName: 'Πάνες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Πάνες Νο.3 (4-9 kg)', subCategoryName: 'Πάνες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Πάνες Νο.4 (7-18 kg)', subCategoryName: 'Πάνες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Πάνες Νο.5 (11-25 kg)', subCategoryName: 'Πάνες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Πάνες Νο.6 (15+ kg)', subCategoryName: 'Πάνες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Πάνες για νύχτα', subCategoryName: 'Πάνες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Πάνες βρακάκι', subCategoryName: 'Πάνες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Πάνες βιολογικές', subCategoryName: 'Πάνες', defaultUnitName: 'Τεμάχιο'),
  (name: 'Πάνες για κολύμβηση', subCategoryName: 'Πάνες', defaultUnitName: 'Τεμάχιο'),

  // ── Μωρομάντηλα & Βρεφική Υγιεινή (10) ──────────────────────────────────
  (name: 'Μωρομάντηλα κλασικά', subCategoryName: 'Μωρομάντηλα & Βρεφική Υγιεινή', defaultUnitName: 'Τεμάχιο'),
  (name: 'Μωρομάντηλα με αλόη', subCategoryName: 'Μωρομάντηλα & Βρεφική Υγιεινή', defaultUnitName: 'Τεμάχιο'),
  (name: 'Μωρομάντηλα με χαμομήλι', subCategoryName: 'Μωρομάντηλα & Βρεφική Υγιεινή', defaultUnitName: 'Τεμάχιο'),
  (name: 'Μωρομάντηλα μεγάλη συσκευασία', subCategoryName: 'Μωρομάντηλα & Βρεφική Υγιεινή', defaultUnitName: 'Τεμάχιο'),
  (name: 'Μωρομάντηλα μικρή συσκευασία', subCategoryName: 'Μωρομάντηλα & Βρεφική Υγιεινή', defaultUnitName: 'Τεμάχιο'),
  (name: 'Μωρομάντηλα βιοδιασπώμενα', subCategoryName: 'Μωρομάντηλα & Βρεφική Υγιεινή', defaultUnitName: 'Τεμάχιο'),
  (name: 'Βρεφική κρέμα συγκάματος', subCategoryName: 'Μωρομάντηλα & Βρεφική Υγιεινή', defaultUnitName: 'Τεμάχιο'),
  (name: 'Βρεφικό λάδι', subCategoryName: 'Μωρομάντηλα & Βρεφική Υγιεινή', defaultUnitName: 'Χιλιοστόλιτρο'),
  (name: 'Βρεφικό σαμπουάν', subCategoryName: 'Μωρομάντηλα & Βρεφική Υγιεινή', defaultUnitName: 'Χιλιοστόλιτρο'),
  (name: 'Βρεφικό αφρόλουτρο', subCategoryName: 'Μωρομάντηλα & Βρεφική Υγιεινή', defaultUnitName: 'Χιλιοστόλιτρο'),

  // ── Βρεφικές Τροφές (10) ────────────────────────────────────────────────
  (name: 'Βρεφική κρέμα δημητριακών ρυζιού', subCategoryName: 'Βρεφικές Τροφές', defaultUnitName: 'Γραμμάριο'),
  (name: 'Βρεφική κρέμα δημητριακών βρώμης', subCategoryName: 'Βρεφικές Τροφές', defaultUnitName: 'Γραμμάριο'),
  (name: 'Βρεφική κρέμα δημητριακών σιταριού', subCategoryName: 'Βρεφικές Τροφές', defaultUnitName: 'Γραμμάριο'),
  (name: 'Βρεφικό βαζάκι κοτόπουλο', subCategoryName: 'Βρεφικές Τροφές', defaultUnitName: 'Τεμάχιο'),
  (name: 'Βρεφικό βαζάκι μοσχάρι', subCategoryName: 'Βρεφικές Τροφές', defaultUnitName: 'Τεμάχιο'),
  (name: 'Βρεφικό βαζάκο λαχανικά', subCategoryName: 'Βρεφικές Τροφές', defaultUnitName: 'Τεμάχιο'),
  (name: 'Βρεφικό βαζάκι φρούτα', subCategoryName: 'Βρεφικές Τροφές', defaultUnitName: 'Τεμάχιο'),
  (name: 'Βρεφικό μπισκότο', subCategoryName: 'Βρεφικές Τροφές', defaultUnitName: 'Τεμάχιο'),
  (name: 'Βρεφικό χυλό', subCategoryName: 'Βρεφικές Τροφές', defaultUnitName: 'Γραμμάριο'),
  (name: 'Βρεφικό γιαούρτι', subCategoryName: 'Βρεφικές Τροφές', defaultUnitName: 'Τεμάχιο'),

  // ── Βρεφικά Αξεσουάρ (10) ───────────────────────────────────────────────
  (name: 'Μπιμπερό γυάλινο', subCategoryName: 'Βρεφικά Αξεσουάρ', defaultUnitName: 'Τεμάχιο'),
  (name: 'Μπιμπερό πλαστικό', subCategoryName: 'Βρεφικά Αξεσουάρ', defaultUnitName: 'Τεμάχιο'),
  (name: 'Πιπίλα σιλικόνης', subCategoryName: 'Βρεφικά Αξεσουάρ', defaultUnitName: 'Τεμάχιο'),
  (name: 'Πιπίλα καουτσούκ', subCategoryName: 'Βρεφικά Αξεσουάρ', defaultUnitName: 'Τεμάχιο'),
  (name: 'Βρεφικό κουτάλι', subCategoryName: 'Βρεφικά Αξεσουάρ', defaultUnitName: 'Τεμάχιο'),
  (name: 'Βρεφικό πιάτο', subCategoryName: 'Βρεφικά Αξεσουάρ', defaultUnitName: 'Τεμάχιο'),
  (name: 'Βρεφικό ποτήρι', subCategoryName: 'Βρεφικά Αξεσουάρ', defaultUnitName: 'Τεμάχιο'),
  (name: 'Βρεφική σαλιάρα', subCategoryName: 'Βρεφικά Αξεσουάρ', defaultUnitName: 'Τεμάχιο'),
  (name: 'Βρεφική θήκη μπιμπερό', subCategoryName: 'Βρεφικά Αξεσουάρ', defaultUnitName: 'Τεμάχιο'),
  (name: 'Βρεφικό μασητικό', subCategoryName: 'Βρεφικά Αξεσουάρ', defaultUnitName: 'Τεμάχιο'),
];