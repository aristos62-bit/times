### 4.4 Drift Migrations (`core/database/migrations/`)

```dart
// Drift handles migrations through the MigrationStrategy in AppDatabase
// Example of future migration:

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) async {
    await m.createAll();
    await _seedAllVersions();
  },
  onUpgrade: (m, from, to) async {
    // Example: Migration from v1 to v2
    if (from < 2) {
      // Add new column
      await m.addColumn(items, items.sku);
      
      // Create new table
      await m.createTable(tags);
      await m.createTable(receiptTags);
    }
    
    // Example: Migration from v2 to v3
    if (from < 3) {
      // Rename column
      await m.renameColumn(suppliers, 'phone', 'landline');
    }
  },
  beforeOpen: (details) async {
    // Enable foreign keys
    await customStatement('PRAGMA foreign_keys = ON');
  },
);
```

### 4.5 Database Backup & Restore (`core/database/backup/`)

> **Πολιτική:** Τα δεδομένα είναι ο θησαυρός της εφαρμογής. Χωρίς backup,
> ο χρήστης χάνει όλα τα οικονομικά δεδομένα του (αποδείξεις, προμηθευτές,
> ιστορικό τιμών). Το backup πρέπει να υπάρχει από τον ΠΡΩΤΟ release.

```dart
// core/database/backup/backup_service.dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import '../app_database.dart';

/// SPO: Backup & Restore service
/// Εξάγει/εισάγει τη βάση + attachments σε ZIP αρχείο.
class BackupService {
  final AppDatabase _db;
  BackupService(this._db);

  static const String _backupDirName = 'backups';
  
  /// Κατασκευή backup φακέλου: <appDocuments>/backups/
  Future<Directory> _backupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(appDir.path, _backupDirName));
    if (!await backupDir.exists()) await backupDir.create(recursive: true);
    return backupDir;
  }
  
  /// Export: ZIP (.db + attachments folder + manifest.json)
  Future<File> createBackup({String? name}) async {
    final backupDir = await _backupDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:\.]'), '-');
    final fileName = name ?? 'backup_$timestamp';
    final zipPath = p.join(backupDir.path, '$fileName.zip');
    
    // 1. WAL CHECKPOINT — ΚΡΙΣΙΜΟ:
    //    Σε WAL mode, πρόσφατες εγγραφές ζουν στο ξεχωριστό .db-wal αρχείο.
    //    Χωρίς checkpoint, ένα raw copy του .db μπορεί να έχει ΠΑΛΙΑ δεδομένα
    //    (χωρίς error!). Το TRUNCATE "αδειάζει" το WAL μέσα στο κύριο .db.
    await _db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
    
    final archive = Archive();
    
    // 2. Βάση δεδομένων (μετά το checkpoint είναι ΠΛΗΡΗΣ)
    final dbDir = await getApplicationDocumentsDirectory();
    final dbFile = await resolveDatabaseFile();
    if (await dbFile.exists()) {
      archive.addFile(
        ArchiveFile('database/${AppConstants.dbName}', await dbFile.length(),
            await dbFile.readAsBytes()),
      );
    }
    
    // 3. Attachments (φωτογραφίες αποδείξεων)
    final attachmentsDir = Directory(p.join(dbDir.path, 'attachments'));
    if (await attachmentsDir.exists()) {
      await for (final entity in attachmentsDir.list(recursive: true)) {
        if (entity is File) {
          final relPath = p.relative(entity.path, from: dbDir.path);
          archive.addFile(
            ArchiveFile(relPath, await entity.length(), await entity.readAsBytes()),
          );
        }
      }
    }
    
    // 4. Manifest (μεταδεδομένα backup)
    final manifest = '{"version":1,"created":"$timestamp","db":"${AppConstants.dbName}"}';
    archive.addFile(ArchiveFile('manifest.json', manifest.length, manifest.codeUnits));
    
    // Εξαγωγή
    final zipBytes = ZipEncoder().encode(archive);
    return await File(zipPath).writeAsBytes(zipBytes!);
  }
  
  /// Restore: διαβάζει ZIP → αντικαθιστά .db + attachments
  Future<void> restoreFromBackup(String zipPath) async {
    // ΚΡΙΣΙΜΟ: Κλείνουμε τη ζωντανή σύνδεση ΠΡΙΝ αντικαταστήσουμε το αρχείο.
    //   - Στα Windows η αντικατάσταση αποτυγχάνει με open file handle.
    //   - Χωρίς close, η ζωντανή σύνδεση συνεχίζει να βλέπει ΠΑΛΙΑ δεδομένα
    //     από cache μέχρι restart — επικίνδυνο (ο χρήστης βλέπει παλιά data).
    await _db.close();
    
    try {
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      final dbDir = await getApplicationDocumentsDirectory();
      
      // Καθαρισμός παλιών WAL/SHM βοηθητικών αρχείων (θα δημιουργηθούν ξανά
      // από τη νέα βάση στο επόμενο άνοιγμα — αλλιώς περιέχουν παλιά δεδομένα).
      final dbFile = await resolveDatabaseFile();
      final dbWal = File('${dbFile.path}-wal');
      final dbShm = File('${dbFile.path}-shm');
      if (await dbWal.exists()) await dbWal.delete();
      if (await dbShm.exists()) await dbShm.delete();
      
      for (final file in archive) {
        final filePath = p.join(dbDir.path, file.name);
        if (file.isFile) {
          await File(filePath)
            ..createSync(recursive: true)
            ..writeAsBytesSync(file.content as List<int>);
        }
      }
      
      // Σημ.: ΔΕΝ ξανανοίγουμε εδώ τη βάση — το κάνει το app startup.
      // Ο UI ενημερώνει: "Η εφαρμογή θα κλείσει μετά την επαναφορά".
    } catch (e) {
      rethrow;
    }
  }
  
  /// Λίστα διαθέσιμων backups
  Future<List<FileSystemEntity>> listBackups() async {
    final dir = await _backupDirectory();
    if (!await dir.exists()) return [];
    return dir.listSync().whereType<File>().toList()
      ..sort((a, b) => b.path.compareTo(a.path));
  }
}
```

#### Πολιτική Backup
- **Τιποτικό backup εντός εφαρμογής:** Από το settings → "Δημιουργία backup"
- **Αυτόματο backup:** Προαιρετικό (μελλοντικά, π.χ. κάθε έξοδο εφαρμογής)
- **Restore:** Από settings → "Επαναφορά από backup". Επιβεβαίωση:
  "Η επαναφορά θα αντικαταστήσει όλα τα τρέχοντα δεδομένα και **η εφαρμογή θα κλείσει**"
  → μετά την επιτυχή restore, κλείνει η εφαρμογή (restart φορτώνει το backup)
- **Χρήστης μπορεί να στείλει το .zip στο cloud/SD card μόνος του (share sheet)**
- **Attachments** συμπεριλαμβάνονται ΠΑΝΤΑ στο backup (δεν γίνεται backup χωρίς τις φωτογραφίες)

#### Migration Tests (`test/unit/core/database/`)
- Κάθε `schemaVersion` bump: test με in-memory DB που εκτελεί upgrade v→v+1
- Test ότι η restore δημιουργεί functional DB (query receipt)
- Test ότι οι UUIDs παραμένουν μοναδικοί μετά από restore
---

