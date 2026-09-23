/// SPoT: Κόμβος του δέντρου καταλόγου για τον editor Ρυθμίσεων —
/// Φάση 4, Βήμα 3 (§2.3:274 DESIGN).
///
/// Το `CategoryTreeNode` είναι **projection**, όχι οντότητα πίνακα: παράγεται
/// in-memory από τον `categoryTreeStreamProvider` πάνω στις ήδη-φορτωμένες
/// λίστες (`categoryStreamProvider` + `subCategoriesStreamProvider` — ΚΑΝΕΝΑ
/// νέο DB query, σκεπτικό §3: μικρές λίστες, ίδιο με το `categorySearchProvider`).
/// Ζει στον ανοιχτό φάκελο `data/models` (§1.2 DESIGN) ως plain record
/// typedef — χωρίς Freezed (τα repos επιστρέφουν Drift data classes /
/// records απευθείας, ίδιο pattern με το `ReceiptSummary`).
///
/// Πεδία: η κατηγορία + οι υποκατηγορίες της (αλφαβητικά, όπως τα upstreams).
/// Κατηγορία χωρίς υποκατηγορίες → κενή λίστα. Χωρίς counts εδώ: η πύλη
/// διαγραφής ζει ξεχωριστά στα `canDelete*Provider` (bool), το πλήθος για
/// το tooltip το παίρνει το Βήμα 4 από το repository.
library;

import '../local/app_database.dart';

/// Κόμβος δέντρου «Κατηγορία ▸ Υποκατηγορίες» για το Βήμα 4 (tree editor).
typedef CategoryTreeNode = ({
  /// Η κατηγορία του κόμβου.
  Category category,

  /// Οι υποκατηγορίες της κατηγορίας, αλφαβητικά (`[]` αν δεν έχει).
  List<SubCategory> subCategories,
});
