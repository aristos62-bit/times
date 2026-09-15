/// SPoT: Βάση όλων των DAOs (Φάση 1, Βήμα 2) — §4.1 DESIGN.
///
/// Συμμετρικό error-handling για όλο το data layer:
///   * [guard] — εκτελεί/παρακολουθεί async op με πλήρες log (tag DB, §1.7)
///     και rethrow του **raw** σφάλματος (ποτέ AppException),
///   * [guardStream] — ίδια λογική πάνω σε stream (watch), έτσι ώστε και η
///     κατασκευή του stream αλλά και κάθε σφάλμα του να καταγράφονται.
///
/// Το mapping σε `AppException` (π.χ. `DataLoadException`) είναι ΑΠΟΚΛΕΙΣΤΙΚΟ
/// δικαίωμα του Repository (Φάση 2) — σύμβαση app_exceptions.dart: οι DAOs
/// είναι καθαρό data layer, χωρίς UI/oops/validators. Έτσι τα reads/streams
/// συμπεριφέρονται ακριβώς όπως τα writes (χωρίς asymmetric σχήμα).
library;

import '../../core/logging/app_logger.dart';
import 'app_database.dart';

/// Μοιραζόμενη συμπεριφορά DAO: κρατά τη σύνδεση [AppDatabase] και τους guards.
///
/// Όλα τα DAO του Βήματος 2 κληρονομούν αυτό, ώστε η διαχείριση σφαλμάτων να
/// μένει σε ΕΝΑ σημείο (SPoT) — οι μέθοδοι τους μόνο χτίζουν queries.
abstract class BaseDao {
  /// Η βάση (injected, όχι singleton) — επιτρέπει in-memory βάση στα tests.
  BaseDao(this.db);

  final AppDatabase db;

  /// Εκτελεί [op], λογκάρει σφάλμα (tag DB) και ξανα-πετάει το raw.
  ///
  /// [action] = dev-facing Ελληνικό μήνυμα στη μορφή `Action` (π.χ.
  /// «Εισαγωγή κατηγορίας») που εμφανίζεται στο log μαζί με το σφάλμα.
  Future<T> guard<T>(String action, Future<T> Function() op) async {
    try {
      return await op();
    } catch (e, s) {
      AppLogger.error(LogTag.db, action, e, s);
      rethrow;
    }
  }

  /// Επιστρέφει stream με την ίδια εγγύηση: κατασκευή/σφάλματα → log + raw.
  Stream<T> guardStream<T>(String action, Stream<T> Function() builder) {
    Stream<T> source;
    try {
      source = builder();
    } catch (e, s) {
      AppLogger.error(LogTag.db, action, e, s);
      return Stream<T>.error(e, s);
    }
    return source.handleError((Object e, StackTrace s) {
      AppLogger.error(LogTag.db, action, e, s);
      throw e;
    });
  }
}