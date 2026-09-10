import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/database/tables/tables.dart';
import 'package:flutter_test/flutter_test.dart' hide Tags;

void main() {
  group('Tables — schema μέσω AppDatabase', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.test();
    });

    tearDown(() async {
      await db.close();
    });

    test('δημιουργεί και τα 11 tables', () async {
      final tables = db.allTables.toList();
      final names = tables.map((t) => t.actualTableName).toList();
      expect(names, [
        'categories',
        'suppliers',
        'items',
        'receipts',
        'receipt_items',
        'payments',
        'price_history',
        'budgets',
        'tags',
        'receipt_tags',
        'user_settings',
      ]);
    });

    test('Categories έχει composite unique key', () {
      final t = db.categories;
      expect(t.uniqueKeys.length, 1);
      expect(t.uniqueKeys.first.length, 2);
    });

    test('ReceiptTags composite PK = 2 columns', () {
      final t = db.receiptTags;
      expect(t.primaryKey.length, 2);
    });

    test('όλα τα tables έχουν μοναδικά ονόματα', () {
      final names = db.allTables.map((t) => t.actualTableName).toSet();
      expect(names.length, 11);
    });
  });

  group('Barrel export', () {
    test('εξάγει όλα τα 11 tables', () {
      const tableTypes = <Type>[
        Categories,
        Suppliers,
        Items,
        Receipts,
        ReceiptItems,
        Payments,
        PriceHistory,
        Budgets,
        Tags,
        ReceiptTags,
        UserSettings,
      ];
      expect(tableTypes.length, 11);
    });

    test('εξάγει UtcDateTimeConverter', () {
      expect(UtcDateTimeConverter, isA<Type>());
    });
  });
}