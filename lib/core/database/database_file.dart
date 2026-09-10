import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';

/// SPoT: Επίλυση της διαδρομής του αρχείου της βάσης.
///
/// Μοναδικό σημείο αλήθειας για το πού βρίσκεται το DB — χρησιμοποιείται τόσο
/// από το `AppDatabase` (άνοιγμα) όσο και από το `BackupService` (backup/restore),
/// ώστε να μην υπάρχει duplication και εκτός συγχρονισμού μονοπάτι. Κανένας
/// κύκλος εξαρτήσεων: το `app_database.dart` και τα backup imports εξαρτώνται
/// μόνο από αυτό το αρχείο, όχι μεταξύ τους.
Future<File> resolveDatabaseFile() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  return File(p.join(dbFolder.path, AppConstants.dbName));
}