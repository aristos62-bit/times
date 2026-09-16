/// Abstract repository για τις μονάδες μέτρησης — Φάση 2, Βήμα 1 (DESIGN §4).
///
/// SPoT: Μοναδικό σημείο πρόσβασης στα δεδομένα μονάδων.
///
/// Error mapping: reads → DataLoadException, writes → DataLoadException
/// (προσωρινά, βλ. NOTE στο app_errors.dart).
library;

import '../local/app_database.dart';

/// Abstract interface — υλοποιείται πάνω στον UnitDao.
abstract interface class UnitRepository {
  /// Παρακολουθεί όλες τις μονάδες, αλφαβητικά.
  Stream<List<Unit>> watchAll();

  /// Διαβάζει μία μονάδα ή null αν δεν υπάρχει.
  Future<Unit?> getById(int id);

  /// Εισάγει μονάδα· επιστρέφει το νέο id.
  Future<int> insert({
    required String name,
    required String abbreviation,
    bool allowsDecimal = false,
  });

  /// Ενημερώνει name/abbreviation/allowsDecimal. True αν υπήρξε αλλαγή.
  Future<bool> updateById(
    int id, {
    String? name,
    String? abbreviation,
    bool? allowsDecimal,
  });

  /// Διαγραφή — επιτρέπεται πάντα (χωρίς dependents).
  Future<bool> deleteById(int id);
}
