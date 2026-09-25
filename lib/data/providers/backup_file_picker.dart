/// SPoT wrapper γύρω από το `file_picker` για τα αντίγραφα (§2.3 DESIGN /
/// Φάση 4 Βήμα 5).
///
/// Απομονώνει το static `FilePicker.platform` (untestable + API που αλλάζει
/// ανά έκδοση — evidence v12: `saveFile` θέλει bytes/δίνει `Uri?`,
/// `pickFile` δίνει `PlatformFile?`): ο controller εξαρτάται ΜΟΝΟ από το
/// abstract (override με fake στα tests, pattern `sharedPreferencesProvider`
/// / `appDatabaseProvider.overrideWithValue`). Dumb delegator: καθόλου
/// business logic, logging, SPoT strings — μόνο προώθηση + null-contract.
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Συμβόλαιο επιλογής/αποθήκευσης αρχείου αντιγράφου.
abstract interface class BackupFilePicker {
  /// Ανοίγει save dialog με [fileName] και γράφει [bytes].
  /// `true` = αποθηκεύτηκε· `false` = ακύρωση από τον χρήστη.
  Future<bool> saveBytes({required String fileName, required List<int> bytes});

  /// Ανοίγει pick dialog (sqlite/db). Επιστρέφει filesystem path ή `null`
  /// (ακύρωση — ή πλατφόρμα χωρίς path, π.χ. web, όπου το restore δεν
  /// υποστηρίζεται στο MVP).
  Future<String?> pickSingleFile();
}

/// Παραγωγική υλοποίηση πάνω στο `FilePicker.platform`.
final class FilePickerBackupPicker implements BackupFilePicker {
  @override
  Future<bool> saveBytes({
    required String fileName,
    required List<int> bytes,
  }) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: Uint8List.fromList(bytes),
    );
    // `null` = ακύρωση (κανένα side effect, ο καλών κάνει no-op + log).
    return uri != null;
  }

  @override
  Future<String?> pickSingleFile() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['sqlite', 'db', 'sqlite3'],
    );
    // `null` = ακύρωση· `path == null` (web) → ο καλών το μετρά ως ακύρωση.
    return picked?.path;
  }
}
