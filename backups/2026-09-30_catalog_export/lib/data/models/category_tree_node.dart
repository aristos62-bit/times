/// SPoT: Κόμβοι του δέντρου καταλόγου 4 επιπέδων — 27-09-2026.
///
/// Projections (όχι οντότητες πίνακα): παράγονται in-memory από τον
/// `categoryTreeStreamProvider` πάνω στις ήδη-φορτωμένες λίστες (ΚΑΝΕΝΑ νέο
/// DB query, σκεπτικό §3). Ζουν στο `data/models` ως plain record typedefs —
/// χωρίς Freezed (pattern `ReceiptSummary`).
library;

import '../local/app_database.dart';

/// Κόμβος «Υποκατηγορία ▸ Τμήματα».
typedef SubCategoryTreeNode = ({
  /// Η υποκατηγορία του κόμβου.
  SubCategory subCategory,

  /// Τα τμήματα της υποκατηγορίας, αλφαβητικά (`[]` αν δεν έχει).
  List<ItemGroup> itemGroups,
});

/// Κόμβος δέντρου «Κατηγορία ▸ Υποκατηγορίες ▸ Τμήματα».
typedef CategoryTreeNode = ({
  /// Η κατηγορία του κόμβου.
  Category category,

  /// Οι υποκόμβοι της κατηγορίας, αλφαβητικά (`[]` αν δεν έχει).
  List<SubCategoryTreeNode> subNodes,
});
