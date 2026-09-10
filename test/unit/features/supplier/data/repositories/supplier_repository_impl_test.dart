// test/unit/features/supplier/data/repositories/supplier_repository_impl_test.dart
//
// Επαληθεύει ότι το SupplierRepositoryImpl (pure delegate) προωθεί σωστά τις
// κλήσεις στον SupplierDao — συμπεριλαμβανομένου του custom aggregate
// getReceiptCount (customSelect) για UI badges.
// Δεν επαναλαμβάνονται λεπτομερείς έλεγχοι του DAO (supplier_dao_test.dart).
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/database/daos/daos.dart';
import 'package:expense_tracker/features/supplier/data/repositories/supplier_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupplierRepositoryImpl', () {
    late AppDatabase db;
    late SupplierRepositoryImpl repo;

    setUp(() async {
      db = AppDatabase.test();
      repo = SupplierRepositoryImpl(SupplierDao(db));
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> createSupplier(String name) => repo.create(
          SuppliersCompanion.insert(
            name: name,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    test('watchAll: αρχικά κενό', () async {
      expect(await repo.watchAll().first, isEmpty);
    });

    test('create + getById (δεδομένα γραμμένα μέσω repo)', () async {
      final id = await createSupplier('Γαλακτοκομικά Κρήτης');
      final supplier = await repo.getById(id);
      expect(supplier?.name, 'Γαλακτοκομικά Κρήτης');
      expect(supplier?.isActive, isTrue);
    });

    test('watchAll: reactive σε insert', () async {
      final stream = repo.watchAll();
      expect(await stream.first, isEmpty);
      await createSupplier('ΩΚΑΑ');
      expect((await stream.first), hasLength(1));
    });

    test('searchByName: case-insensitive LIKE + αγνοεί inactive', () async {
      final id = await createSupplier('MacDonald Ελλάς');
      expect(await repo.searchByName('MAC').first, hasLength(1));
      await repo.softDelete(id);
      expect(await repo.searchByName('MAC').first, isEmpty);
    });

    test('update: rename', () async {
      final id = await createSupplier('Παλιό');
      final supplier = (await repo.getById(id))!;
      await repo.update(
        supplier.toCompanion(true).copyWith(
              name: const Value('Νέο'),
              updatedAt: Value(DateTime.now()),
            ),
      );
      expect((await repo.getById(id))?.name, 'Νέο');
    });

    test('getReceiptCount: 0 χωρίς αποδείξεις', () async {
      final id = await createSupplier('Χωρίς Αποδείξεις');
      expect(await repo.getReceiptCount(id), 0);
    });

    test('getReceiptCount: μετράει μόνο αποδείξεις του προμηθευτή', () async {
      final other = await createSupplier('Άλλος');
      final id = await createSupplier('Με Αποδείξεις');
      final now = DateTime.now();

      final c1 = (await db.select(db.categories).get())[0];
      final c2 = (await db.select(db.categories).get())[1];

      // items για τους δύο προμηθευτές (το receipt κρατάει supplier μέσω supplierId)
      int itemCounter = 0;
      Future<int> seedItem(int supplierId, int catId) async {
        itemCounter += 1;
        return db.into(db.items).insert(
              ItemsCompanion.insert(
                name: 'Item-$supplierId-$itemCounter',
                categoryId: catId,
                lastSupplierId: Value(supplierId),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      int receiptCounter = 0;
      Future<void> seedReceipt(int supplierId, int catId) async {
        receiptCounter += 1;
        final itemId = await seedItem(supplierId, catId);
        final receiptId = await db.into(db.receipts).insert(
              ReceiptsCompanion.insert(
                receiptNumber: receiptCounter,
                receiptDate: now,
                supplierId: supplierId,
                createdAt: now,
                updatedAt: now,
              ),
            );
        await db.into(db.receiptItems).insert(
              ReceiptItemsCompanion.insert(
                receiptId: receiptId,
                itemId: itemId,
                quantity: const Value(1.0),
                unitPrice: 1.0,
                vatRate: Value(0.0),
                totalPrice: 1.0,
                totalWithVat: 1.0,
                createdAt: now,
              ),
            );
      }

      await seedReceipt(id, c1.id);
      await seedReceipt(id, c1.id);
      await seedReceipt(other, c2.id);

      expect(await repo.getReceiptCount(id), 2);
      expect(await repo.getReceiptCount(other), 1);
    });
  });
}