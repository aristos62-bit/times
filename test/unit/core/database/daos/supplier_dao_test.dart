import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/database/daos/daos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupplierDao', () {
    late AppDatabase db;
    late SupplierDao dao;

    setUp(() async {
      db = AppDatabase.test();
      dao = SupplierDao(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> createSupplier(String name) => dao.createSupplier(
          SuppliersCompanion.insert(
            name: name,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    test('watchAllSuppliers: αρχικά κενό', () async {
      expect(await dao.watchAllSuppliers().first, isEmpty);
    });

    test('createSupplier + getSupplierById', () async {
      final id = await createSupplier('Γαλακτοκομικά Κρήτης');
      final supplier = await dao.getSupplierById(id);
      expect(supplier?.name, 'Γαλακτοκομικά Κρήτης');
      expect(supplier?.isActive, isTrue);
    });

    test('watchAllSuppliers: reactive σε insert', () async {
      final stream = dao.watchAllSuppliers();
      expect(await stream.first, isEmpty);
      await createSupplier('ΩΚΑΑ');
      // Δεύτερο event μετά το insert
      final second = await stream.first;
      expect(second.length, 1);
    });

    test('searchSuppliersByName: case-insensitive LIKE', () async {
      await createSupplier('MacDonald Ελλάς');
      await createSupplier('Σκλαβενίτης');

      final results = await dao.searchSuppliersByName('MAC').first;
      expect(results.length, 1);
      expect(results.single.name, 'MacDonald Ελλάς');
    });

    test('searchSuppliersByName: excludes inactive', () async {
      final id = await createSupplier('Jumbo');
      await dao.softDeleteSupplier(id);

      expect(await dao.searchSuppliersByName('Jumbo').first, isEmpty);
    });

    test('updateSupplier: rename με full replace', () async {
      final id = await createSupplier('Παλιό Όνομα');

      final ok = await dao.updateSupplier(
        SuppliersCompanion.insert(
          id: Value(id),
          name: 'Νέο Όνομα',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      expect(ok, isTrue);
      expect((await dao.getSupplierById(id))?.name, 'Νέο Όνομα');
    });

    test('softDeleteSupplier: εξαφανίζεται από active λίστα', () async {
      final id = await createSupplier('Α.Β. Βασιλόπουλος');
      await dao.softDeleteSupplier(id);

      expect(await dao.watchAllSuppliers().first, isEmpty);
      expect((await dao.getSupplierById(id))?.isActive, isFalse);
    });

    test('getReceiptCount: 0 όταν δεν υπάρχουν αποδείξεις', () async {
      final id = await createSupplier('Χωρίς Αποδείξεις');
      expect(await dao.getReceiptCount(id), 0);
    });

    test('getReceiptCount: μετράει τις αποδείξεις του supplier', () async {
      final supplierId = await createSupplier('Με Αποδείξεις');
      final now = DateTime.now();

      await db.transaction(() async {
        await db.into(db.receipts).insert(ReceiptsCompanion.insert(
          receiptNumber: 1,
          receiptDate: now,
          supplierId: supplierId,
          createdAt: now,
          updatedAt: now,
        ));
        await db.into(db.receipts).insert(ReceiptsCompanion.insert(
          receiptNumber: 2,
          receiptDate: now,
          supplierId: supplierId,
          createdAt: now,
          updatedAt: now,
        ));
      });

      expect(await dao.getReceiptCount(supplierId), 2);
    });
  });
}