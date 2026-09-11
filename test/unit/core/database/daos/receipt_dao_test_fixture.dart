// test/unit/core/database/daos/receipt_dao_test_fixture.dart
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/database/daos/daos.dart';
import 'package:expense_tracker/features/receipt/domain/models/receipt_input.dart';

/// Fixture για τα tests του [ReceiptDao].
///
/// Ανυψώνει μια [AppDatabase.test] με SettingDao/ItemDao/TagDao και
/// ετοιμάζει μια δοκιμαστική απόδειξη (1 γραμμή: itemId, qty 2 @ 10.00).
///
/// Χρησιμοποιείται από τα:
/// - receipt_dao_test.dart (CRUD)
/// - receipt_dao_aggregates_test.dart (aggregates)
class ReceiptDaoFixture {
  late AppDatabase db;
  late ReceiptDao dao;
  late ItemDao itemDao;
  late TagDao tagDao;
  late int categoryId;
  late int supplierId;
  late int itemId;

  Future<void> setUp() async {
    db = AppDatabase.test();
    final settingDao = SettingDao(db);
    itemDao = ItemDao(db);
    tagDao = TagDao(db);
    dao = ReceiptDao(
      db,
      settingDao: settingDao,
      itemDao: itemDao,
      tagDao: tagDao,
    );
    final categories = await db.select(db.categories).get();
    categoryId = categories.first.id;
    supplierId = await db.into(db.suppliers).insert(
          SuppliersCompanion.insert(
            name: 'Test Supplier',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
    itemId = await itemDao.createItem(
      ItemsCompanion.insert(
        name: 'Test Item',
        categoryId: categoryId,
        currentStock: const Value(10),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> tearDown() async {
    await db.close();
  }

  /// Δημιουργία απόδειξης μέσω DAO.
  /// Default: 1 γραμμή (itemId, qty 2 @ 10.00, vat 24%, discount 0), χωρίς πληρωμές.
  Future<int> createReceipt({
    DateTime? date,
    int? supplier,
    String? paymentMethod,
    List<ReceiptItemInput>? items,
    List<PaymentInput>? payments,
    String? invoiceNumber,
    String? notes,
  }) {
    return dao.createReceipt(
      ReceiptInput(
        date: date ?? DateTime(2026, 5, 15),
        supplierId: supplier ?? supplierId,
        paymentMethod: paymentMethod ?? 'cash',
        invoiceNumber: invoiceNumber,
        items: items ?? [ReceiptItemInput(itemId: itemId, quantity: 2, unitPrice: 10.0)],
        payments: payments ?? const [],
        notes: notes,
      ),
    );
  }
}