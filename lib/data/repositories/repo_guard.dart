/// SPoT guard repositories (01-10-2026) — ενοποίηση των 8 `_guard` αντιγράφων.
///
/// `on Exception` (όχι `on SqliteException`): στην παραγωγή η βάση τρέχει
/// σε background isolate (drift_flutter) και τα σφάλματα φτάνουν ως
/// `DriftRemoteException` (implements `Exception` — το `SqliteException`
/// δεν επιβιώνει της σειριοποίησης, βλ. drift remote protocol). `Error`
/// (π.χ. `StateError`) μένει σκόπιμα εκτός — programming errors δυνατά.
/// Χωρίς logging: λογκάρει ήδη μία φορά ο DAO guard (§1.7 DESIGN).
library;

import '../../core/errors/app_exceptions.dart';

/// Εκτελεί [op]· κάθε `Exception` → `DataLoadException` (const throw όπως
/// πριν — mapping μόνο, χωρίς stack).
Future<T> guardRepo<T>(Future<T> Function() op) async {
  try {
    return await op();
  } on Exception {
    throw const DataLoadException();
  }
}
