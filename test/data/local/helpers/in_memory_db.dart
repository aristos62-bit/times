/// SPoT: Κοινό helper in-memory Drift βάση για τα data/local tests (§4.1 DESIGN).
///
/// Όλα τα tests του data layer (app_database + DAOs) χρησιμοποιούν αυτή τη
/// συνάρτηση, όχι δικό τους copy — αποφεύγεται η επανάληψη της ρύθμισης
/// (`NativeDatabase.memory()` + `closeStreamsSynchronously`). Το κλείσιμο της
/// βάσης ανατίθεται στον καλούντα μέσω `addTearDown(db.close)`.
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:times/data/local/app_database.dart';

/// Δημιουργεί in-memory `AppDatabase` με `NativeDatabase.memory()`.
///
/// `closeStreamsSynchronously: true` αποτρέπει στάσιμους stream queries από
/// το να κρατούν ανοιχτή τη βάση (drift teardown warning).
AppDatabase inMemoryDb() {
  return AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
}